extends Node
## 《死楼》扩展内容：2-4 楼走廊 / 214·334·404·444·4444 房间 / 逐日崩坏 / 彩蛋 / 蝴蝶决战 / 结局
## 由 world_3d.gd 实例化，W 指向世界脚本以复用其搭建工具。

var W  # world_3d

const F2_Y := 80.0
const F3_Y := 160.0
const F4_Y := 240.0
const R214_Y := -80.0
const R334_Y := -120.0
const R404_Y := -160.0
const R444_Y := -200.0
const R4444_Y := -240.0

## 天数 → 当夜目标房间
const ROOM_OF_DAY := {2: "214", 3: "334", 4: "404", 5: "444"}
## 房号含 4 数（决定手电消耗与氛围）
const FOURS := {"214": 1, "334": 1, "404": 2, "444": 3, "4444": 4}

# 运行时引用
var ghosts := {}          # room -> Node3D 鬼魂
var ghost_faces := {}     # room -> 脸贴片
var room_lights_x := {}   # room -> [OmniLight3D]
var fade_mats := {}       # room -> [要淡出的 MeshInstance3D]
var ritual_nodes := {}    # room -> 仪式交互点（集齐线索后解锁）
var butterflies := []     # 4444 蝴蝶群
var _bf_t := 0.0
var prev_ghost: Node3D    # 404 前管理员（模仿者）
var _mimic_delay := 0.0
var day7_steps := 0       # Day7 调查进度

const CLUES := {
	"214": ["c214_receipts", "c214_phone", "c214_peephole"],
	"334": ["c334_ledger", "c334_debt", "c334_photo"],
	"404": ["c404_bed", "c404_log", "c404_window"],
	"444": ["c444_mirror", "c444_talisman", "c444_photo"],
}

const EGG_TOTAL := 2

func setup(world) -> void:
	W = world

func build_all() -> void:
	_build_floor2()
	_build_floor3()
	_build_floor4()
	_build_room214()
	_build_room334()
	_build_room404()
	_build_room444()
	_build_room4444()
	_build_eggs()
	apply_admin_evolution()
	_apply_wang_visibility()

func _apply_wang_visibility() -> void:
	# Day4 起活人 NPC 全部消失
	if W.wang:
		W.wang.visible = Game.day < 4

