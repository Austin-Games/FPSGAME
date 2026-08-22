extends CharacterBody3D

var health: int = 100
var speed: float = 2.5
var attack_timer: float = 0.0
var player: Node3D
var model: Node3D
var animation_player: AnimationPlayer
var dying: bool = false
var shooting: bool = false

const CHARACTER_DIR: String = "res://characters/Enemy/"
const IDLE_FILE: String = CHARACTER_DIR + "Idle.fbx"
const AIM_FILE: String = CHARACTER_DIR + "Aiming.fbx"
const FIRE_FILE: String = CHARACTER_DIR + "Firing Rifle.fbx"
const JUMP_FILE: String = CHARACTER_DIR + "Jumping.fbx"
const DIE_FILE: String = CHARACTER_DIR + "Dying.fbx"

func _ready() -> void:
	_load_character()
	_build_collision()
	player = get_tree().get_first_node_in_group("player") as Node3D
	add_to_group("enemy")

func _load_character() -> void:
	# Use the main enemy FBX if present. The animation FBXs are loaded below
	# and their AnimationPlayer tracks are copied into this character.
	var enemy_scene: PackedScene = load(CHARACTER_DIR + "enemy.fbx") as PackedScene
	if enemy_scene:
		model = enemy_scene.instantiate()
		add_child(model)
	else:
		print("WARNING: Add characters/enemy/enemy.fbx for the enemy character.")
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(0.9, 1.8, 0.9)
		mesh.mesh = box
		mesh.position.y = 0.9
		mesh.material_override = _mat(Color(0.55, 0.12, 0.1))
		add_child(mesh)

	animation_player = _find_animation_player(self)
	if animation_player:
		_play_animation("Idle")
	else:
		print("WARNING: No AnimationPlayer found in enemy.fbx")

func _find_animation_player(root: Node) -> AnimationPlayer:
	for child: Node in root.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found: AnimationPlayer = _find_animation_player(child)
		if found:
			return found
	return null

func _build_collision() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

func _mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _play_animation(animation_name: String) -> void:
	if animation_player == null:
		return
	var animation_name_to_play: String = _find_animation_name(animation_name)
	if animation_name_to_play != "":
		animation_player.play(animation_name_to_play)

func _find_animation_name(wanted: String) -> String:
	if animation_player == null:
		return ""
	for name: StringName in animation_player.get_animation_list():
		var clean: String = String(name).to_lower().replace("_", " ")
		if clean.contains(wanted.to_lower()):
			return String(name)
	return ""

func _physics_process(delta: float) -> void:
	if dying:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
		return

	var flat: Vector3 = player.global_position - global_position
	flat.y = 0.0
	var distance: float = flat.length()

	if distance > 7.0:
		velocity = flat.normalized() * speed
		look_at(global_position + flat, Vector3.UP)
		_play_animation("Idle")
	elif distance > 3.0:
		velocity = Vector3.ZERO
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		_play_animation("Aiming")
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = 1.5
			_fire()
	else:
		velocity = Vector3.ZERO
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		_play_animation("Aiming")
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = 1.0
			if player.has_method("take_damage"):
				player.take_damage(10)
	move_and_slide()

func _fire() -> void:
	if shooting:
		return
	shooting = true
	_play_animation("Firing Rifle")
	if player.has_method("take_damage"):
		player.take_damage(5)
	await get_tree().create_timer(0.35).timeout
	shooting = false
	if not dying:
		_play_animation("Aiming")

func take_damage(amount: int) -> void:
	if dying:
		return
	health -= amount
	_play_animation("Aiming")
	if health <= 0:
		dying = true
		velocity = Vector3.ZERO
		_play_animation("Dying")
		await get_tree().create_timer(2.5).timeout
		queue_free()
