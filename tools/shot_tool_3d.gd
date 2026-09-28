extends SceneTree
## 3D 世界截图工具（需要带显示运行，非 headless）：
## godot --path dead_building -s res://tools/shot_tool_3d.gd
var Game
var Dialog

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
	await create_timer(1.3).timeout   # 等开场白 0.8s 计时器触发（按真实时间）
	await _skip_until(func(): return not Dialog.active)

	# 1. 管理员室（白天，看办公桌）
	world.player.position = Vector3(0.6, world.ADMIN_Y + 0.05, 1.2)
	world.player.set_look(0.35, -0.08)
	await _settle()
	_shot("3d_admin_day")

	# 2. 走廊（白天，从西端看东侧）
	world._spawn_at("corridor_from_admin")
	world.player.set_look(-PI/2 + 0.15, 0.0)
	await _settle()
	_shot("3d_corridor_day")

	# 2b. 王大妈特写（白天，面对面）
	world.player.position = Vector3(0.5, world.CORRIDOR_Y + 0.05, -0.7)
	world.player.set_look(PI, -0.12)
	await _settle(40)
	_shot("3d_wang_closeup")

	# 3. 走廊（夜晚 + 手电）
	world._spawn_at("corridor_from_admin")
	world.player.set_look(-PI/2 + 0.15, 0.0)
	Game.set_phase(Game.Phase.NIGHT)
	world._apply_phase_lighting(false)
	world.player.set_flashlight(true)
	await _settle(40)
	_shot("3d_corridor_night")

	# 4. 104 红房（夜晚，门口视角看便利贴墙）
	world._spawn_at("r104_door")
	world.player.set_look(0.42, 0.0)
	await _settle()
	_shot("3d_room104_red")

	# 5. 镜子里的她
	world._on_mirror()
	await _skip_until(func(): return not Dialog.active)
	world.player.position = Vector3(0.2, world.R104_Y + 0.05, 0.6)
	world.player.set_look(-1.0, 0.05)
	await _settle()
	_shot("3d_room104_mirror")

	# 6. 治愈后（白房 + 鞠躬）
	world._on_phone_draft()
	await _skip_until(func(): return root.get_node("RitualUI")._open)
	root.get_node("RitualUI").chosen.emit(0)
	await _skip_until(func(): return Game.relics.size() == 1 and not Dialog.active)
	world.player.position = Vector3(0.3, world.R104_Y + 0.05, 2.2)
	world.player.set_look(0.1, 0.05)
	await _settle(50)
	_shot("3d_room104_healed")

	print("=== 3d shots done ===")
	quit(0)

func _settle(frames := 25) -> void:
	for i in frames:
		await process_frame

func _shot(name: String) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png("user://shot_%s.png" % name)
	print("saved shot_", name)

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
