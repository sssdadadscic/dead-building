extends Node2D
## 标题画面

func _ready() -> void:
	Game.hud_visible = false
	Sfx.music_night()
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/sprites/bg_title.png")
	bg.centered = false
	add_child(bg)
	var title := Game.mk_label("死  楼", 56, Color(0.88, 0.84, 0.72))
	title.add_theme_font_override("font", Game.font_bold)
	title.position = Vector2(215, 78)
	title.add_theme_color_override("font_shadow_color", Color(0.6, 0.1, 0.1, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)
	var sub := Game.mk_label("它们不是鬼，是被世界遗忘的人。", 13, Color(0.62, 0.6, 0.58))
	sub.position = Vector2(208, 168)
	add_child(sub)
	var btns := [
		["开始新游戏", _on_new],
		["继续游戏", _on_continue],
		["退出", _on_quit],
	]
	var y := 218
	for b in btns:
		var btn := Game.mk_button(b[0], 15)
		btn.position = Vector2(250, y)
		btn.custom_minimum_size = Vector2(140, 30)
		btn.pressed.connect(b[1])
		add_child(btn)
		y += 38
	var ver := Game.mk_label("垂直切片 v0.1 · Day1 完整流程", 10, Color(0.4, 0.4, 0.42))
	ver.position = Vector2(420, 342)
	add_child(ver)

const WORLD_3D := "res://src/scenes/world_3d.tscn"

func _on_new() -> void:
	Game.new_game()
	Game.hud_visible = true
	SceneFlow.goto(WORLD_3D)

func _on_continue() -> void:
	var data := Game.load_game(-1)
	if data.is_empty():
		_on_new()
		return
	Game.apply_state(data)
	Game.hud_visible = true
	SceneFlow.goto(WORLD_3D)

func _on_quit() -> void:
	get_tree().quit()
