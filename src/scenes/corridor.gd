extends SceneBase
## 走廊：白天暖黄（可对话王大妈）/ 夜晚冷蓝（探索入口）

var door_nodes := {}

func _ready() -> void:
	Game.hud_visible = true
	var night := Game.phase == Game.Phase.NIGHT
	if night:
		add_bg("res://assets/sprites/bg_corridor_night.png")
		add_dark(Color(0.5, 0.52, 0.68))
		Sfx.music_night()
	else:
		add_bg("res://assets/sprites/bg_corridor_day.png")
		Sfx.music_day()
	default_walls()
	spawn_player(Vector2(320, 240), {
		"from_admin": Vector2(60, 240),
		"from_104": Vector2(592, 220),
	})
	if night and player:
		player.set_flashlight(true)
	# 四扇门 + 门牌
	var doors := [[72, "101"], [202, "102"], [462, "103"], [592, "104"]]
	for d in doors:
		var plate := Game.mk_label(d[1], 10, Color(0.25, 0.18, 0.1))
		plate.position = Vector2(d[0] - 10, 60)
		plate.custom_minimum_size = Vector2(20, 0)
		plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if night:
			plate.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85))
		add_child(plate)
		door_nodes[d[1]] = add_interactable(Vector2(d[0], 170), "door_" + d[1], 26)
	# 电梯（右端，氛围物）
	add_interactable(Vector2(620, 150), "elevator", 20)
	# 回管理员室（左端）
	add_interactable(Vector2(22, 240), "to_admin", 22)
	# 王大妈（白天限定）
	if not night:
		var wang := Sprite2D.new()
		wang.texture = load("res://assets/sprites/npc_wang.png")
		wang.scale = Vector2(2, 2)
		wang.position = Vector2(382, 218)
		add_child(wang)
		add_interactable(Vector2(382, 210), "wang", 20)

func _on_used(node: Area2D) -> void:
	var evt: String = node.event_name
	if evt.begins_with("door_"):
		_on_door(evt.trim_prefix("door_"))
	elif evt == "wang":
		_on_wang()
	elif evt == "elevator":
		_on_elevator()
	elif evt == "to_admin":
		SceneFlow.goto("res://src/scenes/admin_room.tscn", "from_corridor")

func _on_door(num: String) -> void:
	var night := Game.phase == Game.Phase.NIGHT
	match num:
		"101":
			Dialog.say(["王大妈家。门缝里飘出饭菜香。"] if not night else ["101 的门后隐约有电视声。这么晚了还没睡。"])
		"102":
			Dialog.say(["102。门口堆着没拆的快递。"] if not night else ["102。门后传来塑料袋摩擦的声音。还不是时候。（214「外卖员」将在下一章开放）"])
		"103":
			Dialog.say(["103。门上贴着褪色的福字。"] if not night else ["103。门牌上蒙了一层灰，摸上去是烫的。你不明白为什么。"])
		"104":
			if not night:
				Dialog.say([
					"104。门锁着。",
					"（大白天的，门把手却冰得粘手。）",
					"（王大妈说过——晚上，这间屋子才有动静。）",
				])
			elif Game.healed.has(104):
				Dialog.say([
					"104。房间里安安静静的。",
					"她已经不哭了。",
				])
			else:
				Dialog.say([
					"104。钥匙插进去的时候，你听见了哭声。",
					"（门牌上的「4」，红得像刚写上去的。）",
				])
				await Dialog.finished
				SceneFlow.goto("res://src/scenes/room_104.tscn")

func _on_wang() -> void:
	if not Game.flags.has("wang_met"):
		Game.flags["wang_met"] = true
		Dialog.say([
			["王大妈", "哎哟，你就是新来的管理员？可算来人了。"],
			["王大妈", "大妈跟你说个事。104那个姑娘，走了以后，那屋子晚上老有哭声。"],
			["王大妈", "她叫……算了，网上都叫她「红裙子」。可怜呐，才二十六。"],
			["王大妈", "这是104的钥匙，你拿着。晚上巡查的时候，去看看她吧。"],
			"（钥匙冰得你指尖发麻。）",
		])
		Game.add_journal("王大妈给了我 104 的钥匙。她说那个叫「红裙子」的姑娘，晚上会哭。")
	else:
		Dialog.say([
			["王大妈", "晚上去看她的时候，温柔点。那姑娘，生前没被温柔对待过。"],
		])

func _on_elevator() -> void:
	if Game.phase == Game.Phase.NIGHT:
		Dialog.say([
			"电梯停在4楼。门没有开。",
			"（楼层显示屏闪了一下，跳出一个不存在的数字：4444。）",
		])
	else:
		Dialog.say(["电梯正常运行中。液晶屏上有个怎么也擦不掉的指印。"])
