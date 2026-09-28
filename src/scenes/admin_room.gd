extends SceneBase
## 管理员室：每天的开始与结束。电话、办公桌（日志/等到黄昏）、出门

func _ready() -> void:
	Game.hud_visible = true
	if Game.phase == Game.Phase.NIGHT:
		Sfx.music_night()
	else:
		Sfx.music_day()
	Sfx.heartbeat(false)
	add_bg("res://assets/sprites/bg_admin_room.png")
	default_walls()
	spawn_player(Vector2(320, 260), {"from_corridor": Vector2(596, 250)})
	# 日历显示天数
	var cal := Game.mk_label("第%d天" % Game.day, 11, Color(0.5, 0.12, 0.1))
	cal.add_theme_font_override("font", Game.font_bold)
	cal.position = Vector2(384, 82)
	cal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cal.custom_minimum_size = Vector2(42, 0)
	add_child(cal)
	add_interactable(Vector2(229, 180), "phone", 20)      # 电话
	add_interactable(Vector2(165, 208), "desk", 24)       # 办公桌
	add_interactable(Vector2(610, 210), "exit", 22)       # 出门
	# 第一天开场
	if Game.day == 1 and not Game.flags.has("intro_done"):
		Game.flags["intro_done"] = true
		await get_tree().create_timer(0.8).timeout
		Dialog.say([
			"（你捏着那封没有署名的邀请函，站在管理员室里。）",
			"“诚邀您担任幸福苑公寓临时管理员。任期7天。期满后可继承本楼产权。”",
			"（失业第三个月。这种好事，怎么看都像骗局。）",
			"（但押金已经交了。七天，忍忍就过去了。）",
			"（WASD/方向键 移动 · E 互动 · Tab 日志 · F 手电 · Esc 菜单）",
		])

func _on_used(node: Area2D) -> void:
	match node.event_name:
		"phone": _on_phone()
		"desk": _on_desk()
		"exit": _on_exit()

func _on_phone() -> void:
	match Game.day:
		1:
			if not Game.flags.has("phone1"):
				Game.flags["phone1"] = true
				Dialog.say([
					["房东（电话）", "喂？新管理员吧。记住，就七天。每天早上我会打电话问进度。"],
					["房东（电话）", "对了，教你个规矩——看房号。带4的房间，少进。"],
					["房东（电话）", "4越多，里面越……不干净。一个4是伤心事，两个4是人命，三个4……"],
					["房东（电话）", "……算了。104那间，晚上要是听见什么，别多想。老楼，隔音差。"],
					"（他笑得不太自然。你看了眼手里的钥匙串。）",
				])
				Game.add_journal("房东的规矩：看房号。4越多，住户执念越深。104 有一个 4。")
			else:
				Dialog.say(["电话那头只剩忙音。"])
		2:
			Dialog.say([
				["房东（电话）", "第二天了。干得不错……我是说，楼挺安静的，对吧？"],
				"（104 的门牌，好像没那么冷了。）",
				"（214 室的门缝里，飘出一股外卖的味道。——214「外卖员」将在下一章开放）",
			])
		_:
			Dialog.say([
				["房东（电话）", "第 %d 天了。继续。" % Game.day],
				"（更多楼层与住户将在后续章节开放。）",
			])

func _on_desk() -> void:
	var opts := ["翻开管理员日志", "等到黄昏，开始夜巡", "先不忙"]
	if Game.phase == Game.Phase.NIGHT:
		opts = ["翻开管理员日志", "出门夜巡", "先不忙"]
	var idx: int = await RitualUI.ask("办公桌。台灯的暖光下摊着日志本。", opts)
	match idx:
		0:
			JournalUI.open()
		1:
			if Game.phase != Game.Phase.NIGHT:
				Game.set_phase(Game.Phase.NIGHT)
				Sfx.music_night()
				Dialog.say([
					"（你睡到黄昏。醒来时，走廊的灯变成了冷蓝色。）",
					"（楼里的声音变了。好像有哪里，有人在哭。）",
				])
				await Dialog.finished
			SceneFlow.goto("res://src/scenes/corridor.tscn")
		_:
			pass

func _on_exit() -> void:
	SceneFlow.goto("res://src/scenes/corridor.tscn", "from_admin")
