extends CharacterBody3D

var health: int = 100
var speed: float = 2.5
var attack_timer: float = 0.0
var player: Node3D
var model: Node3D

func _ready() -> void:
	# Load enemy.fbx from the project. Godot imports FBX as a PackedScene.
	var enemy_scene: PackedScene = load("res://enemy.fbx") as PackedScene
	if enemy_scene:
		model = enemy_scene.instantiate()
		add_child(model)
		model.position.y = 0.0
		model.scale = Vector3.ONE
	else:
		# Fallback placeholder if enemy.fbx has not been copied into the project yet.
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.9, 1.8, 0.9)
		mesh.mesh = box
		mesh.position.y = 0.9
		mesh.material_override = _mat(Color(0.55, 0.12, 0.1))
		add_child(mesh)
		print("WARNING: res://enemy.fbx was not found. Add enemy.fbx to the project root.")

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	player = get_tree().get_first_node_in_group("player") as Node3D
	add_to_group("enemy")

func _mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
		return
	var flat: Vector3 = player.global_position - global_position
	flat.y = 0.0
	if flat.length() > 3.0:
		velocity = flat.normalized() * speed
		look_at(global_position + flat, Vector3.UP)
	else:
		velocity = Vector3.ZERO
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = 1.0
			if player.has_method("take_damage"):
				player.take_damage(10)
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
