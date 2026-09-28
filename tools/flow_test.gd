extends SceneTree
## Day1 完整流程测试：仪式 → 治愈演出 → 遗物 → 次日存档
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
	change_scene_to_file("res://src/scenes/room_104.tscn")
	await process_frame
	await process_frame
	var room = current_scene
	room._clue_sticky()
	room._clue_medical()
	room._clue_dress()
	var ok1: bool = await _skip_until(func(): return room.phone_node.enabled)
	check(ok1, "phone unlocked")
	room._on_phone_draft()
	var ok2: bool = await _skip_until(func(): return RitualUI._open)
	check(ok2, "ritual ui opened")
	RitualUI.chosen.emit(0)
	var ok3: bool = await _skip_until(func(): return Game.relics.size() == 1)
	check(ok3, "completion sequence finished")
	check(Game.flags.has("room104_done"), "room104 done flag")
	check(Game.healed.has(104), "104 in healed list")
	check(Game.relics.size() == 1 and Game.relics[0]["name"] == "红裙子的纽扣", "relic button")
	check(room.bg_white.modulate.a > 0.99, "bg crossfade to white")
	# 离开 → 次日 + 自动存档
	room._on_leave()
	var ok4: bool = await _skip_until(func(): return Game.day == 2)
	check(ok4, "next morning after heal")
	check(Game.phase == Game.Phase.MORNING, "phase morning")
	check(Game.has_save(-1), "autosave written")
	var data: Dictionary = Game.load_game(-1)
	var healed_ints: Array = data.get("healed", []).map(func(h): return int(h))
	check(int(data.get("day", 0)) == 2 and healed_ints.has(104), "autosave content")
	var ok5: bool = await _skip_until(func():
		return current_scene != null and current_scene.scene_file_path == "res://src/scenes/admin_room.tscn")
	check(ok5, "back to admin room")
	print("=== flow test done, failures: ", failures.size(), " ===")
	quit(1 if failures.size() > 0 else 0)

func _skip_until(cond: Callable, max_frames := 8000) -> bool:
	for i in max_frames:
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
		await process_frame
		if cond.call():
			return true
	return false
