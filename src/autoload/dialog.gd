extends CanvasLayer
## 对话框：打字机效果，支持队列。lines 元素为 String 或 [speaker, text]

signal finished

var active := false
var _lines: Array = []
var _idx := 0
var _char_t := 0.0
const CHAR_SPEED := 22.0

var _panel: ColorRect
var _border: ColorRect
var _speaker: Label
var _body: Label
var _hint: Label
var _center_label: Label   # 屏幕中央文字（真相还原用）
var _center_mode := false

func _ready() -> void:
	layer = 90
	_border = ColorRect.new()
	_border.color = Color(0.55, 0.58, 0.66, 0.9)
	_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	_border.offset_left = 6; _border.offset_top = 268
	_border.offset_right = -6; _border.offset_bottom = -6
	_panel = ColorRect.new()
	_panel.color = Color(0.03, 0.04, 0.07, 0.92)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 8; _panel.offset_top = 270
	_panel.offset_right = -8; _panel.offset_bottom = -8
	_speaker = Game.mk_label("", 13, Color(0.85, 0.8, 0.6))
	_speaker.position = Vector2(16, 274)
	_body = Game.mk_label("", 14, Color(0.92, 0.92, 0.94))
	_body.position = Vector2(16, 292)
	_body.size = Vector2(608, 58)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = Game.mk_label("▼ [E]", 11, Color(0.6, 0.62, 0.7))
	_hint.position = Vector2(590, 334)
	for n in [_border, _panel, _speaker, _body, _hint]:
		add_child(n)
	_center_label = Game.mk_label("", 16, Color(0.95, 0.93, 0.88))
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_center_label.offset_left = 60; _center_label.offset_right = -60
	_center_label.offset_top = 100; _center_label.offset_bottom = -100
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	_center_label.add_theme_constant_override("shadow_offset_x", 2)
	_center_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_center_label)
	_hide_all()

func _hide_all() -> void:
	for n in [_border, _panel, _speaker, _body, _hint, _center_label]:
		n.hide()

## 普通底部对话框
func say(lines: Array) -> void:
	if active: return
	active = true
	_center_mode = false
	_lines = lines
	_idx = 0
	Game.lock_ui("dialog")
	_show_current()

## 屏幕中央文字（真相/重要旁白）
func say_center(lines: Array) -> void:
	if active: return
	active = true
	_center_mode = true
	_lines = lines
	_idx = 0
	Game.lock_ui("dialog")
	_show_current()

func _show_current() -> void:
	if _idx >= _lines.size():
		_close()
		return
	var entry = _lines[_idx]
	var speaker := ""
	var text := ""
	if entry is Array:
		speaker = entry[0]; text = entry[1]
	else:
		text = entry
	if _center_mode:
		_center_label.show()
		_hint.show()
		_center_label.text = text
		_center_label.visible_characters = 0
	else:
		for n in [_border, _panel, _body, _hint]: n.show()
		if speaker != "":
			_speaker.show()
			_speaker.text = speaker
		_body.text = text
		_body.visible_characters = 0
	_char_t = 0.0

func _typing_done(lbl: Label) -> bool:
	return lbl.visible_characters == -1 or lbl.visible_characters >= lbl.text.length()

func _process(delta: float) -> void:
	if not active: return
	var lbl: Label = _center_label if _center_mode else _body
	if not _typing_done(lbl):
		_char_t += delta * CHAR_SPEED
		if _char_t >= 1.0:
			var adv := int(_char_t)
			_char_t -= adv
			var next: int = lbl.visible_characters + adv
			if next >= lbl.text.length():
				lbl.visible_characters = -1
			else:
				lbl.visible_characters = next

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event.is_action_pressed("interact"):
		var lbl: Label = _center_label if _center_mode else _body
		if not _typing_done(lbl):
			lbl.visible_characters = -1   # 立即显示全部
		else:
			_idx += 1
			_show_current()
		get_viewport().set_input_as_handled()

func _close() -> void:
	active = false
	_hide_all()
	Game.unlock_ui("dialog")
	emit_signal("finished")
