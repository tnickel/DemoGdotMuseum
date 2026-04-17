extends Node

var config = ConfigFile.new()
var config_path = "user://settings.cfg"

# Default values
var music_volume_db = -12.0 # Master bus volume in dB (-40 = near silent, 0 = full)
var resolution_index = 3 # 3 = 2560x1440
var graphics_quality = 2 # 0: Low, 1: Medium, 2: High
var global_illumination = true
var atmosphere_preset = 4 # 0=L1, 1=L2, 2=L3, 3=L4, 4=L5
var pillar_light_color = Color(1.0, 0.5, 0.0) # Default orange/gold
var is_vr = false # Runtime flag evaluating if OpenXR was initialized
var vr_scale = 1.0 # Render scaling specifically for VR mode (PSVR2)
var show_perf_hud = true # Show FPS/Stats overlay in-game

var resolutions = [
    Vector2i(1280, 720),
    Vector2i(1600, 900),
    Vector2i(1920, 1080),
    Vector2i(2560, 1440),
    Vector2i(3840, 2160)
]

# Signal emitted when visual values change
signal settings_updated

func _ready():
    load_settings()

func load_settings():
    if config.load(config_path) == OK:
        resolution_index = config.get_value("display", "resolution_index", resolution_index)
        graphics_quality = config.get_value("display", "graphics_quality", graphics_quality)
        global_illumination = config.get_value("display", "global_illumination", global_illumination)
        atmosphere_preset = config.get_value("display", "atmosphere_preset", atmosphere_preset)
        pillar_light_color = config.get_value("display", "pillar_light_color", pillar_light_color)
        music_volume_db = config.get_value("audio", "music_volume_db", music_volume_db)
        vr_scale = config.get_value("display", "vr_scale", vr_scale)
        show_perf_hud  = config.get_value("display", "show_perf_hud",  show_perf_hud)
        
    _apply_resolution()
    apply_audio()

func save_settings():
    config.set_value("display", "resolution_index", resolution_index)
    config.set_value("display", "graphics_quality", graphics_quality)
    config.set_value("display", "global_illumination", global_illumination)
    config.set_value("display", "atmosphere_preset", atmosphere_preset)
    config.set_value("display", "pillar_light_color", pillar_light_color)
    config.set_value("audio",   "music_volume_db", music_volume_db)
    config.set_value("display", "vr_scale", vr_scale)
    config.set_value("display", "show_perf_hud",   show_perf_hud)
    config.save(config_path)

func apply_audio():
    var bus_idx = AudioServer.get_bus_index("Master")
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, music_volume_db)

func apply_graphics_settings():
    var effective_quality = graphics_quality
    if is_vr:
        effective_quality = 0 # Force "Low" preset visually

    var env_node = get_tree().root.find_child("WorldEnvironment", true, false)
    if env_node and env_node.environment:
        var env = env_node.environment
        env.ssao_enabled = (effective_quality >= 1)
        env.volumetric_fog_enabled = (effective_quality >= 1)
        env.sdfgi_enabled = global_illumination
        
    var dir_light = get_tree().root.find_child("DirectionalLight3D", true, false)
    if dir_light:
        dir_light.shadow_enabled = (effective_quality >= 1)

    var spot_light = get_tree().root.find_child("SpotLight3D", true, false)
    if spot_light:
        spot_light.shadow_enabled = (effective_quality >= 2)

    var vp = get_viewport()
    if vp:
        if is_vr:
            vp.msaa_3d = Viewport.MSAA_4X # Massive improvement for VR aliasing
        else:
            vp.msaa_3d = Viewport.MSAA_2X if effective_quality == 2 else Viewport.MSAA_DISABLED
            
        vp.scaling_3d_scale = vr_scale if is_vr else 1.0

func set_resolution(idx):
    resolution_index = idx
    _apply_resolution()

func _apply_resolution():
    var res = resolutions[resolution_index]
    DisplayServer.window_set_size(res)
    var screen = DisplayServer.screen_get_size()
    DisplayServer.window_set_position((screen - res) / 2)

func apply_visuals():
    settings_updated.emit()

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        get_tree().quit()
