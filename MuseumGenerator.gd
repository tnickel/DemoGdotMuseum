extends Node3D

const W_HEIGHT = 7.0
const W_THICK = 0.5
const CORR_WIDTH = 6.0
const CORR_LEN = 20.0
const HUB_RADIUS = 10.0
var artists_data = [
    {"id": "vangoth", "name": "Vince van Goth", "desc": "Post-Impressionist master\nknown for bold, dramatic \nbrush strokes and emotive\nlandscapes."},
    {"id": "davenci", "name": "Leon da Venci", "desc": "The ultimate Renaissance \nman, an unparalleled genius\nin art, science, and \nengineering."},
    {"id": "monero", "name": "Claudio Monero", "desc": "Founder of Impressionism,\ncapturing the fleeting nature\nof light across beautiful\nlandscapes."},
    {"id": "picasse", "name": "Paolo Picasse", "desc": "Spanish painter who pioneered\nCubism, radically distorting\nreality into striking \ngeometric forms."},
    {"id": "deli", "name": "Salvatore Deli", "desc": "Eccentric surrealist visionary\nfamous for his bizarre, \ndream-like melting imagery."}
]

var mat_floor = StandardMaterial3D.new()
var mat_wall = StandardMaterial3D.new()
var mat_frame = StandardMaterial3D.new()
var mat_pillar = StandardMaterial3D.new()
var mat_glass = StandardMaterial3D.new()
var mat_marble_white = StandardMaterial3D.new()
var mat_marble_warm = StandardMaterial3D.new()
var mat_gold_trim = StandardMaterial3D.new()
var mat_dome_copper = StandardMaterial3D.new()
var mat_pool_water = StandardMaterial3D.new()
var mat_lamp_glow = StandardMaterial3D.new()

var black_marble_tex: NoiseTexture2D = null

func get_pillar_marble_texture() -> NoiseTexture2D:
    if black_marble_tex: return black_marble_tex
    
    var noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.003 # V2 Style (Breiteres, deutlicheres Gold)
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 5
    noise.fractal_lacunarity = 2.0
    noise.fractal_gain = 0.5
    
    var grad = Gradient.new()
    
    # Safely configure the default 2 points
    grad.set_offset(0, 0.0)
    grad.set_color(0, Color(0.0, 0.0, 0.0))
    grad.set_offset(1, 1.0)
    grad.set_color(1, Color(0.0, 0.0, 0.0))
    
    # Add our golden veins
    grad.add_point(0.42, Color(0.01, 0.01, 0.01))
    grad.add_point(0.48, Color(0.15, 0.1, 0.02))
    grad.add_point(0.50, Color(0.9, 0.7, 0.4)) # Gold glowing veins
    grad.add_point(0.52, Color(0.15, 0.1, 0.02))
    grad.add_point(0.58, Color(0.01, 0.01, 0.01))
    
    var tex = NoiseTexture2D.new()
    tex.noise = noise
    tex.color_ramp = grad
    tex.seamless = true
    tex.width = 1024
    tex.height = 1024
    
    black_marble_tex = tex
    return tex

var old_env: Environment
var space_env: Environment
var drop_buttons = []
var return_buttons = []
var next_buttons = []

# Dynamic Web Image Setup
var current_space_idx = 0
var space_panoramas = [
    "res://textures/skyboxes/jwst_carina.jpg", # JWST Carina Cosmic Cliffs (17MB 4K/8K)
    "res://textures/skyboxes/jwst_pillars.jpg", # JWST Pillars of Creation (31MB 4K/8K)
    "res://textures/skyboxes/jwst_tarantula.jpg", # JWST Tarantula Nebula (22MB 4K/8K)
    "res://textures/skyboxes/jwst_herbig_haro.jpg", # JWST Herbig-Haro 46/47 (33MB 4K/8K)
    "res://textures/skyboxes/hubble_arp273.jpg", # Hubble Interacting Galaxies Arp 273 (19MB 4K/8K)
    "res://textures/skyboxes/space_1.png", # ESO Milky Way (23MB)
    "res://textures/skyboxes/space_2_small.png" # ESO Carina Nebula (23MB)
]

# Web Panoramas for Right-Click live fetching!
var online_panoramas = [
    "https://upload.wikimedia.org/wikipedia/commons/2/2a/Herbig-Haro_46-47_%28NIRCam_Image%29_%282023-131%29.png", # JWST Herbig-Haro 46/47
    "https://upload.wikimedia.org/wikipedia/commons/e/e0/Carina_Nebula_NIRCam_Image_%28High_Res%29.jpg", # JWST Carina Cosmic Cliffs
    "https://upload.wikimedia.org/wikipedia/commons/a/aa/UGC_1810_and_UGC_1813_in_Arp_273_%28captured_by_the_Hubble_Space_Telescope%29.jpg", # Hubble Arp 273 (User's interaction galaxies)
    "https://upload.wikimedia.org/wikipedia/commons/2/25/Pillars_of_Creation_%28NIRCam_Image%29.jpg", # JWST Pillars of Creation
    "https://upload.wikimedia.org/wikipedia/commons/5/5e/Cassiopeia_A_%28MIRI_Image%29.jpg", # JWST Cassiopeia A
    "https://upload.wikimedia.org/wikipedia/commons/c/c9/Crab_Nebula_%28NIRCam%29.jpg", # JWST Crab Nebula
    "https://upload.wikimedia.org/wikipedia/commons/5/5f/Ring_Nebula_-_NIRCam.jpg", # JWST Ring Nebula
    "https://cdn.eso.org/images/large/eso0934a.jpg", # ESO Milky Way alternative
    "https://cdn.eso.org/images/large/eso1242a.jpg"  # Hubble
]
var online_idx = 0

# UI and memory
var brightness_memory = {}
var universe_ui: CanvasLayer
var brightness_slider: HSlider
var ui_label: Label
var http_request: HTTPRequest

func get_active_world_env() -> WorldEnvironment:
    var root = get_tree().root
    var we = root.find_child("WorldEnvironment", true, false)
    return we

func build_universe_ui():
    universe_ui = CanvasLayer.new()
    universe_ui.visible = false
    
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    vbox.position.y -= 100
    
    var title = Label.new()
    title.text = "Galaxy Brightness"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    brightness_slider = HSlider.new()
    brightness_slider.min_value = 0.05
    brightness_slider.max_value = 2.0
    brightness_slider.step = 0.05
    brightness_slider.value = 1.0
    brightness_slider.custom_minimum_size.x = 400
    brightness_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    brightness_slider.value_changed.connect(_on_brightness_changed)
    vbox.add_child(brightness_slider)
    
    ui_label = Label.new()
    ui_label.text = "[Right Click] to Download Internet Space Imagery!"
    ui_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(ui_label)
    
    universe_ui.add_child(vbox)
    add_child(universe_ui)
    
    http_request = HTTPRequest.new()
    http_request.request_completed.connect(_on_http_completed)
    add_child(http_request)

func _on_brightness_changed(val: float):
    # Remember the setting for the current picture!
    brightness_memory[current_space_idx] = val
    # Update the sky dome immediately
    var mat = self.get_meta("sky_dome_mat")
    if mat:
        mat.albedo_color = Color(val, val, val, 1.0)

func _ready():
    # Hook into real-time settings
    var mgr = get_node_or_null("/root/SettingsManager")
    if mgr:
        mgr.settings_updated.connect(apply_atmosphere)

    build_universe_ui()

    setup_materials()
    create_space_env()
    generate_hub()
    generate_exterior()
    upgrade_interior_details()

    var angle_step = (PI * 2.0) / max(1, artists_data.size())
    for i in range(artists_data.size()):
        build_corridor(artists_data[i], i * angle_step)
        var p_angle = i * angle_step + angle_step / 2.0
        var norm_angle = fmod(p_angle, PI * 2.0)
        if abs(norm_angle - PI) > 0.1:
            place_pillar(p_angle, i == 0)

    generate_universe_room()

    # Place the player out on the plaza so they walk in through the entrance
    reposition_player_to_plaza()

    # Apply initial atmosphere
    apply_atmosphere()
    # Save the original env
    var we = get_active_world_env()
    if we and we.environment:
        old_env = we.environment