# ================= 多层走廊 =================
## 与 1 楼同款 24×3 走廊，双数楼层（2/4）声控灯不亮（原著设定）
func _floor_shell(y: float, plates: Array, lit: bool, tint: Color, floor_tint: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Floor%d" % int(y)
	W.add_child(root)
	var c := Vector3(0, y, 0)
	W._room_shell(root, c, 24.0, 3.0, 3.0, tint, floor_tint,
		[{"wall":"n","at":-8.0,"w":1.1},{"wall":"n","at":-2.7,"w":1.1},
		 {"wall":"n","at":2.7,"w":1.1},{"wall":"n","at":8.0,"w":1.1},
		 {"wall":"w","at":0.0,"w":1.1}])
	for i in plates.size():
		W._door_prop(root, c + Vector3(-8.5 + i * 5.3, 0, -1.5), "+z", plates[i])
	W._door_prop(root, c + Vector3(-12.0, 0, 0.5), "+x", "")
	if lit:
		for lx in [-8.0, 0.0, 8.0]:
			W._lamp(root, c + Vector3(lx, 2.82, 0), true)
	else:
		# 双数楼层：只有一盏接触不良的灯
		var li = W._lamp(root, c + Vector3(0.0, 2.82, 0), false)
		li.light_energy = 0.35
	# 电梯（东端，外观一致）
	W._box(root, Vector3(0.2, 2.6, 1.6), c + Vector3(11.9, 1.3, 0), W._mat("", Color(0.3,0.32,0.36)))
	W._box(root, Vector3(0.06, 2.2, 0.75), c + Vector3(11.8, 1.1, -0.38), W._mat("", Color(0.55,0.58,0.62), Vector3(1,1,1), 0.4))
	W._box(root, Vector3(0.06, 2.2, 0.75), c + Vector3(11.8, 1.1, 0.38), W._mat("", Color(0.55,0.58,0.62), Vector3(1,1,1), 0.4))
	W._emissive_panel(root, 0.5, 0.2, c + Vector3(11.78, 2.5, 0), "-x", Color(0.9, 0.3, 0.25), 2.0)
	# 楼梯间（西端角落）：灭火器箱 + 上/下楼梯交互
	W._box(root, Vector3(0.7, 1.1, 0.3), c + Vector3(-11.5, 0.55, -1.3), W._mat("", Color(0.5,0.16,0.14)))
	W._interact(root, c + Vector3(-11.3, 1.2, 1.0), "stairs", "楼梯间", Vector3(1.2, 2.0, 1.0))
	W._interact(root, c + Vector3(11.5, 1.3, 0), "elevator_x", "电梯", Vector3(0.8, 2.4, 1.4))
	return root

func _build_floor2() -> void:
	var root := _floor_shell(F2_Y, ["plate_211", "plate_212", "plate_213", "plate_214"], false,
		Color(0.88, 0.78, 0.62), Color(0.68, 0.55, 0.4))
	var c := Vector3(0, F2_Y, 0)
	# 鞋柜 / 奶箱 / 外卖袋 / 管道
	W._box(root, Vector3(1.0, 0.9, 0.35), c + Vector3(-7.0, 0.45, 1.25), W._mat("", Color(0.55,0.42,0.3)))
	W._box(root, Vector3(0.5, 0.4, 0.3), c + Vector3(-6.9, 1.1, 1.28), W._mat("", Color(0.85,0.83,0.78)), false)
	W._box(root, Vector3(0.4, 0.5, 0.3), c + Vector3(1.0, 0.25, -1.2), W._mat("", Color(0.85,0.7,0.2)))
	W._cyl(root, 0.06, 0.06, 3.0, c + Vector3(4.6, 1.5, 1.38), W._mat("", Color(0.45,0.47,0.5)))
	# 小李（2 楼活人，Day2-3 在）
	_build_xiaoli(root, c + Vector3(-1.5, 0, 0.9))
	# 交互
	W._interact(root, c + Vector3(-8.0, 1.2, -1.2), "door_211", "211", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(-2.7, 1.2, -1.2), "door_212", "212", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(2.7, 1.2, -1.2), "door_213", "213", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(8.0, 1.2, -1.2), "door_214", "214 · 外卖员", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(-7.0, 0.6, 1.1), "shoerack", "鞋柜", Vector3(1.0, 1.0, 0.6))
	W._interact(root, c + Vector3(1.0, 0.5, -1.1), "takeout_bag", "门口的外卖袋", Vector3(0.6, 0.7, 0.5))
	W._interact(root, c + Vector3(-1.5, 1.0, 0.9), "xiaoli", "小李", Vector3(0.9, 1.6, 0.9))
	W._interact(root, c + Vector3(4.6, 1.5, 1.2), "pipe_f2", "暖气管", Vector3(0.5, 2.2, 0.4))

func _build_xiaoli(parent: Node3D, pos: Vector3) -> void:
	var li := Node3D.new()
	li.name = "XiaoLi"
	li.position = pos
	parent.add_child(li)
	W._cyl(li, 0.2, 0.26, 1.05, Vector3(0, 0.52, 0), W._mat("", Color(0.35, 0.45, 0.55)))
	W._sphere(li, 0.19, Vector3(0, 1.28, 0), W._mat("", Color(0.9, 0.75, 0.62)))
	W._sphere(li, 0.2, Vector3(0, 1.36, -0.04), W._mat("", Color(0.15, 0.13, 0.12)))
	li.rotation.y = PI

func _build_floor3() -> void:
	var root := _floor_shell(F3_Y, ["plate_331", "plate_332", "plate_333", "plate_334"], true,
		Color(0.85, 0.75, 0.58), Color(0.62, 0.5, 0.38))
	var c := Vector3(0, F3_Y, 0)
	# 小广告墙（彩蛋传单在这）/ 枯盆栽 / 旧沙发 / 堆叠的纸箱
	W._box(root, Vector3(2.2, 1.2, 0.06), c + Vector3(-0.5, 1.7, 1.42), W._mat("", Color(0.75,0.72,0.66)), false)
	for i in 5:
		W._box(root, Vector3(0.32, 0.42, 0.02), c + Vector3(-1.3 + i * 0.42, 1.7 + (i % 2) * 0.15, 1.39), W._mat("", [Color(0.9,0.88,0.8), Color(0.85,0.8,0.7), Color(0.92,0.85,0.75), Color(0.8,0.82,0.75), Color(0.88,0.86,0.78)][i]), false)
	W._cyl(root, 0.22, 0.16, 0.3, c + Vector3(5.5, 0.15, 1.2), W._mat("", Color(0.6,0.35,0.25)))
	W._cyl(root, 0.02, 0.01, 0.5, c + Vector3(5.5, 0.55, 1.2), W._mat("", Color(0.35,0.3,0.2)))
	W._box(root, Vector3(1.4, 0.5, 0.6), c + Vector3(-4.5, 0.25, 1.1), W._mat("", Color(0.45,0.38,0.3)))
	for i in 3:
		W._box(root, Vector3(0.45, 0.35, 0.4), c + Vector3(9.8, 0.18 + i * 0.36, 1.1), W._mat("", Color(0.6 + i * 0.03, 0.48, 0.32)))
	# 交互
	W._interact(root, c + Vector3(-8.0, 1.2, -1.2), "door_331", "331", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(-2.7, 1.2, -1.2), "door_332", "332", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(2.7, 1.2, -1.2), "door_333", "333", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(8.0, 1.2, -1.2), "door_334", "334 · 商人", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(-0.5, 1.7, 1.3), "adwall", "小广告墙", Vector3(2.2, 1.2, 0.4))
	W._interact(root, c + Vector3(5.5, 0.5, 1.15), "plant_f3", "枯死的盆栽", Vector3(0.5, 0.9, 0.5))
	W._interact(root, c + Vector3(-4.5, 0.4, 1.0), "sofa_f3", "被扔掉的沙发", Vector3(1.4, 0.7, 0.8))
	W._interact(root, c + Vector3(9.8, 0.6, 1.0), "boxes_f3", "纸箱堆", Vector3(0.6, 1.2, 0.6))

func _build_floor4() -> void:
	var root := _floor_shell(F4_Y, ["plate_441", "plate_442", "plate_443", "plate_444"], false,
		Color(0.62, 0.58, 0.52), Color(0.42, 0.38, 0.34))
	var c := Vector3(0, F4_Y, 0)
	# 每户门口的火盆（原著四楼细节）+ 符咒 + 寻人启事 + 涂鸦
	for dx in [-8.0, -2.7, 2.7, 8.0]:
		W._cyl(root, 0.25, 0.2, 0.18, c + Vector3(dx - 0.7, 0.09, -1.1), W._mat("", Color(0.3,0.28,0.26)))
		W._box(root, Vector3(0.2, 0.03, 0.15), c + Vector3(dx - 0.7, 0.19, -1.1), W._mat("", Color(0.25,0.22,0.2)), false)
	W._decal(root, 2.0, 1.4, c + Vector3(0.0, 1.8, -1.42), "+z", "graffiti4")
	W._decal(root, 0.35, 0.95, c + Vector3(-4.2, 1.6, -1.43), "+z", "talisman")
	W._decal(root, 0.35, 0.95, c + Vector3(4.2, 1.6, -1.43), "+z", "talisman")
	W._decal(root, 0.5, 0.66, c + Vector3(-6.5, 1.7, 1.42), "-z", "poster_missing")
	W._decal(root, 0.5, 0.66, c + Vector3(6.0, 1.7, 1.42), "-z", "poster_missing")
	# 交互
	W._interact(root, c + Vector3(-8.0, 1.2, -1.2), "door_441", "441", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(-2.7, 1.2, -1.2), "door_442", "442", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(2.7, 1.2, -1.2), "door_443", "443", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(8.0, 1.2, -1.2), "door_444", "444 · 无头门神", Vector3(1.1, 2.0, 0.6))
	W._interact(root, c + Vector3(0.0, 1.8, -1.3), "graffiti_f4", "满墙的涂鸦", Vector3(2.0, 1.4, 0.4))
	W._interact(root, c + Vector3(-6.5, 1.7, 1.3), "poster_f4", "寻人启事", Vector3(0.6, 0.8, 0.4))
	W._interact(root, c + Vector3(-8.7, 0.3, -1.1), "brazier", "门口的火盆", Vector3(0.6, 0.5, 0.6))

# ================= 楼梯 / 电梯 =================
func _on_stairs() -> void:
	var opts := ["1 楼（大厅·管理员室）"]
	var floors := [0.0]
	if Game.day >= 2: opts.append("2 楼"); floors.append(F2_Y)
	if Game.day >= 3: opts.append("3 楼"); floors.append(F3_Y)
	if Game.day >= 4: opts.append("4 楼"); floors.append(F4_Y)
	opts.append("算了"); floors.append(-1.0)
	var idx: int = await RitualUI.ask("楼梯间。声控灯忽明忽暗。去哪一层？", opts)
	if idx < 0 or floors[idx] < 0: return
	_goto_floor(floors[idx])

func _goto_floor(y: float) -> void:
	Game.lock_ui("teleport")
	Sfx.play("door")
	await SceneFlow.fade_out(0.35)
	W.player.position = Vector3(-10.8, y + 0.05, 0.5)
	W.player.set_look(PI/2)
	await SceneFlow.fade_in(0.45)
	Game.unlock_ui("teleport")

func _on_elevator_x() -> void:
	if Game.phase == Game.Phase.NIGHT and Game.day >= 6 and not Game.healed.has(4444):
		var idx: int = await RitualUI.ask("电梯停在 4 楼。铁栅栏门后，黑得像墨。\n（显示屏上是一个不存在的数字：4444）",
			["扒开铁栅栏，进去", "后退"])
		if idx == 0:
			_enter_4444("elevator")
		return
	if Game.phase == Game.Phase.NIGHT:
		Dialog.say([
			"电梯停在4楼。门没有开。",
			"（楼层显示屏闪了一下，跳出一个不存在的数字：4444。）",
		])
	else:
		Dialog.say(["电梯面板上，4 楼的按钮被人用胶带封住了。", "（胶带下面，按钮自己在闪。）"])

# ================= 房间门（通用入口规则） =================
func _target_room() -> String:
	return ROOM_OF_DAY.get(Game.day, "")

func _room_door(room: String, plate: String) -> void:
	if Game.healed.has(int(room)):
		Dialog.say(["%s。房间里安安静静的。" % room, "（执念已散。这里只剩下一间普通的旧屋子。）"])
		return
	if Game.phase != Game.Phase.NIGHT:
		Dialog.say(["%s。门锁着。" % room, "（大白天的，门把手冰得粘手。）", "（晚上再来。）"])
		return
	if room != _target_room():
		Dialog.say(["%s。你拧了拧门把手，纹丝不动。" % room, "（门牌上的「4」暗着。今晚不属于这间屋子。）"])
		return
	Dialog.say(["%s。钥匙插进去的那一刻，楼里的声音全都停了。" % room,
		"（门牌上的「4」，红得像刚写上去的。）"])
	await Dialog.finished
	match room:
		"214": _enter_room("214", Vector3(0.0, R214_Y + 0.05, 2.0), 0.0)
		"334": _enter_room("334", Vector3(0.0, R334_Y + 0.05, 2.2), 0.0)
		"404": _enter_room("404", Vector3(0.0, R404_Y + 0.05, 2.4), 0.0)
		"444": _enter_room("444", Vector3(0.0, R444_Y + 0.05, 1.6), 0.0)

func _enter_room(room: String, spawn: Vector3, look: float) -> void:
	Game.lock_ui("teleport")
	Sfx.play("door")
	Game.drain_battery(4.0 * FOURS.get(room, 1))   # 4 越多耗电越快
	await SceneFlow.fade_out(0.3)
	W.player.position = spawn
	W.player.set_look(look)
	await SceneFlow.fade_in(0.45)
	Game.unlock_ui("teleport")
	Sfx.heartbeat(true)

# ================= 通用治愈收尾 =================
func _heal_common(room: String, relic_name: String, relic_desc: String, leave_evt: String) -> void:
	Game.flags["room%s_done" % room] = true
	Sfx.heartbeat(false)
	Sfx.play("chime")
	var t = W.create_tween().set_parallel(true)
	for li in room_lights_x.get(room, []):
		t.tween_property(li, "light_color", Color(1.0, 0.95, 0.85), 2.5)
	for m in fade_mats.get(room, []):
		if is_instance_valid(m):
			t.tween_property(m, "transparency", 1.0, 2.5)

func _leave_room(room: String, spawn_back: Vector3, look: float) -> void:
	var roomn := int(room) if room != "4444" else 4444
	if Game.healed.has(roomn):
		_sleep_to_morning()
	else:
		var idx: int = await RitualUI.ask("现在离开？今晚的探索会中断，线索会保留。", ["离开 %s" % room, "再待一会儿"])
		if idx == 0:
			Sfx.heartbeat(false)
			Game.lock_ui("teleport")
			Sfx.play("door")
			await SceneFlow.fade_out(0.3)
			W.player.position = spawn_back
			W.player.set_look(look)
			await SceneFlow.fade_in(0.45)
			Game.unlock_ui("teleport")

func _sleep_to_morning() -> void:
	Sfx.play("door")
	Dialog.say(["（你在管理员室的沙发上沉沉睡去。这一夜，楼里很安静。）"])
	await Dialog.finished
	Game.next_morning()
	Game.save_game(-1, "res://src/scenes/world_3d.tscn")
	Game.lock_ui("teleport")
	await SceneFlow.fade_out(0.5)
	W._apply_phase_lighting(false)
	W.player.position = Vector3(2.2, W.ADMIN_Y + 0.05, 0.5)
	W.player.set_look(PI/2)
	if W.player: W.player.set_flashlight(false)
	Sfx.music_day()
	_apply_wang_visibility()
	apply_admin_evolution()
	await SceneFlow.fade_in(0.6)
	Game.unlock_ui("teleport")
	morning_intro()

## 每天清晨的一句提示（氛围+引导）
func morning_intro() -> void:
	var key := "morning_%d" % Game.day
	if Game.flags.has(key): return
	Game.flags[key] = true
	await W.get_tree().create_timer(0.8).timeout
	match Game.day:
		2:
			Dialog.say([
				"（第二天早晨。枕头上的蓝色头发，变多了。）",
				"（电脑自己亮着——一封没有发件人的邮件：「谢谢你帮了小满。——王大妈」）",
				"（可你从没告诉过她。）",
				"（楼梯间的声控灯修好了。2 楼可以去了。）",
			])
		3:
			Dialog.say([
				"（第三天早晨。墙上的挂钟，从 3:33 走到了 3:34。）",
				"（它在走。它在数。）",
				"（3 楼的门，今天可以进了。）",
			])
		4:
			Dialog.say([
				"（第四天早晨。王大妈不见了。小李也不见了。）",
				"（管理员室的墙上，多了一些不是你自己写上去的东西。）",
				"（4 楼。今天该去 4 楼了。）",
			])
		5:
			Dialog.say([
				"（第五天早晨。电梯里的铁栅栏门，开了。）",
				"（4 楼走廊是倒过来的。至少，看起来是。）",
			])
		6:
			Dialog.say([
				"（第六天早晨。整栋楼安静得像一口井。）",
				"（桌上压着一张字条，是房东的笔迹：「最后一天了。你准备好了吗？」）",
				"（今夜。4444。）",
			])
		7:
			Dialog.say([
				"（第七天早晨。）",
				"（你睡了很久，久到不像只过了一夜。）",
				"（房间里有些东西，想让你看一看。）",
			])

# ================= 角色搭建（王大妈同款：体量+贴图脸） =================
func _mk_figure(parent: Node3D, pos: Vector3, body_tex: String, body_col: Color, face_tex: String,
		body_r := 0.26, body_h := 1.05, skin := Color(0.92, 0.78, 0.66), hair := Color(0.15, 0.13, 0.12)) -> Dictionary:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)
	W._cyl(g, body_r, body_r + 0.06, body_h, Vector3(0, body_h / 2, 0), W._mat("", body_col))
	var bp := MeshInstance3D.new()
	var bpm := PlaneMesh.new()
	bpm.size = Vector2(body_r * 2.6, body_h * 1.4)
	bp.mesh = bpm
	bp.position = Vector3(0, body_h * 0.55, body_r + 0.03)
	bp.rotation.x = PI / 2
	var bm := StandardMaterial3D.new()
	bm.albedo_texture = W._tex(body_tex)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.roughness = 0.9
	bp.material_override = bm
	g.add_child(bp)
	var head := Node3D.new()
	head.position = Vector3(0, body_h + 0.18, 0)
	g.add_child(head)
	W._sphere(head, 0.2, Vector3.ZERO, W._mat("", skin))
	W._sphere(head, 0.21, Vector3(0, 0.07, -0.05), W._mat("", hair))
	var fp := MeshInstance3D.new()
	var fpm := PlaneMesh.new()
	fpm.size = Vector2(0.36, 0.36)
	fp.mesh = fpm
	fp.position = Vector3(0, -0.01, 0.19)
	fp.rotation.x = PI / 2
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = W._tex(face_tex)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	fp.material_override = fm
	head.add_child(fp)
	g.rotation.y = PI
	return {"root": g, "head": head, "face": fp, "face_mat": fm}

func _set_face(room: String, tex: String) -> void:
	if ghost_faces.has(room):
		(ghost_faces[room] as StandardMaterial3D).albedo_texture = W._tex(tex)

