extends CanvasLayer
## HUD：天数/相位 + 手电电量

var _day_label: Label
var _batt_frame: ColorRect
var _batt_fill: ColorRect
var _batt_label: Label
var _crosshair: ColorRect
var _prompt: Label

func _ready() -> void:
	layer = 40
	_day_label = Game.mk_label("", 13, Color(0.95, 0.93, 0.85))
	_day_label.position = Vector2(10, 6)
	_day_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	_day_label.add_theme_constant_override("shadow_offset_x", 1)
	_day_label.add_theme_constant_override("shadow_offset_y", 1)
	_batt_frame = ColorRect.new()
	_batt_frame.color = Color(0.1, 0.11, 0.15, 0.85)
	_batt_frame.position = Vector2(548, 8)
	_batt_frame.size = Vector2(80, 12)
	_batt_fill = ColorRect.new()
	_batt_fill.color = Color(0.5, 0.85, 0.4)
	_batt_fill.position = Vector2(550, 10)
	_batt_fill.size = Vector2(76, 8)
	_batt_label = Game.mk_label("手电", 10, Color(0.8, 0.82, 0.88))
	_batt_label.position = Vector2(518, 6)
	# 准星（3D 模式）
	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.65)
	_crosshair.position = Vector2(318, 178)
	_crosshair.size = Vector2(4, 4)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt = Game.mk_label("", 13, Color(0.95, 0.93, 0.85))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(220, 196)
	_prompt.custom_minimum_size = Vector2(200, 0)
	_prompt.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	_prompt.add_theme_constant_override("shadow_offset_x", 1)
	_prompt.add_theme_constant_override("shadow_offset_y", 1)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n in [_day_label, _batt_frame, _batt_fill, _batt_label, _crosshair, _prompt]:
		add_child(n)
	_crosshair.hide()
	_prompt.hide()
	Game.battery_changed.connect(_on_battery)
	Game.state_changed.connect(_refresh_day)
	visible = false
	_refresh()

func _process(_delta: float) -> void:
	var want := Game.hud_visible
	if visible != want:
		visible = want
		if want: _refresh()

func _refresh() -> void:
	_refresh_day()
	_on_battery(Game.battery)

func _refresh_day() -> void:
	_day_label.text = "第 %d 天 / 7  ·  %s" % [Game.day, Game.PHASE_NAMES[Game.phase]]

func _on_battery(v: float) -> void:
	_batt_fill.size.x = 76.0 * clampf(v / 100.0, 0.0, 1.0)
	if v > 50.0:
		_batt_fill.color = Color(0.5, 0.85, 0.4)
	elif v > 20.0:
		_batt_fill.color = Color(0.95, 0.8, 0.3)
	else:
		_batt_fill.color = Color(0.9, 0.3, 0.25)

# ---------- 3D 准星交互提示 ----------
func set_crosshair(on: bool) -> void:
	_crosshair.visible = on

func show_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.show()
	_crosshair.show()

func hide_prompt() -> void:
	_prompt.hide()
