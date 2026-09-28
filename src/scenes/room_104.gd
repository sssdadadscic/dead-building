extends SceneBase
## 104房间「红裙子」：Day1 完整流程
## 探索(3线索) → 真相还原 → 愿望仪式(短信草稿) → 治愈演出 → 遗物

const CLUE_IDS := ["sticky", "medical", "dress"]
const RITUAL_OPTIONS := [
	"你尽力了，这不是你的错。",
	"那些人太过分了，别理他们。",
	"你应该坚强一点，都会过去的。",
]

var done := false
var bg_white: Sprite2D
var frost: Sprite2D
var dark: CanvasModulate
var mirror_ghost: AnimatedSprite2D
var ghost_center: AnimatedSprite2D
var phone_node: Area2D
var anomaly_timer: Timer
var comment_idx := 0
const COMMENTS := ["“怎么还不死”", "“博同情吧”", "“装的吧，举报了”", "“戏真多”", "“又想骗捐款？”"]

func _ready() -> void:
	Game.hud_visible = true
	done = Game.flags.has("room104_done")
	Sfx.music_night()
	# 背景
	add_bg("res://assets/sprites/bg_room104_red.png")
	bg_white = Sprite2D.new()
	bg_white.texture = load("res://assets/sprites/bg_room104_white.png")
	bg_white.centered = false
	bg_white.z_index = -9
	bg_white.modulate.a = 0.0
	add_child(bg_white)
	default_walls()
	spawn_player(Vector2(560, 250))
	# 黑暗 + 手电
	if done:
		add_dark(Color(0.85, 0.83, 0.8))
		bg_white.modulate.a = 1.0
	else:
		add_dark(Color(0.36, 0.32, 0.36))
		dark = get_children().filter(func(n): return n is CanvasModulate)[0]
		if player:
			player.set_flashlight(true)
		Sfx.heartbeat(true)
		# 寒霜边框
		frost = Sprite2D.new()
		frost.texture = load("res://assets/sprites/fx_frost.png")
		frost.centered = false
		frost.z_index = 5
		add_child(frost)
	# 镜子里的她
	mirror_ghost = _make_ghost(Vector2(469, 190), 2.0)
	mirror_ghost.modulate = Color(0.8, 0.9, 1.0, 0.85)
	mirror_ghost.hide()
	# 房间中央的她（治愈演出用）
	ghost_center = _make_ghost(Vector2(320, 215), 2.5)
	ghost_center.hide()
	# 互动物
	add_interactable(Vector2(210, 110), "sticky", 30)     # 墙上便利贴
	add_interactable(Vector2(265, 180), "medical", 20)    # 床头柜病历
	add_interactable(Vector2(380, 145), "dress", 26)      # 衣柜红裙
	add_interactable(Vector2(264, 168), "radio", 16)      # 收音机
	add_interactable(Vector2(469, 165), "mirror", 20)     # 镜子
	phone_node = add_interactable(Vector2(140, 168), "phone", 20)  # 床上的手机
	phone_node.set_enabled(false)
	add_interactable(Vector2(594, 195), "leave", 22)      # 门
	# 随机异常事件
	anomaly_timer = Timer.new()
	anomaly_timer.one_shot = true
	anomaly_timer.timeout.connect(_on_anomaly)
	add_child(anomaly_timer)
	if done:
		pass
	else:
		_start_anomaly()
		if not Game.flags.has("room104_entered"):
			Game.flags["room104_entered"] = true
			await get_tree().create_timer(0.6).timeout
			Dialog.say([
				"（推开门的一瞬间，你屏住了呼吸。）",
				"（整个房间是红色的。墙、床单、窗帘——像被血泡过。）",
				"（温度很低。你呼出的气，结成了白雾。）",
				"（哭声停了。她在等你开口。）",
			])

func _make_ghost(pos: Vector2, sc: float) -> AnimatedSprite2D:
	var tex: Texture2D = load("res://assets/sprites/ghost_104.png")
	var sf := SpriteFrames.new()
	sf.add_animation("g")
	sf.set_animation_loop("g", false)
	for f in 3:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(f * 24, 0, 24, 36)
		sf.add_frame("g", at)
	var g := AnimatedSprite2D.new()
	g.sprite_frames = sf
	g.animation = "g"
	g.scale = Vector2(sc, sc)
	g.position = pos
	add_child(g)
	return g

