extends CharacterBody2D
class_name Player
## 玩家：四方向行走 / 互动检测 / 手电与电量

const SPEED := 100.0
const BATTERY_DRAIN := 0.55   # 每秒

var sprite: AnimatedSprite2D
var light: PointLight2D
var interact_area: Area2D
var target = null            # 附近的 Interactable
var flashlight_on := false
var _step_t := 0.0
var _flicker_t := 0.0

func _ready() -> void:
	# 碰撞（脚底小矩形）
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 10)
	col.shape = rect
	col.position = Vector2(0, -5)
	add_child(col)
	# 行走图
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.scale = Vector2(2, 2)
	sprite.position = Vector2(0, -32)
	sprite.animation = "down"
	sprite.frame = 0
	add_child(sprite)
	# 互动检测圈
	interact_area = Area2D.new()
	interact_area.name = "InteractArea"
	var ish := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	ish.shape = circle
	ish.position = Vector2(0, -14)
	interact_area.add_child(ish)
	interact_area.monitoring = true
	interact_area.monitorable = false
	add_child(interact_area)
	# 手电
	light = PointLight2D.new()
	light.texture = load("res://assets/sprites/light_grad.png")
	light.texture_scale = 2.3
	light.energy = 0.95
	light.color = Color(1.0, 0.96, 0.82)
	light.position = Vector2(0, -24)
	light.enabled = false
	add_child(light)

func _build_frames() -> SpriteFrames:
	var tex: Texture2D = load("res://assets/sprites/player_walk.png")
	var sf := SpriteFrames.new()
	var dirs := ["down", "left", "right", "up"]
	for d in 4:
		sf.add_animation(dirs[d])
		sf.set_animation_speed(dirs[d], 8.0)
		sf.set_animation_loop(dirs[d], true)
		for f in 4:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(f * 24, d * 32, 24, 32)
			sf.add_frame(dirs[d], at)
	return sf

func set_flashlight(on: bool) -> void:
	flashlight_on = on
	light.enabled = on and Game.battery > 0.0

func _physics_process(delta: float) -> void:
	if Game.ui_locked():
		velocity = Vector2.ZERO
		move_and_slide()
		_set_anim(Vector2.ZERO)
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	_set_anim(dir)
	# 脚步声
	if dir != Vector2.ZERO:
		_step_t += delta
		if _step_t > 0.34:
			_step_t = 0.0
			Sfx.play("footstep")
	# 手电耗电
	if flashlight_on and Game.battery > 0.0:
		Game.drain_battery(BATTERY_DRAIN * delta)
		if Game.battery <= 0.0:
			set_flashlight(false)
			Dialog.say(["手电闪了两下，熄灭了。电池耗尽了。"])
	# 手电轻微闪烁
	if light.enabled:
		_flicker_t += delta
		if _flicker_t > 0.09:
			_flicker_t = 0.0
			light.energy = 0.95 + randf_range(-0.06, 0.02)
			if Game.battery < 20.0:
				light.energy += randf_range(-0.25, 0.0)

func _set_anim(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		sprite.stop()
		sprite.frame = 0
		return
	var anim := "down"
	if absf(dir.x) > absf(dir.y):
		anim = "right" if dir.x > 0 else "left"
	else:
		anim = "down" if dir.y > 0 else "up"
	if sprite.animation != anim:
		sprite.animation = anim
	sprite.play()

func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_locked(): return
	if event.is_action_pressed("interact") and target != null:
		if target.enabled:
			target.interact()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flashlight"):
		set_flashlight(not flashlight_on)
