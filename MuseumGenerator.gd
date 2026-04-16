extends Node3D

const W_HEIGHT = 5.0
const W_THICK = 0.5
const CORR_WIDTH = 6.0
const CORR_LEN = 20.0
const HUB_RADIUS = 10.0

var artists_data = [
    {"id": "vangogh", "name": "Vincent van Gogh", "desc": "Post-Impressionist master\nknown for bold, dramatic \nbrush strokes and emotive\nlandscapes."},
    {"id": "davinci", "name": "Leonardo da Vinci", "desc": "The ultimate Renaissance \nman, an unparalleled genius\nin art, science, and \nengineering."},
    {"id": "monet", "name": "Claude Monet", "desc": "Founder of Impressionism,\ncapturing the fleeting nature\nof light across beautiful\nlandscapes."},
    {"id": "picasso", "name": "Pablo Picasso", "desc": "Spanish painter who pioneered\nCubism, radically distorting\nreality into striking \ngeometric forms."},
    {"id": "dali", "name": "Salvador Dali", "desc": "Eccentric surrealist visionary\nfamous for his bizarre, \ndream-like melting imagery."}
]

var mat_floor = StandardMaterial3D.new()
var mat_wall = StandardMaterial3D.new()
var mat_frame = StandardMaterial3D.new()
var mat_pillar = StandardMaterial3D.new()

func _ready():
    setup_materials()
    generate_hub()
    var angle_step = (PI * 2.0) / artists_data.size()
    for i in range(artists_data.size()):
        build_corridor(artists_data[i], i * angle_step)
        # Place a sealing pillar BETWEEN the corridors to close the gaps
        place_pillar(i * angle_step + (angle_step / 2.0))

func setup_materials():
    # Premium Dark Marble Floor
    mat_floor.albedo_color = Color(0.04, 0.04, 0.05)
    mat_floor.roughness = 0.05
    mat_floor.metallic = 0.8
    
    # Pristine Gallery White Walls
    mat_wall.albedo_color = Color(0.95, 0.95, 0.97)
    mat_wall.roughness = 0.85
    mat_wall.metallic = 0.0
    
    # Premium Gold/Wood framing
    mat_frame.albedo_color = Color(0.8, 0.6, 0.2)
    mat_frame.metallic = 0.6
    mat_frame.roughness = 0.3
    
    # Pillars (Glossy Black/Gold)
    mat_pillar.albedo_color = Color(0.02, 0.02, 0.02)
    mat_pillar.metallic = 0.9
    mat_pillar.roughness = 0.2

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

func place_pillar(angle):
    # Places a huge architectural pillar to seal the gap between Corridors
    # The pillar will spawn right on the circular seam, overlapping the corridor walls perfectly!
    var dist = HUB_RADIUS + 0.5
    var px = sin(angle) * dist
    var pz = cos(angle) * dist
    
    var inst = MeshInstance3D.new()
    var mesh = CylinderMesh.new()
    mesh.radius = 3.5 # Massive pillar to seal all gaps
    mesh.height = W_HEIGHT + 0.2
    inst.mesh = mesh
    inst.material_override = mat_pillar
    inst.position = Vector3(px, W_HEIGHT/2.0, pz)
    add_child(inst)
    
    var coll = StaticBody3D.new()
    var cshape = CollisionShape3D.new()
    var cyl_shape = CylinderShape3D.new()
    cyl_shape.radius = 3.5
    cyl_shape.height = W_HEIGHT
    cshape.shape = cyl_shape
    coll.add_child(cshape)
    inst.add_child(coll)

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
    
    # Center Light
    var clight = OmniLight3D.new()
    clight.position = Vector3(0, W_HEIGHT - 0.5, 0)
    clight.omni_range = 30.0
    clight.light_energy = 3.5
    clight.shadow_enabled = true
    hub.add_child(clight)