func _start_anomaly() -> void:
	anomaly_timer.wait_time = randf_range(14.0, 26.0)
	anomaly_timer.start()

func _on_anomaly() -> void:
	if done: return
	Sfx.play("static")
	var c := Game.mk_label(COMMENTS[randi() % COMMENTS.size()], 13, Color(0.85, 0.3, 0.3, 0.9))
	c.position = Vector2(randf_range(80, 480), randf_range(90, 220))
	add_child(c)
	var t := create_tween().set_parallel(true)
	t.tween_property(c, "position:y", c.position.y - 36, 2.6)
	t.tween_property(c, "modulate:a", 0.0, 2.6)
	t.chain().tween_callback(c.queue_free)
	_start_anomaly()

func _on_used(node: Area2D) -> void:
	if Dialog.active: return
	match node.event_name:
		"sticky": _clue_sticky()
		"medical": _clue_medical()
		"dress": _clue_dress()
		"radio": _on_radio()
		"mirror": _on_mirror()
		"phone": _on_phone_draft()
		"leave": _on_leave()

# ---------- 线索 ----------
func _clue_sticky() -> void:
	if Game.clues.has("sticky"):
		Dialog.say(["那些字钉在墙上，也钉在她身上。"])
		return
	Sfx.play("paper")
	Dialog.say([
		"（墙上贴满了打印出来的截图，一层盖一层，像鱼鳞。）",
		"“你怎么还不死”　“博同情也要有底线”　“装病博流量，举报了”",
		"（每一条下面，都有同一个ID在回复：）",
		"“我只是想记录下来……对不起。”",
	])
	Game.add_clue("sticky", "满墙的恶意评论", "她分享抗癌日记，被骂“装病博流量”。她一直在道歉。")
	_check_truth()

func _clue_medical() -> void:
	if Game.clues.has("medical"):
		Dialog.say(["确诊日期：2024年3月。她一个人拿到这张纸。"])
		return
	Sfx.play("paper")
	Dialog.say([
		"（床头柜上压着一张病历。）",
		"晚期淋巴癌。确诊日期：2024年3月。",
		"（病历背面有一行小字：）",
		"“治疗费还差很多，但我不想麻烦任何人。”",
	])
	Game.add_clue("medical", "晚期病历", "2024年3月确诊晚期淋巴癌。她谁也没告诉。")
	_check_truth()

func _clue_dress() -> void:
	if Game.clues.has("dress"):
		Dialog.say(["裙子很干净。除了裙摆。"])
		return
	Sfx.play("paper")
	Dialog.say([
		"（衣柜里只有一件衣服。一条红裙子。）",
		"（裙摆上有大片的褐色污渍。你知道那是什么。）",
		"（内衬里绣着一行字，针脚很抖：）",
		"“如果我够好，是不是就不会这样。”",
	])
	Game.add_clue("dress", "衣柜里的红裙子", "她穿着它走的。内衬绣着“如果我够好，是不是就不会这样”。")
	_check_truth()

func _check_truth() -> void:
	if Game.clue_count(CLUE_IDS) == 3 and not Game.flags.has("truth_104"):
		Game.flags["truth_104"] = true
		await Dialog.finished
		Sfx.play("static")
		Dialog.say_center([
			"你全都明白了。",
			"她确诊之后，在网络上记录自己的抗癌日记。",
			"他们说她“装病博流量”。",
			"她最后一条动态是：“如果我死了，你们会道歉吗。”",
			"第二天，她穿着那条红裙子，死在了浴室里。",
			"她不是想红。她只是不想一个人死。",
		])
		await Dialog.finished
		Game.add_journal("【真相·104】网络暴力 + 绝症。她至死都在道歉，可错的不是她。")
		phone_node.set_enabled(true)
		Dialog.say(["（床上的手机忽然亮了。草稿箱里，躺着一条没发出去的短信。）"])

# ---------- 氛围事件 ----------
func _on_radio() -> void:
	Sfx.play("static")
	comment_idx = (comment_idx + 1) % COMMENTS.size()
	Dialog.say([
		"（收音机自己转了起来。杂音里，一个机械的声音在念：）",
		COMMENTS[comment_idx] + "　" + COMMENTS[(comment_idx + 2) % COMMENTS.size()],
		"（你把它关掉了。手指在抖。）",
	])

