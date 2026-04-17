extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var camera = $Camera3D
var raycast: RayCast3D
var can_move = true

var xr_origin: XROrigin3D
var vr_camera: XRCamera3D

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    var mgr = get_node("/root/SettingsManager")
    if mgr.is_vr:
        xr_origin = XROrigin3D.new()
        xr_origin.position.y = 0.0 # 0.0 means virtual floor = physical floor. Headset adds physical height naturally.
        add_child(xr_origin)
        vr_camera = XRCamera3D.new()
        xr_origin.add_child(vr_camera)
        
        camera.current = false
        vr_camera.current = true
        
        raycast = RayCast3D.new()
        raycast.target_position = Vector3(0, 0, -4.0)
        vr_camera.add_child(raycast)
        
        var canvas = CanvasLayer.new()
        add_child(canvas)
        var center = CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        canvas.add_child(center)
        var dot = ColorRect.new()
        dot.custom_minimum_size = Vector2(4, 4)
        dot.color = Color(1, 1, 1, 0.5)
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        center.add_child(dot)
    else:
        raycast = RayCast3D.new()
        raycast.target_position = Vector3(0, 0, -4.0)
        camera.add_child(raycast)
        
        var canvas = CanvasLayer.new()
        add_child(canvas)
        var center = CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        canvas.add_child(center)
        var dot = ColorRect.new()
        dot.custom_minimum_size = Vector2(4, 4)
        dot.color = Color(1, 1, 1, 0.5)
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        center.add_child(dot)

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and can_move:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        if is_instance_valid(xr_origin):
            xr_origin.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
            xr_origin.rotation.x = clamp(xr_origin.rotation.x, -PI/2.1, PI/2.1)
        else:
            camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
            camera.rotation.x = clamp(camera.rotation.x, -PI/2.1, PI/2.1)
    
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_move:
        if raycast.is_colliding():
            var obj = raycast.get_collider()
            if obj and obj.is_in_group("interactable"):
                if obj.has_method("on_interact"):
                    obj.on_interact(self)
    
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    if not can_move: return
    
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    var speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
    
    var x = 0.0
    var z = 0.0
    if Input.is_physical_key_pressed(KEY_W): z -= 1.0
    if Input.is_physical_key_pressed(KEY_S): z += 1.0
    if Input.is_physical_key_pressed(KEY_A): x -= 1.0
    if Input.is_physical_key_pressed(KEY_D): x += 1.0
    
    # fallback to arrows
    if x == 0 and z == 0:
        x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
        z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
        
    var input_dir = Vector2(x, z).normalized()
    
    var h_rot = transform.basis
    if is_instance_valid(vr_camera):
        var cam_z = vr_camera.global_transform.basis.z
        cam_z.y = 0; cam_z = cam_z.normalized()
        var cam_x = vr_camera.global_transform.basis.x
        cam_x.y = 0; cam_x = cam_x.normalized()
        h_rot = Basis(cam_x, Vector3.UP, cam_z)
        
    var direction = (h_rot * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()
