extends CharacterBody3D

# FPSGAME - Godot 4.2.2
# Native GLB enemy support. No FBX importer is required.
# Files:
# res://characters/enemy/enemy.glb
# res://characters/enemy/Idle.glb
# res://characters/enemy/Aiming.glb
# res://characters/enemy/Firing_Rifle.glb
# res://characters/enemy/Jumping.glb
# res://characters/enemy/Dying.glb

const CHARACTER_DIR: String = "res://characters/enemy/"
const MODEL_FILE: String = CHARACTER_DIR + "enemy.glb"
const ANIMATION_FILES: Dictionary = {
	"Idle": "Idle.glb",
	"Aiming": "Aiming.glb",
	"Firing Rifle": "Firing_Rifle.glb",
	"Jumping": "Jumping.glb",
	"Dying": "Dying.glb"
}

var health: int = 100
var speed: float = 2.5
var attack_timer: float = 0.0
var player: Node3D
var model: Node3D
var animation_player: AnimationPlayer
var animations: Dictionary = {}
var dying: bool = false
var shooting: bool = false
var current_animation: String = ""

func _ready() -> void:
	_load_model()
	_load_glb_animations()
	_build_collision()
	player = get_tree().get_first_node_in_group("player") as Node3D
	add_to_group("enemy")
	_play_animation("Idle")

func _load_model() -> void:
	var scene: PackedScene = load(MODEL_FILE) as PackedScene
	if scene == null:
		print("ERROR: Missing ", MODEL_FILE)
		return
	model = scene.instantiate()
	add_child(model)
	animation_player = _find_animation_player(model)
	if animation_player == null:
		print("ERROR: No AnimationPlayer found in ", MODEL_FILE)

func _load_glb_animations() -> void:
	if animation_player == null:
		return
	var library: AnimationLibrary = animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)

	for animation_name: String in ANIMATION_FILES.keys():
		var file_name: String = String(ANIMATION_FILES[animation_name])
		var scene: PackedScene = load(CHARACTER_DIR + file_name) as PackedScene
		if scene == null:
			print("WARNING: Could not load ", CHARACTER_DIR + file_name)
			continue

		var animation_scene: Node = scene.instantiate()
		var source_player: AnimationPlayer = _find_animation_player(animation_scene)
		if source_player == null:
			print("WARNING: No AnimationPlayer in ", file_name)
			animation_scene.queue_free()
			continue

		var source_library: AnimationLibrary = source_player.get_animation_library("")
		if source_library == null:
			animation_scene.queue_free()
			continue

		var source_names: PackedStringArray = source_library.get_animation_list()
		if source_names.is_empty():
			animation_scene.queue_free()
			continue

		var source_animation: Animation = source_library.get_animation(source_names[0])
		if source_animation != null:
			library.add_animation(animation_name, source_animation.duplicate())
			animations[animation_name] = true

		animation_scene.queue_free()

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child: Node in root.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
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

func _play_animation(animation_name: String) -> void:
	if animation_player == null or not animations.has(animation_name):
		return
	if current_animation == animation_name:
		return
	current_animation = animation_name
	animation_player.play(animation_name)

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
	if health <= 0:
		dying = true
		velocity = Vector3.ZERO
		_play_animation("Dying")
		await get_tree().create_timer(2.5).timeout
		queue_free()
