extends CanvasLayer

var panel: Panel
var mgr

func _ready():
    mgr = get_node("/root/SettingsManager")
    
    panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
    panel.set_offsets_preset(Control.PRESET_CENTER_TOP)
    panel.position.y = 80
    panel.custom_minimum_size = Vector2(500, 350)
    panel.visible = false
    add_child(panel)
    
    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
    panel.add_child(vbox)
    
    var title = Label.new()
    title.text = "MUSEUM SETTINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    
    vbox.add_child(HSeparator.new())
    
    # 1. Resolution
    var res_hbox = HBoxContainer.new()
    var res_lbl = Label.new()
    res_lbl.text = "Resolution"
    res_lbl.custom_minimum_size.x = 220
    res_hbox.add_child(res_lbl)
    
    var res_opt = OptionButton.new()
    res_opt.add_item("1280 x 720 (HD)")
    res_opt.add_item("1600 x 900")
    res_opt.add_item("1920 x 1080 (FHD)")
    res_opt.add_item("2560 x 1440 (QHD)")
    res_opt.add_item("3840 x 2160 (4K UHD)")
    res_opt.selected = mgr.resolution_index
    res_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    res_opt.item_selected.connect(func(idx): mgr.set_resolution(idx))
    res_hbox.add_child(res_opt)
    vbox.add_child(res_hbox)
    
    # 2. Quality
    var qual_hbox = HBoxContainer.new()
    var qual_lbl = Label.new()
    qual_lbl.text = "Graphics Preset"
    qual_lbl.custom_minimum_size.x = 220
    qual_hbox.add_child(qual_lbl)
    
    var qual_opt = OptionButton.new()
    qual_opt.add_item("Low (Fast)")
    qual_opt.add_item("Medium (SSAO, Fog)")
    qual_opt.add_item("High (Dynamic Shadows, MSAA)")
    qual_opt.selected = mgr.graphics_quality
    qual_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    qual_opt.item_selected.connect(func(idx): 
        mgr.graphics_quality = idx
        mgr.apply_graphics_settings()
    )
    qual_hbox.add_child(qual_opt)
    vbox.add_child(qual_hbox)
    
    # 3. Global Illumination Toggle
    var gi_hbox = HBoxContainer.new()
    var gi_lbl = Label.new()
    gi_lbl.text = "SDFGI (Software Raytracing)"
    gi_lbl.custom_minimum_size.x = 220
    gi_hbox.add_child(gi_lbl)
    var gi_chk = CheckButton.new()
    gi_chk.button_pressed = mgr.global_illumination
    gi_chk.toggled.connect(func(v): 
        mgr.global_illumination = v
        mgr.apply_graphics_settings()
    )
    gi_hbox.add_child(gi_chk)
    vbox.add_child(gi_hbox)
    
    # 3.5 Atmosphere Preset
    var atm_hbox = HBoxContainer.new()
    var atm_lbl = Label.new()
    atm_lbl.text = "Atmosphere (Light & Floor)"
    atm_lbl.custom_minimum_size.x = 220
    atm_hbox.add_child(atm_lbl)
    
    var atm_opt = OptionButton.new()
    atm_opt.add_item("L1: Cinematic Fog")
    atm_opt.add_item("L2: Crisp Gallery")
    atm_opt.add_item("L3: Moody Dark")
    atm_opt.add_item("L4: Bright Volumetric")
    atm_opt.add_item("L5: Pure Raytracing (Dark Floor)")
    atm_opt.selected = mgr.atmosphere_preset
    atm_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    atm_opt.item_selected.connect(func(idx): 
        mgr.atmosphere_preset = idx
        mgr.apply_visuals()
    )
    atm_hbox.add_child(atm_opt)
    vbox.add_child(atm_hbox)
    
    # 3.6 Pillar Light Color
    var col_hbox = HBoxContainer.new()
    var col_lbl = Label.new()
    col_lbl.text = "Interior Pillar Light Color"
    col_lbl.custom_minimum_size.x = 220
    col_hbox.add_child(col_lbl)
    
    var col_picker = ColorPickerButton.new()
    col_picker.color = mgr.pillar_light_color
    col_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col_picker.color_changed.connect(func(c): 
        mgr.pillar_light_color = c
        mgr.apply_visuals()
    )
    col_hbox.add_child(col_picker)
    vbox.add_child(col_hbox)
    
    # 3.7 VR Render Scale
    var vr_hbox = HBoxContainer.new()
    var vr_lbl = Label.new()
    vr_lbl.text = "VR Render Scale"
    vr_lbl.custom_minimum_size.x = 160
    vr_hbox.add_child(vr_lbl)
    
    var vr_slider = HSlider.new()
    vr_slider.min_value = 0.5
    vr_slider.max_value = 2.0
    vr_slider.step = 0.05
    vr_slider.value = mgr.vr_scale
    vr_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var vr_val_lbl = Label.new()
    vr_val_lbl.custom_minimum_size.x = 60
    vr_val_lbl.text = "%.2f x" % mgr.vr_scale
    
    vr_slider.value_changed.connect(func(v):
        mgr.vr_scale = v
        vr_val_lbl.text = "%.2f x" % v
        mgr.apply_graphics_settings()
    )
    vr_hbox.add_child(vr_slider)
    vr_hbox.add_child(vr_val_lbl)
    vbox.add_child(vr_hbox)

    # 4. Volume
    var vol_hbox = HBoxContainer.new()
    var vol_lbl = Label.new()
    vol_lbl.text = "Music Volume"
    vol_lbl.custom_minimum_size.x = 160
    vol_hbox.add_child(vol_lbl)
    
    var vol_slider = HSlider.new()
    vol_slider.min_value = -40.0
    vol_slider.max_value = 0.0
    vol_slider.step = 0.5
    vol_slider.value = mgr.music_volume_db
    vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var vol_val_lbl = Label.new()
    vol_val_lbl.custom_minimum_size.x = 60
    vol_val_lbl.text = str(mgr.music_volume_db) + " dB"
    
    vol_slider.value_changed.connect(func(v):
        mgr.music_volume_db = v
        vol_val_lbl.text = str(v) + " dB"
        mgr.apply_audio()
    )
    vol_hbox.add_child(vol_slider)
    vol_hbox.add_child(vol_val_lbl)
    vbox.add_child(vol_hbox)
    
    vbox.add_child(HSeparator.new())
    
    # Save & Actions
    var btn_save = Button.new()
    btn_save.text = "Save Settings"
    btn_save.pressed.connect(func(): mgr.save_settings())
    vbox.add_child(btn_save)
    
    var btn_restart = Button.new()
    btn_restart.text = "Restart Museum"
    btn_restart.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
    vbox.add_child(btn_restart)

func _process(delta):
    if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
        panel.visible = true
    else:
        panel.visible = false