func evaluator_loop():
    print("Starting automated vitrine tests...")
    var artifact_dir = "C:/Users/tnickel/.gemini/antigravity/brain/f71db92b-5c0f-4075-823e-dde539179444/artifacts/"
    
    # Wait for environment to stabilize
    await get_tree().create_timer(1.0).timeout
    
    var angle = (PI * 2.0) / 5.0 * 0.5
    var px = sin(angle) * (10.0 + 0.5)
    var pz = cos(angle) * (10.0 + 0.5)
    
    # Hide the central rings so they don't block the camera!
    var hub = get_node_or_null("MuseumHub")
    if hub: hub.visible = false
    
    var cam = Camera3D.new()
    # Move camera much closer to the pillar (about 4 meters away) and look slightly up
    cam.position = Vector3(px * 0.6, 2.0, pz * 0.6)
    cam.fov = 60.0
    cam.current = true
    add_child(cam)
    cam.look_at(Vector3(px, 3.2, pz), Vector3.UP)
    
    var root = null
    for c in get_children():
        if c.name.begins_with("PillarRoot_"):
            root = c
            break
            
    if not root:
        print("Root not found!")
        get_tree().quit()
        return
        
    var inner = null
    var glass = null
    var spot_l = null
    var spot_r = null
    var placeholder = null
    
    for c in root.get_children():
        if c.name == "PillarInnerBackground": inner = c
        if c is CSGBox3D: glass = c
        if c is SpotLight3D:
            if spot_l == null: spot_l = c
            else: spot_r = c
        if c is MeshInstance3D and c.name != "PillarInnerBackground":
            placeholder = c
    
    for i in range(1, 11):
        # BASELINE RESET FOR EACH TEST
        inner.material_override = mat_pillar
        glass.visible = true
        
        spot_l.light_color = Color(1.0, 0.75, 0.3)
        spot_r.light_color = Color(1.0, 0.75, 0.3)
        spot_l.light_energy = 4.0
        spot_r.light_energy = 4.0
        spot_l.spot_angle = 25.0
        spot_r.spot_angle = 25.0
        spot_l.light_volumetric_fog_energy = 2.5
        spot_r.light_volumetric_fog_energy = 2.5
        
        mat_pillar.emission_enabled = true
        mat_pillar.emission_energy_multiplier = 0.05
        mat_pillar.albedo_color = Color(0.01, 0.01, 0.01)
        mat_pillar.roughness = 0.05 # Glossy reflection!
        mat_pillar.metallic = 0.9
        
        mat_glass.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
        mat_glass.metallic = 0.5
        
        match i:
            1:
                # V1: Very Sharp, Low Energy, Pitch Black Bg
                spot_l.light_energy = 1.0; spot_r.light_energy = 1.0
                spot_l.spot_angle = 20.0; spot_r.spot_angle = 20.0
                mat_pillar.emission_energy_multiplier = 0.0
            2:
                # V2: Moderate Wide, Smooth Dark Gloss Background
                spot_l.light_energy = 2.5; spot_r.light_energy = 2.5
                spot_l.spot_angle = 45.0; spot_r.spot_angle = 45.0
            3:
                # V3: Matte Background (No Mirror Reflection of spots)
                mat_pillar.roughness = 0.8
                spot_l.light_energy = 3.0; spot_r.light_energy = 3.0
            4:
                # V4: High Reflection Glass + Subtle Background
                mat_glass.metallic = 0.95
                mat_pillar.emission_energy_multiplier = 0.1
            5:
                # V5: Single Spot From Below Center
                spot_l.position = Vector3(0, -3.0, -0.5)
                spot_l.look_at_from_position(spot_l.position, Vector3(0, 0, -1.0), Vector3.UP)
                spot_r.visible = false
                spot_l.light_energy = 4.0
            6:
                # V6: Single Spot, Extremely Dark Room
                spot_l.light_energy = 1.5
                spot_l.spot_angle = 25.0
                mat_pillar.emission_enabled = false
            7:
                # V7: Reset Position, Very Soft High Energy
                spot_r.visible = true
                spot_l.position = Vector3(-1.2, -2.8, -0.2); spot_l.look_at_from_position(spot_l.position, Vector3(0, 0, -1.0), Vector3.UP)
                spot_r.position = Vector3(1.2, -2.8, -0.2); spot_r.look_at_from_position(spot_r.position, Vector3(0, 0, -1.0), Vector3.UP)
                spot_l.light_energy = 4.0; spot_r.light_energy = 4.0
                spot_l.spot_angle = 60.0; spot_r.spot_angle = 60.0
            8:
                # V8: White/Gold Split
                spot_l.light_color = Color(1.0, 1.0, 1.0)
                spot_r.light_color = Color(1.0, 0.7, 0.2)
            9:
                # V9: Super Gloss Background (Deep Reflections)
                mat_pillar.roughness = 0.05
                spot_l.light_energy = 1.5; spot_r.light_energy = 1.5
            10:
                # V10: Very Elegant Moderate Hybrid
                mat_pillar.emission_energy_multiplier = 0.08
                spot_l.light_energy = 2.0; spot_r.light_energy = 2.0
                spot_l.spot_angle = 35.0; spot_r.spot_angle = 35.0

        await get_tree().create_timer(1.2).timeout
        var img = get_viewport().get_texture().get_image()
        img.save_png(artifact_dir + "eval_v" + str(i) + ".png")
        print("Captured eval_v", i)
        
    print("Done! Evaluation finished.")
    get_tree().quit()

func _add_drop_button_in_hub():
    # Freestanding marble pedestal with a glowing red trigger button.
    # Placed at the +Z back of the hub so it sits opposite the entrance
    # and the player has to cross the hub to reach it.
    var pedestal_root = Node3D.new()
    pedestal_root.name = "HubDropPedestal"
    pedestal_root.position = Vector3(-6.0, 0, 0.0)
    add_child(pedestal_root)

    var pedestal = MeshInstance3D.new()
    var pm = CylinderMesh.new()
    pm.top_radius = 0.45
    pm.bottom_radius = 0.55
    pm.height = 1.1
    pedestal.mesh = pm
    pedestal.material_override = mat_marble_warm
    pedestal.position = Vector3(0, 0.55, 0)
    pedestal_root.add_child(pedestal)

    # Gold cap ring
    var cap = MeshInstance3D.new()
    var cm = CylinderMesh.new()
    cm.top_radius = 0.5
    cm.bottom_radius = 0.5
    cm.height = 0.05
    cap.mesh = cm
    cap.material_override = mat_gold_trim
    cap.position = Vector3(0, 1.125, 0)
    pedestal_root.add_child(cap)

    # The trigger button itself
    var btn = Area3D.new()
    var bmesh = CSGBox3D.new()
    bmesh.size = Vector3(0.5, 0.2, 0.5)
    var bmat = StandardMaterial3D.new()
    bmat.albedo_color = Color(1, 0, 0)
    bmat.emission_enabled = true
    bmat.emission = Color(1, 0.1, 0.1)
    bmat.emission_energy_multiplier = 2.5
    bmesh.material = bmat
    btn.add_child(bmesh)
    var col = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(1.5, 2.0, 1.5)
    col.shape = box_shape
    btn.add_child(col)
    btn.position = Vector3(0, 1.25, 0)
    pedestal_root.add_child(btn)
    drop_buttons.append(btn)

func apply_atmosphere():
    var mgr = get_node_or_null("/root/SettingsManager")
    if not mgr: return
    
    var preset = mgr.atmosphere_preset
    var l = [
        {"name": "L1", "fog": 0.04, "exposure": 1.0, "pillar_glow": 1.0, "bg_color": Color(0.01, 0.01, 0.015)},
        {"name": "L2", "fog": 0.005, "exposure": 1.2, "pillar_glow": 1.5, "bg_color": Color(0.02, 0.02, 0.02)},
        {"name": "L3", "fog": 0.02, "exposure": 0.75, "pillar_glow": 1.5, "bg_color": Color(0.002, 0.002, 0.002)},
        {"name": "L4", "fog": 0.06, "exposure": 1.4, "pillar_glow": 0.8, "bg_color": Color(0.015, 0.015, 0.015)},
        {"name": "L5", "fog": 0.00, "exposure": 1.1, "pillar_glow": 1.2, "bg_color": Color(0.005, 0.005, 0.005)}
    ][clamp(preset, 0, 4)]
    
    # Update Pillar Glow explicitly (Inner hollow walls)
    mat_pillar.emission_energy_multiplier = l["pillar_glow"]
    
    var p_light_color = mgr.pillar_light_color
    
    # Update environment globally
    var we = get_active_world_env()
    if we and we.environment:
        we.environment.volumetric_fog_density = l["fog"]
        we.environment.tonemap_exposure = l["exposure"]
        # Only apply flat background color when not using a sky panorama
        if we.environment.background_mode == Environment.BG_COLOR:
            we.environment.background_color = l["bg_color"]
        we.environment.glow_hdr_threshold = 0.8
        we.environment.glow_hdr_scale = 2.0
                
    # Update all internal pillar lights
    for c in get_children():
        if c.name.begins_with("PillarRoot_"):
            for child in c.get_children():
                if child is OmniLight3D:
                    child.light_color = p_light_color

func setup_materials():
    var pillar_marble_tex = get_pillar_marble_texture()
    
    # Warm Obsidian Floor (upgraded — warmer, slightly less mirror-like for luxury feel)
    mat_floor.albedo_color = Color(0.08, 0.07, 0.06)
    mat_floor.roughness = 0.12
    mat_floor.metallic = 0.7
    mat_floor.emission_enabled = false

    # Cream Marble Gallery Walls (upgraded — warmer, less clinical)
    mat_wall.albedo_color = Color(0.93, 0.90, 0.82)
    mat_wall.roughness = 0.55
    mat_wall.metallic = 0.05

    # Premium Brighter Gold framing (upgraded — more saturated gold)
    mat_frame.albedo_color = Color(0.95, 0.75, 0.25)
    mat_frame.metallic = 0.9
    mat_frame.roughness = 0.18
    
    # Premium Showcase Glass (for hollow pillars)
    mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat_glass.albedo_color = Color(1.0, 1.0, 1.0, 0.0) # Completely clear and invisible base!
    mat_glass.roughness = 0.02 # Almost smooth
    mat_glass.metallic = 0.6 # Moderate reflection to keep glass clear but visible
    mat_glass.cull_mode = BaseMaterial3D.CULL_DISABLED # Visible from both sides
    
    # Pillars (Glossy Black/Gold Marble)
    mat_pillar.albedo_color = Color(0.0, 0.0, 0.0) # Ensure base is completely black to prevent blowout
    mat_pillar.albedo_texture = pillar_marble_tex
    mat_pillar.metallic = 0.85
    mat_pillar.roughness = 0.15
    mat_pillar.emission_enabled = true
    mat_pillar.emission_texture = pillar_marble_tex
    mat_pillar.emission = Color(1.0, 1.0, 1.0)
    mat_pillar.emission_energy_multiplier = 1.0
    mat_pillar.uv1_scale = Vector3(1.5, 3.0, 1.5)

    # Classical White Marble (facade, columns, stairs, statues)
    mat_marble_white.albedo_color = Color(0.95, 0.94, 0.90)
    mat_marble_white.metallic = 0.1
    mat_marble_white.roughness = 0.35

    # Warm Cream Marble (pediment, plaza tiles, dome drum, roof)
    mat_marble_warm.albedo_color = Color(0.92, 0.87, 0.78)
    mat_marble_warm.metallic = 0.1
    mat_marble_warm.roughness = 0.40

    # Gold Trim (capitals, dome ribs, baseboards, pool lip)
    mat_gold_trim.albedo_color = Color(0.95, 0.75, 0.25)
    mat_gold_trim.metallic = 1.0
    mat_gold_trim.roughness = 0.18

    # Oxidized Copper Dome
    mat_dome_copper.albedo_color = Color(0.72, 0.42, 0.18)
    mat_dome_copper.metallic = 1.0
    mat_dome_copper.roughness = 0.25

    # Reflection Pool Water (mirror-like dark)
    mat_pool_water.albedo_color = Color(0.02, 0.05, 0.12)
    mat_pool_water.metallic = 1.0
    mat_pool_water.roughness = 0.02

    # Lamp bulb glow (strongly emissive warm light source)
    mat_lamp_glow.albedo_color = Color(1.0, 0.85, 0.55)
    mat_lamp_glow.emission_enabled = true
    mat_lamp_glow.emission = Color(1.0, 0.85, 0.55)
    mat_lamp_glow.emission_energy_multiplier = 6.0

func create_box(parent, size, pos, rot_y, mat, use_coll):
    var inst = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = size
    inst.mesh = mesh
    inst.material_override = mat
    inst.position = pos
    inst.rotation.y = rot_y
    parent.add_child(inst)
    
    if use_coll:
        var coll = StaticBody3D.new()
        var cshape = CollisionShape3D.new()
        cshape.shape = BoxShape3D.new()
        cshape.shape.size = size
        coll.add_child(cshape)
        inst.add_child(coll)

