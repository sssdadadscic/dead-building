extends SceneTree
## 3D 世界 Day1 完整流程测试：开场 → 电话/王大妈 → 夜入104 → 三线索 → 真相 → 仪式 → 治愈 → 次日存档
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
	check(world != null and world.scene_file_path == "res://src/scenes/world_3d.tscn", "world_3d loaded")
	# 跳过开场白
	var ok0: bool = await _skip_until(func(): return not Dialog.active)
	check(ok0, "intro dialog done")
	check(world.player != null, "player spawned")
	check(abs(world.player.position.y - world.ADMIN_Y) < 2.0, "player starts in admin room")
	# 房东电话（Day1）
	world._on_phone()
	var ok1: bool = await _skip_until(func(): return not Dialog.active and Game.flags.has("phone1"))
	check(ok1, "landlord phone day1")
	# 出管理员室 → 走廊
	world._teleport("corridor_from_admin")
	var ok2: bool = await _skip_until(func(): return abs(world.player.position.y - world.CORRIDOR_Y) < 2.0)
	check(ok2, "teleport to corridor")
	# 王大妈给钥匙
	world._on_wang()
	var ok3: bool = await _skip_until(func(): return not Dialog.active and Game.flags.has("wang_met"))
	check(ok3, "wang gives key")
	# 白天进不去 104
	world._on_door104()
	var ok4: bool = await _skip_until(func(): return not Dialog.active)
	check(ok4, "104 locked at daytime")
	check(abs(world.player.position.y - world.CORRIDOR_Y) < 2.0, "still in corridor")
	# 切换到夜晚，进入 104
	Game.set_phase(Game.Phase.NIGHT)
	world._apply_phase_lighting(false)
	world._on_door104()
	var ok5: bool = await _skip_until(func(): return abs(world.player.position.y - world.R104_Y) < 2.0)
	check(ok5, "teleport into 104 at night")
	# 三线索
	world._clue_sticky()
	world._clue_medical()
	world._clue_dress()
	var ok6: bool = await _skip_until(func(): return world.phone_node.enabled)
	check(ok6, "phone unlocked after truth")
	check(Game.clue_count(world.CLUE_IDS) == 3, "3 clues collected")
	check(Game.flags.has("truth_104"), "truth flag")
	# 镜子事件（可选流程）
	world._on_mirror()
	var ok7: bool = await _skip_until(func(): return not Dialog.active)
	check(ok7, "mirror event done")
	check(world.ghost.visible, "ghost visible after mirror")
	# 手机草稿 → 仪式
	world._on_phone_draft()
	var ok8: bool = await _skip_until(func(): return RitualUI._open)
	check(ok8, "ritual ui opened")
	RitualUI.chosen.emit(0)
	var ok9: bool = await _skip_until(func(): return Game.relics.size() == 1 and not Dialog.active)
	check(ok9, "completion sequence finished")
	check(Game.flags.has("room104_done"), "room104 done flag")
	check(Game.healed.has(104), "104 in healed list")
	check(Game.relics[0]["name"] == "红裙子的纽扣", "relic button")
	# 治愈演出结果：红灯转暖白、血迹淡出
	check(world.room_lights.size() > 0 and world.room_lights[0].light_color.g > 0.8, "red lights turned warm")
	var blood_faded := true
	for bd in world.blood_decals:
		if bd.transparency < 0.99:
			blood_faded = false
	check(blood_faded, "blood decals faded")
	# 离开 → 次日 + 自动存档 + 回到管理员室
	world._on_leave()
	var ok10: bool = await _skip_until(func(): return Game.day == 2 and not Dialog.active)
	check(ok10, "next morning after heal")
	check(Game.phase == Game.Phase.MORNING, "phase morning")
	check(Game.has_save(-1), "autosave written")
	var data: Dictionary = Game.load_game(-1)
	var healed_ints: Array = data.get("healed", []).map(func(h): return int(h))
	check(int(data.get("day", 0)) == 2 and healed_ints.has(104), "autosave content")
	var ok11: bool = await _skip_until(func(): return abs(world.player.position.y - world.ADMIN_Y) < 2.0)
	check(ok11, "back to admin room")
	print("=== flow test 3d done, failures: ", failures.size(), " ===")
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