# ================= 214 · 外卖员 =================
func _build_room214() -> void:
	var done214: bool = Game.healed.has(214)
	var root := Node3D.new()
	root.name = "Room214"
	W.add_child(root)
	var c := Vector3(0, R214_Y, 0)
	var wall_tint := Color(0.75, 0.68, 0.45) if not done214 else Color(0.93, 0.9, 0.84)
	W._room_shell(root, c, 5.0, 6.0, 3.0, wall_tint, Color(0.55, 0.48, 0.34),
		[{"wall":"s","at":0.0,"w":1.1}])
	W._door_prop(root, c + Vector3(-0.55, 0, 3.0), "-z", "")
	# 厨房（北西）：折叠桌 + 外卖盒堆 + 冰箱 + 排气扇
	W._box(root, Vector3(1.4, 0.06, 0.8), c + Vector3(-1.4, 0.7, -1.8), W._mat("", Color(0.6,0.55,0.45)))
	W._box(root, Vector3(0.08, 0.7, 0.08), c + Vector3(-1.9, 0.35, -1.6), W._mat("", Color(0.4,0.36,0.3)))
	W._box(root, Vector3(0.08, 0.7, 0.08), c + Vector3(-0.9, 0.35, -2.0), W._mat("", Color(0.4,0.36,0.3)))
	fade_mats["214"] = []
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 214
	for i in 9:  # 发霉的外卖盒堆
		var bx := c + Vector3(-1.7 + rnd.randf() * 0.8, 0.82 + (i % 3) * 0.18, -1.95 + rnd.randf() * 0.5)
		fade_mats["214"].append(W._box(root, Vector3(0.3, 0.16, 0.25), bx,
			W._mat("", Color(0.72, 0.6, 0.25).darkened(rnd.randf() * 0.25)), false))
	# 那份"新鲜"的外卖（独立发亮，细思极恐）
	W._box(root, Vector3(0.32, 0.18, 0.26), c + Vector3(-1.1, 0.84, -1.55), W._mat("", Color(0.95, 0.8, 0.3)), false)
	W._emissive_panel(root, 0.2, 0.12, c + Vector3(-1.1, 0.95, -1.55), "+z", Color(0.9, 0.75, 0.3), 0.5)
	# 冰箱 + 外卖单墙（线索 1）
	W._box(root, Vector3(0.7, 1.5, 0.6), c + Vector3(-2.1, 0.75, -0.3), W._mat("", Color(0.8,0.82,0.85)))
	W._decal(root, 1.5, 1.1, c + Vector3(-2.44, 1.5, -0.3), "+x", "receipts")
	# 排气扇（高处）+ 电闸
	W._box(root, Vector3(0.5, 0.5, 0.1), c + Vector3(-1.4, 2.4, -2.95), W._mat("", Color(0.5,0.52,0.55), Vector3(1,1,1), 0.5), false)
	W._box(root, Vector3(0.4, 0.5, 0.12), c + Vector3(2.2, 1.5, -2.9), W._mat("", Color(0.4,0.42,0.45)), false)
	# 卧室（北东）：床 + 床底手机（线索 2）+ 床底笔记本（仪式）
	W._box(root, Vector3(1.3, 0.4, 2.0), c + Vector3(1.5, 0.35, -1.5), W._mat("", Color(0.45,0.35,0.25)))
	W._box(root, Vector3(1.2, 0.15, 1.9), c + Vector3(1.5, 0.6, -1.5), W._mat("", Color(0.7, 0.68, 0.6)))
	var phone_glow = W._emissive_panel(root, 0.12, 0.2, c + Vector3(1.2, 0.06, -0.9), "+z", Color(0.5, 0.7, 0.9), 1.0)
	phone_glow.rotation = Vector3.ZERO
	W._box(root, Vector3(0.5, 0.05, 0.35), c + Vector3(1.8, 0.05, -0.6), W._mat("", Color(0.2,0.2,0.22)), false)
	# 门 + 猫眼（线索 3）
	W._cyl(root, 0.04, 0.04, 0.06, c + Vector3(-0.55, 1.5, 2.93), W._mat("", Color(0.7, 0.65, 0.4), Vector3(1,1,1), 0.3), false)
	# 灯光（冷黄）
	var li := OmniLight3D.new()
	li.position = c + Vector3(0, 2.5, 0)
	li.light_color = Color(0.9, 0.8, 0.5) if not done214 else Color(1.0, 0.95, 0.85)
	li.light_energy = 0.9
	li.omni_range = 9.0
	root.add_child(li)
	room_lights_x["214"] = [li]
	# 小陈（戴头盔，面罩有雾）
	var fig := _mk_figure(root, c + Vector3(-0.6, 0, -0.5), "chen_body", Color(0.85, 0.65, 0.15), "chen_face", 0.24, 1.1, Color(0.8, 0.62, 0.45), Color(0.1, 0.1, 0.1))
	ghosts["214"] = fig.root
	ghost_faces["214"] = fig.face_mat
	var helmet: MeshInstance3D = W._sphere(fig.head, 0.24, Vector3(0, 0.02, 0), W._mat("", Color(0.9, 0.75, 0.2)))
	helmet.name = "Helmet"
	var visor := StandardMaterial3D.new()
	visor.albedo_color = Color(0.8, 0.85, 0.9, 0.45)
	visor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visor.roughness = 0.15
	var visor_mesh := MeshInstance3D.new()
	var vp := PlaneMesh.new()
	vp.size = Vector2(0.3, 0.22)
	visor_mesh.mesh = vp
	visor_mesh.position = Vector3(0, -0.03, 0.23)
	visor_mesh.rotation.x = PI / 2
	visor_mesh.material_override = visor
	visor_mesh.name = "Visor"
	fig.head.add_child(visor_mesh)
	ghosts["214"].set_meta("helmet", helmet)
	ghosts["214"].set_meta("visor", visor_mesh)
	if done214:
		helmet.hide(); visor_mesh.hide()
		_set_face("214", "chen_face_smile")
	# 交互
	W._interact(root, c + Vector3(-2.1, 1.2, -0.3), "c214_receipts", "贴满冰箱的外卖单", Vector3(0.8, 1.4, 0.7))
	W._interact(root, c + Vector3(1.2, 0.3, -0.9), "c214_phone", "床底亮着的手机", Vector3(0.6, 0.4, 0.6))
	W._interact(root, c + Vector3(-0.55, 1.5, 2.8), "c214_peephole", "猫眼", Vector3(0.4, 0.5, 0.4))
	W._interact(root, c + Vector3(2.2, 1.5, -2.8), "meter214", "电闸", Vector3(0.5, 0.6, 0.4))
	W._interact(root, c + Vector3(-1.4, 2.4, -2.8), "fan214", "排气扇", Vector3(0.6, 0.6, 0.4))
	ritual_nodes["214"] = W._interact(root, c + Vector3(1.8, 0.3, -0.6), "laptop214", "床底的旧笔记本", Vector3(0.6, 0.4, 0.5))
	ritual_nodes["214"].set_enabled(false)
	W._interact(root, c + Vector3(-1.4, 0.85, -1.8), "boxes214", "成山的外卖盒", Vector3(1.3, 0.8, 0.9))
	W._interact(root, c + Vector3(-1.1, 0.85, -1.5), "freshbox", "一份新鲜的外卖", Vector3(0.45, 0.4, 0.4))
	W._interact(root, c + Vector3(0.6, 1.2, 2.8), "leave214", "离开 214", Vector3(1.0, 2.0, 0.5))

# ================= 334 · 商人 =================
func _build_room334() -> void:
	var done334: bool = Game.healed.has(334)
	var root := Node3D.new()
	root.name = "Room334"
	W.add_child(root)
	var c := Vector3(0, R334_Y, 0)
	var wall_tint := Color(0.6, 0.55, 0.42) if not done334 else Color(0.92, 0.9, 0.85)
	W._room_shell(root, c, 6.0, 6.0, 3.0, wall_tint, Color(0.5, 0.42, 0.3),
		[{"wall":"s","at":0.0,"w":1.1}])
	W._door_prop(root, c + Vector3(-0.55, 0, 3.0), "-z", "")
	fade_mats["334"] = []
	# 客厅：开裂皮沙发 + 茶几 + 满桌冥币
	W._box(root, Vector3(1.8, 0.4, 0.8), c + Vector3(-1.5, 0.3, -0.8), W._mat("", Color(0.4, 0.28, 0.2)))
	W._box(root, Vector3(1.8, 0.5, 0.2), c + Vector3(-1.5, 0.65, -1.15), W._mat("", Color(0.38, 0.26, 0.19)))
	W._box(root, Vector3(1.1, 0.45, 0.6), c + Vector3(-0.2, 0.22, -0.2), W._mat("", Color(0.3, 0.22, 0.15)))
	W._decal(root, 1.0, 0.5, c + Vector3(-0.2, 0.47, -0.2), "+z", "moneywall")
	fade_mats["334"].append(W._decal(root, 2.2, 1.4, c + Vector3(-2.9, 1.6, 0.5), "+x", "moneywall"))
	# 保险柜（墙角）
	W._box(root, Vector3(0.7, 0.9, 0.6), c + Vector3(2.5, 0.45, -2.5), W._mat("", Color(0.25, 0.27, 0.3), Vector3(1,1,1), 0.5))
	W._emissive_panel(root, 0.15, 0.1, c + Vector3(2.15, 0.6, -2.5), "-x", Color(0.3, 0.6, 0.3), 0.8)
	# 卧室：双人床（一边有枕头）+ 床头柜合影（线索 3）
	W._box(root, Vector3(1.8, 0.4, 2.0), c + Vector3(1.5, 0.35, 1.2), W._mat("", Color(0.45, 0.35, 0.28)))
	W._box(root, Vector3(1.7, 0.15, 1.9), c + Vector3(1.5, 0.6, 1.2), W._mat("", Color(0.65, 0.6, 0.55)))
	W._box(root, Vector3(0.4, 0.12, 0.3), c + Vector3(1.05, 0.68, 2.0), W._mat("", Color(0.8, 0.75, 0.7)), false)
	W._box(root, Vector3(0.5, 0.4, 0.4), c + Vector3(0.4, 0.2, 2.3), W._mat("", Color(0.4, 0.32, 0.22)))
	W._decal(root, 0.4, 0.5, c + Vector3(0.4, 0.55, 2.3), "+z", "poster_missing", Color(0.85, 0.8, 0.75))
	# 书房角落：书桌 + 账本（线索 1）
	W._box(root, Vector3(1.0, 0.75, 0.5), c + Vector3(-2.4, 0.38, -2.5), W._mat("", Color(0.35, 0.25, 0.18)))
	W._box(root, Vector3(0.35, 0.05, 0.28), c + Vector3(-2.4, 0.8, -2.5), W._mat("", Color(0.85, 0.8, 0.7)), false)
	# 床底催债单（线索 2）：露出白纸角
	W._box(root, Vector3(0.3, 0.02, 0.2), c + Vector3(0.9, 0.05, 1.0), W._mat("", Color(0.9, 0.88, 0.8)), false)
	# 马桶水箱（仪式道具：银行卡）
	W._box(root, Vector3(0.5, 0.6, 0.25), c + Vector3(-2.6, 0.9, 2.6), W._mat("", Color(0.85, 0.87, 0.88)))
	# 摇椅 + 老贾
	W._box(root, Vector3(0.55, 0.5, 0.55), c + Vector3(0.3, 0.25, -1.2), W._mat("", Color(0.4, 0.3, 0.2)))
	var fig := _mk_figure(root, c + Vector3(0.3, 0.5, -1.2), "jia_body", Color(0.42, 0.42, 0.45), "jia_face", 0.34, 0.95, Color(0.95, 0.8, 0.68), Color(0.3, 0.28, 0.26))
	ghosts["334"] = fig.root
	ghost_faces["334"] = fig.face_mat
	if done334: _set_face("334", "jia_face_cry")
	# 灯光
	var li := OmniLight3D.new()
	li.position = c + Vector3(0, 2.5, 0)
	li.light_color = Color(0.95, 0.85, 0.55) if not done334 else Color(1.0, 0.95, 0.85)
	li.light_energy = 0.95
	li.omni_range = 9.0
	root.add_child(li)
	room_lights_x["334"] = [li]
	# 交互
	W._interact(root, c + Vector3(-2.4, 0.8, -2.4), "c334_ledger", "书桌上的账本", Vector3(0.9, 0.6, 0.5))
	W._interact(root, c + Vector3(0.9, 0.25, 1.0), "c334_debt", "床底的纸", Vector3(0.6, 0.4, 0.6))
	W._interact(root, c + Vector3(0.4, 0.55, 2.2), "c334_photo", "床头柜的合影", Vector3(0.5, 0.5, 0.4))
	ritual_nodes["334"] = W._interact(root, c + Vector3(-2.6, 1.0, 2.5), "tank334", "马桶水箱", Vector3(0.6, 0.7, 0.5))
	ritual_nodes["334"].set_enabled(false)
	W._interact(root, c + Vector3(2.4, 0.6, -2.4), "safe334", "保险柜", Vector3(0.7, 0.9, 0.6))
	W._interact(root, c + Vector3(-0.2, 0.5, -0.2), "money334", "茶几上的现金", Vector3(1.0, 0.6, 0.6))
	W._interact(root, c + Vector3(-1.5, 0.6, -0.8), "sofa334", "开裂的皮沙发", Vector3(1.6, 0.8, 0.8))
	W._interact(root, c + Vector3(0.6, 1.2, 2.8), "leave334", "离开 334", Vector3(1.0, 2.0, 0.5))

