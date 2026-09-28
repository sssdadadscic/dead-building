extends SceneTree
## 鼠标点击仪式按钮测试（复现"和桌子一交互就卡住"）
var failures := []
var Game
var Dialog
var RitualUI

func check(cond: bool, name: String) -> void:
	if cond:
		print("[PASS] ", name)
	else:
		failures.append(name)
		print("[FAIL] ", name)

func _initialize() -> void:
	await process_frame
	await process_frame
	Game = root.get_node("Game")
	Dialog = root.get_node("Dialog")
	RitualUI = root.get_node("RitualUI")
	Game.new_game()
	change_scene_to_file("res://src/scenes/world_3d.tscn")
	await process_frame
	await process_frame
	var world = current_scene
	await create_timer(1.3).timeout
	await _press_until(func(): return not Dialog.active)

	# 瞄准办公桌按 E
	world.player.position = Vector3(-0.8, world.ADMIN_Y + 0.05, -0.4)
	world.player.set_look(0, -0.56)
	await _settle(10)
	await _tap("interact")
	var ok1: bool = await _wait(func(): return RitualUI._open)
	check(ok1, "desk menu opened")

	# 检查按钮是否真的可见可点（尺寸>0 且已加入场景树）
	var btn = RitualUI._btns[0]
	check(btn.size.y > 4 and btn.is_visible_in_tree(), "ritual button has height")

	# 真实鼠标点击第一个按钮（翻开管理员日志 → 应打开日志）
	var center: Vector2 = btn.get_global_rect().get_center()
	await _click(center)
	var ok2: bool = await _wait(func(): return not RitualUI._open)
	check(ok2, "menu closed after MOUSE CLICK")
	await _settle(5)
	check(root.get_node("JournalUI")._open, "journal opened by click")
	await _tap("journal")
	await _settle(5)

	# 再开一次，点"先不忙"，确认玩家恢复控制
	await _tap("interact")
	await _wait(func(): return RitualUI._open)
	var btn3 = RitualUI._btns[2]
	await _click(btn3.get_global_rect().get_center())
	var ok3: bool = await _wait(func(): return not RitualUI._open)
	check(ok3, "second menu closed by click")
	await _settle(5)
	check(not Game.ui_locked(), "ui fully unlocked after click")
	if Game.ui_locked():
		print("   remaining locks=", Game._locks.keys())

	print("=== click test done, failures: ", failures.size(), " ===")
	quit(1 if failures.size() > 0 else 0)

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame

func _click(viewport_pos: Vector2) -> void:
	var pos: Vector2 = root.get_final_transform() * viewport_pos   # 画布坐标 → 物理窗口坐标（含 stretch 缩放）
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	Input.parse_input_event(move)
	await process_frame
	await process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	Input.parse_input_event(up)
	await process_frame
	await process_frame

func _wait(cond: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		await process_frame
		if cond.call():
			return true
	return false

func _press_until(cond: Callable, max_frames := 3000) -> bool:
	for i in max_frames:
		await _tap("interact")
		if cond.call():
			return true
	return false
