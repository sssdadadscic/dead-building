extends SceneTree
## 冒烟测试：逐场景加载 + 存档往返 + 核心逻辑断言
## 运行：godot --headless --path dead_building -s res://tools/smoke_test.gd
## 注意：-s 入口脚本编译期看不到 autoload 单例，统一用 root.get_node 动态获取

var failures := []
var Game

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

	# --- 场景加载测试 ---
	for sc in [
		"res://src/scenes/title.tscn",
		"res://src/scenes/admin_room.tscn",
		"res://src/scenes/corridor.tscn",
		"res://src/scenes/room_104.tscn",
	]:
		var err = change_scene_to_file(sc)
		await process_frame
		await process_frame
		await process_frame
		check(err == OK and current_scene != null, "scene load: " + sc)
		if current_scene != null:
			print("       nodes=", current_scene.get_child_count())

	# --- 核心逻辑 ---
	Game.new_game()
	check(Game.day == 1 and Game.phase == Game.Phase.MORNING, "new_game state")
	check(Game.journal_entries.size() == 1, "new_game journal seed")

	Game.add_clue("t1", "测试线索", "测试描述")
	check(Game.clues.has("t1") and Game.clue_details["t1"]["title"] == "测试线索", "add_clue")
	Game.add_relic("测试遗物", "desc")
	check(Game.relics.size() == 1, "add_relic")

	Game.next_morning()
	check(Game.day == 2 and Game.battery == 100.0, "next_morning")

	# --- 存档往返 ---
	var ok: bool = Game.save_game(1, "res://src/scenes/admin_room.tscn")
	check(ok and Game.has_save(1), "save_game slot1")
	var data: Dictionary = Game.load_game(1)
	check(data.get("day") == 2 and data.get("scene") == "res://src/scenes/admin_room.tscn", "load_game roundtrip")
	Game.day = 5
	Game.apply_state(data)
	check(Game.day == 2, "apply_state restores day")

	# --- 104 房间逻辑（直接驱动） ---
	Game.new_game()
	change_scene_to_file("res://src/scenes/room_104.tscn")
	await process_frame
	await process_frame
	var room = current_scene
	check(room.player != null, "room104 player spawned")
	check(room.phone_node != null and not room.phone_node.enabled, "room104 phone locked until truth")
	# 模拟三个线索
	room._clue_sticky()
	room._clue_medical()
	room._clue_dress()
	await process_frame
	check(Game.clue_count(room.CLUE_IDS) == 3, "room104 3 clues collected")
	# 模拟按键跳过对话
	for i in 60:
		_sim_interact()
		await process_frame
	check(Game.flags.has("truth_104"), "room104 truth revealed")
	check(room.phone_node.enabled, "room104 phone unlocked")

	print("=== smoke test done, failures: ", failures.size(), " ===")
	quit(1 if failures.size() > 0 else 0)

func _sim_interact() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