# ================= 404 · 前管理员 =================
func _build_room404() -> void:
	var done404: bool = Game.healed.has(404)
	var root := Node3D.new()
	root.name = "Room404"
	W.add_child(root)
	var c := Vector3(0, R404_Y, 0)
	var wall_tint := Color(0.85, 0.84, 0.8) if not done404 else Color(0.95, 0.94, 0.9)
	W._room_shell(root, c, 9.0, 7.0, 3.2, wall_tint, Color(0.7, 0.68, 0.62),
		[{"wall":"s","at":0.0,"w":1.1}])
	W._door_prop(root, c + Vector3(-0.55, 0, 3.5), "-z", "")
	fade_mats["404"] = []
	# 满墙的 4 和"不要开门"（治愈后淡出）
	if not done404:
		fade_mats["404"].append(W._decal(root, 3.4, 1.9, c + Vector3(-1.5, 1.9, -3.42), "+z", "graffiti4"))
		fade_mats["404"].append(W._decal(root, 3.4, 1.9, c + Vector3(2.0, 1.9, -3.42), "+z", "graffiti4"))
		fade_mats["404"].append(W._decal(root, 2.6, 1.6, c + Vector3(-4.42, 1.8, 0.0), "+x", "graffiti4"))
	# 地板日历（Day1-365 循环）
	W._floor_decal(root, 3.6, c + Vector3(0, 0.008, -0.5), "calendar_floor", Color(1, 1, 1, 0.85))
	# 和管理员室一样的床与桌子（线索 1、2）
	W._box(root, Vector3(1.3, 0.4, 2.1), c + Vector3(-3.2, 0.35, -2.0), W._mat("", Color(0.4, 0.4, 0.42)))
	W._box(root, Vector3(1.2, 0.15, 2.0), c + Vector3(-3.2, 0.6, -2.0), W._mat("", Color(0.6, 0.62, 0.66)))
	W._box(root, Vector3(1.2, 0.08, 0.7), c + Vector3(3.2, 0.78, -2.2), W._mat("", Color(0.42, 0.3, 0.2)))
	W._box(root, Vector3(0.08, 0.78, 0.08), c + Vector3(2.75, 0.39, -2.4), W._mat("", Color(0.34, 0.24, 0.16)))
	W._box(root, Vector3(0.08, 0.78, 0.08), c + Vector3(3.65, 0.39, -2.0), W._mat("", Color(0.34, 0.24, 0.16)))
	W._box(root, Vector3(0.4, 0.03, 0.3), c + Vector3(3.2, 0.84, -2.2), W._mat("", Color(0.88, 0.85, 0.78)), false)
	# 窗（楼中楼）
	W._box(root, Vector3(1.3, 1.5, 0.06), c + Vector3(0.8, 1.8, -3.45), W._mat("", Color(0.15, 0.14, 0.16)))
	W._emissive_panel(root, 1.2, 1.4, c + Vector3(0.8, 1.8, -3.41), "+z", Color(0.12, 0.13, 0.2), 0.8)
	# 镜子（照出的是你）
	W._box(root, Vector3(0.5, 1.9, 0.08), c + Vector3(4.4, 1.2, 0.5), W._mat("", Color(0.35, 0.28, 0.2)))
	W._decal(root, 0.4, 1.75, c + Vector3(4.35, 1.2, 0.5), "-x", "mirror")
	# 天花板抓痕
	W._decal(root, 1.8, 1.2, c + Vector3(0, 3.05, 0), "-z", "blood_drips", Color(0.2, 0.2, 0.2, 0.6))
	# 前管理员（和你一模一样）
	var fig := _mk_figure(root, c + Vector3(0, 0, -0.5), "prev_body", Color(0.2, 0.28, 0.4), "prev_face", 0.24, 1.15, Color(0.92, 0.78, 0.66), Color(0.18, 0.16, 0.15))
	prev_ghost = fig.root
	ghosts["404"] = fig.root
	ghost_faces["404"] = fig.face_mat
	if done404: prev_ghost.hide()
	# 灯光（惨白）
	var li := OmniLight3D.new()
	li.position = c + Vector3(0, 2.8, 0)
	li.light_color = Color(0.85, 0.87, 0.9) if not done404 else Color(1.0, 0.98, 0.92)
	li.light_energy = 0.85
	li.omni_range = 11.0
	root.add_child(li)
	room_lights_x["404"] = [li]
	# 交互
	W._interact(root, c + Vector3(-3.2, 0.6, -2.0), "c404_bed", "和你一样的床", Vector3(1.2, 0.7, 1.8))
	W._interact(root, c + Vector3(3.2, 0.85, -2.1), "c404_log", "管理日志", Vector3(1.0, 0.6, 0.6))
	W._interact(root, c + Vector3(0.8, 1.8, -3.3), "c404_window", "窗外", Vector3(1.2, 1.4, 0.4))
	W._interact(root, c + Vector3(4.2, 1.2, 0.5), "mirror404", "镜子", Vector3(0.5, 1.6, 0.7))
	ritual_nodes["404"] = W._interact(root, c + Vector3(0, 1.1, -0.5), "prev_talk", "另一个你", Vector3(1.0, 1.8, 1.0))
	ritual_nodes["404"].set_enabled(false)
	W._interact(root, c + Vector3(0.6, 1.2, 3.3), "leave404", "离开 404", Vector3(1.0, 2.0, 0.5))

# ================= 444 · 无头门神（倒置空间） =================
func _build_room444() -> void:
	var done444: bool = Game.healed.has(444)
	var root := Node3D.new()
	root.name = "Room444"
	W.add_child(root)
	var c := Vector3(0, R444_Y, 0)
	var wall_tint := Color(0.45, 0.42, 0.4) if not done444 else Color(0.9, 0.88, 0.84)
	W._room_shell(root, c, 5.0, 5.0, 3.4, wall_tint, Color(0.35, 0.33, 0.3),
		[{"wall":"s","at":0.0,"w":1.1}])
	W._door_prop(root, c + Vector3(-0.55, 0, 2.5), "-z", "")
	# 倒置的家具（挂在"天花板"上——其实是地板）
	var table = W._box(root, Vector3(1.0, 0.08, 0.6), c + Vector3(-1.2, 3.1, -1.0), W._mat("", Color(0.4, 0.3, 0.22)), false)
	table.rotation.z = PI
	var chair = W._box(root, Vector3(0.4, 0.5, 0.4), c + Vector3(-0.4, 3.0, -0.6), W._mat("", Color(0.35, 0.28, 0.2)), false)
	chair.rotation.z = PI
	var lamp_h = W._cyl(root, 0.05, 0.1, 0.4, c + Vector3(1.0, 3.2, -1.2), W._mat("", Color(0.5, 0.45, 0.35)), false)
	lamp_h.rotation.z = PI
	# 巨镜（整面北墙）
	W._box(root, Vector3(3.6, 2.6, 0.1), c + Vector3(0, 1.5, -2.42), W._mat("", Color(0.3, 0.26, 0.22)))
	W._decal(root, 3.4, 2.4, c + Vector3(0, 1.5, -2.36), "+z", "mirror")
	# 符咒（治愈后变金）
	var tal_mats := []
	for pos in [Vector3(-2.42, 1.6, -0.8), Vector3(-2.42, 1.6, 0.8), Vector3(2.42, 1.6, 0.0)]:
		var facing := "+x" if pos.x < 0 else "-x"
		var tm = W._decal(root, 0.35, 0.95, c + pos, facing, "talisman")
		tal_mats.append(tm)
	root.set_meta("talismans", tal_mats)
	# 地板暗格（一块颜色略深的板）
	W._box(root, Vector3(0.6, 0.04, 0.45), c + Vector3(1.4, 0.03, 1.2), W._mat("", Color(0.28, 0.26, 0.24)), false)
	# 无头门神（2.4 米高，无头，红布包）
	var god := Node3D.new()
	god.position = c + Vector3(0, 0, -0.8)
	root.add_child(god)
	W._cyl(god, 0.32, 0.4, 2.2, Vector3(0, 1.1, 0), W._mat("", Color(0.16, 0.28, 0.2)))
	var bp := MeshInstance3D.new()
	var bpm := PlaneMesh.new()
	bpm.size = Vector2(0.85, 1.7)
	bp.mesh = bpm
	bp.position = Vector3(0, 1.2, 0.36)
	bp.rotation.x = PI / 2
	var bm := StandardMaterial3D.new()
	bm.albedo_texture = W._tex("doorgod_body")
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.roughness = 0.9
	bp.material_override = bm
	god.add_child(bp)
	W._cyl(god, 0.14, 0.16, 0.12, Vector3(0, 2.26, 0), W._mat("", Color(0.5, 0.42, 0.38)))  # 断面
	W._box(god, Vector3(0.28, 0.28, 0.28), Vector3(0.45, 1.3, 0.15), W._mat("", Color(0.6, 0.12, 0.1)), false)  # 红布包
	god.rotation.y = PI
	ghosts["444"] = god
	# 灯光（惨绿）
	var li := OmniLight3D.new()
	li.position = c + Vector3(0, 2.8, 0.5)
	li.light_color = Color(0.7, 0.85, 0.72) if not done444 else Color(1.0, 0.97, 0.88)
	li.light_energy = 0.8
	li.omni_range = 8.0
	root.add_child(li)
	room_lights_x["444"] = [li]
	# 交互
	W._interact(root, c + Vector3(0, 1.5, -2.2), "c444_mirror", "占满整面墙的镜子", Vector3(3.2, 2.4, 0.5))
	W._interact(root, c + Vector3(-2.3, 1.6, -0.8), "c444_talisman", "墙上的符咒", Vector3(0.5, 1.0, 0.5))
	W._interact(root, c + Vector3(1.4, 0.3, 1.2), "c444_photo", "地板的暗格", Vector3(0.7, 0.4, 0.6))
	W._interact(root, c + Vector3(1.0, 2.9, -0.9), "inverted", "倒置的家具", Vector3(1.6, 0.8, 1.2))
	ritual_nodes["444"] = W._interact(root, c + Vector3(0, 1.2, -0.8), "doorgod", "无头门神", Vector3(1.1, 2.2, 1.1))
	ritual_nodes["444"].set_enabled(false)
	W._interact(root, c + Vector3(0.6, 1.2, 2.3), "leave444", "离开 444", Vector3(1.0, 2.0, 0.5))

