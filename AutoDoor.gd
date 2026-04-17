extends Node3D
# Auto-opening double door, styled like a classical museum entrance:
# dark walnut leaves with recessed coffered panels and brass trim.
#
# Place one instance at the doorway centre (y = door centre height, z = door plane).
# Two hinged leaves swing outward when any body enters the Area3D trigger
# and swing back shut when it leaves.

@export var door_width: float = 2.9
@export var door_height: float = 6.5
@export var door_thickness: float = 0.18
@export var open_angle_deg: float = 95.0
@export var open_speed: float = 3.5
@export var trigger_radius_xz: Vector2 = Vector2(5.0, 4.0)
@export var trigger_height: float = 4.0

var _pivot_left: Node3D
var _pivot_right: Node3D
var _target_open: bool = false

var _mat_wood: StandardMaterial3D
var _mat_wood_dark: StandardMaterial3D
var _mat_brass: StandardMaterial3D

func _ready():
    _mat_wood = StandardMaterial3D.new()
    _mat_wood.albedo_color = Color(0.18, 0.10, 0.06)
    _mat_wood.metallic = 0.15
    _mat_wood.roughness = 0.55
    _mat_wood.cull_mode = BaseMaterial3D.CULL_DISABLED  # both sides visible

    _mat_wood_dark = StandardMaterial3D.new()
    _mat_wood_dark.albedo_color = Color(0.10, 0.05, 0.03)
    _mat_wood_dark.metallic = 0.2
    _mat_wood_dark.roughness = 0.6
    _mat_wood_dark.cull_mode = BaseMaterial3D.CULL_DISABLED

    _mat_brass = StandardMaterial3D.new()
    _mat_brass.albedo_color = Color(0.75, 0.58, 0.22)
    _mat_brass.metallic = 1.0
    _mat_brass.roughness = 0.25
    _mat_brass.cull_mode = BaseMaterial3D.CULL_DISABLED

    _pivot_left = _build_leaf(-1)
    _pivot_right = _build_leaf(1)
    add_child(_pivot_left)
    add_child(_pivot_right)

    var area = Area3D.new()
    var cs = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(trigger_radius_xz.x * 2.0, trigger_height, trigger_radius_xz.y * 2.0)
    cs.shape = box
    area.add_child(cs)
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    add_child(area)

func _build_leaf(side: int) -> Node3D:
    # side: -1 = left leaf (hinge on -x), +1 = right leaf (hinge on +x).
    var pivot = Node3D.new()
    pivot.position = Vector3(side * door_width, 0, 0)

    # Main slab
    var leaf = MeshInstance3D.new()
    var lm = BoxMesh.new()
    lm.size = Vector3(door_width, door_height, door_thickness)
    leaf.mesh = lm
    leaf.material_override = _mat_wood
    leaf.position = Vector3(-side * door_width / 2.0, 0, 0)
    pivot.add_child(leaf)

    # Outer perimeter frame (brass trim around the whole leaf)
    _add_frame(pivot, side)

    # Coffered panels: 3 rows × 1 column of recessed rectangles,
    # each with a brass inner edge for depth.
    var panel_w = door_width * 0.70
    var rows = 3
    var row_spacing = door_height * 0.28
    var row_start = (rows - 1) * 0.5 * row_spacing
    for r in range(rows):
        var y_off = row_start - r * row_spacing
        _add_panel(pivot, side, y_off, panel_w, door_height * 0.22)

    # Brass handle + escutcheon near the inner (meeting) edge
    _add_handle(pivot, side)

    return pivot

func _add_frame(pivot: Node3D, side: int):
    # Thin brass trim along the four edges of the leaf's visible face.
    var frame_t = 0.04
    var inset_z = door_thickness / 2.0 + 0.005
    var leaf_center_x = -side * door_width / 2.0

    # Top trim
    var top_trim = MeshInstance3D.new()
    var ttm = BoxMesh.new()
    ttm.size = Vector3(door_width * 0.96, frame_t, 0.02)
    top_trim.mesh = ttm
    top_trim.material_override = _mat_brass
    top_trim.position = Vector3(leaf_center_x, door_height / 2.0 - frame_t, inset_z)
    pivot.add_child(top_trim)

    var bot_trim = top_trim.duplicate()
    bot_trim.position = Vector3(leaf_center_x, -door_height / 2.0 + frame_t, inset_z)
    pivot.add_child(bot_trim)

    # Side trims
    var side_trim = MeshInstance3D.new()
    var stm = BoxMesh.new()
    stm.size = Vector3(frame_t, door_height * 0.96, 0.02)
    side_trim.mesh = stm
    side_trim.material_override = _mat_brass
    side_trim.position = Vector3(leaf_center_x - door_width / 2.0 + frame_t, 0, inset_z)
    pivot.add_child(side_trim)

    var side_trim2 = side_trim.duplicate()
    side_trim2.position = Vector3(leaf_center_x + door_width / 2.0 - frame_t, 0, inset_z)
    pivot.add_child(side_trim2)

    # Mirror the trim on the back face so the door looks finished from inside.
    for node in [top_trim, bot_trim, side_trim, side_trim2]:
        var back = node.duplicate()
        back.position.z = -inset_z
        pivot.add_child(back)

