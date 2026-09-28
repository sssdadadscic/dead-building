extends Area2D
## 可互动物：玩家靠近显示 [E] 提示，按 E 触发 used 信号

signal used(node)

var event_name := ""
var enabled := true
var prompt: Sprite2D

func setup(pos: Vector2, evt: String, radius := 18.0) -> void:
	position = pos
	event_name = evt
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	col.shape = c
	add_child(col)
	monitoring = true
	monitorable = true

func _ready() -> void:
	prompt = Sprite2D.new()
	prompt.texture = load("res://assets/sprites/item_prompt_e.png")
	prompt.position = Vector2(0, -30)
	prompt.hide()
	add_child(prompt)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
	if prompt.visible:
		prompt.position.y = -30 + sin(Time.get_ticks_msec() / 300.0) * 2.0

func _on_area_entered(area: Area2D) -> void:
	var p = area.get_parent()
	if p is Player and enabled:
		p.target = self
		prompt.show()

func _on_area_exited(area: Area2D) -> void:
	var p = area.get_parent()
	if p is Player:
		if p.target == self:
			p.target = null
		prompt.hide()

func interact() -> void:
	if enabled:
		emit_signal("used", self)

func set_enabled(v: bool) -> void:
	enabled = v
	if not v:
		prompt.hide()