# ================= 4444 · 蝴蝶（无限走廊） =================
func _build_room4444() -> void:
	var root := Node3D.new()
	root.name = "Room4444"
	W.add_child(root)
	var c := Vector3(0, R4444_Y, 0)
	W._room_shell(root, c, 30.0, 3.4, 3.2, Color(0.16, 0.1, 0.2), Color(0.1, 0.07, 0.13), [])
	# 失踪人口海报（每张都是"上一个玩家"）
	for i in 12:
		var px := -13.5 + i * 2.4
		W._decal(root, 0.5, 0.66, c + Vector3(px, 1.7, -1.62), "+z", "poster_missing", Color(0.8, 0.75, 0.8))
		if i % 2 == 0:
			W._decal(root, 0.5, 0.66, c + Vector3(px + 1.2, 1.7, 1.62), "-z", "poster_missing", Color(0.75, 0.7, 0.75))
	# 尽头：发微光的"蝶群中心"
	W._emissive_panel(root, 1.6, 2.2, c + Vector3(14.7, 1.5, 0), "-x", Color(0.5, 0.3, 0.7), 1.4)
	# 蝴蝶群（_process 里绕飞）
	var bm := StandardMaterial3D.new()
	bm.albedo_texture = W._tex("butterfly")
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.emission_enabled = true
	bm.emission = Color(0.6, 0.4, 0.9)
	bm.emission_energy_multiplier = 0.8
	for i in 10:
		var bf := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.3, 0.3)
		bf.mesh = pm
		bf.material_override = bm
		bf.set_meta("phase", i * 0.63)
		bf.set_meta("radius", 0.8 + (i % 4) * 0.5)
		bf.set_meta("height", 1.2 + (i % 3) * 0.5)
		root.add_child(bf)
		butterflies.append(bf)
	# 灯光（极暗紫）
	for lx in [-10.0, 0.0, 10.0]:
		var li := OmniLight3D.new()
		li.position = c + Vector3(lx, 2.6, 0)
		li.light_color = Color(0.45, 0.3, 0.6)
		li.light_energy = 0.5
		li.omni_range = 7.0
		root.add_child(li)
	room_lights_x["4444"] = []
	# 交互
	W._interact(root, c + Vector3(14.0, 1.4, 0), "butterfly_voice", "蝶群的声音", Vector3(1.4, 2.0, 1.6))
	W._interact(root, c + Vector3(-8.0, 1.7, -1.4), "posters4444", "失踪人口海报", Vector3(2.0, 1.2, 0.5))
	W._interact(root, c + Vector3(-14.0, 1.2, 0), "leave4444", "来时的方向", Vector3(1.0, 2.0, 1.2))

# ================= 彩蛋 =================
func _build_eggs() -> void:
	# 1. 四蛆兄弟传单（3 楼小广告墙）
	var f3 = W.get_node("Floor%d" % int(F3_Y))
	W._decal(f3, 0.4, 0.4, Vector3(0.72, 1.72, F3_Y + 1.4), "-z", "egg_siqu")
	W._interact(f3, Vector3(0.72, 1.72, F3_Y + 1.3), "egg_siqu", "一张奇怪的传单", Vector3(0.4, 0.4, 0.3))
	# 2. 华为竹知了（1 楼暖气片后面）
	var c1 := Vector3(0, 0, 0)
	W._decal(W.get_node("Corridor"), 0.3, 0.3, c1 + Vector3(-5.5, 0.85, 1.44), "-z", "egg_cicada")
	W._interact(W.get_node("Corridor"), c1 + Vector3(-5.5, 0.8, 1.3), "egg_cicada", "暖气片后面", Vector3(0.5, 0.5, 0.4))

func _egg(id: String, title: String, lines: Array) -> void:
	if Game.flags.has("egg_" + id):
		Dialog.say(["（彩蛋已经收进日志了。）"])
		return
	Game.flags["egg_" + id] = true
	var n := 0
	for k in Game.flags:
		if str(k).begins_with("egg_"): n += 1
	Game.add_journal("【彩蛋 %d/%d】%s" % [n, EGG_TOTAL, title])
	Dialog.say(lines)
	await Dialog.finished
	if n >= EGG_TOTAL:
		Sfx.play("chime")
		Dialog.say_center(["彩蛋集齐了（%d/%d）。" % [n, EGG_TOTAL], "这栋楼的开发商，品味真的很杂。"])
	else:
		Dialog.say(["（彩蛋收集：%d/%d）" % [n, EGG_TOTAL]])

# ================= 管理员室逐日崩坏 =================
func apply_admin_evolution() -> void:
	var adm = W.get_node_or_null("Admin")
	if adm == null: return
	var ay = W.ADMIN_Y
	if Game.day >= 3 and adm.get_node_or_null("EvoClock") == null:
		var clk = W._decal(adm, 0.4, 0.4, Vector3(-0.15, ay + 1.8, -2.42), "+z", "clock333")
		clk.name = "EvoClock"
		W._interact(adm, Vector3(-0.15, ay + 1.8, -2.3), "clock_evt", "挂钟", Vector3(0.45, 0.45, 0.3))
	if Game.day >= 4 and adm.get_node_or_null("EvoGraffiti") == null:
		var gf = W._decal(adm, 2.4, 1.4, Vector3(0.0, ay + 1.9, 2.42), "-z", "graffiti4", Color(1, 1, 1, 0.9))
		gf.name = "EvoGraffiti"
	if Game.day >= 6 and adm.get_node_or_null("EvoPC") == null:
		var pc = W._emissive_panel(adm, 0.3, 0.2, Vector3(0.1, ay + 1.0, -1.68), "+z", Color(0.4, 0.7, 0.9), 1.2)
		pc.name = "EvoPC"
		W._interact(adm, Vector3(0.35, ay + 1.0, -1.7), "computer_evo", "自己开机的电脑", Vector3(0.5, 0.5, 0.5))
	if Game.day >= 7 and adm.get_node_or_null("EvoReport") == null:
		W._decal(adm, 0.6, 0.4, Vector3(0.1, ay + 1.05, -1.66), "+z", "death_report").name = "EvoReport"
		W._interact(adm, Vector3(-2.5, ay + 1.5, -1.7), "cabinet7", "铁皮柜顶层", Vector3(0.6, 0.5, 0.5))
		W._interact(adm, Vector3(-0.2, ay + 0.85, -1.5), "invitation7", "那封邀请函", Vector3(0.4, 0.3, 0.35))

# ================= 线索（通用） =================
func _clue(room: String, id: String, title: String, desc: String, lines: Array) -> void:
	if Game.clues.has(id):
		Dialog.say(["（这条线索已经记进日志了。）"])
		return
	Dialog.say(lines)
	Game.add_clue(id, title, desc)
	await Dialog.finished
	_check_truth_x(room)

const TRUTH_LINES := {
	"214": [
		"你全都明白了。",
		"小陈不是在送外卖。那 30 单全是借口。",
		"他在蹲 404 的那个人——他拍到了不该拍的东西。",
		"最后一段录音之后，就再也没有小陈了。",
		"他到死都攥着那部手机，因为里面有要寄给妈妈的证据。",
	],
	"334": [
		"你全都明白了。",
		"老贾骗了整栋楼的钱。王大妈的 30 万，李老头的 50 万。",
		"但他自己也被高利贷逼到了绝路。",
		"合影上每个人的脸都被划掉了，只有他被红笔圈着——「下一个」。",
		"他数了一辈子的钱，最后没能赎回任何一个人，包括他自己。",
	],
	"404": [
		"你全都明白了。",
		"他就是你。或者说，是上一个你。",
		"他治愈过他们，但他们第二天又出现了。",
		"他杀过自己，醒来还是 Day 1。",
		"他不是疯子。他只是比你多撑了三百六十五天。",
	],
	"444": [
		"你全都明白了。",
		"陈卫国是这栋楼的保安。4 号楼出事那晚，他是唯一冲进去的人。",
		"他没能救出所有人，也没能带回自己的头。",
		"但直到现在，他还站在门口。",
		"「头不重要。心重要。」",
	],
}

const TRUTH_JOURNAL := {
	"214": "【真相·214】他用外卖单做掩护调查 404，被发现了。证据要寄给妈妈。",
	"334": "【真相·334】他骗了全楼，也被高利贷逼死。赃款该还给住户家属。",
	"404": "【真相·404】他是上一个管理员，困在循环里 365 天。让他休息。",
	"444": "【真相·444】保安陈卫国，为救住户死在 4 号楼。他不需要头，需要一颗被承认的心。",
}

func _check_truth_x(room: String) -> void:
	if Game.clue_count(CLUES[room]) == 3 and not Game.flags.has("truth_" + room):
		Game.flags["truth_" + room] = true
		await Dialog.finished
		Sfx.play("static")
		Dialog.say_center(TRUTH_LINES[room])
		await Dialog.finished
		Game.add_journal(TRUTH_JOURNAL[room])
		ritual_nodes[room].set_enabled(true)
		match room:
			"214": Dialog.say(["（床底的旧笔记本电脑，屏幕亮了一下。它还在等那封邮件。）"])
			"334": Dialog.say(["（浴室的方向，传来水箱滴水的声音。好像有什么东西在里面。）"])
			"404": Dialog.say(["（他抬起头，看着你。像等了很多年。）"])
			"444": Dialog.say(["（门神转过身，「看」着你。虽然他没有头。）"])

