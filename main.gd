extends Node3D

func _ready() -> void:
	_build_level()

func mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	return m

func box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var b: StaticBody3D = StaticBody3D.new()
	b.position = pos
	add_child(b)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var shape_mesh: BoxMesh = BoxMesh.new()
	shape_mesh.size = size
	mesh.mesh = shape_mesh
	mesh.material_override = mat(color)
	b.add_child(mesh)
	var cs: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	b.add_child(cs)
	return b

func _build_level() -> void:
	box(Vector3(40,0.4,40), Vector3(0,-0.2,0), Color(0.12,0.13,0.15))
	box(Vector3(40,6,0.4), Vector3(0,3,-20), Color(0.18,0.19,0.21))
	box(Vector3(40,6,0.4), Vector3(0,3,20), Color(0.18,0.19,0.21))
	box(Vector3(0.4,6,40), Vector3(-20,3,0), Color(0.18,0.19,0.21))
	box(Vector3(0.4,6,40), Vector3(20,3,0), Color(0.18,0.19,0.21))
	box(Vector3(6,3,2), Vector3(0,1.5,-7), Color(0.25,0.26,0.28))
	box(Vector3(2,2,6), Vector3(-7,1,-2), Color(0.25,0.26,0.28))
	box(Vector3(4,1,4), Vector3(7,0.5,7), Color(0.3,0.31,0.33))
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-25,0)
	light.light_energy = 1.2
	add_child(light)
	var world: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025,0.03,0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35,0.38,0.45)
	env.ambient_light_energy = 0.7
	world.environment = env
	add_child(world)

	var player: CharacterBody3D = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0,1,12)
	player.set_script(load("res://player.gd"))
	player.add_to_group("player")
	add_child(player)

	for p: Vector3 in [Vector3(-10,1,-8), Vector3(10,1,-10), Vector3(0,1,-15)]:
		var enemy: CharacterBody3D = CharacterBody3D.new()
		enemy.position = p
		enemy.set_script(load("res://enemy.gd"))
		add_child(enemy)
