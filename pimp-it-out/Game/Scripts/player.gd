extends RigidBody3D

var _pid := Pid3D.new(15.0, 0.1, 1.0)
const TARGET_SPEED := 20.0
const JUMP_FORCE := 5.0
@export var ray : RayCast3D
@export var camera : Camera3D
@export var sensitivity := 0.003

var _pitch := 0.0
var _yaw := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	
	var canvas = CanvasLayer.new()
	var cursor = ColorRect.new()
	cursor.size = Vector2(4, 4)
	cursor.color = Color.DARK_RED
	cursor.anchor_left = 0.5
	cursor.anchor_top = 0.5
	cursor.anchor_right = 0.5
	cursor.anchor_bottom = 0.5
	cursor.offset_left = -2
	cursor.offset_top = -2
	cursor.offset_right = 2
	cursor.offset_bottom = 2
	canvas.add_child(cursor)
	add_child(canvas)

func _input(event):
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	rotation.y = _yaw
	camera.rotation.x = _pitch

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

func _is_on_floor():
	return ray.is_colliding()
