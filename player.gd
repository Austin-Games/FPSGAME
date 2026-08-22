extends CharacterBody3D

var speed: float = 6.0
var sprint: float = 10.0
var jump: float = 5.0
var gravity: float = 9.8
var sensitivity: float = 0.0025
var pitch: float = 0.0
var camera: Camera3D
var gun: MeshInstance3D
var health: int = 100
var hud: Label

func _ready() -> void:
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0,1.55,0)
	camera.current = true
	add_child(camera)
	var gun_mesh: MeshInstance3D = MeshInstance3D.new()
	var gun_box: BoxMesh = BoxMesh.new()
	gun_box.size = Vector3(0.22,0.18,0.8)
	gun_mesh.mesh = gun_box
	gun_mesh.position = Vector3(0.35,-0.25,-0.65)
	gun_mesh.material_override = _mat(Color(0.08,0.09,0.1))
	camera.add_child(gun_mesh)
	gun = gun_mesh
	var ui: CanvasLayer = CanvasLayer.new()
	add_child(ui)
	hud = Label.new()
	hud.position = Vector2(25,25)
	hud.add_theme_font_size_override("font_size",24)
	ui.add_child(hud)
	var cross: Label = Label.new()
	cross.text = "+"
	cross.position = Vector2(637,347)
	cross.add_theme_font_size_override("font_size",28)
	ui.add_child(cross)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _mat(c: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity)
		pitch = clamp(pitch - event.relative.y * sensitivity,-1.45,1.45)
		camera.rotation.x = pitch
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func shoot() -> void:
	gun.position.z = -0.85
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + -camera.global_transform.basis.z * 100.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to)
	query.exclude = [self]
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		var target: Object = hit.get("collider")
		if target and target.has_method("take_damage"):
			target.take_damage(25)
	await get_tree().create_timer(0.08).timeout
	gun.position.z = -0.65

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump
	var x: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var z: float = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var input_vec: Vector2 = Vector2(x,z)
	if input_vec.length() > 1.0: input_vec = input_vec.normalized()
	var dir: Vector3 = (transform.basis * Vector3(input_vec.x,0,input_vec.y)).normalized()
	var current_speed: float = sprint if Input.is_key_pressed(KEY_SHIFT) else speed
	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed
	move_and_slide()
	hud.text = "HEALTH: %d    WASD MOVE | SHIFT SPRINT | SPACE JUMP | LMB FIRE" % health

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		get_tree().reload_current_scene()
