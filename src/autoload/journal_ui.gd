extends CanvasLayer
## 管理员日志（Tab 开关）：左页日志，右页线索与遗物

var _open := false
var _root: Control

func _ready() -> void:
	layer = 60
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/ui_journal.png")
	bg.position = Vector2(110, 30)
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	_root.add_child(bg)
	var title := Game.mk_label("管理员日志", 15, Color(0.3, 0.22, 0.14))
	title.position = Vector2(126, 40)
	_root.add_child(title)
	var close_hint := Game.mk_label("[Tab 合上]", 10, Color(0.45, 0.38, 0.28))
	close_hint.position = Vector2(430, 308)
	_root.add_child(close_hint)
	_root.hide()

func _input(event: InputEvent) -> void:
	if not Game.hud_visible: return
	if event.is_action_pressed("journal"):
		if _open: close()
		elif not Dialog.active: open()
		get_viewport().set_input_as_handled()

func open() -> void:
	_open = true
	Game.lock_ui("journal")
	_rebuild()
	_root.show()

func close() -> void:
	_open = false
	Game.unlock_ui("journal")
	_root.hide()

func _rebuild() -> void:
	for n in _root.get_children():
		if n is Label and n.name.begins_with("entry"):
			n.queue_free()
	# 左页：最近日志
	var left_lines := PackedStringArray()
	var entries := Game.journal_entries
	var start := maxi(0, entries.size() - 7)
	for i in range(start, entries.size()):
		var e = entries[i]
		left_lines.append("第%d天  %s" % [e["day"], e["text"]])
	var lt := Game.mk_label("\n\n".join(left_lines) if left_lines.size() > 0 else "（还没有记录）", 11, Color(0.25, 0.2, 0.14))
	lt.name = "entryL"
	lt.position = Vector2(126, 62)
	lt.size = Vector2(180, 250)
	lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(lt)
	# 右页：线索 + 遗物
	var right := PackedStringArray()
	right.append("— 线索 —")
	if Game.clue_details.is_empty():
		right.append("（暂无）")
	for id in Game.clue_details:
		right.append("· " + Game.clue_details[id]["title"])
	right.append("")
	right.append("— 遗物 —")
	if Game.relics.is_empty():
		right.append("（暂无）")
	for r in Game.relics:
		right.append("· " + r["name"])
	var rt := Game.mk_label("\n".join(right), 11, Color(0.25, 0.2, 0.14))
	rt.name = "entryR"
	rt.position = Vector2(336, 62)
	rt.size = Vector2(178, 250)
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(rt)
