extends RigidBody3D

var _pid := Pid3D.new(15.0, 0.1, 1.0)
const TARGET_SPEED := 20.0
const JUMP_FORCE := 5.0

@export var grounded : RayCast3D
@export var camera : Camera3D
@export var view : RayCast3D
@export var sensitivity := 0.003

var _pitch := 0.0
var _yaw := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

func _input(event):
#	--- Lógica de Cámara
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	rotation.y = _yaw
	camera.rotation.x = _pitch

	# --- Lógica de visión ---
	var npc = _get_looked_at_npc()
	if npc:
		var tipo = npc.get_meta("type", "unknown")
		match tipo:
			"merchant": print("Mercader: ", npc.get_meta("name", "???"))
			"enemy":    print("Enemigo: ", npc.get_meta("name", "???"))
			"guard":    print("Guardia: ", npc.get_meta("name", "???"))
   # --- Lógica de control ---
	var input = Vector3(
		Input.get_action_strength("move_left") - Input.get_action_strength("move_right"),
		0.0,
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)

	if Input.is_action_just_pressed("move_jump") and _is_on_floor():
		linear_velocity.y = JUMP_FORCE

	if input.x == 0 and input.z == 0:
		_pid.reset_integral()
		linear_velocity.x = lerp(linear_velocity.x, 0.0, 0.1)
		linear_velocity.z = lerp(linear_velocity.z, 0.0, 0.1)
		return

	var direction = (global_transform.basis * input).normalized()
	var target_velocity = direction * TARGET_SPEED
	var error = target_velocity - linear_velocity
	var correction_impulse = _pid.update(error, delta) * 0.001
	apply_central_impulse(correction_impulse)

func _is_on_floor() -> bool:
	return grounded.is_colliding()

func _get_looked_at_npc() -> Node:
	if not view.is_colliding():
		return null
	var collider = view.get_collider()
	if collider == null or not collider.is_in_group("npc"):
		return null
	return collider
