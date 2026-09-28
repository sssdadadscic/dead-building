extends Area3D
## 3D 可互动物：准星指向时显示提示，按 E 触发

signal used(node)

var event_name := ""
var prompt_text := "查看"
var enabled := true

func setup(pos: Vector3, evt: String, prompt: String, size := Vector3(0.6, 0.6, 0.6)) -> void:
	position = pos
	event_name = evt
	prompt_text = prompt
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	add_child(col)
	monitoring = false
	monitorable = true

func _ready() -> void:
	pass

func interact() -> void:
	if enabled:
		emit_signal("used", self)

func set_enabled(v: bool) -> void:
	enabled = v