# ================= 214 事件 =================
func _on_meter214() -> void:
	if Game.flags.has("power214"):
		Dialog.say(["电闸已经拉下了。排气扇停了。"])
		return
	Game.flags["power214"] = true
	Sfx.play("static")
	Dialog.say(["（你拉下电闸。整间屋子的电器嗡了一声，安静下来。）", "（排气扇，停了。）"])

func _on_fan214() -> void:
	if not Game.flags.has("power214"):
		Dialog.say(["排气扇还在转。扇叶后面卡着一个东西，但你不敢伸手。", "（先找电闸。）"])
		return
	if Game.flags.has("usb214"):
		Dialog.say(["排气扇里空了。风道尽头积着一层灰。"])
		return
	Game.flags["usb214"] = true
	Sfx.play("paper")
	Dialog.say([
		"（你踮起脚，从扇叶后面抠出一个小小的 U 盘。）",
		"（U 盘上贴着便利贴，是小陈的字：「给妈妈。」）",
	])
	Game.add_journal("【道具】U 盘——排气扇里藏着的证据。")

func _on_laptop214() -> void:
	if Game.healed.has(214): return
	if not Game.flags.has("usb214"):
		Dialog.say(["（旧笔记本还能开机，邮箱已经登录好了。）", "（但附件是空的——你得先找到他藏起来的证据。）"])
		return
	Dialog.say([
		"（你把 U 盘插进去。里面是照片和视频——404 门口的血迹，和一个背影。）",
		"（收件人栏是空的。他到最后都没敢填。）",
		"（小李说过，他妈妈姓陈，邮箱里带着她生日的数字。）",
	])
	await Dialog.finished
	var idx: int = await RitualUI.ask("选择收件人——", [
		"chenmama520@qq.com", "chenxiaoma214@qq.com", "mamachen404@qq.com", "xiaochen777@qq.com"])
	match idx:
		0: _heal_214()
		_:
			Sfx.play("static")
			Dialog.say(["（发送失败。地址不存在。）", "（你再想想。520——妈妈把爱藏在了数字里。）"])
			Game.drain_battery(6.0)

func _heal_214() -> void:
	_heal_common("214", "", "", "")
	Sfx.play("chime")
	Dialog.say_center(["发送成功。", "一秒钟后，自动回复弹了出来：", "「儿子，妈妈一直相信你。」"])
	await Dialog.finished
	var t = W.create_tween().set_parallel(true)
	for li in room_lights_x["214"]:
		t.tween_property(li, "light_color", Color(1.0, 0.95, 0.85), 2.5)
	for m in fade_mats["214"]:
		if is_instance_valid(m): t.tween_property(m, "transparency", 1.0, 2.5)
	await t.finished
	# 他摘下头盔，露出年轻的笑脸
	var god: Node3D = ghosts["214"]
	(god.get_meta("helmet") as MeshInstance3D).hide()
	(god.get_meta("visor") as MeshInstance3D).hide()
	_set_face("214", "chen_face_smile")
	Dialog.say([
		"（发霉的外卖盒一个一个消失了。）",
		"（他站在门口，第一次摘下了头盔——很年轻的一张脸，在笑。）",
		["外卖员小陈", "帮我跟妈妈说……她的儿子不是失踪，是去做了件对的事。"],
	])
	await Dialog.finished
	Game.add_relic("五星好评头盔", "小陈的头盔。面罩上的雾气散了，再也看不到里面的呼吸。")
	Game.healed.append(214)
	Dialog.say(["（楼道里飘来一股饭菜香。该回去了。）"])

# ================= 334 事件 =================
func _on_tank334() -> void:
	if Game.flags.has("card334"):
		Dialog.say(["水箱里只剩生锈的浮球。"])
		return
	Game.flags["card334"] = true
	Sfx.play("paper")
	Dialog.say([
		"（你掀开水箱盖。一个塑料袋用胶带粘在箱壁上。）",
		"（里面是一张银行卡，和一张字条：「淑芬，对不起。」）",
	])
	Game.add_journal("【道具】老贾的银行卡——藏赃款的卡。")

func _on_safe334() -> void:
	if Game.healed.has(334): return
	if not Game.flags.has("truth_334"):
		Dialog.say(["保险柜。密码盘上的数字被磨得发亮。", "（你不知道密码。）"])
		return
	if not Game.flags.has("card334"):
		Dialog.say(["保险柜。就算打开它，你也需要一张能转账的卡。", "（账本上写，真正的卡「在最干净的地方」。）"])
		return
	Dialog.say(["（账本最后一页，那道算错的加法：）", "「2024 年 3 月 15 日，应收合计：2042+3+15……」", "（他把年份也加进去了。正确的密码应该是——）"])
	await Dialog.finished
	var idx: int = await RitualUI.ask("输入密码——", ["2042", "2024", "3153", "2060"])
	match idx:
		0: _heal_334()
		_:
			Sfx.play("static")
			Dialog.say(["（密码错误。保险柜发出一声短促的蜂鸣。）", "（2024+3+15。他把年份也加进去了，那你呢？）"])
			Game.drain_battery(6.0)

func _heal_334() -> void:
	_heal_common("334", "", "", "")
	Sfx.play("chime")
	Dialog.say_center([
		"转账成功。",
		"一笔一笔，按账本上的名字，连本带利。",
		"手机震了一下：「收到了。老贾，下辈子别这样了。」",
	])
	await Dialog.finished
	var t = W.create_tween().set_parallel(true)
	for li in room_lights_x["334"]:
		t.tween_property(li, "light_color", Color(1.0, 0.95, 0.85), 2.5)
	for m in fade_mats["334"]:
		if is_instance_valid(m): t.tween_property(m, "transparency", 1.0, 2.5)
	await t.finished
	_set_face("334", "jia_face_cry")
	Dialog.say([
		"（满屋的冥币，一张一张变成了纸灰。）",
		"（摇椅上的他还在笑，但眼泪是红色的。）",
		["商人老贾", "数了一辈子钱……最后一笔，总算是数对了。"],
	])
	await Dialog.finished
	Game.add_relic("刻着「对不起」的钥匙", "老贾的保险柜钥匙。他最后锁进保险柜的，是道歉。")
	Game.healed.append(334)
	Dialog.say(["（管理员室的挂钟，好像往前走了一格。该回去了。）"])

# ================= 404 事件 =================
func _on_prev_talk() -> void:
	if Game.healed.has(404): return
	Dialog.say([
		["前管理员", "你来了。第几个了？我数过，后来不数了。"],
		["前管理员", "我治愈过他们每一个人。商人、外卖员、红裙子。第二天，他们又坐在原来的位置。"],
		["前管理员", "Day 365，我杀了 自己。醒来的时候，日历翻回了 Day 1。"],
		["前管理员", "你还想试吗？"],
	])
	await Dialog.finished
	var idx: int = await RitualUI.ask("看着他疲惫的眼睛，你说——", [
		"「谢谢你。但让我来。你可以休息了。」",
		"「我会比你强。」",
	])
	match idx:
		0: _heal_404()
		_:
			Sfx.play("static")
			Game.drain_battery(15.0)
			Dialog.say([
				"（他笑了。笑声和你一模一样，只是旧了很多。）",
				["前管理员", "我也是这么说的。"],
				"（他的手电扫过你的眼睛，你踉跄退开。手电电量掉了一大截。）",
				"（再说一次。好好说。）",
			])

func _heal_404() -> void:
	_heal_common("404", "", "", "")
	Sfx.play("chime")
	# 满墙的 4 淡出
	var t = W.create_tween().set_parallel(true)
	for m in fade_mats["404"]:
		if is_instance_valid(m): t.tween_property(m, "transparency", 1.0, 2.5)
	for li in room_lights_x["404"]:
		t.tween_property(li, "light_color", Color(1.0, 0.97, 0.9), 2.5)
	await t.finished
	# 墙上出现"祝你成功"，他消散
	var root = W.get_node("Room404")
	var wish = W._decal(root, 1.8, 0.6, Vector3(0, R404_Y + 2.0, -3.38), "+z", "zhuni")
	(wish.material_override as StandardMaterial3D).emission_enabled = true
	(wish.material_override as StandardMaterial3D).emission = Color(1.0, 0.85, 0.5)
	(wish.material_override as StandardMaterial3D).emission_energy_multiplier = 0.8
	var tw = W.create_tween()
	tw.tween_property(prev_ghost, "scale", Vector3(1.0, 0.02, 1.0), 2.0)
	tw.parallel().tween_property(prev_ghost, "position:y", prev_ghost.position.y - 0.3, 2.0)
	await tw.finished
	prev_ghost.hide()
	Dialog.say([
		"（满墙的「4」一个一个淡去。）",
		["前管理员", "替我……走到第 7 天。"],
		"（他在墙上写下最后四个字，然后像关掉的手电一样，暗了下去。）",
		"（墙上留着：「祝你成功。」）",
	])
	await Dialog.finished
	Game.add_relic("管理日志的最后一页", "前一任管理员的绝笔。纸的背面写着一个房号：4444。——是你的。")
	Game.healed.append(404)
	Dialog.say(["（窗外的「楼中楼」消失了。外面是普通的夜空。该回去了。）"])

# ================= 444 事件 =================
func _on_doorgod() -> void:
	if Game.healed.has(444): return
	var has_button := false
	for r in Game.relics:
		if r.get("name", "") == "红裙子的纽扣": has_button = true
	if not has_button:
		Dialog.say([
			"（他「看」着你空着的双手，没有动。）",
			"（腹部传来沉闷的声音：「心。带来。心。」）",
			"（他需要一颗「心」——一个被治愈过的灵魂留下的东西。）",
		])
		return
	Dialog.say([
		"（你摊开手。红裙子的纽扣躺在掌心，还是温的。）",
		"（他微微弯下腰，把平整的颈间断面凑近你。）",
	])
	await Dialog.finished
	var idx: int = await RitualUI.ask("把纽扣放上他的颈间——", [
		"「你不需要头也能看见真相。这颗心，就够了。」",
		"「我帮你把头找回来。」",
	])
	match idx:
		0: _heal_444()
		_:
			Sfx.play("static")
			Dialog.say(["（他直起身，摇了摇头——虽然他没有头。）", "（腹部传来声音：「头。不重要。」）"])
			Game.drain_battery(6.0)

