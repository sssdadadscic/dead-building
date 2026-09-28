extends SceneTree
## 真实输入路径测试：射线瞄准 → E 键交互 → UI 打开时鼠标必须可点击（修"交互完卡死"）
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
	await _press_until("interact", func(): return not Dialog.active)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse captured in 3d world")

	# --- 电话：射线瞄准 + E 键 ---
	world.player.position = Vector3(0.1, world.ADMIN_Y + 0.05, -0.6)
	world.player.set_look(0, -0.53)
	await _settle(10)
	check(world.player.target != null and world.player.target.event_name == "phone", "raycast targets phone")
	await _tap("interact")
	await _settle(5)
	check(Dialog.active, "phone dialog opened via E key")
	await _press_until("interact", func(): return not Dialog.active)
	check(not Game.ui_locked(), "ui unlocked after dialog")
	check(Game.flags.has("phone1"), "phone1 flag via real input")

	# --- 办公桌：仪式界面打开时鼠标必须释放 ---
	world.player.position = Vector3(-0.8, world.ADMIN_Y + 0.05, -0.4)
	world.player.set_look(0, -0.56)
	await _settle(10)
	check(world.player.target != null and world.player.target.event_name == "desk", "raycast targets desk")
	await _tap("interact")
	var ok1: bool = await _wait(func(): return RitualUI._open)
	check(ok1, "desk menu opened")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "MOUSE RELEASED when ritual ui open (卡死修复点)")
	await _key(KEY_3)   # 先不忙
	var ok2: bool = await _wait(func(): return not RitualUI._open)
	check(ok2, "ritual closed by number key")
	await _settle(5)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse recaptured after ritual closed")
	check(not Game.ui_locked(), "ui unlocked after ritual")

	# --- 日志：Tab 开关时鼠标状态 ---
	await _tap("journal")
	await _settle(5)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse released when journal open")
	await _tap("journal")
	await _settle(5)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse recaptured after journal closed")

	# --- 暂停菜单 ---
	await _tap("pause")
	await _settle(5)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse released when pause open")
	await _tap("pause")
	await _settle(5)
	check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "mouse recaptured after pause closed")

	print("=== ui input test done, failures: ", failures.size(), " ===")
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

func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame

func _wait(cond: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		await process_frame
		if cond.call():
			return true
	return false

func _press_until(action: String, cond: Callable, max_frames := 3000) -> bool:
	for i in max_frames:
		await _tap(action)
		if cond.call():
			return true
	return false