func _on_mirror() -> void:
	if done:
		Dialog.say(["镜子里只有你自己。和她留下的一点点暖意。"])
		return
	if not Game.flags.has("mirror_104"):
		Game.flags["mirror_104"] = true
		mirror_ghost.frame = 0
		mirror_ghost.show()
		Dialog.say(["（镜子里站着她。红裙子，长头发，背对着你。）"])
		await Dialog.finished
		mirror_ghost.frame = 1   # 突然转头微笑
		Sfx.play("static")
		Dialog.say([
			"（你刚要退后——她忽然转过头。）",
			"（她在微笑。）",
			["？？？", "你也觉得，是我的错吗？"],
		])
	else:
		Dialog.say([
			"（她还在镜子里看着你，等着你的答案。）",
		])

# ---------- 愿望仪式 ----------
func _on_phone_draft() -> void:
	if done: return
	Sfx.play("paper")
	Dialog.say([
		"（草稿箱里只有一条短信，收件人是她自己。）",
		"“对不起，让大家失望了。我……”",
		"（后面是空白。她直到最后，都不知道该怎么说完这句话。）",
		"（你替她写下去。）",
	])
	await Dialog.finished
	var idx: int = await RitualUI.ask("补上那句话——", RITUAL_OPTIONS)
	match idx:
		0:
			_complete()
		1:
			Sfx.play("static")
			Dialog.say(["（手机屏幕闪了一下，暗下去。）", "（这句话太轻了，托不住她的一生。）"])
			Game.drain_battery(8.0)
		2:
			Sfx.play("static")
			Dialog.say(["（屏幕黑了。）", "（道理她都懂。她不需要别人再说教。）"])
			Game.drain_battery(8.0)
		_:
			pass

func _complete() -> void:
	done = true
	Game.flags["room104_done"] = true
	anomaly_timer.stop()
	Sfx.heartbeat(false)
	Sfx.play("chime")
	Dialog.say_center([
		"短信发出去了。",
		"没有人收到。但全世界都该收到。",
	])
	await Dialog.finished
	# 红色退潮
	var t := create_tween().set_parallel(true)
	t.tween_property(bg_white, "modulate:a", 1.0, 2.8)
	if frost: t.tween_property(frost, "modulate:a", 0.0, 2.8)
	if dark: t.tween_property(dark, "color", Color(0.85, 0.83, 0.8), 2.8)
	await t.finished
	# 她换上白睡衣，鞠躬
	mirror_ghost.frame = 2
	mirror_ghost.modulate = Color(1, 1, 1, 1)
	ghost_center.frame = 2
	ghost_center.show()
	Dialog.say([
		"（红色开始褪去，像退潮一样。）",
		"（她站在房间中央，换上了白色的睡衣。）",
		"（她对着你，深深地、深深地鞠了一躬。）",
		["红裙子", "谢谢你。我终于可以换件衣服了。"],
	])
	await Dialog.finished
	Sfx.play("paper")
	Dialog.say([
		"（床头柜上多了一张字条：）",
		"“谢谢你听我说话。这枚纽扣给你——它是我裙子上，唯一没被染红的东西。”",
	])
	Game.add_relic("红裙子的纽扣", "一枚红色塑料纽扣。104的谢意。据说它能在关键时刻帮到你。")
	Game.healed.append(104)
	await Dialog.finished
	Dialog.say(["（门外的走廊，似乎没有那么冷了。该回去了。）"])

# ---------- 离开 ----------
func _on_leave() -> void:
	if done:
		Sfx.play("door")
		Dialog.say(["（你在管理员室的沙发上沉沉睡去。这一夜，楼里很安静。）"])
		await Dialog.finished
		Game.next_morning()
		Game.save_game(-1, "res://src/scenes/admin_room.tscn")
		SceneFlow.goto("res://src/scenes/admin_room.tscn")
	else:
		var idx: int = await RitualUI.ask("现在离开？今晚的探索会中断，线索会保留。", ["离开104", "再待一会儿"])
		if idx == 0:
			Sfx.heartbeat(false)
			SceneFlow.goto("res://src/scenes/corridor.tscn", "from_104")
