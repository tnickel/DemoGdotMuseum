extends CharacterBody3D

const SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var camera = $Camera3D

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        camera.rotation.x = clamp(camera.rotation.x, -PI/2.1, PI/2.1)
    
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
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
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()