func place_pillar(angle, is_first: bool = false):
    # Places a huge architectural pillar to seal the gap between Corridors.
    # Converted to a procedural hollow CSG structure with a glass window and internal light!
    var dist = HUB_RADIUS + 0.5
    var px = sin(angle) * dist
    var pz = cos(angle) * dist
    
    var pillar_root = Node3D.new()
    pillar_root.name = "PillarRoot_" + str(angle)
    pillar_root.position = Vector3(px, W_HEIGHT/2.0, pz)
    pillar_root.rotation.y = angle # -Z axis points straight towards the hub center
    add_child(pillar_root)
    
    var csg = CSGCombiner3D.new()
    csg.use_collision = true
    pillar_root.add_child(csg)
    
    var p_radius = 3.5
    var p_height = W_HEIGHT + 0.2
    
    # 1. Outer Black Obsidian Shell
    var outer = CSGCylinder3D.new()
    outer.radius = p_radius
    outer.height = p_height
    outer.sides = 64
    
    # Force pitch black material on everything the CSG touches (no white frames!)
    var black_mat = StandardMaterial3D.new()
    black_mat.albedo_color = Color(0.01, 0.01, 0.01)
    black_mat.metallic = 0.8
    black_mat.roughness = 0.2
    outer.material = black_mat
    csg.add_child(outer)
    
    # 1.b) Hollow Core Subtraction! 
    var core = CSGCylinder3D.new()
    core.operation = CSGShape3D.OPERATION_SUBTRACTION
    core.radius = p_radius - 0.2
    core.height = p_height - 0.5
    core.sides = 64
    core.material = mat_pillar # THIS fixes the blinding white CSG rendering bug on floor/ceiling!
    csg.add_child(core)
    
    # 2. Window Cutout
    var cut = CSGBox3D.new()
    cut.operation = CSGShape3D.OPERATION_SUBTRACTION
    cut.size = Vector3(4.8, p_height - 1.5, p_radius * 1.5)
    cut.position = Vector3(0, 0, -p_radius) # Face explicitly to the front (-Z)
    cut.material = black_mat # Edges of the cut will be totally black
    csg.add_child(cut)
    
    # 3. Inner Hollow Wall (MeshInstance bypasses CSG material bugs entirely!)
    var inner = MeshInstance3D.new()
    inner.name = "PillarInnerBackground"
    var inner_mesh = CylinderMesh.new()
    inner_mesh.top_radius = p_radius - 0.2
    inner_mesh.bottom_radius = p_radius - 0.2
    inner_mesh.height = p_height - 0.5
    inner_mesh.flip_faces = true # Faces point INWARD toward the object!
    inner.mesh = inner_mesh
    inner.material_override = mat_pillar
    pillar_root.add_child(inner)
    
    # 4. The Glass Pane
    var glass = CSGBox3D.new()
    glass.size = Vector3(5.0, p_height - 1.5, 0.05)
    # Placed exactly on the front edge
    glass.position = Vector3(0, 0, -p_radius + 0.1)
    glass.material = mat_glass
    pillar_root.add_child(glass)
    
    # 5. Dual Beam Spotlights from below
    var spot_l = SpotLight3D.new()
    spot_l.position = Vector3(-1.0, -2.5, -0.5)
    spot_l.look_at_from_position(spot_l.position, Vector3(0, 0, -1.0), Vector3.UP)
    spot_l.light_color = Color(1.0, 0.75, 0.3) # Pure Golden Light
    spot_l.light_energy = 2.0
    spot_l.spot_angle = 35.0
    spot_l.light_volumetric_fog_energy = 2.5 # Visible physical light beams!
    spot_l.shadow_enabled = true
    pillar_root.add_child(spot_l)
    
    var spot_r = SpotLight3D.new()
    spot_r.position = Vector3(1.0, -2.5, -0.5)
    spot_r.look_at_from_position(spot_r.position, Vector3(0, 0, -1.0), Vector3.UP)
    spot_r.light_color = Color(1.0, 0.75, 0.3) # Pure Golden Light
    spot_r.light_energy = 2.0
    spot_r.spot_angle = 35.0
    spot_r.light_volumetric_fog_energy = 2.5 # Visible light beams
    spot_r.shadow_enabled = true
    pillar_root.add_child(spot_r)
    
    # 6. Showcase Artifact (A highly reflective metallic object that catches light beautifully!)
    var placeholder = MeshInstance3D.new()
    var p_mesh = BoxMesh.new()
    p_mesh.size = Vector3(1.2, 1.2, 1.2)
    placeholder.mesh = p_mesh
    placeholder.position = Vector3(0, 0, -1.0)
    placeholder.rotation.x = PI / 4.0
    placeholder.rotation.y = PI / 4.0
    
    var p_mat = StandardMaterial3D.new()
    p_mat.albedo_color = Color(0.1, 0.1, 0.1) # Dark, relies purely on spotlight!
    p_mat.metallic = 1.0 # Pure metal
    p_mat.roughness = 0.05 # Crystal clear mirror finish to reflect the beams
    placeholder.material_override = p_mat
    pillar_root.add_child(placeholder)

    if is_first:
        # 7. The Interactive Red Drop Button (Proximity Trigger!)
        var btn = Area3D.new()
        
        var bmesh = CSGBox3D.new()
        bmesh.size = Vector3(0.6, 0.6, 0.2)
        
        var bmat = StandardMaterial3D.new()
        bmat.albedo_color = Color(1, 0, 0)
        bmat.emission_enabled = true
        bmat.emission = Color(1, 0, 0)
        bmat.emission_energy_multiplier = 2.0
        bmesh.material = bmat
        btn.add_child(bmesh)
        
        var col = CollisionShape3D.new()
        var box_shape = BoxShape3D.new()
        box_shape.size = Vector3(1.5, 2.0, 1.5) # Large invisible trigger area!
        col.shape = box_shape
        btn.add_child(col)
        
        # Button prominently on the lower front frame (about 1 meter off the ground)
        # pillar_root is at W_HEIGHT / 2.0, so -W_HEIGHT/2.0 is the floor.
        btn.position = Vector3(0, -(W_HEIGHT / 2.0) + 1.0, -p_radius - 0.05)
        
        # Track the button for distance-checking instead of physics triggers
        drop_buttons.append(btn)
        
        pillar_root.add_child(btn)

func generate_hub():
    var hub = Node3D.new()
    hub.name = "CentralHub"
    add_child(hub)
    
    # Hub Floor
    var floor_mesh = CylinderMesh.new()
    floor_mesh.bottom_radius = HUB_RADIUS + 2.0
    floor_mesh.top_radius = HUB_RADIUS + 2.0
    floor_mesh.height = 0.2
    var f_inst = MeshInstance3D.new()
    f_inst.mesh = floor_mesh
    f_inst.material_override = mat_floor
    f_inst.position = Vector3(0, -0.1, 0)
    hub.add_child(f_inst)
    
    # Fast collision
    var hc = StaticBody3D.new()
    var hcs = CollisionShape3D.new()
    hcs.shape = CylinderShape3D.new()
    hcs.shape.radius = HUB_RADIUS + 2.0
    hcs.shape.height = 0.2
    hc.add_child(hcs)
    f_inst.add_child(hc)
    
    # Ceiling
    var c_inst = MeshInstance3D.new()
    c_inst.mesh = floor_mesh
    c_inst.material_override = mat_floor
    c_inst.position = Vector3(0, W_HEIGHT + 0.1, 0)
    hub.add_child(c_inst)
    
    # Glowing Statue in the center (from Labyrinth)
    var StatueClass = load("res://AbstractStatue.gd")
    if StatueClass:
        var st = StatueClass.new()
        st.scale = Vector3(1.5, 1.5, 1.5)
        st.position.y = 0.1
        hub.add_child(st)
        
    # World Environment (Premium Lighting + Cosmic Sky)
    var env_node = WorldEnvironment.new()
    var env = Environment.new()

    # Use JWST cosmic panorama as the sky (BG_SKY)
    env.background_mode = Environment.BG_SKY
    var sky = Sky.new()
    var sky_mat = PanoramaSkyMaterial.new()
    var sky_img = Image.load_from_file(ProjectSettings.globalize_path("res://textures/skyboxes/jwst_carina.jpg"))
    if sky_img:
        sky_mat.panorama = ImageTexture.create_from_image(sky_img)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.35

    env.tonemap_mode = Environment.TONE_MAPPER_ACES # Film-like color grading
    env.sdfgi_enabled = true                    # Software Raytracing GI
    env.sdfgi_use_occlusion = true
    env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
    env.volumetric_fog_enabled = true           # Soft atmosphere
    env.volumetric_fog_density = 0.008          # Reduced so sky is visible
    env.volumetric_fog_albedo = Color(0.9, 0.9, 0.95)
    env.glow_enabled = true                     # Makes the candles actually glow
    env.glow_bloom = 0.2
    env_node.environment = env
    hub.add_child(env_node)
    
    # Center Light
    var clight = OmniLight3D.new()
    clight.position = Vector3(0, W_HEIGHT - 0.5, 0)
    clight.omni_range = 30.0
    clight.light_energy = 3.5
    clight.shadow_enabled = true
    clight.light_volumetric_fog_energy = 2.5 # Enhances god-rays spreading from the center
    hub.add_child(clight)
    
    # Ambient Hub Floor Fill (prevents crushed blacks when SDFGI is off)
    var floor_fill = OmniLight3D.new()
    floor_fill.position = Vector3(0, 1.0, 0)
    floor_fill.omni_range = HUB_RADIUS * 1.8
    floor_fill.light_energy = 0.5
    floor_fill.shadow_enabled = false
    hub.add_child(floor_fill)
    
    # Grazing Floor Spots
    var spot_count = 12
    var sp_step = (PI * 2.0) / spot_count
    for i in range(spot_count):
        var a = i * sp_step
        var spot = SpotLight3D.new()
        # Place slightly above floor, right at the edge of the hub
        spot.position = Vector3(sin(a) * (HUB_RADIUS - 0.5), 0.2, cos(a) * (HUB_RADIUS - 0.5))
        # Point towards the center along the floor (horizontal)
        spot.rotation.y = a + PI
        spot.rotation.x = -0.05 # Slight downward angle to catch the marble floor speculars
        spot.spot_range = HUB_RADIUS + 2.0
        spot.light_energy = 2.0
        spot.spot_angle = 60.0
        spot.shadow_enabled = true
        hub.add_child(spot)

