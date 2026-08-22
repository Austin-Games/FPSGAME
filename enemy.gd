extends CharacterBody3D

var health: int = 100
var speed: float = 2.5
var attack_timer: float = 0.0
var player: Node3D

func _ready() -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.9,1.8,0.9)
	mesh.mesh = box
	mesh.position.y = 0.9
	mesh.material_override = _mat(Color(0.55,0.12,0.1))
	add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.9,1.8,0.9)
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")

func _mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	var flat: Vector3 = player.global_position - global_position
	flat.y = 0
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
