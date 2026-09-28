extends CharacterBody3D
class_name Player3D
## 第一人称控制器：WASD + 鼠标视角 + 手电 + 准星交互

const SPEED := 3.0
const MOUSE_SENS := 0.0022
const BATTERY_DRAIN := 0.5
const GRAVITY := 18.0

var camera: Camera3D
var flashlight: SpotLight3D
var ray: RayCast3D
var flashlight_on := false
var target = null
var _pitch := 0.0
var _step_t := 0.0
var _flicker_t := 0.0

func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 68.0
	add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.spot_angle = 30.0
	flashlight.spot_range = 14.0
	flashlight.light_energy = 3.2
	flashlight.light_color = Color(1.0, 0.95, 0.8)
	flashlight.shadow_enabled = true
	flashlight.visible = false
	camera.add_child(flashlight)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.8)
	ray.collide_with_areas = true
	ray.collide_with_bodies = false
	camera.add_child(ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_flashlight(on: bool) -> void:
	flashlight_on = on
	flashlight.visible = on and Game.battery > 0.0

func look_yaw() -> float:
	return rotation.y

func set_look(yaw: float, pitch := 0.0) -> void:
	rotation.y = yaw
	_pitch = pitch
	camera.rotation.x = pitch

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not Game.ui_locked():
		rotation.y -= event.relative.x * MOUSE_SENS
		_pitch = clampf(_pitch - event.relative.y * MOUSE_SENS, -1.35, 1.35)
		camera.rotation.x = _pitch
	if Game.ui_locked(): return
	if event.is_action_pressed("interact") and target != null and target.enabled:
		target.interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flashlight"):
		set_flashlight(not flashlight_on)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if Game.ui_locked():
		velocity.x = 0; velocity.z = 0
		move_and_slide()
		_update_ray()
		return
	var dir2 := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var fwd := -global_transform.basis.z
	var right := global_transform.basis.x
	fwd.y = 0; right.y = 0
	var move := (right * dir2.x + fwd * -dir2.y).normalized()
	velocity.x = move.x * SPEED
	velocity.z = move.z * SPEED
	move_and_slide()
	if move.length() > 0.1 and is_on_floor():
		_step_t += delta
		if _step_t > 0.45:
			_step_t = 0.0
			Sfx.play("footstep")
	# 手电
	if flashlight_on and Game.battery > 0.0:
		Game.drain_battery(BATTERY_DRAIN * delta)
		if Game.battery <= 0.0:
			set_flashlight(false)
			Dialog.say(["手电闪了两下，熄灭了。电池耗尽了。"])
	if flashlight.visible:
		_flicker_t += delta
		if _flicker_t > 0.09:
			_flicker_t = 0.0
			flashlight.light_energy = 3.2 + randf_range(-0.25, 0.1)
			if Game.battery < 20.0:
				flashlight.light_energy += randf_range(-1.2, 0.0)
	_update_ray()

func _update_ray() -> void:
	target = null
	if ray.is_colliding():
		var c = ray.get_collider()
		if c != null and c.get("event_name") != null and c.enabled:
			target = c
	if target != null and not Game.ui_locked():
		HUD.show_prompt("[E] " + target.prompt_text)
	else:
		HUD.hide_prompt()