func build_corridor(a, angle):
    var corridor = Node3D.new()
    corridor.name = "Corridor_" + a.id
    corridor.rotation.y = angle
    add_child(corridor)
    
    var offset_z = HUB_RADIUS - 1.0 # start at the edge of the hub
    
    # Base Architecture
    # Floor
    create_box(corridor, Vector3(CORR_WIDTH, 0.2, CORR_LEN), Vector3(0, -0.1, offset_z + CORR_LEN/2.0), 0.0, mat_floor, true)
    
    # The Premium Carpet
    var carpet = MeshInstance3D.new()
    var cmesh = BoxMesh.new()
    var carpet_width = 3.0 # Slightly narrower than corridor
    cmesh.size = Vector3(carpet_width, 0.02, CORR_LEN)
    carpet.mesh = cmesh
    carpet.position = Vector3(0, 0.01, offset_z + CORR_LEN/2.0)
    
    var mat_carpet = StandardMaterial3D.new()
    var ctex = generate_carpet_texture()
    mat_carpet.albedo_texture = ctex
    mat_carpet.uv1_scale = Vector3(1.0, CORR_LEN/3.0, 1.0) # Stretch nicely along corridor
    mat_carpet.albedo_color = Color(0.8, 0.2, 0.2) # Deep gallery red base
    mat_carpet.roughness = 0.9 # Wool/fabric texture
    carpet.material_override = mat_carpet
    corridor.add_child(carpet)
    
    # Ceiling
    create_box(corridor, Vector3(CORR_WIDTH, 0.2, CORR_LEN), Vector3(0, W_HEIGHT + 0.1, offset_z + CORR_LEN/2.0), 0.0, mat_floor, true)
    
    # Left Wall (+X)
    create_box(corridor, Vector3(W_THICK, W_HEIGHT, CORR_LEN), Vector3(CORR_WIDTH/2.0 + W_THICK/2.0, W_HEIGHT/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_wall, true)
    # Right Wall (-X)
    create_box(corridor, Vector3(W_THICK, W_HEIGHT, CORR_LEN), Vector3(-CORR_WIDTH/2.0 - W_THICK/2.0, W_HEIGHT/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_wall, true)
    # Back Wall (+Z)
    create_box(corridor, Vector3(CORR_WIDTH + W_THICK*2, W_HEIGHT, W_THICK), Vector3(0, W_HEIGHT/2.0, offset_z + CORR_LEN + W_THICK/2.0), 0.0, mat_wall, true)
    
    # Baseboards (Skirting) for Graphic Design Detail
    var board_h = 0.15
    var board_t = 0.05
    # Left baseboard
    create_box(corridor, Vector3(board_t, board_h, CORR_LEN), Vector3(CORR_WIDTH/2.0 - board_t/2.0, board_h/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_pillar, false)
    # Right baseboard
    create_box(corridor, Vector3(board_t, board_h, CORR_LEN), Vector3(-CORR_WIDTH/2.0 + board_t/2.0, board_h/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_pillar, false)
    # Back baseboard
    create_box(corridor, Vector3(CORR_WIDTH, board_h, board_t), Vector3(0, board_h/2.0, offset_z + CORR_LEN - board_t/2.0), 0.0, mat_pillar, false)
    
    # The chandelier provides light and luxury
    var ChandelierClass = load("res://Chandelier.gd")
    if ChandelierClass:
        var ch = ChandelierClass.new()
        ch.position = Vector3(0, W_HEIGHT, offset_z + CORR_LEN/2.0)
        corridor.add_child(ch)

    # -----------------
    # Artwork Placement
    # -----------------
    var path = "res://artists/" + a.id + "/"
    
    var l_wall_x = CORR_WIDTH/2.0 - 0.05
    var r_wall_x = -CORR_WIDTH/2.0 + 0.05
    var r_rot = Vector3(0, PI/2.0, 0)
    var l_rot = Vector3(0, -PI/2.0, 0)
    
    var p_y = 2.5 # Constant comfortable viewing height regardless of ceiling height
    
    # Portrait
    add_picture(corridor, path + a.id + "_portrait", Vector3(r_wall_x, p_y, offset_z + 4.5), r_rot, true)
    
    # Description Text
    var lbl = Label3D.new()
    lbl.text = "— " + a.name.to_upper() + " —\n\n" + a.desc
    lbl.pixel_size = 0.003
    lbl.modulate = Color(0.1, 0.1, 0.1)
    lbl.font_size = 90
    lbl.outline_modulate = Color(1,1,1,0.2)
    lbl.outline_size = 2
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.position = Vector3(r_wall_x, p_y + 0.5, offset_z + 8.5)
    lbl.rotation = r_rot
    corridor.add_child(lbl)
    
    var spot_desc = SpotLight3D.new()
    spot_desc.position = Vector3(r_wall_x + 2.0, p_y + 1.5, offset_z + 8.5)
    spot_desc.rotation.x = -deg_to_rad(45.0)
    spot_desc.rotation.y = deg_to_rad(90.0)
    spot_desc.spot_range = 6.0
    spot_desc.light_energy = 1.0
    spot_desc.spot_angle = 45.0
    corridor.add_child(spot_desc)
        
    # LEFT & RIGHT WALLS: Paintings
    add_picture(corridor, path + a.id + "_p1", Vector3(l_wall_x, p_y, offset_z + 6.5), l_rot, true)
    add_picture(corridor, path + a.id + "_p2", Vector3(l_wall_x, p_y, offset_z + 14.5), l_rot, true)
    add_picture(corridor, path + a.id + "_p3", Vector3(r_wall_x, p_y, offset_z + 14.5), r_rot, true)
    
    # Back wall: feature painting
    add_picture(corridor, path + a.id + "_p4", Vector3(0, p_y, offset_z + CORR_LEN - 0.05), Vector3(0, PI, 0), true)

func add_picture(parent, texture_prefix, pos, rot, add_frame):
    var tex_path = texture_prefix + ".jpg"
    var dir = DirAccess.open("res://artists/" + texture_prefix.get_slice("/", 3))
    if dir:
        for f in dir.get_files():
            if f.begins_with(texture_prefix.get_file()) and f.ends_with(".jpg") and not f.ends_with(".import"):
                tex_path = "res://artists/" + texture_prefix.get_slice("/", 3) + "/" + f
                break
    
    var file = Image.new()
    if file.load(ProjectSettings.globalize_path(tex_path)) != OK:
        print("Missing texture for: ", texture_prefix)
        return null
        
    var tex = ImageTexture.create_from_image(file)
    if not tex: return null
    
    var quad = MeshInstance3D.new()
    var mat = StandardMaterial3D.new()
    mat.albedo_texture = tex
    mat.metallic = 0.05
    mat.roughness = 0.4
    
    var qmesh = QuadMesh.new()
    var aspect = float(tex.get_width()) / float(tex.get_height())
    var p_height = 2.5
    qmesh.size = Vector2(p_height * aspect, p_height)
    
    quad.mesh = qmesh
    quad.material_override = mat
    quad.position = pos
    quad.rotation = rot
    parent.add_child(quad)
    
    if add_frame:
        var frame = MeshInstance3D.new()
        var fbox = BoxMesh.new()
        fbox.size = Vector3(qmesh.size.x + 0.3, qmesh.size.y + 0.3, 0.1)
        frame.mesh = fbox
        frame.material_override = mat_frame
        frame.position = Vector3(0, 0, -0.06)
        quad.add_child(frame)
        
        var spot = SpotLight3D.new()
        spot.position = Vector3(0, 2.5, 2.0)
        spot.rotation.x = -deg_to_rad(50.0)
        spot.spot_range = 6.0
        spot.light_energy = 4.0
        spot.spot_angle = 35.0
        spot.shadow_enabled = true
        quad.add_child(spot)
        
    return quad

func generate_carpet_texture():
    var img = Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
    for y in range(256):
        for x in range(256):
            var c = Color(0.6, 0.1, 0.1) # Base Red
            # Golden borders
            if (x < 24 and x > 16) or (x > 232 and x < 240):
                c = Color(0.9, 0.7, 0.1)
            if (y < 24 and y > 16) or (y > 232 and y < 240):
                c = Color(0.9, 0.7, 0.1)
            img.set_pixel(x, y, c)
    return ImageTexture.create_from_image(img)

func generate_universe_room():
    var univ = Node3D.new()
    univ.name = "UniverseRoom"
    univ.position = Vector3(0, -100, 1000) # Very far away
    add_child(univ)
    
    # 1. Glass Dome
    var dome = CSGSphere3D.new()
    dome.radius = 40.0
    dome.radial_segments = 64
    dome.rings = 32
    var mat_glass = StandardMaterial3D.new()
    mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat_glass.albedo_color = Color(1.0, 1.0, 1.0, 0.1)
    mat_glass.roughness = 0.05
    mat_glass.metallic = 0.9
    dome.material = mat_glass
    univ.add_child(dome)
    
    # Glass Platform Floor (Floating in the galaxy)
    var floor = CSGCylinder3D.new()
    floor.radius = 39.5
    floor.height = 1.0
    floor.position = Vector3(0, -20.0, 0)
    var f_mat = StandardMaterial3D.new()
    f_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    f_mat.albedo_color = Color(0.05, 0.2, 0.5, 0.15) # Barely visible blue tint
    f_mat.metallic = 1.0 # Perfectly reflective
    f_mat.roughness = 0.05 # Slight blur for realism
    f_mat.clearcoat_enabled = true # High-end glass shine
    f_mat.clearcoat = 1.0
    floor.material = f_mat
    floor.use_collision = true
    univ.add_child(floor)
    
    # Glowing Pedestal in the center
    var ped = CSGCylinder3D.new()
    ped.radius = 2.0
    ped.height = 1.0
    ped.position = Vector3(0, -19.5, 0)
    var p_mat = StandardMaterial3D.new()
    p_mat.albedo_color = Color(0.2, 0.2, 0.2)
    p_mat.metallic = 1.0
    p_mat.roughness = 0.3
    ped.material = p_mat
    univ.add_child(ped)
    
    # Ambient Light for the Dome
    var dome_light = OmniLight3D.new()
    dome_light.position = Vector3(0, 5.0, 0)
    dome_light.light_color = Color(0.8, 0.9, 1.0)
    dome_light.light_energy = 5.0
    dome_light.omni_range = 50.0
    dome_light.shadow_enabled = true
    univ.add_child(dome_light)
    
    # 2. Return Button (In the center of the dome)
    var ret_btn = Area3D.new()
    ret_btn.position = Vector3(0, -18.5, 0) # Center of the dome
    
    var rb = CSGBox3D.new()
    rb.size = Vector3(1.0, 1.0, 1.0)
    var b_mat = StandardMaterial3D.new()
    b_mat.albedo_color = Color(1.0, 0.0, 0.0)
    b_mat.emission_enabled = true
    b_mat.emission = Color(1.0, 0.0, 0.0)
    b_mat.emission_energy_multiplier = 3.0
    rb.material = b_mat
    ret_btn.add_child(rb)
    
    var col = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(2.5, 2.5, 2.5) # Large trigger area!
    col.shape = box
    ret_btn.add_child(col)
    
    return_buttons.append(ret_btn)
    univ.add_child(ret_btn)
    
    # 3. Next Galaxy Button (Offset from center)
    var nxt_btn = Area3D.new()
    nxt_btn.position = Vector3(8.0, -18.5, 0)
    var n_ped = CSGCylinder3D.new()
    n_ped.radius = 1.5
    n_ped.height = 1.0
    n_ped.position = Vector3(0, -1.0, 0)
    var n_mat = StandardMaterial3D.new()
    n_mat.albedo_color = Color(0.1, 0.1, 0.1)
    n_mat.emission_enabled = true
    n_mat.emission = Color(0.1, 0.5, 1.0) # Bright Blue Button
    n_mat.emission_energy_multiplier = 4.0
    n_ped.material = n_mat
    nxt_btn.add_child(n_ped)
    univ.add_child(nxt_btn)
    next_buttons.append(nxt_btn)
    
    # NEW: Giant Physical Sky Dome (Bypasses Godot PanoramaSkyMaterial Pipeline bugs)
    var sky_dome = CSGSphere3D.new()
    sky_dome.radius = 800.0
    sky_dome.radial_segments = 64
    sky_dome.rings = 32
    sky_dome.flip_faces = true # We are INSIDE the sphere!
    var s_mat = StandardMaterial3D.new()
    s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    var b_img = Image.load_from_file(space_panoramas[0])
    s_mat.albedo_texture = ImageTexture.create_from_image(b_img)
    sky_dome.material = s_mat
    univ.add_child(sky_dome)
    self.set_meta("sky_dome_mat", s_mat)
func trigger_drop(player: Node3D):
    if not player or not "can_move" in player: return
    player.can_move = false
    
    # CRITICAL FIX: Correctly locate the active Environment node inside CentralHub
    var we = get_active_world_env()
    if we and space_env:
        we.environment = space_env
        
    # Build sweeping Path down to the Dome
    var track = Path3D.new()
    var curve = Curve3D.new()
    
    # Extreme winding water-slide coords
    curve.add_point(Vector3(0, 150, 950), Vector3(0, 0, -20), Vector3(0, -30, 20))
    curve.add_point(Vector3(80, 50, 975), Vector3(-40, 20, 0), Vector3(40, -20, 0))
    curve.add_point(Vector3(-80, -20, 990), Vector3(-40, 40, 0), Vector3(40, -40, 0))
    curve.add_point(Vector3(0, -118, 1000), Vector3(0, 40, 0), Vector3(0, -10, 0))
    track.curve = curve
    add_child(track)
    
    # NEW: Hexagonal Cyber Tube!
    var tube = CSGPolygon3D.new()
    tube.mode = CSGPolygon3D.MODE_PATH
    tube.path_node = tube.get_path_to(track)
    
    var circle_pts = PackedVector2Array()
    var segments = 6 # Hexagon for cool sci-fi aesthetic!
    for i in range(segments):
        var a = (float(i) / segments) * PI * 2.0
        circle_pts.append(Vector2(cos(a), sin(a)) * 5.0)
    tube.polygon = circle_pts
    tube.smooth_faces = false # Flat shaded high-speed tunnel
    tube.path_interval = 2.0
    
    var tube_mat = StandardMaterial3D.new()
    tube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    tube_mat.albedo_color = Color(0.02, 0.05, 0.1, 0.6) # Darker glass to make neon pop!
    tube_mat.metallic = 1.0
    tube_mat.roughness = 0.0
    tube_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    tube.material = tube_mat
    add_child(tube)
    
    var follower = PathFollow3D.new()
    follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
    track.add_child(follower)
    
    # Intense Rainbow Neon Warp Rings
    var length = curve.get_baked_length()
    var spacing = 10.0 
    var count = int(length / spacing)
    for i in range(count):
        var tr = curve.sample_baked_with_rotation(float(i) * spacing)
        tr = tr.rotated_local(Vector3(1, 0, 0), PI / 2.0)
        
        var ring = CSGTorus3D.new()
        ring.inner_radius = 4.8
        ring.outer_radius = 5.2
        ring.global_transform = tr
        var mat = StandardMaterial3D.new()
        mat.emission_enabled = true
        # Gradient from Cyan to Hot Pink down the length
        var progress = float(i) / float(count)
        var hc = Color(0.1, 1.0, 1.0).lerp(Color(1.0, 0.0, 0.8), progress)
        mat.emission = hc
        mat.emission_energy_multiplier = 6.0
        ring.material = mat
        track.add_child(ring)
        
    var parent = player.get_parent()
    if parent: parent.remove_child(player)
    follower.add_child(player)
    player.position = Vector3.ZERO
    player.rotation = Vector3.ZERO
    
    # Dynamic Barrel-Roll Water Slide Animation!
    var tw = get_tree().create_tween()
    tw.set_parallel(true)
    tw.tween_property(follower, "progress_ratio", 1.0, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    
    # Spin the player wildly as they fall (3 Full barrel rolls)
    var tw_spin = get_tree().create_tween()
    tw_spin.tween_method(func(v): player.rotation.z = v, 0.0, PI * 6.0, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    
    tw.chain().tween_callback(func():
        follower.remove_child(player)
        add_child(player)
        
        if is_instance_valid(track): track.queue_free()
        if is_instance_valid(tube): tube.queue_free()
        
        # Land safely 15 meters away from the center button!
        player.global_position = Vector3(0, -118, 1015) 
        player.rotation = Vector3.ZERO 
        player.can_move = true
    )

func return_to_museum(player: Node3D):
    var we = get_active_world_env()
    if we and old_env:
        we.environment = old_env
        
    player.global_position = Vector3(0, 0.5, 0)
    player.rotation = Vector3.ZERO
    player.can_move = true

var debug_timer = 0.0

func _process(delta):
    var player = get_tree().root.find_child("Player", true, false)
    
    if not player or not player.get("can_move"): return
    
    # 1. Check drop buttons (Museum to Dome)
    for btn in drop_buttons:
        if player.global_position.distance_to(btn.global_position) < 2.5:
            print("[DEBUG MuseumGenerator] DROP TRIGGERED BY DISTANCE!")
            trigger_drop(player)
            return
            
    # 2. Check return buttons (Dome to Museum)
    for btn in return_buttons:
        if player.global_position.distance_to(btn.global_position) < 3.0:
            print("[DEBUG MuseumGenerator] RETURN TRIGGERED BY DISTANCE!")
            return_to_museum(player)
            return
            
    # 3. Check Next Galaxy buttons
    for btn in next_buttons:
        if player.global_position.distance_to(btn.global_position) < 2.5:
            print("[DEBUG MuseumGenerator] NEXT GALAXY TRIGGERED!")
            current_space_idx = (current_space_idx + 1) % space_panoramas.size()
            _apply_galaxy_image(space_panoramas[current_space_idx])
            
            # Bump player away slightly backwards
            var push_dir = (player.global_position - btn.global_position).normalized()
            push_dir.y = 0
            if push_dir.length() < 0.1: push_dir = Vector3(1, 0, 0)
            player.global_position += push_dir * 4.0
            player.global_position.y = -118
            return
            
    # Show mapping UI ONLY when inside dome
    if universe_ui:
        universe_ui.visible = (player.global_position.y < -50)

func _apply_galaxy_image(path: String):
    var p_img = Image.load_from_file(path)
    var s_mat = self.get_meta("sky_dome_mat")
    if p_img and s_mat:
        s_mat.albedo_texture = ImageTexture.create_from_image(p_img)
        # Restore specific brightness memory
        var stored_b = brightness_memory.get(current_space_idx, 1.0)
        s_mat.albedo_color = Color(stored_b, stored_b, stored_b, 1.0)
        if brightness_slider: brightness_slider.value = stored_b

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        var player = get_tree().root.find_child("Player", true, false)
        if player and player.global_position.y < -50:
            if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
                print("Already downloading!")
                return
                
            var url = online_panoramas[online_idx]
            ui_label.text = "Downloading High-Res Internet Image... Please Wait!"
            ui_label.modulate = Color(1, 1, 0)
            
            http_request.request(url)
            print("[DEBUG] Started HTTP request to: ", url)

func _on_http_completed(result, response_code, headers, body):
    var current_url = online_panoramas[online_idx]
    online_idx = (online_idx + 1) % online_panoramas.size()
    
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        ui_label.text = "Download Failed! Response Details: " + str(response_code)
        ui_label.modulate = Color(1, 0, 0)
        return
        
    var image = Image.new()
    var err = image.load_png_from_buffer(body)
    var is_png = true
    if err != OK: 
        err = image.load_jpg_from_buffer(body)
        is_png = false
        
    if err == OK:
        ui_label.text = "[Right Click] to Download Internet Space Imagery!"
        ui_label.modulate = Color(1, 1, 1)
        
        # Save to TMP directory so user can see it physically!
        var dir = DirAccess.open("res://textures/skyboxes/")
        if dir and not dir.dir_exists("tmp"):
            dir.make_dir("tmp")
            
        var filename = current_url.get_file()
        if not filename.contains("."):
            filename += ".png" if is_png else ".jpg"
        var save_path = "res://textures/skyboxes/tmp/" + filename
        
        if is_png:
            image.save_png(save_path)
        else:
            image.save_jpg(save_path)
            
        print("[DEBUG] Saved Right-Click Download to: ", save_path)
        
        var tex = ImageTexture.create_from_image(image)
        space_panoramas.append(save_path)
        current_space_idx = space_panoramas.size() - 1
        
        var s_mat = self.get_meta("sky_dome_mat")
        if s_mat:
            s_mat.albedo_texture = tex
            var stored_b = brightness_memory.get(current_space_idx, 1.0)
            s_mat.albedo_color = Color(stored_b, stored_b, stored_b, 1.0)
            if brightness_slider: brightness_slider.value = stored_b
    else:
        ui_label.text = "Failed to parse image from download!"
        ui_label.modulate = Color(1, 0, 0)

func create_space_env():
    # Use a pure black environment void without fog, and rely on the physical SkyDome for visuals.
    space_env = Environment.new()
    space_env.background_mode = Environment.BG_COLOR
    space_env.background_color = Color.BLACK
    space_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    space_env.ambient_light_color = Color(0.1, 0.1, 0.1)
    space_env.glow_enabled = true
    space_env.volumetric_fog_enabled = false

# ============================================================
#  EXTERIOR — Classical Museum Facade, Plaza, Dome, Colonnades
# ============================================================

func generate_exterior():
    var ex = Node3D.new()
    ex.name = "Exterior"
    add_child(ex)

    generate_plaza(ex)
    generate_reflection_pool(ex)
    generate_lamp_posts(ex)
    generate_staircase(ex)
    generate_portico(ex)
    generate_pediment(ex)
    generate_facade(ex)
    generate_dome(ex)
    generate_entrance_statues(ex)
    generate_building_envelope(ex)
    generate_exterior_lighting(ex)

func generate_building_envelope(parent: Node3D):
    # Outer pentagonal shell that joins the ends of the five radial corridors
    # so the museum reads as a closed building from the outside. Each wall
    # sits tangent to a circle of radius HUB_RADIUS - 1 + CORR_LEN = 29, at
    # the angle halfway between two adjacent corridors (so the walls never
    # cut through corridor geometry).
    var r_tangent = HUB_RADIUS - 1.0 + CORR_LEN + 0.3   # ~29.3
    var wall_h = 8.0
    var wall_t = 0.5
    var angle_step = TAU / 5.0
    # Pentagon edge length for a tangent circle of radius r: 2·r·tan(36°).
    var edge_len = 2.0 * r_tangent * tan(deg_to_rad(36.0))

    for i in range(5):
        # Bisector angle between corridor i and corridor i+1.
        var bisect = i * angle_step + angle_step / 2.0
        # Skip the bisector that sits behind the facade/portico (≈180°).
        # The facade itself closes that side of the building.
        var norm_angle = fmod(bisect, TAU)
        if abs(norm_angle - PI) < 0.1:
            continue

        var wall = MeshInstance3D.new()
        var wm = BoxMesh.new()
        wm.size = Vector3(edge_len, wall_h, wall_t)
        wall.mesh = wm
        wall.material_override = mat_marble_white
        wall.position = Vector3(sin(bisect) * r_tangent, wall_h / 2.0, cos(bisect) * r_tangent)
        # Rotate so the wall's local +X runs along the tangent direction,
        # i.e. its normal points outward along the bisector.
        wall.rotation.y = bisect
        parent.add_child(wall)

        var coll = StaticBody3D.new()
        var cs = CollisionShape3D.new()
        cs.shape = BoxShape3D.new()
        cs.shape.size = wm.size
        coll.add_child(cs)
        wall.add_child(coll)

        # Gold frieze band near the top for a bit of cornice detail.
        var band = MeshInstance3D.new()
        var bm = BoxMesh.new()
        bm.size = Vector3(edge_len, 0.25, wall_t + 0.05)
        band.mesh = bm
        band.material_override = mat_gold_trim
        band.position = Vector3(sin(bisect) * r_tangent, wall_h - 0.25, cos(bisect) * r_tangent)
        band.rotation.y = bisect
        parent.add_child(band)

func generate_plaza(parent: Node3D):
    # Large marble plaza extending from the hub edge out into the cosmic void.
    var plaza = MeshInstance3D.new()
    var pmesh = BoxMesh.new()
    pmesh.size = Vector3(80, 0.2, 60)
    plaza.mesh = pmesh
    # Sat slightly below the circular hub floor (y_top=0) to eliminate Z-fighting
    # in the overlap zone near z=-10..-12 where the hub cylinder (r=12) and the
    # rectangular plaza share the same height.
    plaza.position = Vector3(0, -0.115, -40)
    plaza.material_override = mat_marble_warm
    parent.add_child(plaza)

    # Collision for the plaza so the player can walk
    var coll = StaticBody3D.new()
    var cshape = CollisionShape3D.new()
    cshape.shape = BoxShape3D.new()
    cshape.shape.size = Vector3(80, 0.2, 60)
    coll.add_child(cshape)
    plaza.add_child(coll)

func generate_reflection_pool(parent: Node3D):
    var pool_center = Vector3(0, 0, -45)

    # Basin (recessed marble box)
    var basin = CSGBox3D.new()
    basin.size = Vector3(20, 0.4, 10)
    basin.position = pool_center + Vector3(0, -0.2, 0)
    basin.material = mat_marble_white
    basin.use_collision = true
    parent.add_child(basin)

    # Water surface (mirror plane just above basin)
    var water = MeshInstance3D.new()
    var wmesh = PlaneMesh.new()
    wmesh.size = Vector2(19.5, 9.5)
    water.mesh = wmesh
    water.material_override = mat_pool_water
    water.position = pool_center + Vector3(0, 0.02, 0)
    parent.add_child(water)

    # Gold trim lip around the pool
    var lip_t = 0.25
    var lip_h = 0.15
    var lips = [
        {"size": Vector3(20.5, lip_h, lip_t), "pos": pool_center + Vector3(0, lip_h/2.0, 5.125)},
        {"size": Vector3(20.5, lip_h, lip_t), "pos": pool_center + Vector3(0, lip_h/2.0, -5.125)},
        {"size": Vector3(lip_t, lip_h, 10.5), "pos": pool_center + Vector3(10.125, lip_h/2.0, 0)},
        {"size": Vector3(lip_t, lip_h, 10.5), "pos": pool_center + Vector3(-10.125, lip_h/2.0, 0)}
    ]
    for lp in lips:
        var lip = MeshInstance3D.new()
        var lm = BoxMesh.new()
        lm.size = lp.size
        lip.mesh = lm
        lip.position = lp.pos
        lip.material_override = mat_gold_trim
        parent.add_child(lip)

func generate_lamp_posts(parent: Node3D):
    var positions = [
        Vector3(-8, 0, -50), Vector3(8, 0, -50),
        Vector3(-8, 0, -40), Vector3(8, 0, -40),
        Vector3(-8, 0, -30), Vector3(8, 0, -30)
    ]
    for pos in positions:
        var lamp_root = Node3D.new()
        lamp_root.position = pos
        parent.add_child(lamp_root)

        # Base
        var base = MeshInstance3D.new()
        var bmesh = CylinderMesh.new()
        bmesh.top_radius = 0.25
        bmesh.bottom_radius = 0.35
        bmesh.height = 0.4
        base.mesh = bmesh
        base.material_override = mat_marble_white
        base.position = Vector3(0, 0.2, 0)
        lamp_root.add_child(base)

        # Post (gold)
        var post = MeshInstance3D.new()
        var pmesh = CylinderMesh.new()
        pmesh.top_radius = 0.08
        pmesh.bottom_radius = 0.1
        pmesh.height = 3.5
        post.mesh = pmesh
        post.material_override = mat_gold_trim
        post.position = Vector3(0, 2.0, 0)
        lamp_root.add_child(post)

        # Bulb (emissive sphere)
        var bulb = MeshInstance3D.new()
        var sm = SphereMesh.new()
        sm.radius = 0.22
        sm.height = 0.44
        bulb.mesh = sm
        bulb.material_override = mat_lamp_glow
        bulb.position = Vector3(0, 4.0, 0)
        lamp_root.add_child(bulb)

        # Light
        var light = OmniLight3D.new()
        light.position = Vector3(0, 4.0, 0)
        light.omni_range = 8.0
        light.light_energy = 2.5
        light.light_color = Color(1.0, 0.85, 0.55)
        light.light_volumetric_fog_energy = 2.0
        light.shadow_enabled = true
        lamp_root.add_child(light)

func generate_staircase(parent: Node3D):
    # Shallow 3-step decorative stair at the plaza→portico transition.
    # Earlier a tall 3m staircase led to a raised portico floor, but that
    # blocked the player from walking back out through the door. Everything
    # now stays at plaza level (y≈0) so the door is walkable both ways;
    # the stair is a purely visual border at z=-26.
    var steps = 3
    var rise = 0.05        # 5 cm per step — CharacterBody can step over
    var run = 0.25
    for i in range(steps):
        var step = MeshInstance3D.new()
        var sm = BoxMesh.new()
        var tread_depth = (steps - i) * run + 0.3
        sm.size = Vector3(20, rise, tread_depth)
        step.mesh = sm
        step.material_override = mat_marble_warm
        var step_y = rise * 0.5 + i * rise
        var step_z = -27.0 + i * run + tread_depth * 0.5
        step.position = Vector3(0, step_y, step_z)
        parent.add_child(step)

        var coll = StaticBody3D.new()
        var cshape = CollisionShape3D.new()
        cshape.shape = BoxShape3D.new()
        cshape.shape.size = sm.size
        coll.add_child(cshape)
        step.add_child(coll)

    # Small flat portico landing flush with the top of the steps (~y=0.15 top).
    # Previously this was a 3 m high platform that stranded the player.
    # Extends from z=-26 to z=-17 so the player walks seamlessly from the
    # top step to the doorway without any gap.
    var portico_floor = MeshInstance3D.new()
    var pfm = BoxMesh.new()
    pfm.size = Vector3(22, 0.3, 9)
    portico_floor.mesh = pfm
    portico_floor.material_override = mat_marble_white
    portico_floor.position = Vector3(0, 0.0, -21.5)
    parent.add_child(portico_floor)
    var pf_coll = StaticBody3D.new()
    var pf_cs = CollisionShape3D.new()
    pf_cs.shape = BoxShape3D.new()
    pf_cs.shape.size = pfm.size
    pf_coll.add_child(pf_cs)
    portico_floor.add_child(pf_coll)

func generate_portico(parent: Node3D):
    # Majestic thick block columns
    var col_x_positions = [-10.0, -6.0, 6.0, 10.0]
    var col_z = -23.5
    var floor_y = 0.15
    var shaft_h = 9.85
    var shaft_top_y = floor_y + shaft_h

    for cx in col_x_positions:
        # Massive gold-trimmed base
        var base_gold = MeshInstance3D.new()
        var bg_m = BoxMesh.new()
        bg_m.size = Vector3(2.2, 0.4, 2.2)
        base_gold.mesh = bg_m
        base_gold.material_override = mat_gold_trim
        base_gold.position = Vector3(cx, floor_y + 0.2, col_z)
        parent.add_child(base_gold)
        
        var base_w = MeshInstance3D.new()
        var bw_m = BoxMesh.new()
        bw_m.size = Vector3(2.0, 0.6, 2.0)
        base_w.mesh = bw_m
        base_w.material_override = mat_marble_warm
        base_w.position = Vector3(cx, floor_y + 0.7, col_z)
        parent.add_child(base_w)
        
        # Massive dark obsidian rectangular shaft
        var shaft = MeshInstance3D.new()
        var sm = BoxMesh.new()
        sm.size = Vector3(1.6, shaft_h - 1.5, 1.6)
        shaft.mesh = sm
        shaft.material_override = mat_pillar
        var shaft_y = floor_y + 1.0 + (shaft_h - 1.5)/2.0
        shaft.position = Vector3(cx, shaft_y, col_z)
        parent.add_child(shaft)
        
        # Thin gold corners
        for dx in [-0.8, 0.8]:
            for dz in [-0.8, 0.8]:
                var strip = MeshInstance3D.new()
                var stm = BoxMesh.new()
                stm.size = Vector3(0.08, shaft_h - 1.5, 0.08)
                strip.mesh = stm
                strip.material_override = mat_gold_trim
                strip.position = Vector3(cx + dx, shaft_y, col_z + dz)
                parent.add_child(strip)
                
        var coll = StaticBody3D.new()
        var cshape = CollisionShape3D.new()
        var cbox = BoxShape3D.new()
        cbox.size = Vector3(1.6, shaft_h, 1.6)
        cshape.shape = cbox
        coll.position = Vector3(cx, shaft_y, col_z)
        coll.add_child(cshape)
        parent.add_child(coll)
        
        # Capital
        var cap_w = MeshInstance3D.new()
        var cw_m = BoxMesh.new()
        cw_m.size = Vector3(2.0, 0.3, 2.0)
        cap_w.mesh = cw_m
        cap_w.material_override = mat_marble_warm
        cap_w.position = Vector3(cx, shaft_top_y - 0.35, col_z)
        parent.add_child(cap_w)
        
        var cap_g = MeshInstance3D.new()
        var cg_m = BoxMesh.new()
        cg_m.size = Vector3(2.2, 0.2, 2.2)
        cap_g.mesh = cg_m
        cap_g.material_override = mat_gold_trim
        cap_g.position = Vector3(cx, shaft_top_y - 0.1, col_z)
        parent.add_child(cap_g)
        
    var ent = MeshInstance3D.new()
    var em = BoxMesh.new()
    em.size = Vector3(24, 1.0, 2.5)
    ent.mesh = em
    ent.material_override = mat_marble_warm
    ent.position = Vector3(0, shaft_top_y + 0.5, col_z)
    parent.add_child(ent)

    var frieze = MeshInstance3D.new()
    var fm = BoxMesh.new()
    fm.size = Vector3(24.2, 0.15, 2.6)
    frieze.mesh = fm
    frieze.material_override = mat_gold_trim
    frieze.position = Vector3(0, shaft_top_y + 0.5, col_z)
    parent.add_child(frieze)

func generate_pediment(parent: Node3D):
    # Triangular gable made of three thin rotated CSG boxes forming a triangle.
    var apex_y = 13.5
    var base_y = 11.5
    var half_w = 11.0
    var col_z = -23.5
    var thick = 0.8

    # Pediment as an extruded triangle via SurfaceTool
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Triangle vertices (front face at z=col_z - thick/2)
    var front_z = col_z - thick/2.0
    var back_z = col_z + thick/2.0
    var v_front = [
        Vector3(-half_w, base_y, front_z),
        Vector3(half_w, base_y, front_z),
        Vector3(0, apex_y, front_z)
    ]
    var v_back = [
        Vector3(-half_w, base_y, back_z),
        Vector3(half_w, base_y, back_z),
        Vector3(0, apex_y, back_z)
    ]

    # Front face
    st.set_normal(Vector3(0, 0, -1))
    st.add_vertex(v_front[0]); st.add_vertex(v_front[1]); st.add_vertex(v_front[2])
    # Back face (reversed winding)
    st.set_normal(Vector3(0, 0, 1))
    st.add_vertex(v_back[2]); st.add_vertex(v_back[1]); st.add_vertex(v_back[0])
    # Bottom
    st.set_normal(Vector3(0, -1, 0))
    st.add_vertex(v_front[1]); st.add_vertex(v_front[0]); st.add_vertex(v_back[0])
    st.add_vertex(v_front[1]); st.add_vertex(v_back[0]); st.add_vertex(v_back[1])
    # Left slope
    var ln = Vector3(-(apex_y - base_y), -half_w, 0).normalized()
    st.set_normal(ln)
    st.add_vertex(v_front[0]); st.add_vertex(v_front[2]); st.add_vertex(v_back[2])
    st.add_vertex(v_front[0]); st.add_vertex(v_back[2]); st.add_vertex(v_back[0])
    # Right slope
    var rn = Vector3((apex_y - base_y), -half_w, 0).normalized()
    st.set_normal(rn)
    st.add_vertex(v_front[2]); st.add_vertex(v_front[1]); st.add_vertex(v_back[1])
    st.add_vertex(v_front[2]); st.add_vertex(v_back[1]); st.add_vertex(v_back[2])

    var mesh = st.commit()
    var pediment = MeshInstance3D.new()
    pediment.mesh = mesh
    pediment.material_override = mat_marble_warm
    parent.add_child(pediment)

func generate_facade(parent: Node3D):
    # Classical portal on the -Z side: marble slab with arched doorway,
    # flanking portico side walls that enclose the entrance, and
    # auto-opening double doors.
    var combiner = CSGCombiner3D.new()
    combiner.use_collision = true
    combiner.name = "FacadeCombiner"
    parent.add_child(combiner)

    # Front slab
    var front = CSGBox3D.new()
    front.size = Vector3(22, 12, 1.0)
    front.position = Vector3(0, 6, -20)
    front.material = mat_marble_white
    combiner.add_child(front)

    # --- Portico side walls (enclose the entrance porch, z=-24..-20) ---
    # These sit ENTIRELY in the -Z exterior zone, so they do NOT cut
    # through the radial corridors (which extend in the +Z hemisphere).
    for sign in [-1, 1]:
        var sw = MeshInstance3D.new()
        var swm = BoxMesh.new()
        swm.size = Vector3(0.6, 10.5, 4.0)
        sw.mesh = swm
        sw.material_override = mat_marble_white
        sw.position = Vector3(sign * 10.7, 5.25, -22.0)
        parent.add_child(sw)
        var sc = StaticBody3D.new()
        var scs = CollisionShape3D.new()
        scs.shape = BoxShape3D.new()
        scs.shape.size = swm.size
        sc.add_child(scs)
        sw.add_child(sc)

    # --- Portico ceiling (coffered underside of the entablature) ---
    var ceiling = MeshInstance3D.new()
    var cem = BoxMesh.new()
    cem.size = Vector3(22, 0.3, 4.0)
    ceiling.mesh = cem
    ceiling.material_override = mat_marble_warm
    ceiling.position = Vector3(0, 10.5, -22.0)
    parent.add_child(ceiling)

    # Rectangular door cutout
    var door_cut = CSGBox3D.new()
    door_cut.operation = CSGShape3D.OPERATION_SUBTRACTION
    door_cut.size = Vector3(6, 7, 2)
    door_cut.position = Vector3(0, 3.5, -20)
    combiner.add_child(door_cut)

    # Arched top cutout (cylinder rotated)
    var arch = CSGCylinder3D.new()
    arch.operation = CSGShape3D.OPERATION_SUBTRACTION
    arch.radius = 3.0
    arch.height = 2.0
    arch.sides = 32
    arch.rotation = Vector3(0, 0, PI/2.0)
    arch.position = Vector3(0, 7.0, -20)
    combiner.add_child(arch)

    # NOTE: Previously there were side walls (x=±11) and a roof (y=12.3) spanning
    # z=-20 to +4. They cut through the radial corridors and the hub cylinder, so
    # they have been removed. The facade is now a free-standing classical portal;
    # the museum "building" itself is the hub with its radial corridors.

    # (Walkway removed — the plaza already covers this area. A separate walkway
    # caused Z-fighting / flickering because both sat at y=-0.1 with the same
    # thickness.)

    # Auto-opening double doors — swings outward when the player approaches
    # from either side, closes when they leave the trigger volume.
    var AutoDoorScript = load("res://AutoDoor.gd")
    if AutoDoorScript:
        var doors = AutoDoorScript.new()
        # Centre of the doorway in world coords. The two leaves together
        # span x=[-2.9..+2.9] which fits inside the 6 m-wide door cut.
        doors.position = Vector3(0, 3.25, -20.0)
        parent.add_child(doors)

func generate_dome(parent: Node3D):
    # Drum (cylindrical base under the dome)
    var drum = MeshInstance3D.new()
    var dm = CylinderMesh.new()
    dm.top_radius = 8.0
    dm.bottom_radius = 8.0
    dm.height = 3.0
    drum.mesh = dm
    drum.material_override = mat_marble_white
    drum.position = Vector3(0, 13.5, 0)
    parent.add_child(drum)

    # Gold pilasters around the drum
    var pilaster_count = 12
    for i in range(pilaster_count):
        var ang = (float(i) / pilaster_count) * PI * 2.0
        var pil = MeshInstance3D.new()
        var pm = BoxMesh.new()
        pm.size = Vector3(0.3, 3.0, 0.4)
        pil.mesh = pm
        pil.material_override = mat_gold_trim
        pil.position = Vector3(sin(ang) * 8.05, 13.5, cos(ang) * 8.05)
        pil.rotation.y = ang
        parent.add_child(pil)

    # Dome shell — a CSG sphere clipped by a subtraction box below
    var dome_combiner = CSGCombiner3D.new()
    parent.add_child(dome_combiner)

    var shell = CSGSphere3D.new()
    shell.radius = 8.0
    shell.radial_segments = 48
    shell.rings = 24
    shell.material = mat_dome_copper
    shell.position = Vector3(0, 15.0, 0)
    dome_combiner.add_child(shell)

    var clip = CSGBox3D.new()
    clip.operation = CSGShape3D.OPERATION_SUBTRACTION
    clip.size = Vector3(20, 10, 20)
    clip.position = Vector3(0, 10.0, 0)
    dome_combiner.add_child(clip)

    # Gold meridian ribs (8)
    var rib_count = 8
    for i in range(rib_count):
        var ang = (float(i) / rib_count) * PI * 2.0
        var rib = MeshInstance3D.new()
        var tm = TorusMesh.new()
        tm.inner_radius = 7.98
        tm.outer_radius = 8.10
        rib.mesh = tm
        rib.material_override = mat_gold_trim
        rib.position = Vector3(0, 15.0, 0)
        # Rotate torus so it sits along a vertical meridian
        rib.rotation = Vector3(PI/2.0, ang, 0)
        parent.add_child(rib)

    # Gold ring around the dome base (cornice)
    var cornice = MeshInstance3D.new()
    var cr = TorusMesh.new()
    cr.inner_radius = 8.0
    cr.outer_radius = 8.25
    cornice.mesh = cr
    cornice.material_override = mat_gold_trim
    cornice.position = Vector3(0, 15.0, 0)
    parent.add_child(cornice)

    # Lantern (gold finial on top)
    var lantern_base = MeshInstance3D.new()
    var lbm = CylinderMesh.new()
    lbm.top_radius = 0.7
    lbm.bottom_radius = 0.9
    lbm.height = 1.5
    lantern_base.mesh = lbm
    lantern_base.material_override = mat_gold_trim
    lantern_base.position = Vector3(0, 23.0, 0)
    parent.add_child(lantern_base)

    var lantern_orb = MeshInstance3D.new()
    var lom = SphereMesh.new()
    lom.radius = 0.6
    lom.height = 1.2
    lantern_orb.mesh = lom
    lantern_orb.material_override = mat_gold_trim
    lantern_orb.position = Vector3(0, 24.1, 0)
    parent.add_child(lantern_orb)

    var spire = MeshInstance3D.new()
    var spm = CylinderMesh.new()
    spm.top_radius = 0.02
    spm.bottom_radius = 0.15
    spm.height = 1.2
    spire.mesh = spm
    spire.material_override = mat_gold_trim
    spire.position = Vector3(0, 25.3, 0)
    parent.add_child(spire)

func generate_colonnades(parent: Node3D):
    # Two quarter-circle arched colonnades flanking the plaza
    var steps = 7
    for side in [-1, 1]:
        var center_x = side * 15.0
        var center_z = -30.0
        var radius = 14.0
        var prev_col_pos = null
        for i in range(steps):
            var t = float(i) / float(steps - 1)
            var angle = t * (PI / 2.0)
            var px = center_x + cos(angle) * radius * -side
            var pz = center_z + sin(angle) * radius
            var col_pos = Vector3(px, 0, pz)

            # Column base
            var base = MeshInstance3D.new()
            var bm = CylinderMesh.new()
            bm.top_radius = 0.5
            bm.bottom_radius = 0.55
            bm.height = 0.3
            base.mesh = bm
            base.material_override = mat_marble_white
            base.position = col_pos + Vector3(0, 0.15, 0)
            parent.add_child(base)

            # Shaft
            var shaft = MeshInstance3D.new()
            var sm = CylinderMesh.new()
            sm.top_radius = 0.35
            sm.bottom_radius = 0.4
            sm.height = 4.5
            shaft.mesh = sm
            shaft.material_override = mat_marble_white
            shaft.position = col_pos + Vector3(0, 0.3 + 2.25, 0)
            parent.add_child(shaft)
            var sc = StaticBody3D.new()
            var scs = CollisionShape3D.new()
            var scyl = CylinderShape3D.new()
            scyl.radius = 0.45
            scyl.height = 4.5
            scs.shape = scyl
            sc.position = col_pos + Vector3(0, 0.3 + 2.25, 0)
            sc.add_child(scs)
            parent.add_child(sc)

            # Gold capital
            var cap = MeshInstance3D.new()
            var cmm = BoxMesh.new()
            cmm.size = Vector3(1.0, 0.25, 1.0)
            cap.mesh = cmm
            cap.material_override = mat_gold_trim
            cap.position = col_pos + Vector3(0, 4.7, 0)
            parent.add_child(cap)

            # Arch beam to previous column
            if prev_col_pos != null:
                var mid = (prev_col_pos + col_pos) * 0.5
                var dist = prev_col_pos.distance_to(col_pos)
                var beam = MeshInstance3D.new()
                var bmm = BoxMesh.new()
                bmm.size = Vector3(dist, 0.5, 0.6)
                beam.mesh = bmm
                beam.material_override = mat_marble_warm
                beam.position = mid + Vector3(0, 5.0, 0)
                # Rotate beam to align along X between the two columns
                var dir = col_pos - prev_col_pos
                beam.rotation.y = atan2(dir.x, dir.z) - PI/2.0
                parent.add_child(beam)
            prev_col_pos = col_pos

func generate_entrance_statues(parent: Node3D):
    # Statues flank the portico at plaza level (portico floor top ≈ y=0.15).
    # Moved out to x=±8.5 so they don't crowd the 6 m-wide walking path to
    # the door, and off to z=-21.5 so they're in front of the columns.
    build_classical_statue(parent, Vector3(-8.5, 0.15, -21.5))
    build_classical_statue(parent, Vector3(8.5, 0.15, -21.5))

func build_classical_statue(parent: Node3D, pos: Vector3):
    var root = Node3D.new()
    root.position = pos
    parent.add_child(root)

    # Pedestal
    var ped = MeshInstance3D.new()
    var pm = BoxMesh.new()
    pm.size = Vector3(1.4, 1.5, 1.4)
    ped.mesh = pm
    ped.material_override = mat_marble_warm
    ped.position = Vector3(0, 0.75, 0)
    root.add_child(ped)

    # Torso (capsule)
    var torso = MeshInstance3D.new()
    var tm = CapsuleMesh.new()
    tm.radius = 0.32
    tm.height = 1.4
    torso.mesh = tm
    torso.material_override = mat_marble_white
    torso.position = Vector3(0, 2.2, 0)
    root.add_child(torso)

    # Head
    var head = MeshInstance3D.new()
    var hm = SphereMesh.new()
    hm.radius = 0.22
    hm.height = 0.44
    head.mesh = hm
    head.material_override = mat_marble_white
    head.position = Vector3(0, 3.15, 0)
    root.add_child(head)

    # Legs (2 cylinders)
    for dx in [-0.12, 0.12]:
        var leg = MeshInstance3D.new()
        var lm = CylinderMesh.new()
        lm.top_radius = 0.14
        lm.bottom_radius = 0.16
        lm.height = 1.2
        leg.mesh = lm
        leg.material_override = mat_marble_white
        leg.position = Vector3(dx, 2.1, 0)
        root.add_child(leg)

    # Arm stubs
    for dx in [-0.45, 0.45]:
        var arm = MeshInstance3D.new()
        var am = CapsuleMesh.new()
        am.radius = 0.13
        am.height = 1.0
        arm.mesh = am
        arm.material_override = mat_marble_white
        arm.position = Vector3(dx, 2.45, 0)
        arm.rotation.z = -sign(dx) * deg_to_rad(18.0)
        root.add_child(arm)

    # Dramatic warm uplight
    var spot = SpotLight3D.new()
    spot.position = Vector3(0, 1.7, 0.8)
    spot.rotation.x = deg_to_rad(70.0)
    spot.light_color = Color(1.0, 0.85, 0.55)
    spot.light_energy = 2.0
    spot.spot_angle = 40.0
    spot.spot_range = 8.0
    spot.light_volumetric_fog_energy = 1.2
    root.add_child(spot)

func generate_exterior_lighting(parent: Node3D):
    # Warm sun DirectionalLight3D (key light washing the facade)
    var sun = DirectionalLight3D.new()
    sun.light_color = Color(1.0, 0.78, 0.45)
    sun.light_energy = 2.5
    sun.shadow_enabled = true
    sun.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-30.0), 0)
    sun.position = Vector3(0, 40, -30)
    parent.add_child(sun)

    # Retune the existing scene-root DirectionalLight3D to a cool cosmic rim
    var root_dir = get_tree().root.find_child("DirectionalLight3D", true, false)
    if root_dir and root_dir is DirectionalLight3D:
        root_dir.light_color = Color(0.4, 0.55, 0.85)
        root_dir.light_energy = 0.8

    # 4 portico uplight spots at the base of key columns
    var uplight_xs = [-10.0, -2.0, 2.0, 10.0]
    for ux in uplight_xs:
        var sp = SpotLight3D.new()
        sp.position = Vector3(ux, 3.3, -23.0)
        sp.rotation.x = deg_to_rad(80.0)  # point nearly straight up
        sp.light_color = Color(1.0, 0.78, 0.45)
        sp.light_energy = 3.0
        sp.spot_angle = 45.0
        sp.spot_range = 12.0
        sp.light_volumetric_fog_energy = 1.5
        sp.shadow_enabled = true
        parent.add_child(sp)

    # 8 cool dome rim spots around the drum
    for i in range(8):
        var a = (float(i) / 8.0) * PI * 2.0
        var sp = SpotLight3D.new()
        sp.position = Vector3(sin(a) * 8.3, 13.0, cos(a) * 8.3)
        sp.rotation.x = deg_to_rad(-65.0)
        sp.rotation.y = a
        sp.light_color = Color(0.6, 0.7, 1.0)
        sp.light_energy = 2.0
        sp.spot_angle = 60.0
        sp.spot_range = 10.0
        sp.light_volumetric_fog_energy = 1.0
        parent.add_child(sp)

# ============================================================
#  INTERIOR UPGRADES — Coffered ceiling, gold trim, prisms
# ============================================================

func upgrade_interior_details():
    # Coffered ceiling grid over the hub
    var hub = get_node_or_null("CentralHub")
    if hub:
        var grid = 5
        var panel = 2.4
        var spacing = panel + 0.2
        var start = -(grid - 1) * spacing / 2.0
        for gx in range(grid):
            for gz in range(grid):
                var px = start + gx * spacing
                var pz = start + gz * spacing
                # Check distance — only place inside hub disc
                if Vector2(px, pz).length() > (HUB_RADIUS + 1.5):
                    continue

                # Recessed coffer panel (slightly lower than ceiling)
                var coff = MeshInstance3D.new()
                var cm = BoxMesh.new()
                cm.size = Vector3(panel, 0.15, panel)
                coff.mesh = cm
                coff.material_override = mat_wall
                coff.position = Vector3(px, W_HEIGHT - 0.25, pz)
                hub.add_child(coff)

                # Gold trim border (thin box frame)
                var trim = MeshInstance3D.new()
                var tmesh = BoxMesh.new()
                tmesh.size = Vector3(panel + 0.15, 0.05, panel + 0.15)
                trim.mesh = tmesh
                trim.material_override = mat_gold_trim
                trim.position = Vector3(px, W_HEIGHT - 0.1, pz)
                hub.add_child(trim)

                # Small warm coffer fill light
                var cl = OmniLight3D.new()
                cl.position = Vector3(px, W_HEIGHT - 0.4, pz)
                cl.light_color = Color(1.0, 0.9, 0.7)
                cl.light_energy = 0.4
                cl.omni_range = 3.5
                cl.shadow_enabled = false
                hub.add_child(cl)

func reposition_player_to_plaza():
    var player = get_tree().root.find_child("Player", true, false)
    if player:
        player.global_position = Vector3(0, 1.8, -58)
        player.rotation = Vector3(0, 0, 0)   # facing +Z toward the museum
