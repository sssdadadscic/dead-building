extends SceneTree
## 多天全流程测试：Day2(214) → Day3(334) → Day4(404) → Day5(444) → Day6(4444六问) → Day7(真结局)
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
	var extra = world.extra
	check(extra != null, "extra rooms built")
	await _skip_until(func(): return not Dialog.active)
	# 直接完成 Day1（444 仪式需要纽扣遗物）
	Game.flags["room104_done"] = true
	Game.healed.append(104)
	Game.add_relic("红裙子的纽扣", "测试")

	# ---------- Day 2 · 214 ----------
	Game.day = 2
	Game.set_phase(Game.Phase.NIGHT)
	extra.handle("door_214")
	var ok := await _skip_until(func(): return abs(world.player.position.y - extra.R214_Y) < 2.0)
	check(ok, "enter 214 at night day2")
	extra.handle("c214_receipts")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c214_phone")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c214_peephole")
	ok = await _skip_until(func(): return Game.flags.has("truth_214") and not Dialog.active)
	check(ok, "214 truth")
	ok = await _wait(func(): return extra.ritual_nodes["214"].enabled)
	check(ok, "laptop unlocked")
	extra.handle("meter214")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("fan214")
	check(Game.flags.has("usb214"), "usb found")
	extra.handle("laptop214")
	await _answer(0)
	ok = await _skip_until(func(): return Game.healed.has(214) and not Dialog.active)
	check(ok, "214 healed")
	extra.handle("leave214")
	ok = await _skip_until(func(): return Game.day == 3 and abs(world.player.position.y - world.ADMIN_Y) < 2.0)
	check(ok, "sleep to day3")

	# ---------- Day 3 · 334 ----------
	Game.set_phase(Game.Phase.NIGHT)
	extra.handle("door_334")
	ok = await _skip_until(func(): return abs(world.player.position.y - extra.R334_Y) < 2.0)
	check(ok, "enter 334 at night day3")
	extra.handle("c334_ledger")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c334_debt")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c334_photo")
	ok = await _skip_until(func(): return Game.flags.has("truth_334") and not Dialog.active)
	check(ok, "334 truth")
	extra.handle("tank334")
	check(Game.flags.has("card334"), "bank card found")
	extra.handle("safe334")
	await _answer(0)
	ok = await _skip_until(func(): return Game.healed.has(334) and not Dialog.active)
	check(ok, "334 healed")
	extra.handle("leave334")
	ok = await _skip_until(func(): return Game.day == 4)
	check(ok, "sleep to day4")

	# ---------- Day 4 · 404 ----------
	Game.set_phase(Game.Phase.NIGHT)
	extra.handle("door_404")
	ok = await _skip_until(func(): return abs(world.player.position.y - extra.R404_Y) < 2.0)
	check(ok, "enter 404 at night day4")
	extra.handle("c404_bed")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c404_log")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c404_window")
	ok = await _skip_until(func(): return Game.flags.has("truth_404") and not Dialog.active)
	check(ok, "404 truth")
	extra.handle("prev_talk")
	await _answer(0)
	ok = await _skip_until(func(): return Game.healed.has(404) and not Dialog.active)
	check(ok, "404 healed")
	extra.handle("leave404")
	ok = await _skip_until(func(): return Game.day == 5)
	check(ok, "sleep to day5")

	# ---------- Day 5 · 444 ----------
	Game.set_phase(Game.Phase.NIGHT)
	extra.handle("door_444")
	ok = await _skip_until(func(): return abs(world.player.position.y - extra.R444_Y) < 2.0)
	check(ok, "enter 444 at night day5")
	extra.handle("c444_mirror")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c444_talisman")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("c444_photo")
	ok = await _skip_until(func(): return Game.flags.has("truth_444") and not Dialog.active)
	check(ok, "444 truth")
	extra.handle("doorgod")
	await _answer(0)
	ok = await _skip_until(func(): return Game.healed.has(444) and not Dialog.active)
	check(ok, "444 healed")
	extra.handle("leave444")
	ok = await _skip_until(func(): return Game.day == 6)
	check(ok, "sleep to day6")

	# ---------- Day 6 · 4444 蝴蝶六问 ----------
	Game.set_phase(Game.Phase.NIGHT)
	extra.handle("elevator_x")
	await _answer(0)
	ok = await _skip_until(func(): return abs(world.player.position.y - extra.R4444_Y) < 2.0)
	check(ok, "enter 4444 via elevator")
	extra.handle("butterfly_voice")
	for i in 6:
		await _answer(0)
	ok = await _skip_until(func(): return Game.day == 7 and abs(world.player.position.y - world.ADMIN_Y) < 2.0)
	check(ok, "quiz done, sleep to day7")
	check(int(Game.flags.get("quiz_score", 0)) == 6, "quiz score 6/6")

	# ---------- Day 7 · 真相 → 真结局 ----------
	extra.day7_steps = 0
	extra.handle("computer_evo")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("cabinet7")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("invitation7")
	ok = await _skip_until(func(): return Game.flags.has("ending") and RitualUI._open)
	check(ok, "ending shown")
	check(Game.flags.get("ending", "") == "true", "TRUE ending")
	RitualUI.chosen.emit(0)   # 重新开始
	await _skip_until(func(): return Game.day == 1)
	check(Game.day == 1, "restart new game")

	# ---------- 彩蛋 ----------
	Game.new_game()
	extra.handle("egg_siqu")
	await _skip_until(func(): return not Dialog.active)
	extra.handle("egg_cicada")
	ok = await _skip_until(func(): return not Dialog.active)
	var eggs := 0
	for k in Game.flags:
		if str(k).begins_with("egg_"): eggs += 1
	check(eggs == 2, "all 2 easter eggs collected (%d)" % eggs)

	print("=== days test done, failures: ", failures.size(), " ===")
	quit(1 if failures.size() > 0 else 0)

func _answer(idx: int) -> void:
	var ok: bool = await _wait(func(): return RitualUI._open)
	if ok:
		RitualUI.chosen.emit(idx)
	await _wait(func(): return not RitualUI._open, 120)

func _skip_until(cond: Callable) -> bool:
	for i in 6000:
		await process_frame
		# 自动推进对话
		if Dialog.active:
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
		if cond.call():
			return true
	return false

func _wait(cond: Callable, max_frames := 6000) -> bool:
	for i in max_frames:
		await process_frame
		if Dialog.active:
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
		if cond.call():
			return true
	return false
