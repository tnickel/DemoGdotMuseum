extends Node3D

var mat_gold = StandardMaterial3D.new()
var mat_glow = StandardMaterial3D.new()

func _ready():
    # Polished Gold Material
    mat_gold.albedo_color = Color(0.9, 0.7, 0.1)
    mat_gold.metallic = 1.0
    mat_gold.roughness = 0.15

    # Glowing Candle Material
    mat_glow.albedo_color = Color(1.0, 0.9, 0.7)
    mat_glow.emission_enabled = true
    mat_glow.emission = Color(1.0, 0.9, 0.7)
    mat_glow.emission_energy_multiplier = 7.0

    build_chandelier()
    build_crystal_prisms()

func build_chandelier():
    # Central Pole (drops down from ceiling)
    # The ceiling is at Y = 7.0, so local 0,0,0 is at the ceiling attachment point.
    var pole = MeshInstance3D.new()
    var p_mesh = CylinderMesh.new()
    p_mesh.bottom_radius = 0.05
    p_mesh.top_radius = 0.05
    p_mesh.height = 3.0
    pole.mesh = p_mesh
    pole.material_override = mat_gold
    pole.position = Vector3(0, -1.5, 0)
    add_child(pole)
    
    # Bottom Ring
    var ring1 = MeshInstance3D.new()
    var r1_mesh = TorusMesh.new()
    r1_mesh.inner_radius = 1.2
    r1_mesh.outer_radius = 1.3
    ring1.mesh = r1_mesh
    ring1.material_override = mat_gold
    ring1.position = Vector3(0, -2.8, 0)
    add_child(ring1)

    # Top Ring
    var ring2 = MeshInstance3D.new()
    var r2_mesh = TorusMesh.new()
    r2_mesh.inner_radius = 0.6
    r2_mesh.outer_radius = 0.7
    ring2.mesh = r2_mesh
    ring2.material_override = mat_gold
    ring2.position = Vector3(0, -2.0, 0)
    add_child(ring2)
    
    # Build Arms & Candles for Bottom Ring
    var arms_count_1 = 8
    build_arms_and_candles(arms_count_1, 1.2, -2.8, -2.4, 0.8)
    
    # Build Arms & Candles for Top Ring
    var arms_count_2 = 4
    build_arms_and_candles(arms_count_2, 0.6, -2.0, -1.6, 0.4)

    # Central Soft Light Source for the Chandelier
    var light = OmniLight3D.new()
    light.position = Vector3(0, -3.5, 0) # MOVED BELOW THE POLE TO PREVENT OCCLUSION!
    light.omni_range = 25.0
    light.light_color = Color(1.0, 0.95, 0.8) # Warm golden light
    light.light_energy = 4.5
    light.shadow_enabled = true
    light.light_volumetric_fog_energy = 2.0
    add_child(light)

func build_crystal_prisms():
    # 8 small downward-pointing emissive crystal shards around the lower ring
    var count = 8
    var ring_radius = 1.15
    var ring_y = -2.8
    for i in range(count):
        var a = (float(i) / count) * PI * 2.0
        var px = sin(a) * ring_radius
        var pz = cos(a) * ring_radius

        var prism = MeshInstance3D.new()
        var pmesh = BoxMesh.new()
        pmesh.size = Vector3(0.05, 0.15, 0.05)
        prism.mesh = pmesh
        prism.material_override = mat_glow
        prism.position = Vector3(px, ring_y - 0.18, pz)
        prism.rotation = Vector3(0, a, deg_to_rad(8.0))
        add_child(prism)

    # Secondary warm sparkle light below the chandelier
    var sparkle = OmniLight3D.new()
    sparkle.position = Vector3(0, -3.2, 0)
    sparkle.light_color = Color(1.0, 0.9, 0.7)
    sparkle.light_energy = 1.5
    sparkle.omni_range = 10.0
    sparkle.shadow_enabled = false
    add_child(sparkle)

func build_arms_and_candles(count, radius, ch_y, arm_mid_y, attach_radius):
    var angle_step = (PI * 2.0) / count
    for i in range(count):
        var a = i * angle_step
        var px = sin(a) * radius
        var pz = cos(a) * radius
        
        # The Candle
        var candle = MeshInstance3D.new()
        var c_mesh = CapsuleMesh.new()
        c_mesh.radius = 0.04
        c_mesh.height = 0.3
        candle.mesh = c_mesh
        candle.material_override = mat_glow
        candle.position = Vector3(px, ch_y + 0.15, pz)
        add_child(candle)
        
        # The Golden Holder
        var holder = MeshInstance3D.new()
        var h_mesh = CylinderMesh.new()
        h_mesh.bottom_radius = 0.06
        h_mesh.top_radius = 0.06
        h_mesh.height = 0.1
        holder.mesh = h_mesh
        holder.material_override = mat_gold
        holder.position = Vector3(px, ch_y - 0.05, pz)
        add_child(holder)
        
        # Connect to center with an angled beam
        var cx = sin(a) * attach_radius
        var cz = cos(a) * attach_radius
        
        var arm = MeshInstance3D.new()
        var arm_mesh = CylinderMesh.new()
        arm_mesh.bottom_radius = 0.02
        arm_mesh.top_radius = 0.02
        
        var start_pos = Vector3(cx, arm_mid_y, cz)
        var end_pos = Vector3(px, ch_y, pz)
        var dist = start_pos.distance_to(end_pos)
        arm_mesh.height = dist
        arm.mesh = arm_mesh
        arm.material_override = mat_gold
        
        arm.position = start_pos.lerp(end_pos, 0.5)
        # Point the cylinder along the path
        arm.look_at_from_position(arm.position, end_pos, Vector3.UP)
        # Cylinder extends along Y, but look_at aligns Z towards target. Rotate it visually!
        arm.rotation.x -= PI/2.0
        add_child(arm)