func _heal_444() -> void:
	_heal_common("444", "", "", "")
	Sfx.play("chime")
	Dialog.say_center(["纽扣贴上断面的那一刻，符咒全部亮了。", "金色的。"])
	await Dialog.finished
	# 符咒变金
	var root = W.get_node("Room444")
	if root.has_meta("talismans"):
		for tm in root.get_meta("talismans"):
			if is_instance_valid(tm):
				W.create_tween().tween_property((tm as MeshInstance3D).material_override, "albedo_color", Color(1.2, 1.0, 0.4), 2.0)
	# 他化为一堵墙，守住门口
	var god: Node3D = ghosts["444"]
	var t = W.create_tween().set_parallel(true)
	t.tween_property(god, "position", Vector3(0, R444_Y + 0.0, -2.2), 2.5)
	t.tween_property(god, "scale", Vector3(2.6, 1.4, 0.35), 2.5)
	await t.finished
	Dialog.say([
		"（他走到 4444 入口的方向，展开身体，砌进了墙里。）",
		"（腹部传来最后的声音，闷闷的，但很稳：）",
		["无头门神", "去。我守着。"],
	])
	await Dialog.finished
	Game.add_relic("符咒碎片", "金色的符咒一角。据说能抵挡一次致命伤害。")
	Game.healed.append(444)
	Dialog.say(["（444 的镜子亮了。镜子里有一条路，通向 4 号楼。）", "（你也可以在夜里，从电梯的铁栅栏后面进去。）"])

# ================= 4444 事件 =================
func _enter_4444(src: String) -> void:
	if Game.flags.has("butterfly_done") and Game.healed.has(4444):
		Dialog.say(["4 号楼已经安静了。"])
		return
	Dialog.say(["（%s。你跨了进去。）" % ("铁栅栏在你身后合拢" if src == "elevator" else "镜面像水一样漫过你"),
		"（这不是一个房间。这是一整栋楼。）",
		"（走廊两边贴满了失踪人口海报——每一张，都是「上一个你」。）"])
	await Dialog.finished
	Game.lock_ui("teleport")
	Sfx.play("door")
	Game.drain_battery(16.0)
	await SceneFlow.fade_out(0.4)
	W.player.position = Vector3(-13.5, R4444_Y + 0.05, 0)
	W.player.set_look(PI / 2)
	await SceneFlow.fade_in(0.6)
	Game.unlock_ui("teleport")
	Sfx.heartbeat(true)

func _on_butterfly_voice() -> void:
	if Game.flags.has("butterfly_done"): return
	Dialog.say([
		"（蝶群聚拢过来。翅膀上的眼睛，一齐看向你。）",
		["？？？", "第 48 个。你比他们走得都远。"],
		["？？？", "我是这栋楼所有声音的集合。他们叫我——蝴蝶。"],
		["蝴蝶", "回答我六个问题。答得出来，楼归你，我们安息。答不出来——"],
		["蝴蝶", "你就留下来，陪我守门。"],
	])
	await Dialog.finished
	_butterfly_quiz()

const QUIZ := [
	{"q": "第一个问题：她死前穿的睡衣，是什么颜色？", "opts": ["白色", "红色", "蓝色", "她从不穿睡衣"], "a": 0},
	{"q": "第二个问题：小陈妈妈的邮箱，最后三位数字是？", "opts": ["520", "214", "404", "777"], "a": 0},
	{"q": "第三个问题：老贾保险柜的密码是？", "opts": ["2042", "2024", "3153", "4444"], "a": 0},
	{"q": "第四个问题：他在墙上写下的最后一句话是？", "opts": ["祝你成功", "不要开门", "救救我", "我恨你"], "a": 0},
	{"q": "第五个问题：门神生前的名字是？", "opts": ["陈卫国", "陈守楼", "王卫国", "李平安"], "a": 0},
	{"q": "最后一个问题：你——是什么时候死的？", "opts": ["7 天前", "昨天晚上", "我还没有死", "4444 年"], "a": 0},
]

func _butterfly_quiz() -> void:
	var score := 0
	for i in QUIZ.size():
		var q: Dictionary = QUIZ[i]
		var idx: int = await RitualUI.ask(q.q, q.opts)
		if idx == q.a:
			score += 1
			Sfx.play("chime")
			Dialog.say([["蝴蝶", "……对。下一个。"]])
		else:
			Sfx.play("static")
			Dialog.say([["蝴蝶", "错。你没有真的看见他们。"]])
		await Dialog.finished
	Game.flags["quiz_score"] = score
	Game.flags["butterfly_done"] = true
	if score >= 5:
		Dialog.say([["蝴蝶", "六个问题，你对 %d 个。" % score], ["蝴蝶", "你不是来上班的。你是真的来听他们说话的。"], ["蝴蝶", "明天早上，去看看你的电脑吧。然后——替我们，好好安息。"]])
	elif score >= 3:
		Dialog.say([["蝴蝶", "六个问题，你对 %d 个。" % score], ["蝴蝶", "你看见了他们，但还不够。还不够啊。"], ["蝴蝶", "明天会到来。但对你而言，明天永远是 Day 1。"]])
	else:
		Dialog.say([["蝴蝶", "六个问题，你只对了 %d 个。" % score], ["蝴蝶", "伪善者。你和那些扔石头的人，没有区别。"], ["蝴蝶", "留下来。守门。"]])
	await Dialog.finished
	Game.healed.append(4444)
	Game.save_game(-1, "res://src/scenes/world_3d.tscn")
	Sfx.heartbeat(false)
	_sleep_to_morning()

# ================= Day 7 · 真相与结局 =================
func _day7_step(lines: Array) -> void:
	Dialog.say(lines)
	await Dialog.finished
	day7_steps += 1
	if day7_steps >= 3:
		_ending()

func _ending() -> void:
	var score := int(Game.flags.get("quiz_score", 0))
	Game.flags["ending"] = "true" if score >= 5 else ("normal" if score >= 3 else "bad")
	await W.get_tree().create_timer(0.5).timeout
	if score >= 5:
		Dialog.say_center([
			"你想起了一切。",
			"七天前的雨夜，货车，刺眼的车灯。你没有躲开。",
			"你的执念只有一个：「想把一件事，好好做完。」",
			"现在，它做完了。",
			"——红裙子、外卖员、商人、管理员、门神，都安息了。",
			"这栋楼从今往后，是亡灵的中转站。",
			"而你，是它的楼长。",
			"《死楼》 · 真结局 ——「中转站」",
			"感谢游玩。",
		])
	elif score >= 3:
		Dialog.say_center([
			"你想起了一切。七天前的雨夜，货车，刺眼的车灯。",
			"但你没能治愈所有人。",
			"所以今晚 24:00，日历会自己翻回去——",
			"Day 8 就是 Day 1。记忆保留，循环继续。",
			"第 49 个管理员到来之前，你还有无数次机会。",
			"《死楼》 · 普通结局 ——「回魂夜」",
		])
	else:
		Dialog.say_center([
			"你想起了一切。七天前的雨夜，货车，刺眼的车灯。",
			"但你谁也不曾真正看见。",
			"蝴蝶收走了你的答案，也收走了你。",
			"从此 444 的门口多了一尊新的无头门神，",
			"等下一个管理员，带来下一颗「心」。",
			"《死楼》 · Bad Ending ——「门神」",
		])
	await Dialog.finished
	var idx: int = await RitualUI.ask("《死楼》", ["重新开始", "退出游戏"])
	if idx == 0:
		Game.new_game()
		SceneFlow.goto("res://src/scenes/world_3d.tscn")
	else:
		W.get_tree().quit()

# ================= 动画 =================
func _process(delta: float) -> void:
	_bf_t += delta
	# 4444 蝶群绕飞
	for bf in butterflies:
		if not is_instance_valid(bf): continue
		var ph: float = bf.get_meta("phase") + _bf_t * 0.9
		var r: float = bf.get_meta("radius")
		bf.position = Vector3(14.0 + cos(ph) * r, R4444_Y + bf.get_meta("height") + sin(_bf_t * 2.0 + ph) * 0.15, sin(ph) * r)
		bf.rotation.y = -ph
	# 404 前管理员：延迟 3 秒般缓慢模仿你的朝向
	if prev_ghost != null and prev_ghost.visible and W.player != null:
		if absf(prev_ghost.position.y - R404_Y) < 1.0 and absf(W.player.position.y - R404_Y) < 5.0:
			var to_player: float = atan2(W.player.position.x - prev_ghost.position.x, W.player.position.z - prev_ghost.position.z)
			prev_ghost.rotation.y = lerp_angle(prev_ghost.rotation.y, to_player, delta * 0.35)

func _on_xiaoli() -> void:
	if Game.day >= 4:
		Dialog.say(["（小李家门口贴着一张「房屋出租」。他也不见了。）"])
		return
	Dialog.say([
		["小李", "你是新来的管理员吧？我住 212。"],
		["小李", "你问 214 的小陈？……他一个月前失踪了。警察说可能是被绑架了。"],
		["小李", "他最后出现的地方，就是这栋楼。他妈妈到现在还在给他发邮件。"],
		["小李", "对了，他妈妈姓陈。邮箱我记得是 chen 开头，后面带着 520——小陈总说那是「妈妈我爱你」。"],
	])
	Game.add_journal("小李：214 的小陈一个月前失踪，最后出现在这栋楼。他妈妈的邮箱后三位是 520。")

