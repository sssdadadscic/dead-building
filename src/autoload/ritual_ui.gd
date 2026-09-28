extends CanvasLayer
## 仪式/抉择界面：标题 + 选项按钮，await 返回所选下标
## 注意：按钮手动排版（不用 Container，容器在固定坐标布局下会把子节点排成 0x0）

signal chosen(idx: int)

var _open := false
var _root: Control
var _title: Label
var _btns: Array = []

func _ready() -> void:
	layer = 70
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := ColorRect.new()
	panel.name = "Panel"
	panel.color = Color(0.05, 0.06, 0.1, 0.95)
	panel.position = Vector2(120, 90)
	panel.size = Vector2(400, 200)
	_root.add_child(panel)
	var border := ColorRect.new()
	border.name = "Border"
	border.color = Color(0.5, 0.45, 0.35)
	border.position = Vector2(118, 88)
	border.size = Vector2(404, 204)
	border.z_index = -1
	_root.add_child(border)
	_title = Game.mk_label("", 15, Color(0.92, 0.88, 0.75))
	_title.position = Vector2(140, 100)
	_title.size = Vector2(360, 52)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_title)
	var hint := Game.mk_label("（鼠标点击 或 按数字键选择）", 10, Color(0.55, 0.53, 0.48))
	hint.name = "Hint"
	hint.position = Vector2(140, 268)
	_root.add_child(hint)
	_root.hide()

func ask(title: String, options: Array) -> int:
	if _open: return -1
	_open = true
	Game.lock_ui("ritual")
	_title.text = title
	# 面板高度随选项数量自适应（按钮区 y156 起，每个 36 高）
	var ph: float = 120.0 + options.size() * 36.0
	var panel: ColorRect = _root.get_node("Panel")
	var border: ColorRect = _root.get_node("Border")
	var hint: Label = _root.get_node("Hint")
	panel.size.y = ph
	border.size.y = ph + 4
	hint.position.y = 90 + ph - 22
	for c in _btns: c.queue_free()
	_btns.clear()
	for i in options.size():
		var b := Game.mk_button("%d. %s" % [i + 1, options[i]], 13)
		b.position = Vector2(140, 156 + i * 36)
		b.size = Vector2(360, 30)
		b.pressed.connect(_on_pick.bind(i))
		_root.add_child(b)
		_btns.append(b)
	_root.show()
	var idx: int = await chosen
	_root.hide()
	Game.unlock_ui("ritual")
	_open = false
	return idx

func _on_pick(i: int) -> void:
	emit_signal("chosen", i)

func _input(event: InputEvent) -> void:
	if not _open: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _btns.size():
			if _btns[i].get_global_rect().has_point(event.position):
				emit_signal("chosen", i)
				get_viewport().set_input_as_handled()
				return

func _unhandled_input(event: InputEvent) -> void:
	if not _open: return
	if event is InputEventKey and event.pressed:
		var n := _btns.size()
		for i in mini(n, 9):
			if event.physical_keycode == KEY_1 + i:
				emit_signal("chosen", i)
				get_viewport().set_input_as_handled()
				return