func build_corridor(a, angle):
    var corridor = Node3D.new()
    corridor.name = "Corridor_" + a.id
    corridor.rotation.y = angle
    add_child(corridor)
    
    var offset_z = HUB_RADIUS - 1.0 # start at the edge of the hub
    
    # Floor
    create_box(corridor, Vector3(CORR_WIDTH, 0.2, CORR_LEN), Vector3(0, -0.1, offset_z + CORR_LEN/2.0), 0.0, mat_floor, true)
    # Ceiling
    create_box(corridor, Vector3(CORR_WIDTH, 0.2, CORR_LEN), Vector3(0, W_HEIGHT + 0.1, offset_z + CORR_LEN/2.0), 0.0, mat_floor, true)
    
    # Left Wall (+X)
    create_box(corridor, Vector3(W_THICK, W_HEIGHT, CORR_LEN), Vector3(CORR_WIDTH/2.0 + W_THICK/2.0, W_HEIGHT/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_wall, true)
    # Right Wall (-X)
    create_box(corridor, Vector3(W_THICK, W_HEIGHT, CORR_LEN), Vector3(-CORR_WIDTH/2.0 - W_THICK/2.0, W_HEIGHT/2.0, offset_z + CORR_LEN/2.0), 0.0, mat_wall, true)
    # Back Wall (+Z)
    create_box(corridor, Vector3(CORR_WIDTH + W_THICK*2, W_HEIGHT, W_THICK), Vector3(0, W_HEIGHT/2.0, offset_z + CORR_LEN + W_THICK/2.0), 0.0, mat_wall, true)
    
    var light = OmniLight3D.new()
    light.position = Vector3(0, W_HEIGHT - 0.5, offset_z + CORR_LEN/2.0)
    light.omni_range = CORR_LEN * 1.5
    light.light_energy = 1.0
    light.distance_fade_enabled = true
    light.distance_fade_begin = 35.0
    light.distance_fade_length = 5.0
    corridor.add_child(light)

    # -----------------
    # Artwork Placement
    # -----------------
    var path = "res://artists/" + a.id + "/"
    
    var l_wall_x = CORR_WIDTH/2.0 - 0.05
    var r_wall_x = -CORR_WIDTH/2.0 + 0.05
    var r_rot = Vector3(0, PI/2.0, 0)
    var l_rot = Vector3(0, -PI/2.0, 0)
    
    # Portrait
    add_picture(corridor, path + a.id + "_portrait", Vector3(r_wall_x, W_HEIGHT/2.0, offset_z + 2.0), r_rot, true)
    
    # Description Text
    var lbl = Label3D.new()
    lbl.text = "— " + a.name.to_upper() + " —\n\n" + a.desc
    lbl.pixel_size = 0.003
    lbl.modulate = Color(0.1, 0.1, 0.1)
    lbl.font_size = 90
    lbl.outline_modulate = Color(1,1,1,0.2)
    lbl.outline_size = 2
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.position = Vector3(r_wall_x, W_HEIGHT/2.0, offset_z + 6.0)
    lbl.rotation = r_rot
    corridor.add_child(lbl)
    
    var spot_desc = SpotLight3D.new()
    spot_desc.position = Vector3(r_wall_x + 2.0, W_HEIGHT - 0.5, offset_z + 6.0)
    spot_desc.rotation.x = -deg_to_rad(45.0)
    spot_desc.rotation.y = deg_to_rad(90.0)
    spot_desc.spot_range = 6.0
    spot_desc.light_energy = 1.0
    spot_desc.spot_angle = 45.0
    corridor.add_child(spot_desc)
        
    # LEFT & RIGHT WALLS: Paintings
    add_picture(corridor, path + a.id + "_p1", Vector3(l_wall_x, W_HEIGHT/2.0, offset_z + 4.0), l_rot, true)
    add_picture(corridor, path + a.id + "_p2", Vector3(l_wall_x, W_HEIGHT/2.0, offset_z + 12.0), l_rot, true)
    add_picture(corridor, path + a.id + "_p3", Vector3(r_wall_x, W_HEIGHT/2.0, offset_z + 12.0), r_rot, true)
    
    # Back wall: feature painting
    add_picture(corridor, path + a.id + "_p4", Vector3(0, W_HEIGHT/2.0, offset_z + CORR_LEN - 0.05), Vector3(0, PI, 0), true)

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
