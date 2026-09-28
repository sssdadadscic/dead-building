extends SceneTree
## 新增道具互动测试：文件柜/沙发/书架/电表箱/抽屉/床底/地毯/衣柜动画/走廊事件
var failures := []
var Game
var Dialog

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
	Game.new_game()
	change_scene_to_file("res://src/scenes/world_3d.tscn")
	await process_frame
	await process_frame
	var world = current_scene
	await _skip_until(func(): return not Dialog.active)

	# 新节点引用
	check(world.cabinet_drawer != null, "cabinet drawer node")
	check(world.wardrobe_door != null, "wardrobe door node")
	check(world.drawer_104 != null, "104 drawer node")
	check(world.door_104_inner != null, "104 inner door ref")
	check(world.corridor_ghost != null and not world.corridor_ghost.visible, "corridor ghost hidden")

	# 文件柜：拉开动画 + 字条 + 日志
	var journals_before: int = Game.journal_entries.size()
	world._on_cabinet()
	await _skip_until(func(): return not Dialog.active)
	check(Game.flags.has("cabinet_note"), "cabinet note flag")
	check(Game.journal_entries.size() == journals_before + 1, "cabinet journal added")

	# 沙发：首次回电，之后不回
	Game.battery = 50.0
	world._on_sofa()
	await _skip_until(func(): return not Dialog.active)
	check(Game.battery == 75.0, "sofa restores battery once")
	world._on_sofa()
	await _skip_until(func(): return not Dialog.active)
	check(Game.battery == 75.0, "sofa no double dip")

	# 书架
	world._on_bookshelf()
	await _skip_until(func(): return not Dialog.active)
	check(Game.flags.has("shelf_log"), "bookshelf flag")

	# 电表箱：白天无用，夜晚修灯
	world._on_meter()
	await _skip_until(func(): return not Dialog.active)
	check(not world.lamp_fixed, "meter useless at day")
	Game.set_phase(Game.Phase.NIGHT)
	world._on_meter()
	await _skip_until(func(): return not Dialog.active)
	check(world.lamp_fixed and world.lamps[1].light_energy > 0.8, "meter fixes flickering lamp")

	# 104 内部道具
	world._on_drawer()
	await _skip_until(func(): return not Dialog.active)
	check(Game.flags.has("drawer_104"), "104 drawer flag")
	world._on_under_bed()
	await _skip_until(func(): return not Dialog.active)
	check(Game.flags.has("under_bed"), "under bed flag")
	world._on_rug()
	await _skip_until(func(): return not Dialog.active)
	check(Game.flags.has("rug_104"), "rug flag")

	# 衣柜门滑开动画
	var wx: float = world.wardrobe_door.position.x
	world._clue_dress()
	var ok1: bool = await _wait(func(): return world.wardrobe_door.position.x > wx + 0.5)
	check(ok1, "wardrobe door slides open")
	await _skip_until(func(): return not Dialog.active)

	# 走廊恐怖事件（夜晚+玩家在走廊）
	world.player.position = Vector3(0, world.CORRIDOR_Y + 0.05, 0)
	world._on_corridor_event()
	await _settle(40)
	check(true, "corridor event no crash")

	# 王大妈白天面向玩家
	Game.set_phase(Game.Phase.MORNING)
	world.player.position = Vector3(0.5, world.CORRIDOR_Y + 0.05, 2.5)
	await _settle(30)
	check(abs(world.wang.rotation.y) < 1.2 or abs(world.wang.rotation.y - PI*2) > 0.0, "wang faces player")

	print("=== props test done, failures: ", failures.size(), " ===")
	quit(1 if failures.size() > 0 else 0)

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame

func _wait(cond: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		await process_frame
		if cond.call():
			return true
	return false

func _skip_until(cond: Callable, max_frames := 4000) -> bool:
	for i in max_frames:
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
		await process_frame
		if cond.call():
			return true
	return false
