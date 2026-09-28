extends CanvasLayer
## 暂停菜单（Esc）：继续 / 存档三槽 / 读档三槽 / 回标题

var _open := false
var _root: Control
var _status: Label

func _ready() -> void:
	layer = 80
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var title := Game.mk_label("— 暂停 —", 18, Color(0.9, 0.87, 0.78))
	title.position = Vector2(270, 60)
	_root.add_child(title)
	_status = Game.mk_label("", 12, Color(0.7, 0.85, 0.7))
	_status.position = Vector2(230, 92)
	_root.add_child(_status)
	var y := 120
	var btn_resume := Game.mk_button("继续", 15)
	btn_resume.position = Vector2(250, y); btn_resume.custom_minimum_size = Vector2(140, 30)
	btn_resume.pressed.connect(close)
	_root.add_child(btn_resume)
	y += 44
	for slot in [1, 2, 3]:
		var bs := Game.mk_button("保存到槽位 %d" % slot, 13)
		bs.position = Vector2(180, y); bs.custom_minimum_size = Vector2(130, 26)
		bs.pressed.connect(_on_save.bind(slot))
		_root.add_child(bs)
		var bl := Game.mk_button("读取槽位 %d" % slot, 13)
		bl.position = Vector2(330, y); bl.custom_minimum_size = Vector2(130, 26)
		bl.pressed.connect(_on_load.bind(slot))
		_root.add_child(bl)
		y += 32
	y += 8
	var btn_title := Game.mk_button("回到标题", 14)
	btn_title.position = Vector2(250, y); btn_title.custom_minimum_size = Vector2(140, 28)
	btn_title.pressed.connect(_on_title)
	_root.add_child(btn_title)
	_root.hide()

func _input(event: InputEvent) -> void:
	if not Game.hud_visible: return
	if event.is_action_pressed("pause"):
		if _open: close()
		elif not Dialog.active:
			open()
		get_viewport().set_input_as_handled()

func open() -> void:
	_open = true
	_status.text = ""
	Game.lock_ui("pause")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_root.show()

func close() -> void:
	_open = false
	Game.unlock_ui("pause")   # unlock_ui 内部会按场景恢复鼠标模式
	_root.hide()

func _current_scene_path() -> String:
	var cs := get_tree().current_scene
	if cs and cs.scene_file_path != "":
		return cs.scene_file_path
	return "res://src/scenes/world_3d.tscn"

func _on_save(slot: int) -> void:
	if Game.save_game(slot, _current_scene_path()):
		_status.text = "已保存到槽位 %d" % slot
	else:
		_status.text = "保存失败"

func _on_load(slot: int) -> void:
	var data := Game.load_game(slot)
	if data.is_empty():
		_status.text = "槽位 %d 没有存档" % slot
		return
	close()
	Game.apply_state(data)
	SceneFlow.goto(data.get("scene", "res://src/scenes/admin_room.tscn"))

func _on_title() -> void:
	close()
	Game.hud_visible = false
	SceneFlow.goto("res://src/scenes/title.tscn")