# ================= 事件分发 =================
func handle(evt: String) -> bool:
	match evt:
		# ---- 楼梯 / 电梯 ----
		"stairs": _on_stairs()
		"elevator_x": _on_elevator_x()
		# ---- 房间门 ----
		"door_214": _room_door("214", "plate_214")
		"door_334": _room_door("334", "plate_334")
		"door_404": _room_door("404", "plate_404")
		"door_444": _room_door("444", "plate_444")
		"door_211", "door_212", "door_213":
			Dialog.say(["%s。里面住的是普通人家，日子过得很安静。" % evt.trim_prefix("door_")] if Game.phase != Game.Phase.NIGHT else ["%s。门后黑着灯。" % evt.trim_prefix("door_")])
		"door_331", "door_332", "door_333":
			Dialog.say(["%s。门缝里飘出炖汤的味道。" % evt.trim_prefix("door_")] if Game.phase != Game.Phase.NIGHT else ["%s。门牌摸上去是烫的。" % evt.trim_prefix("door_")])
		"door_441", "door_442", "door_443":
			Dialog.say(["%s。门口摆着火盆，盆里是剪碎的照片和头发编的小人。" % evt.trim_prefix("door_"), "（你不想知道为什么。）"])
		# ---- 走廊物件 ----
		"shoerack": Dialog.say(["公共鞋柜。最上面一层摆着一双小皮鞋，擦得很亮。", "（鞋柜标签：214·陈。他已经一个月没来取了。）"])
		"takeout_bag": Dialog.say(["门口挂着一袋外卖，备注写着：「放门口就行，谢谢小哥。」", "（下单时间是 32 天前。餐盒还是温的。）"])
		"xiaoli": _on_xiaoli()
		"pipe_f2": Dialog.say(["暖气管。铁皮上被人用指甲刻了一行小字：「妈妈生日快乐」。", "（刻痕很新。）"])
		"adwall": Dialog.say(["小广告墙：通下水、开锁、办证、高价回收。", "（最底下压着一张没有电话的传单，只有一句话：「招管理员。任期 7 天。」）"])
		"plant_f3": Dialog.say(["一盆枯死的绿萝。盆里插着一张物业费催缴单。", "（单子上 334 的欠费金额，被红笔划掉，改成了「已清」。）"])
		"sofa_f3": Dialog.say(["被扔掉的旧沙发。坐垫缝里塞着几张名片：「贾总·投资理财」。"])
		"boxes_f3": Dialog.say(["纸箱堆。最上面的箱子上印着「冥通银行·理财大礼包」。", "（箱子很轻。轻得像什么都没有。）"])
		"graffiti_f4": Dialog.say(["满墙的「4」和「不要开门」。字迹有几十种，像是几十个人写的。", "（最角落有一行新的，墨迹还没干：「轮到你了」。）"])
		"poster_f4": Dialog.say(["寻人启事。照片上的年轻人穿着深蓝色的管理员制服。", "（姓名栏是空的。——照片上的脸，越看越像你。）"])
		"brazier": Dialog.say(["火盆里没有纸钱，只有剪碎的照片和头发编的小人。", "（你翻了一下。照片里的人，全都没有头。）"])
		# ---- 214 线索 ----
		"c214_receipts": _clue("214", "c214_receipts", "30 张外卖单",
			"30 单，收件人全是「林先生」，地址全是 404，时间跨度一个月。",
			["（冰箱门上贴满了外卖单。你一张张看过去——）",
			 "30 单。收件人全是「林先生」，地址全是 404。时间跨度整整一个月。",
			 "（没有人会给同一个人连点 30 天外卖。除非——点单的人根本不是去送餐的。）"])
		"c214_phone": _clue("214", "c214_phone", "床底的手机",
			"碎屏手机里的最后一段录音：「我拍到他了，他在 404……」",
			["（床底下，一部碎屏手机还亮着。你按下播放键——）",
			 "「我拍到他了……他在 404……」（杂音）（搏斗声）（喘息声）",
			 "（然后，就什么都没有了。）"])
		"c214_peephole": _clue("214", "c214_peephole", "猫眼外的人",
			"猫眼里，一个戴鸭舌帽的男人在走廊徘徊。开门，走廊空无一人。",
			["（你凑近猫眼——）",
			 "（走廊上站着一个戴鸭舌帽的男人，一动不动，正对着这扇门。）",
			 "（你猛地拉开门。走廊空无一人。只有声控灯，啪，灭了。）"])
		"meter214": _on_meter214()
		"fan214": _on_fan214()
		"laptop214": _on_laptop214()
		"boxes214": Dialog.say(["成山的外卖盒，都发霉了。备注栏全是同一句话：「放门口就行。」", "（他调查的那一个月，自己吃的全是这些。）"])
		"freshbox": Dialog.say(["一份新鲜的外卖，还冒着热气。订单时间：昨天。", "（你昨天没有点过外卖。）", "（备注：「管理员辛苦了。——404」）"])
		"leave214": _leave_room("214", Vector3(8.0, F2_Y + 0.05, -0.6), PI)
		# ---- 334 线索 ----
		"c334_ledger": _clue("334", "c334_ledger", "账本",
			"账本记录了他如何一户一户骗钱。最后一页有一道算错的加法。",
			["（账本上密密麻麻：「王大妈：30 万，说能换新房」「李老头：50 万，说能办社保」……）",
			 "（翻到最后一页，是一道加法，算错了。他把年份也加了进去。）",
			 "（再往后一页，只有一行小字：「淑芬化疗的钱，还差 8 万。」）"])
		"c334_debt": _clue("334", "c334_debt", "床底的催债单",
			"高利贷催债单：「不还钱，就杀你全家。」",
			["（床底扫出一叠皱巴巴的纸。全是催债单。）",
			 "「最后期限：4 月 4 日。」「不还钱，就杀你全家。」",
			 "（他骗了全楼的钱，自己却也被别人逼到了墙角。）"])
		"c334_photo": _clue("334", "c334_photo", "被划掉的合影",
			"全楼合影上每个人的脸都被划掉了，只有他被红笔圈住，写着「下一个」。",
			["（床头柜上的合影：老贾和全楼住户。每个人的脸都被划掉了。）",
			 "（除了他自己——被红笔端端正正圈住，旁边写着「下一个」。）",
			 "（划掉别人脸的笔迹，和圈住他的笔迹，是同一只手的。）"])
		"tank334": _on_tank334()
		"safe334": _on_safe334()
		"money334": Dialog.say(["茶几上堆满了现金。你拿起一张——印着「冥通银行」。", "（全是冥币。一张一张，码得整整齐齐。）"])
		"sofa334": Dialog.say(["开裂的皮沙发。这是全楼最贵的家具，也是唯一没被当掉的东西。", "（他说，这是淑芬挑的。）"])
		"leave334": _leave_room("334", Vector3(8.0, F3_Y + 0.05, -0.6), PI)
		# ---- 404 线索 ----
		"c404_bed": _clue("404", "c404_bed", "一样的床",
			"床上叠着一件管理员制服，和你的一模一样。口袋里有封邀请函，名字被涂掉了。",
			["（床上叠着一件深蓝色工装，左胸的「幸福苑」logo 已经褪色。）",
			 "（和你身上这件，一模一样。）",
			 "（口袋里有一封邀请函。收件人的名字，被人用黑笔涂掉了。）"])
		"c404_log": _clue("404", "c404_log", "管理日志",
			"日志记录了他 365 天的尝试，字迹和你一模一样。",
			["（「Day 3：我治愈了商人，但他第二天又出现了。」）",
			 "（「Day 5：我意识到我在循环里。」）",
			 "（「Day 7：我杀了自己，但醒来了，又是 Day 1。」）",
			 "（这本日志的字迹，和你的一模一样。）"])
		"c404_window": _clue("404", "c404_window", "楼中楼",
			"窗外不是城市，是这栋楼本身。",
			["（你推开窗。窗外没有城市，没有夜空。）",
			 "（窗外是这栋楼本身——一模一样的窗户，一格一格，延伸到看不见的地方。）",
			 "（对面某一扇窗里，有个人也在看窗外。他挥了挥手。）",
			 "（你也下意识地，挥了挥手。动作分毫不差。）"])
		"mirror404": Dialog.say(["（镜子里站着的人穿着和你一样的制服。）", "（但你分不清那是他，还是你。）"])
		"prev_talk": _on_prev_talk()
		"inverted": Dialog.say(["（家具都钉在「天花板」上。你抬头看它们的时候，忽然分不清哪边是上。）", "（也许从一开始，倒过来的就是你自己。）"])
		"leave404": _leave_room("404", Vector3(8.0, F4_Y + 0.05, -0.6), PI)
		# ---- 444 线索 ----
		"c444_mirror": _clue("444", "c444_mirror", "镜中的门神",
			"镜中的无头人手里捧着的不是你的头——仔细看，是一枚红色的纽扣。",
			["（镜子里站着一个无头的人，手里捧着一个圆圆的东西。）",
			 "（你第一反应是你的头。但你仔细看——）",
			 "（那是一枚红色的纽扣。）",
			 "（他在等有人带来一颗「心」。）"])
		"c444_talisman": _clue("444", "c444_talisman", "发光的符咒",
			"靠近时符咒显出隐藏文字：「4 号楼不可入」。",
			["（你靠近符咒，纸面忽然泛起微光，浮出一行隐藏的字——）",
			 "「守门」「封邪」「4 号楼不可入」。",
			 "（落款是一个名字：陈卫国。）"])
		"c444_photo": _clue("444", "c444_photo", "暗格里的照片",
			"4 号楼的照片。这栋楼里，根本不存在 4 号楼。照片背面有签名。",
			["（你撬开暗格。里面是一张照片：一栋和这里一模一样的楼，门牌却是「4 号楼」。）",
			 "（这栋楼里，根本不存在 4 号楼。）",
			 "（照片背面有一行褪色的钢笔字：「陈卫国 · 摄于入职第一天」。）"])
		"doorgod": _on_doorgod()
		"leave444": _leave_room("444", Vector3(8.0, F4_Y + 0.05, -0.6), PI)
		# ---- 4444 ----
		"butterfly_voice": _on_butterfly_voice()
		"posters4444": Dialog.say(["（你一张张看过去。第 1 个管理员，第 2 个，第 3 个……第 47 个。）", "（最后一张海报是空白的，只印着一个编号：48。）"])
		"leave4444":
			if Game.flags.has("butterfly_done"):
				_leave_room("4444", Vector3(11.0, F4_Y + 0.05, 0.5), -PI/2)
			else:
				var idx: int = await RitualUI.ask("蝶群在你身后合拢。现在离开？", ["离开", "留下答题"])
				if idx == 0:
					Sfx.heartbeat(false)
					Game.lock_ui("teleport")
					await SceneFlow.fade_out(0.4)
					W.player.position = Vector3(11.0, F4_Y + 0.05, 0.5)
					W.player.set_look(-PI/2)
					await SceneFlow.fade_in(0.5)
					Game.unlock_ui("teleport")
		# ---- 管理员室逐日 ----
		"clock_evt": Dialog.say(["挂钟指着 3:34。它从入住第一天起就没动过——直到昨天夜里。", "（秒针每走一格，楼里就有什么东西，醒了一分。）"])
		"computer_evo":
			if Game.day >= 7:
				_day7_step([
					"（电脑自己开着。屏幕上是一份 PDF：）",
					"《死亡报告》——死因：车祸，失血过多。",
					"时间：7 天前，凌晨 3:33。",
					"死者姓名栏里，是你自己的名字。",
					"编号：第 48 号管理员。状态：确认死亡。",
				])
			else:
				Dialog.say(["（电脑自己开着。屏幕雪花里，一份文档的标题一闪而过：《死亡报告》。）", "（你伸手去点，它黑屏了。）", "（像它还没准备好让你看。）"])
		"cabinet7": _day7_step([
			"（铁皮柜的锁自己弹开了。）",
			"（里面挂着一件管理员制服，和你的一模一样——不，就是你的。）",
			"（左胸的名牌上绣着你的名字。你终于肯看清它了。）",
		])
		"invitation7": _day7_step([
			"（桌上的邀请函。你把它翻到背面——）",
			"（邮戳日期：7 天前。寄件地址：幸福苑 4444。）",
			"（原来它不是聘书。）",
			"（是回魂夜的门票。）",
		])
		# ---- 彩蛋 ----
		"egg_siqu": _egg("siqu", "「四蛆兄弟」传单", [
			"（小广告墙上钉着一张传单，四个 logo 端端正正印在同一张纸上——）",
			"华为的花瓣、转转的箭头、视觉中国的水印、字节跳动的音符。",
			"标题四个大字：「四蛆兄弟」。下面还有一行小字：「中国企业四大名著」。",
			"（这传单是谁印的？这栋楼里到底住过什么人？）",
		])
		"egg_cicada": _egg("cicada", "华为竹知了", [
			"（暖气片后面卡着一只竹篾编的知了。）",
			"竹黄的翅膀、竹黄的身子，肚子上工工整整刻着一朵红色花瓣，和一行小字：HUAWEI。",
			"（你碰了碰它。夏天的蝉鸣，好像从很远的地方响了一声。）",
			"（七月的风，再也吹不进这栋楼了。）",
		])
		_:
			return false
	return true