func _add_panel(pivot: Node3D, side: int, y_off: float, panel_w: float, panel_h: float):
    var leaf_center_x = -side * door_width / 2.0
    var inset_z = door_thickness / 2.0

    # Recessed dark wood plate (pushed slightly into the leaf)
    var panel = MeshInstance3D.new()
    var pm = BoxMesh.new()
    pm.size = Vector3(panel_w, panel_h, 0.04)
    panel.mesh = pm
    panel.material_override = _mat_wood_dark
    panel.position = Vector3(leaf_center_x, y_off, inset_z - 0.025)
    pivot.add_child(panel)

    # Thin brass bevel ringing the panel
    var bevel_t = 0.025
    var bevels = [
        {"size": Vector3(panel_w + 2 * bevel_t, bevel_t, 0.01),
         "pos": Vector3(leaf_center_x, y_off + panel_h / 2.0, inset_z + 0.002)},
        {"size": Vector3(panel_w + 2 * bevel_t, bevel_t, 0.01),
         "pos": Vector3(leaf_center_x, y_off - panel_h / 2.0, inset_z + 0.002)},
        {"size": Vector3(bevel_t, panel_h, 0.01),
         "pos": Vector3(leaf_center_x - panel_w / 2.0, y_off, inset_z + 0.002)},
        {"size": Vector3(bevel_t, panel_h, 0.01),
         "pos": Vector3(leaf_center_x + panel_w / 2.0, y_off, inset_z + 0.002)},
    ]
    for b in bevels:
        var bv = MeshInstance3D.new()
        var bm = BoxMesh.new()
        bm.size = b.size
        bv.mesh = bm
        bv.material_override = _mat_brass
        bv.position = b.pos
        pivot.add_child(bv)
        var back = bv.duplicate()
        back.position.z = -b.pos.z
        pivot.add_child(back)

    # Mirror the recessed panel on the back face
    var panel_back = panel.duplicate()
    panel_back.position.z = -panel.position.z
    pivot.add_child(panel_back)

func _add_handle(pivot: Node3D, side: int):
    var leaf_center_x = -side * door_width / 2.0
    var inner_edge_x = leaf_center_x + side * (door_width / 2.0 - 0.30)
    var handle_y = 0.0  # door centre height

    for z_face in [1.0, -1.0]:
        # Escutcheon plate (oval-ish rectangle)
        var esc = MeshInstance3D.new()
        var em = BoxMesh.new()
        em.size = Vector3(0.18, 0.45, 0.02)
        esc.mesh = em
        esc.material_override = _mat_brass
        esc.position = Vector3(inner_edge_x, handle_y, z_face * (door_thickness / 2.0 + 0.01))
        pivot.add_child(esc)

        # Ball knob
        var knob = MeshInstance3D.new()
        var sm = SphereMesh.new()
        sm.radius = 0.09
        sm.height = 0.18
        knob.mesh = sm
        knob.material_override = _mat_brass
        knob.position = Vector3(inner_edge_x, handle_y, z_face * (door_thickness / 2.0 + 0.12))
        pivot.add_child(knob)

func _on_body_entered(_body):
    _target_open = true

func _on_body_exited(_body):
    _target_open = false

func _process(delta):
    var target_left = 0.0
    var target_right = 0.0
    if _target_open:
        target_left = -deg_to_rad(open_angle_deg)
        target_right = deg_to_rad(open_angle_deg)
    _pivot_left.rotation.y = lerp_angle(_pivot_left.rotation.y, target_left, clamp(open_speed * delta, 0.0, 1.0))
    _pivot_right.rotation.y = lerp_angle(_pivot_right.rotation.y, target_right, clamp(open_speed * delta, 0.0, 1.0))
