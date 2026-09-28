extends Node3D
## 《死楼》3D 世界：走廊 + 管理员室 + 104 房间（第一人称）
## 三个区域在物理上分开（不同 Y 高度），门交互 = 开门动画 + 淡入淡出传送

const Inter3D := preload("res://src/objects/interactable_3d.gd")
const PlayerScene := preload("res://src/player/player_3d.tscn")
const ExtraRooms := preload("res://src/scenes/extra_rooms.gd")

const CLUE_IDS := ["sticky", "medical", "dress"]
const RITUAL_OPTIONS := [
	"你尽力了，这不是你的错。",
	"那些人太过分了，别理他们。",
	"你应该坚强一点，都会过去的。",
]
const COMMENTS := ["“怎么还不死”", "“博同情吧”", "“装的吧，举报了”", "“戏真多”", "“又想骗捐款？”"]

# 区域中心
const CORRIDOR_Y := 0.0
const ADMIN_Y := 40.0
const R104_Y := -40.0

var player: Player3D
var world_env: WorldEnvironment
var T := {}            # 贴图缓存
var lamps := []        # 走廊灯
var room_lights := []  # 104 红灯
var ghost: Node3D
var ghost_face: MeshInstance3D
var ghost_head: Node3D
var ghost_hairfall: MeshInstance3D
var wang: Node3D
var wang_face: MeshInstance3D
var wang_head: Node3D
var _talk_t := 0.0
var cabinet_drawer: MeshInstance3D
var wardrobe_door: MeshInstance3D
var drawer_104: MeshInstance3D
var door_104_inner: Node3D
var corridor_ghost: Node3D
var lamp_fixed := false
var corridor_evt_timer: Timer
var _idle_t := 0.0
var done := false
var extra  # ExtraRooms：2-4 楼走廊、214-4444 房间、彩蛋、结局
var phone_node: Area3D
var anomaly_timer: Timer
var comment_idx := 0
var blood_decals := []
var heal_mats := []   # [材质, 治愈后目标色]
var _door_meshes := {}

# 治愈时红色退潮的颜色映射 [原色, 目标色]
const HEAL_MAP := [
	[Color(0.55, 0.14, 0.13), Color(0.95, 0.93, 0.88)],      # 墙
	[Color(0.5225, 0.133, 0.1235), Color(0.9, 0.88, 0.84)],  # 天花（墙色*0.95）
	[Color(0.35, 0.09, 0.08), Color(0.72, 0.62, 0.5)],       # 地板
	[Color(0.5, 0.12, 0.11), Color(0.9, 0.88, 0.84)],        # 床单
	[Color(0.3, 0.07, 0.07), Color(0.5, 0.38, 0.28)],        # 衣柜
	[Color(0.36, 0.09, 0.09), Color(0.56, 0.43, 0.32)],      # 衣柜门
	[Color(0.5, 0.16, 0.15), Color(0.75, 0.68, 0.6)],        # 地毯
]

func _tex(name: String) -> Texture2D:
	if not T.has(name):
		T[name] = load("res://assets/tex/%s.png" % name)
	return T[name]

func _ready() -> void:
	Game.hud_visible = true
	done = Game.flags.has("room104_done")
	_build_environment()
	_build_corridor()
	_build_admin()
	_build_room104()
	extra = ExtraRooms.new()
	extra.setup(self)
	add_child(extra)
	extra.build_all()
	_spawn_player()
	_apply_phase_lighting(false)
	# 走廊恐怖事件计时器（夜晚生效）
	corridor_evt_timer = Timer.new()
	corridor_evt_timer.one_shot = true
	corridor_evt_timer.timeout.connect(_on_corridor_event)
	add_child(corridor_evt_timer)
	if Game.phase == Game.Phase.NIGHT:
		Sfx.music_night()
		corridor_evt_timer.start(randf_range(18.0, 30.0))
	else:
		Sfx.music_day()
	# 第一天开场
	if Game.day == 1 and not Game.flags.has("intro_done"):
		Game.flags["intro_done"] = true
		await get_tree().create_timer(0.8).timeout
		Dialog.say([
			"（你捏着那封没有署名的邀请函，站在管理员室里。）",
			"“诚邀您担任幸福苑公寓临时管理员。任期7天。期满后可继承本楼产权。”",
			"（失业第三个月。这种好事，怎么看都像骗局。）",
			"（但押金已经交了。七天，忍忍就过去了。）",
			"（WASD 移动 · 鼠标转视角 · E 互动 · Tab 日志 · F 手电 · Esc 菜单）",
		])
	elif Game.day >= 2:
		extra.morning_intro()

# ================= 基础搭建工具 =================
func _mat(tex: String, tint: Color, uv := Vector3(1,1,1), rough := 0.92) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if tex != "":
		m.albedo_texture = _tex(tex)
	m.albedo_color = tint
	m.roughness = rough
	if uv != Vector3(1,1,1):
		m.uv1_scale = uv
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, col := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	if mat: mi.material_override = mat
	parent.add_child(mi)
	if col:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		body.position = pos
		parent.add_child(body)
	return mi

func _cyl(parent: Node3D, r1: float, r2: float, h: float, pos: Vector3, mat: Material, col := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r1; cm.bottom_radius = r2; cm.height = h
	mi.mesh = cm
	mi.position = pos
	if mat: mi.material_override = mat
	parent.add_child(mi)
	if col:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(max(r1,r2)*2, h, max(r1,r2)*2)
		cs.shape = bs
		body.add_child(cs)
		body.position = pos
		parent.add_child(body)
	return mi

func _sphere(parent: Node3D, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r; sm.height = r*2
	mi.mesh = sm
	mi.position = pos
	if mat: mi.material_override = mat
	parent.add_child(mi)
	return mi

## 竖向贴片（墙面贴纸/血迹/海报等）。facing: +z / -z / +x / -x
func _decal(parent: Node3D, w: float, h: float, pos: Vector3, facing: String, tex: String, tint := Color.WHITE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, h)
	mi.mesh = pm
	mi.position = pos
	match facing:
		"+z": mi.rotation.x = PI/2
		"-z": mi.rotation.x = -PI/2
		"+x": mi.rotation = Vector3(PI/2, PI/2, 0)
		"-x": mi.rotation = Vector3(PI/2, -PI/2, 0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(tex)
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	mi.material_override = m
	parent.add_child(mi)
	return mi

func _floor_decal(parent: Node3D, w: float, pos: Vector3, tex: String, tint := Color.WHITE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, w)
	mi.mesh = pm
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(tex)
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	parent.add_child(mi)
	return mi

func _emissive_panel(parent: Node3D, w: float, h: float, pos: Vector3, facing: String, color: Color, energy := 1.2) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, h)
	mi.mesh = pm
	mi.position = pos
	match facing:
		"+z": mi.rotation.x = PI/2
		"-z": mi.rotation.x = -PI/2
		"+x": mi.rotation = Vector3(PI/2, PI/2, 0)
		"-x": mi.rotation = Vector3(PI/2, -PI/2, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	mi.material_override = m
	parent.add_child(mi)
	return mi

## 房间壳：地面/天花/四面墙。openings: [{wall:"n",at:偏移x,w:宽}]
func _room_shell(parent: Node3D, c: Vector3, w: float, d: float, h: float, tint: Color, floor_tint: Color, openings := []) -> void:
	_box(parent, Vector3(w, 0.1, d), c + Vector3(0, -0.05, 0), _mat("woodfloor", floor_tint, Vector3(w/2.2, d/2.2, 1)))
	_box(parent, Vector3(w, 0.1, d), c + Vector3(0, h+0.05, 0), _mat("ceiling", tint*0.95, Vector3(w/2.0, d/2.0, 1)))
	var wt := 0.15
	# 北墙 z=-d/2，南墙 z=+d/2，西墙 x=-w/2，东墙 x=+w/2
	for wall in ["n", "s", "e", "w"]:
		var segs := []
		var wall_len := w if wall in ["n","s"] else d
		var ops := openings.filter(func(o): return o.get("wall") == wall)
		if ops.is_empty():
			segs = [[-wall_len/2, wall_len/2, 0.0]]
		else:
			var o = ops[0]
			var ow: float = o.get("w", 1.1)
			var at: float = o.get("at", 0.0)
			segs = [[-wall_len/2, at-ow/2, 0.0], [at+ow/2, wall_len/2, 0.0]]
			# 门楣
			var lintel_len := ow
			var lp: Vector3
			var ls: Vector3
			if wall == "n": lp = c + Vector3(at, (h+2.1)/2.0, -d/2); ls = Vector3(lintel_len, h-2.1, wt)
			elif wall == "s": lp = c + Vector3(at, (h+2.1)/2.0, d/2); ls = Vector3(lintel_len, h-2.1, wt)
			elif wall == "e": lp = c + Vector3(w/2, (h+2.1)/2.0, at); ls = Vector3(wt, h-2.1, lintel_len)
			else: lp = c + Vector3(-w/2, (h+2.1)/2.0, at); ls = Vector3(wt, h-2.1, lintel_len)
			_box(parent, ls, lp, _mat("wallpaper", tint, Vector3(lintel_len/2, (h-2.1)/2, 1)))
		for s in segs:
			var mid: float = (s[0]+s[1])/2.0
			var ln: float = abs(s[1]-s[0])
			if ln < 0.01: continue
			var sp: Vector3
			var ss: Vector3
			if wall == "n": sp = c + Vector3(mid, h/2, -d/2); ss = Vector3(ln, h, wt)
			elif wall == "s": sp = c + Vector3(mid, h/2, d/2); ss = Vector3(ln, h, wt)
			elif wall == "e": sp = c + Vector3(w/2, h/2, mid); ss = Vector3(wt, h, ln)
			else: sp = c + Vector3(-w/2, h/2, mid); ss = Vector3(wt, h, ln)
			_box(parent, ss, sp, _mat("wallpaper", tint, Vector3(ln/2.2, h/2.2, 1)))

func _door_prop(parent: Node3D, pos: Vector3, facing: String, plate: String) -> MeshInstance3D:
	# 门板（可绕轴转动开门）
	var pivot := Node3D.new()
	pivot.position = pos
	match facing:
		"+z": pivot.rotation.y = 0.0
		"-z": pivot.rotation.y = PI
		"+x": pivot.rotation.y = PI/2
		"-x": pivot.rotation.y = -PI/2
	parent.add_child(pivot)
	var door_mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 2.1, 0.08)
	door_mi.mesh = bm
	door_mi.position = Vector3(0.5, 1.05, 0)
	door_mi.material_override = _mat("door", Color.WHITE, Vector3(1,1,1))
	pivot.add_child(door_mi)
	# 门牌
	if plate != "":
		var pm := MeshInstance3D.new()
		var plm := PlaneMesh.new()
		plm.size = Vector2(0.44, 0.22)
		pm.mesh = plm
		pm.position = Vector3(0.5, 2.35, 0.06)
		pm.rotation.x = PI/2
		pm.material_override = _mat(plate, Color.WHITE)
		pivot.add_child(pm)
	_door_meshes[plate] = pivot
	return door_mi

func _lamp(parent: Node3D, pos: Vector3, warm := true) -> OmniLight3D:
	_cyl(parent, 0.02, 0.02, 0.25, pos + Vector3(0, 0.22, 0), _mat("", Color(0.15,0.13,0.1)))
	_cyl(parent, 0.16, 0.05, 0.14, pos, _mat("", Color(0.25,0.2,0.14)))
	var bulb := _sphere(parent, 0.07, pos - Vector3(0, 0.08, 0), _mat("", Color(1,0.95,0.8)))
	var bm := StandardMaterial3D.new()
	bm.emission_enabled = true
	bm.emission = Color(1, 0.9, 0.7) if warm else Color(0.7, 0.85, 1.0)
	bm.emission_energy_multiplier = 2.0
	bulb.material_override = bm
	var li := OmniLight3D.new()
	li.position = pos - Vector3(0, 0.25, 0)
	li.light_color = Color(1, 0.87, 0.66) if warm else Color(0.62, 0.74, 0.95)
	li.light_energy = 0.9
	li.omni_range = 7.0
	li.omni_attenuation = 1.4
	parent.add_child(li)
	lamps.append(li)
	return li

func _interact(parent: Node, pos: Vector3, evt: String, prompt: String, size := Vector3(0.7, 0.7, 0.7)) -> Area3D:
	var a := Area3D.new()
	a.set_script(Inter3D)
	a.setup(pos, evt, prompt, size)
	a.used.connect(_on_used)
	parent.add_child(a)
	return a

# ================= 环境 =================
func _build_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.8, 0.66)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.fog_enabled = false
	world_env.environment = env
	add_child(world_env)

func _apply_phase_lighting(animate := true) -> void:
	var env := world_env.environment
	var night := Game.phase == Game.Phase.NIGHT
	var target_amb: Color = Color(0.24, 0.3, 0.46) if night else Color(0.9, 0.8, 0.66)
	var target_energy := 0.16 if night else 0.5
	if animate:
		var t := create_tween().set_parallel(true)
		t.tween_property(env, "ambient_light_color", target_amb, 1.2)
		t.tween_property(env, "ambient_light_energy", target_energy, 1.2)
	else:
		env.ambient_light_color = target_amb
		env.ambient_light_energy = target_energy
	env.fog_enabled = night
	if night:
		env.fog_light_color = Color(0.1, 0.13, 0.22)
		env.fog_density = 0.035
	for i in lamps.size():
		var li: OmniLight3D = lamps[i]
		if night:
			li.light_energy = 0.3 if i != 1 else 0.12   # 第二盏灯接触不良
		else:
			li.light_energy = 0.9
	if wang:
		wang.visible = not night   # 王大妈晚上回屋睡觉
	if lamp_fixed and lamps.size() > 1 and night:
		lamps[1].light_energy = 0.9

# ================= 走廊 =================
func _build_corridor() -> void:
	var root := Node3D.new()
	root.name = "Corridor"
	add_child(root)
	var c := Vector3(0, CORRIDOR_Y, 0)
	_room_shell(root, c + Vector3(0, 0, 0), 24.0, 3.0, 3.0,
		Color(0.95, 0.85, 0.68), Color(0.75, 0.6, 0.42),
		[{"wall":"n","at":-8.0,"w":1.1},{"wall":"n","at":-2.7,"w":1.1},
		 {"wall":"n","at":2.7,"w":1.1},{"wall":"n","at":8.0,"w":1.1},
		 {"wall":"w","at":0.0,"w":1.1}])
	# 门 + 门牌（北侧四个房间，西端管理员室）
	_door_prop(root, c + Vector3(-8.5, 0, -1.5), "+z", "plate_101")
	_door_prop(root, c + Vector3(-3.2, 0, -1.5), "+z", "plate_102")
	_door_prop(root, c + Vector3(2.2, 0, -1.5), "+z", "plate_103")
	_door_prop(root, c + Vector3(7.5, 0, -1.5), "+z", "plate_104")
	_door_prop(root, c + Vector3(-12.0, 0, 0.5), "+x", "")
	# 顶灯
	for lx in [-8.0, 0.0, 8.0]:
		_lamp(root, c + Vector3(lx, 2.82, 0), true)
	# 电梯（东端）：门框 + 双开门（关着）+ 楼层屏
	_box(root, Vector3(0.2, 2.6, 1.6), c + Vector3(11.9, 1.3, 0), _mat("", Color(0.3,0.32,0.36)))
	_box(root, Vector3(0.06, 2.2, 0.75), c + Vector3(11.8, 1.1, -0.38), _mat("", Color(0.55,0.58,0.62), Vector3(1,1,1), 0.4))
	_box(root, Vector3(0.06, 2.2, 0.75), c + Vector3(11.8, 1.1, 0.38), _mat("", Color(0.55,0.58,0.62), Vector3(1,1,1), 0.4))
	_emissive_panel(root, 0.5, 0.2, c + Vector3(11.78, 2.5, 0), "-x", Color(0.9, 0.3, 0.25), 2.0)
	# 走廊杂物：暖气片/灭火器/小柜
	_box(root, Vector3(1.2, 0.8, 0.25), c + Vector3(-5.5, 0.4, 1.3), _mat("", Color(0.7,0.68,0.62)))
	_cyl(root, 0.09, 0.09, 0.5, c + Vector3(5.2, 0.25, 1.25), _mat("", Color(0.7,0.15,0.12)))
	# 公告栏（南墙）
	_box(root, Vector3(1.4, 0.9, 0.05), c + Vector3(-0.5, 1.6, 1.42), _mat("", Color(0.5,0.38,0.24)), false)
	for i in 3:
		_box(root, Vector3(0.3, 0.4, 0.02), c + Vector3(-0.95 + i*0.45, 1.62, 1.39), _mat("", [Color(0.92,0.9,0.82), Color(0.85,0.82,0.7), Color(0.95,0.88,0.75)][i]), false)
	# 103 门口快递堆
	_box(root, Vector3(0.5, 0.35, 0.4), c + Vector3(3.4, 0.18, -1.1), _mat("", Color(0.62,0.5,0.34)))
	_box(root, Vector3(0.4, 0.3, 0.35), c + Vector3(3.5, 0.5, -1.15), _mat("", Color(0.58,0.46,0.3)))
	_box(root, Vector3(0.35, 0.25, 0.3), c + Vector3(3.25, 0.72, -1.1), _mat("", Color(0.66,0.54,0.38)))
	# 电表箱（北墙东侧，夜晚可"修"闪烁的灯）
	_box(root, Vector3(0.5, 0.7, 0.12), c + Vector3(5.6, 1.5, -1.42), _mat("", Color(0.4,0.42,0.45), Vector3(1,1,1), 0.5), false)
	_box(root, Vector3(0.36, 0.2, 0.04), c + Vector3(5.6, 1.62, -1.36), _mat("", Color(0.2,0.22,0.25)), false)
	# 保洁桶+拖把
	_cyl(root, 0.22, 0.18, 0.35, c + Vector3(-9.8, 0.18, 1.1), _mat("", Color(0.3,0.45,0.55)))
	_cyl(root, 0.02, 0.02, 1.3, c + Vector3(-9.6, 0.65, 1.15), _mat("", Color(0.6,0.5,0.35))).rotation.z = 0.18
	# 走廊尽头的"她"（夜晚闪现用，平时隐藏）
	corridor_ghost = _build_ghost(root, c + Vector3(10.8, 0.0, 0))
	corridor_ghost.rotation.y = -PI/2
	corridor_ghost.hide()
	# 王大妈（白天）
	_build_wang(root, c + Vector3(0.5, 0, 0.9))
	# 交互
	_interact(root, c + Vector3(-8.0, 1.2, -1.2), "door_101", "101 · 王大妈家", Vector3(1.1, 2.0, 0.6))
	_interact(root, c + Vector3(-2.7, 1.2, -1.2), "door_102", "102", Vector3(1.1, 2.0, 0.6))
	_interact(root, c + Vector3(2.7, 1.2, -1.2), "door_103", "103", Vector3(1.1, 2.0, 0.6))
	_interact(root, c + Vector3(8.0, 1.2, -1.2), "door_104", "104 · 红裙子", Vector3(1.1, 2.0, 0.6))
	_interact(root, c + Vector3(-11.6, 1.2, 0.5), "door_admin", "管理员室", Vector3(0.6, 2.0, 1.1))
	_interact(root, c + Vector3(11.5, 1.3, 0), "elevator", "电梯", Vector3(0.8, 2.4, 1.4))
	_interact(root, c + Vector3(0.5, 1.0, 0.9), "wang", "王大妈", Vector3(0.9, 1.6, 0.9))
	_interact(root, c + Vector3(-0.5, 1.6, 1.3), "notice", "公告栏", Vector3(1.4, 0.9, 0.4))
	_interact(root, c + Vector3(3.4, 0.5, -1.0), "packages", "快递堆", Vector3(0.8, 0.9, 0.6))
	_interact(root, c + Vector3(5.6, 1.5, -1.3), "meter", "电表箱", Vector3(0.6, 0.8, 0.4))
	_interact(root, c + Vector3(5.2, 0.4, 1.2), "extinguisher", "灭火器", Vector3(0.4, 0.6, 0.4))
	_interact(root, c + Vector3(-9.8, 0.4, 1.1), "bucket", "保洁桶", Vector3(0.6, 0.6, 0.6))

func _build_wang(parent: Node3D, pos: Vector3) -> void:
	wang = Node3D.new()
	wang.name = "Wang"
	wang.position = pos
	parent.add_child(wang)
	# 身体：圆柱体量 + 正面贴图（围裙碎花）
	_cyl(wang, 0.24, 0.32, 1.0, Vector3(0, 0.5, 0), _mat("", Color(0.48, 0.23, 0.26)))
	var body_plane := MeshInstance3D.new()
	var bp := PlaneMesh.new()
	bp.size = Vector2(0.72, 1.44)
	body_plane.mesh = bp
	body_plane.position = Vector3(0, 0.72, 0.3)
	body_plane.rotation.x = PI/2
	var bm := StandardMaterial3D.new()
	bm.albedo_texture = _tex("wang_body")
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.roughness = 0.9
	body_plane.material_override = bm
	wang.add_child(body_plane)
	# 手臂（袖管）
	_cyl(wang, 0.07, 0.06, 0.55, Vector3(-0.3, 0.75, 0.05), _mat("", Color(0.48, 0.23, 0.26))).rotation.z = 0.25
	_cyl(wang, 0.07, 0.06, 0.55, Vector3(0.3, 0.75, 0.05), _mat("", Color(0.48, 0.23, 0.26))).rotation.z = -0.25
	# 头部组（可点头/转向）
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.22, 0)
	wang.add_child(head)
	_sphere(head, 0.2, Vector3(0, 0, 0), _mat("", Color(0.92, 0.78, 0.66)))          # 脸体量
	_sphere(head, 0.21, Vector3(0, 0.07, -0.05), _mat("", Color(0.62, 0.6, 0.58)))   # 发
	_sphere(head, 0.1, Vector3(0, 0.24, -0.08), _mat("", Color(0.62, 0.6, 0.58)))    # 髻
	var fp := MeshInstance3D.new()
	var fpm := PlaneMesh.new()
	fpm.size = Vector2(0.36, 0.36)
	fp.mesh = fpm
	fp.position = Vector3(0, -0.01, 0.19)
	fp.rotation.x = PI/2
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = _tex("wang_face")
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	fp.material_override = fm
	head.add_child(fp)
	wang_face = fp
	wang_head = head
	wang.rotation.y = PI

# ================= 管理员室 =================
func _build_admin() -> void:
	var root := Node3D.new()
	root.name = "Admin"
	add_child(root)
	var c := Vector3(0, ADMIN_Y, 0)
	_room_shell(root, c, 6.0, 5.0, 3.0, Color(0.95, 0.85, 0.68), Color(0.75, 0.6, 0.42),
		[{"wall":"e","at":0.0,"w":1.1}])
	_door_prop(root, c + Vector3(2.5, 0, 0.5), "-x", "")
	# 窗（带光）
	_box(root, Vector3(0.05, 1.5, 1.3), c + Vector3(-2.945, 1.7, 0.8), _mat("", Color(0.35,0.28,0.2)))
	_emissive_panel(root, 1.2, 1.4, c + Vector3(-2.915, 1.7, 0.8), "+x", Color(1.0, 0.95, 0.8), 1.5)
	# 办公桌
	_box(root, Vector3(2.0, 0.08, 0.9), c + Vector3(-0.5, 0.78, -1.6), _mat("", Color(0.42,0.28,0.17)))
	for dx in [-1.35, 0.35]:
		for dz in [-1.95, -1.25]:
			_box(root, Vector3(0.08, 0.78, 0.08), c + Vector3(dx, 0.39, dz), _mat("", Color(0.34,0.22,0.13)))
	# 桌上：台灯/文件/电话/茶杯
	_cyl(root, 0.03, 0.06, 0.3, c + Vector3(-1.2, 0.95, -1.8), _mat("", Color(0.16,0.15,0.14)))
	_sphere(root, 0.09, c + Vector3(-1.2, 1.14, -1.8), _mat("", Color(1,0.95,0.7)))
	_box(root, Vector3(0.4, 0.1, 0.3), c + Vector3(-0.6, 0.87, -1.5), _mat("", Color(0.94,0.92,0.85)))
	_box(root, Vector3(0.3, 0.16, 0.24), c + Vector3(0.1, 0.9, -1.7), _mat("", Color(0.14,0.14,0.16)))
	_cyl(root, 0.06, 0.05, 0.12, c + Vector3(-0.9, 0.88, -1.4), _mat("", Color(0.9,0.88,0.82)))
	# 台灯点光
	var dl := OmniLight3D.new()
	dl.position = c + Vector3(-1.2, 1.3, -1.8)
	dl.light_color = Color(1, 0.88, 0.62)
	dl.light_energy = 0.7
	dl.omni_range = 4.0
	root.add_child(dl)
	# 椅子
	_box(root, Vector3(0.5, 0.06, 0.5), c + Vector3(-0.5, 0.45, -0.8), _mat("", Color(0.3,0.2,0.12)))
	_box(root, Vector3(0.5, 0.55, 0.06), c + Vector3(-0.5, 0.75, -0.58), _mat("", Color(0.3,0.2,0.12)))
	# 文件柜
	_box(root, Vector3(0.6, 1.6, 0.5), c + Vector3(-2.5, 0.8, -1.9), _mat("", Color(0.42,0.36,0.28)))
	for i in 4:
		_box(root, Vector3(0.5, 0.32, 0.04), c + Vector3(-2.5, 0.3+i*0.38, -1.64), _mat("", Color(0.5,0.43,0.33)))
	# 日历 + 海报 + 公告板
	_decal(root, 0.45, 0.56, c + Vector3(0.6, 1.8, -2.42), "+z", "calendar")
	_decal(root, 0.8, 0.6, c + Vector3(1.8, 1.75, -2.42), "+z", "poster")
	_box(root, Vector3(1.0, 0.7, 0.04), c + Vector3(-1.5, 1.8, -2.43), _mat("", Color(0.6,0.45,0.28)))
	# 书架 + 书
	_box(root, Vector3(0.9, 1.8, 0.35), c + Vector3(2.4, 0.9, -2.2), _mat("", Color(0.4,0.28,0.17)))
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 8
	for shelf in 3:
		var bx := 2.05
		while bx < 2.7:
			var bw := rnd.randf_range(0.04, 0.08)
			var col: Color = [Color(0.6,0.25,0.2), Color(0.25,0.35,0.5), Color(0.35,0.45,0.28), Color(0.7,0.55,0.25)][rnd.randi() % 4]
			_box(root, Vector3(bw, 0.32, 0.22), c + Vector3(bx, 0.5+shelf*0.5, -2.2), _mat("", col), false)
			bx += bw + 0.015
	# 地毯
	_floor_decal(root, 2.4, c + Vector3(-0.5, 0.006, -0.2), "woodfloor", Color(0.7, 0.4, 0.32))
	# 沙发（绿色布艺，可休息）
	_box(root, Vector3(1.6, 0.35, 0.7), c + Vector3(1.6, 0.18, 1.9), _mat("", Color(0.32, 0.42, 0.3)))
	_box(root, Vector3(1.6, 0.55, 0.18), c + Vector3(1.6, 0.6, 2.2), _mat("", Color(0.3, 0.4, 0.28)))
	_box(root, Vector3(0.18, 0.5, 0.7), c + Vector3(0.85, 0.42, 1.9), _mat("", Color(0.3, 0.4, 0.28)))
	_box(root, Vector3(0.18, 0.5, 0.7), c + Vector3(2.35, 0.42, 1.9), _mat("", Color(0.3, 0.4, 0.28)))
	_box(root, Vector3(0.5, 0.14, 0.3), c + Vector3(1.2, 0.42, 2.0), _mat("", Color(0.7, 0.62, 0.4)), false)  # 靠枕
	# 钥匙板（墙上挂着各房间钥匙）
	_box(root, Vector3(0.7, 0.4, 0.03), c + Vector3(2.2, 1.7, -2.44), _mat("", Color(0.55, 0.42, 0.26)), false)
	for i in 4:
		_box(root, Vector3(0.03, 0.1, 0.03), c + Vector3(1.95 + i*0.17, 1.62, -2.42), _mat("", Color(0.75, 0.7, 0.55), Vector3(1,1,1), 0.35), false)
	# 文件柜抽屉（可拉开）
	cabinet_drawer = _box(root, Vector3(0.5, 0.3, 0.4), c + Vector3(-2.5, 0.49, -1.78), _mat("", Color(0.55, 0.47, 0.36)), false)
	# 交互
	_interact(root, c + Vector3(0.1, 1.0, -1.7), "phone", "电话", Vector3(0.5, 0.5, 0.5))
	_interact(root, c + Vector3(-0.8, 0.9, -1.6), "desk", "办公桌", Vector3(1.0, 0.9, 0.9))
	_interact(root, c + Vector3(2.9, 1.2, 0.5), "exit_admin", "出门", Vector3(0.6, 2.0, 1.1))
	_interact(root, c + Vector3(1.6, 0.5, 1.9), "sofa", "旧沙发", Vector3(1.4, 0.8, 0.8))
	_interact(root, c + Vector3(-2.5, 0.6, -1.7), "cabinet", "文件柜", Vector3(0.7, 1.4, 0.6))
	_interact(root, c + Vector3(2.4, 1.1, -2.1), "bookshelf", "书架", Vector3(0.9, 1.8, 0.5))
	_interact(root, c + Vector3(0.6, 1.8, -2.3), "calendar_evt", "日历", Vector3(0.5, 0.6, 0.3))
	_interact(root, c + Vector3(2.2, 1.7, -2.3), "keyrack", "钥匙板", Vector3(0.7, 0.5, 0.3))
	_interact(root, c + Vector3(-2.8, 1.6, 0.8), "window_admin", "窗户", Vector3(0.4, 1.5, 1.3))

# ================= 104 房间 =================
func _build_room104() -> void:
	var root := Node3D.new()
	root.name = "Room104"
	add_child(root)
	var c := Vector3(0, R104_Y, 0)
	var wall_tint := Color(0.55, 0.14, 0.13) if not done else Color(0.95, 0.93, 0.88)
	var floor_tint := Color(0.35, 0.09, 0.08) if not done else Color(0.72, 0.62, 0.5)
	_room_shell(root, c, 6.0, 7.0, 3.0, wall_tint, floor_tint,
		[{"wall":"s","at":2.2,"w":1.1}])
	_door_prop(root, c + Vector3(1.7, 0, 3.5), "-z", "")
	door_104_inner = _door_meshes[""]
	# 窗（夜晚）
	_box(root, Vector3(1.3, 1.5, 0.06), c + Vector3(-1.2, 1.7, -3.45), _mat("", Color(0.2,0.16,0.12)))
	_emissive_panel(root, 1.2, 1.4, c + Vector3(-1.2, 1.7, -3.415), "+z",
		Color(0.16, 0.2, 0.34) if not done else Color(0.95, 0.93, 0.85), 1.2)
	# 床
	_box(root, Vector3(1.4, 0.35, 2.2), c + Vector3(-2.0, 0.35, -1.6), _mat("", Color(0.3,0.2,0.14)))
	_box(root, Vector3(1.3, 0.18, 2.0), c + Vector3(-2.0, 0.6, -1.6), _mat("", Color(0.5,0.12,0.11) if not done else Color(0.9,0.88,0.84)))
	_box(root, Vector3(0.5, 0.12, 0.35), c + Vector3(-2.0, 0.68, -2.4), _mat("", Color(0.85,0.8,0.75)))
	# 床底纸箱（露出一个角）
	_box(root, Vector3(0.55, 0.25, 0.45), c + Vector3(-1.55, 0.13, -0.62), _mat("", Color(0.6,0.48,0.32)))
	# 地毯（床尾）
	_floor_decal(root, 1.6, c + Vector3(-0.8, 0.007, 0.6), "woodfloor", Color(0.5,0.16,0.15) if not done else Color(0.75,0.68,0.6))
	# 床头柜 + 收音机 + 病历
	_box(root, Vector3(0.55, 0.5, 0.5), c + Vector3(-1.0, 0.25, -2.6), _mat("", Color(0.35,0.24,0.16)))
	_box(root, Vector3(0.3, 0.16, 0.2), c + Vector3(-1.0, 0.58, -2.6), _mat("", Color(0.16,0.15,0.14)))
	_box(root, Vector3(0.28, 0.02, 0.2), c + Vector3(-0.7, 0.51, -2.55), _mat("", Color(0.93,0.9,0.85)), false)
	drawer_104 = _box(root, Vector3(0.4, 0.14, 0.32), c + Vector3(-1.0, 0.32, -2.5), _mat("", Color(0.42,0.3,0.2)), false)
	# 衣柜（带可滑开的门）
	_box(root, Vector3(1.2, 2.2, 0.6), c + Vector3(1.6, 1.1, -3.1), _mat("", Color(0.3,0.07,0.07) if not done else Color(0.5,0.38,0.28)))
	wardrobe_door = _box(root, Vector3(0.55, 2.0, 0.05), c + Vector3(1.33, 1.1, -2.78), _mat("", Color(0.36,0.09,0.09) if not done else Color(0.56,0.43,0.32)), false)
	# 镜子 + 边框
	_box(root, Vector3(0.5, 1.9, 0.08), c + Vector3(2.9, 1.2, -0.9), _mat("", Color(0.35,0.25,0.15)))
	_decal(root, 0.4, 1.75, c + Vector3(2.85, 1.2, -0.9), "-x", "mirror")
	# 浴室门（虚掩的黑暗）
	_box(root, Vector3(0.9, 2.1, 0.1), c + Vector3(-2.5, 1.05, 3.5), _mat("", Color(0.08,0.05,0.05)))
	# 便利贴墙
	_decal(root, 2.6, 1.9, c + Vector3(-0.6, 1.7, -3.41), "+z", "stickywall")
	# 血迹
	if not done:
		blood_decals.append(_decal(root, 3.0, 2.2, c + Vector3(0.8, 2.2, -3.41), "+z", "blood_drips"))
		blood_decals.append(_decal(root, 2.0, 1.6, c + Vector3(-2.91, 1.8, 0.8), "+x", "blood_drips"))
		blood_decals.append(_floor_decal(root, 2.2, c + Vector3(-1.6, 0.01, 1.4), "blood_pool"))
		blood_decals.append(_floor_decal(root, 1.4, c + Vector3(-2.2, 0.01, 2.6), "blood_pool"))
	# 红灯（治愈后变暖白）
	for lp in [c + Vector3(-1.5, 2.5, -1.0), c + Vector3(1.5, 2.5, 1.5)]:
		var li := OmniLight3D.new()
		li.position = lp
		li.light_color = Color(1.0, 0.22, 0.18) if not done else Color(1.0, 0.95, 0.85)
		li.light_energy = 1.1
		li.omni_range = 8.0
		root.add_child(li)
		room_lights.append(li)
	# 手机（床上，微光）
	_box(root, Vector3(0.14, 0.03, 0.24), c + Vector3(-1.7, 0.72, -1.0), _mat("", Color(0.1,0.1,0.12)), false)
	var phone_glow := _emissive_panel(root, 0.12, 0.2, c + Vector3(-1.7, 0.75, -1.0), "+z", Color(0.5, 0.7, 0.9), 1.0)
	phone_glow.rotation.x = 0
	phone_glow.rotation = Vector3(0, 0, 0)   # 平躺
	# 鬼（初始隐藏，镜子事件/治愈演出用）
	ghost = _build_ghost(root, c + Vector3(2.55, 0.0, -0.9))
	ghost.hide()
	# 交互
	_interact(root, c + Vector3(-0.6, 1.6, -3.2), "sticky", "满墙的便利贴", Vector3(2.4, 1.6, 0.5))
	_interact(root, c + Vector3(-0.7, 0.6, -2.55), "medical", "床头柜上的病历", Vector3(0.6, 0.5, 0.5))
	_interact(root, c + Vector3(1.6, 1.2, -2.8), "dress", "衣柜", Vector3(1.2, 1.8, 0.7))
	_interact(root, c + Vector3(-1.0, 0.62, -2.6), "radio", "收音机", Vector3(0.45, 0.4, 0.4))
	_interact(root, c + Vector3(2.75, 1.2, -0.9), "mirror", "穿衣镜", Vector3(0.5, 1.6, 0.8))
	phone_node = _interact(root, c + Vector3(-1.7, 0.75, -1.0), "phone104", "床上的手机", Vector3(0.5, 0.4, 0.5))
	phone_node.set_enabled(false)
	_interact(root, c + Vector3(-2.5, 1.2, 3.3), "bathroom", "浴室", Vector3(0.9, 1.8, 0.5))
	_interact(root, c + Vector3(2.2, 1.2, 3.3), "leave", "离开 104", Vector3(1.1, 2.0, 0.5))
	_interact(root, c + Vector3(-1.0, 0.35, -2.4), "drawer", "床头柜抽屉", Vector3(0.5, 0.4, 0.4))
	_interact(root, c + Vector3(-1.55, 0.25, -0.62), "under_bed", "床底的纸箱", Vector3(0.7, 0.4, 0.6))
	_interact(root, c + Vector3(-1.2, 1.6, -3.3), "windowsill", "窗台", Vector3(1.3, 1.0, 0.4))
	_interact(root, c + Vector3(-0.8, 0.2, 0.6), "rug", "旧地毯", Vector3(1.4, 0.4, 1.4))
	# 异常事件计时器
	anomaly_timer = Timer.new()
	anomaly_timer.one_shot = true
	anomaly_timer.timeout.connect(_on_anomaly)
	add_child(anomaly_timer)
	if not done:
		_collect_heal_mats(root)

## 收集治愈时需要退红的材质（按 HEAL_MAP 原色匹配）
func _collect_heal_mats(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var m = child.material_override
			if m is StandardMaterial3D:
				for pair in HEAL_MAP:
					var c: Color = m.albedo_color
					var p: Color = pair[0]
					if absf(c.r - p.r) < 0.01 and absf(c.g - p.g) < 0.01 and absf(c.b - p.b) < 0.01:
						heal_mats.append([m, pair[1]])
						break
		_collect_heal_mats(child)

func _build_ghost(parent: Node3D, pos: Vector3) -> Node3D:
	var g := Node3D.new()
	g.name = "Ghost"
	g.position = pos
	parent.add_child(g)
	# 裙子：锥形体量 + 红裙贴图（褶皱/裙摆污渍）
	var dm := StandardMaterial3D.new()
	dm.albedo_texture = _tex("ghost_dress")
	dm.roughness = 0.95
	var dress := _cyl(g, 0.06, 0.46, 1.2, Vector3(0, 0.62, 0), dm)
	dress.name = "Dress"
	# 手臂（苍白，垂着）
	_cyl(g, 0.045, 0.04, 0.6, Vector3(-0.16, 0.95, 0.02), _mat("", Color(0.88, 0.84, 0.8))).rotation.z = 0.12
	_cyl(g, 0.045, 0.04, 0.6, Vector3(0.16, 0.95, 0.02), _mat("", Color(0.88, 0.84, 0.8))).rotation.z = -0.12
	# 头部组（可歪头/鞠躬）
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.42, 0)
	g.add_child(head)
	ghost_head = head
	_sphere(head, 0.21, Vector3(0, 0, 0), _mat("", Color(0.91, 0.87, 0.83)))          # 脸体量
	_sphere(head, 0.22, Vector3(0, 0.08, -0.05), _mat("", Color(0.08, 0.05, 0.06)))   # 发顶
	var hf := _cyl(head, 0.17, 0.21, 0.62, Vector3(0, -0.32, -0.13), _mat("", Color(0.08, 0.05, 0.06)))  # 垂发
	hf.name = "HairFall"
	ghost_hairfall = hf
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.4, 0.4)
	ghost_face = MeshInstance3D.new()
	ghost_face.mesh = pm
	ghost_face.position = Vector3(0, 0, 0.2)
	ghost_face.rotation.x = PI/2
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = _tex("ghost_face_hair")
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost_face.material_override = fm
	head.add_child(ghost_face)
	return g

func _set_ghost_face(name: String) -> void:
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = _tex(name)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost_face.material_override = fm

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if ghost and ghost.visible:
		ghost.position.y += sin(t * 2.0) * 0.0008          # 漂浮
		if ghost_hairfall:
			ghost_hairfall.rotation.z = sin(t * 1.6) * 0.06   # 垂发飘动
	if wang and player and Game.phase != Game.Phase.NIGHT:
		var to_p: Vector3 = player.global_position - wang.global_position
		var dist := Vector2(to_p.x, to_p.z).length()
		if dist < 5.0 and abs(to_p.y) < 3.0:
			# 面向玩家 + 呼吸感 + 说话时换嘴型
			var target_yaw := atan2(to_p.x, to_p.z)
			wang.rotation.y = lerp_angle(wang.rotation.y, target_yaw, 0.08)
			wang.scale.y = 1.0 + sin(t * 2.2) * 0.012
			_talk_t += _delta
			if _talk_t > 0.28:
				_talk_t = 0.0
				var talking := Dialog.active and dist < 3.0
				var fm := StandardMaterial3D.new()
				fm.albedo_texture = _tex("wang_face_talk" if talking else "wang_face")
				fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				fm.cull_mode = BaseMaterial3D.CULL_DISABLED
				wang_face.material_override = fm
	# 挂机惩罚：夜晚在走廊站太久，灯会替你"闭眼"
	if player and Game.phase == Game.Phase.NIGHT and abs(player.position.y - CORRIDOR_Y) < 3.0 and not Game.ui_locked():
		if player.velocity.length() < 0.1:
			_idle_t += _delta
		else:
			_idle_t = 0.0
		if _idle_t > 20.0:
			_idle_t = -12.0   # 冷却
			_idle_scare()
	else:
		_idle_t = 0.0

func _idle_scare() -> void:
	Sfx.play("static")
	for li in lamps:
		li.light_energy = 0.0
	await get_tree().create_timer(0.9).timeout
	for i in lamps.size():
		lamps[i].light_energy = 0.3 if (i != 1 or lamp_fixed) else 0.12
	if lamp_fixed and lamps.size() > 1:
		lamps[1].light_energy = 0.9
	Dialog.say(["（灯灭了一秒。）", "（黑暗里，有什么东西轻轻吸了一口气。）"])

# ================= 玩家 =================
func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	add_child(player)
	# 出生点：管理员室桌边；走廊来则出现在管理员室门口
	match SceneFlow.pending_spawn:
		"admin_door":
			player.position = Vector3(2.2, ADMIN_Y + 0.05, 0.5)
			player.set_look(PI/2)
		"corridor_from_admin":
			player.position = Vector3(-11.0, CORRIDOR_Y + 0.05, 0.5)
			player.set_look(PI/2)
		"r104_door":
			player.position = Vector3(2.2, R104_Y + 0.05, 2.8)
			player.set_look(0)
		"corridor_from_104":
			player.position = Vector3(8.0, CORRIDOR_Y + 0.05, -0.6)
			player.set_look(PI)
		_:
			player.position = Vector3(0.2, ADMIN_Y + 0.05, 0.2)
			player.set_look(PI)
	SceneFlow.pending_spawn = ""
	if Game.phase == Game.Phase.NIGHT:
		player.set_flashlight(true)

# ================= 门传送 =================
func _teleport(to_spawn: String, door_plate := "") -> void:
	Game.lock_ui("teleport")
	Sfx.play("door")
	if door_plate != "" and _door_meshes.has(door_plate):
		var pivot: Node3D = _door_meshes[door_plate]
		var t := create_tween()
		t.tween_property(pivot, "rotation:y", pivot.rotation.y + 1.3, 0.35)
		await t.finished
	await SceneFlow.fade_out(0.3)
	_spawn_at(to_spawn)
	if to_spawn == "r104_door":
		enter_room104_effects()
	await SceneFlow.fade_in(0.45)
	Game.unlock_ui("teleport")

func _spawn_at(spawn: String) -> void:
	match spawn:
		"admin_door":
			player.position = Vector3(2.2, ADMIN_Y + 0.05, 0.5); player.set_look(PI/2)
		"corridor_from_admin":
			player.position = Vector3(-11.0, CORRIDOR_Y + 0.05, 0.5); player.set_look(PI/2)
		"r104_door":
			player.position = Vector3(2.2, R104_Y + 0.05, 2.8); player.set_look(0)
		"corridor_from_104":
			player.position = Vector3(8.0, CORRIDOR_Y + 0.05, -0.6); player.set_look(PI)

# ================= 交互分发 =================
func _on_used(node: Area3D) -> void:
	if Dialog.active: return
	var evt: String = node.event_name
	match evt:
		"phone": _on_phone()
		"desk": _on_desk()
		"exit_admin": _teleport("corridor_from_admin")
		"door_admin": _teleport("admin_door")
		"door_101": _on_door101()
		"door_102": Dialog.say(["102。门口堆着没拆的快递，收件人姓林。"] if Game.phase != Game.Phase.NIGHT else ["102。门后隐约有电视声，这么晚了还没睡。"])
		"door_103": Dialog.say(["103。门上贴着褪色的福字。"] if Game.phase != Game.Phase.NIGHT else ["103。门牌蒙着一层灰，摸上去是烫的。你不明白为什么。"])
		"door_104": _on_door104()
		"elevator": _on_elevator()
		"wang": _on_wang()
		"sticky": _clue_sticky()
		"medical": _clue_medical()
		"dress": _clue_dress()
		"radio": _on_radio()
		"mirror": _on_mirror()
		"phone104": _on_phone_draft()
		"bathroom": Dialog.say(["（浴室门锁死了。门缝里渗出的寒气，比房间里更冷。）", "（你决定不去打开它。）"])
		"leave": _on_leave()
		"sofa": _on_sofa()
		"cabinet": _on_cabinet()
		"bookshelf": _on_bookshelf()
		"calendar_evt": Dialog.say(["日历停留在你被圈住的那一天：第 %d 天。" % Game.day, "（后面的日期，全是空白。）"])
		"keyrack": Dialog.say(["钥匙板上挂着一串钥匙：101、102、103……", "104 的那一把，此刻正在你的口袋里。它比别的钥匙冷。"])
		"window_admin": Dialog.say(["窗外是老城区的屋顶。天色灰蒙蒙的。"] if Game.phase != Game.Phase.NIGHT else ["窗外没有月亮。对面楼的窗户一格一格，全是黑的。", "（只有你身后的这一扇，还亮着。）"])
		"notice": Dialog.say(["公告栏上贴着三张纸：", "《催缴物业费通知》——被红笔划掉了。", "《寻人启事》——照片上的姑娘穿着红裙子。", "《幸福苑住户守则》第七条：夜里听到哭声，请关好门窗。"])
		"packages": Dialog.say(["103 门口的快递越堆越高。收件人姓林。", "（最上面那盒的胶带，是从里面被顶开的。）"])
		"meter": _on_meter()
		"extinguisher": Dialog.say(["灭火器。压力表的指针停在红区。", "（真出了事，它大概指望不上。）"])
		"bucket": Dialog.say(["保洁桶里的水很干净，漂着一片消毒泡腾片。", "（桶沿搭着的抹布却是黑的，怎么拧都拧不出清水。）"])
		"drawer": _on_drawer()
		"under_bed": _on_under_bed()
		"windowsill": Dialog.say(["窗台上有一层灰，唯独中间干净了一块——", "有人生前常常趴在这里，看楼下的路灯。"] if not done else ["窗台擦得很干净。摆着一只小小的、空的花瓶。"])
		"rug": _on_rug()
		_:
			extra.handle(evt)

# ================= 管理员室事件 =================
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
					"（他笑得不太自然。你放下电话，看了眼桌上的钥匙串。）",
				])
				Game.add_journal("房东的规矩：看房号。4越多，住户执念越深。104 有一个 4。")
			else:
				Dialog.say(["电话那头只剩忙音。"])
		2:
			Dialog.say([
				["房东（电话）", "第二天了。干得不错……我是说，楼挺安静的，对吧？"],
				["房东（电话）", "214 那间，外卖员的事……晚上要是闻到外卖味，别多想。"],
				"（104 的门牌，好像没那么冷了。楼梯间的声控灯，修好了。）",
			])
			Game.add_journal("房东：214 有一个 4。外卖员。")
		3:
			Dialog.say([
				["房东（电话）", "第三天。进度怎么样？……你问 334？贾总啊，生意人，生意人。"],
				["房东（电话）", "记住，七天。已经过去快一半了。"],
				"（他的语气，比昨天急了一点。）",
			])
			Game.add_journal("房东：334 有一个 4。商人老贾。")
		4:
			Dialog.say([
				["房东（电话）", "第四天。……你见到「他」了吗？算了，当我没问。"],
				["房东（电话）", "4 楼的房间，两个 4。进去之前，想清楚。"],
				"（电话挂得很快。快得像他不敢多说一个字。）",
			])
			Game.add_journal("房东：404 有两个 4。人命。")
		5:
			Dialog.say([
				["房东（电话）", "第五天。电梯……电梯可以用了，对吧。"],
				["房东（电话）", "444 的那位，是这栋楼最对不起的人。替我问声好。"],
			])
			Game.add_journal("房东：444 有三个 4。门神。")
		6:
			Dialog.say([
				["房东（电话）", "最后一天了。你准备好了吗？"],
				["房东（电话）", "4444 不存在。记住这一点，然后，忘了它。"],
				"（忙音。这一次，你连他的呼吸声都听不到了。）",
			])
		7:
			Dialog.say(["（电话没有响。）", "（它以后，也不会再响了。）"])
		_:
			Dialog.say(["电话那头只剩忙音。"])

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
				_apply_phase_lighting(true)
				corridor_evt_timer.start(randf_range(15.0, 25.0))
				if player: player.set_flashlight(true)
				Dialog.say([
					"（你睡到黄昏。醒来时，楼里的声音变了。）",
					"（走廊的灯变成了冷蓝色。好像有哪里，有人在哭。）",
				])
				await Dialog.finished
			_teleport("corridor_from_admin")
		_:
			pass

# ================= 走廊事件 =================
func _on_door101() -> void:
	Dialog.say(["王大妈家。门缝里飘出饭菜香。"] if Game.phase != Game.Phase.NIGHT else ["101。门后隐约有电视声。这么晚了还没睡。"])

func _on_door104() -> void:
	if Game.phase != Game.Phase.NIGHT:
		Dialog.say([
			"104。门锁着。",
			"（大白天的，门把手却冰得粘手。）",
			"（王大妈说过——晚上，这间屋子才有动静。）",
		])
	elif Game.healed.has(104):
		Dialog.say(["104。房间里安安静静的。", "她已经不哭了。"])
	else:
		Dialog.say([
			"104。钥匙插进去的时候，你听见了哭声。",
			"（门牌上的「4」，红得像刚写上去的。）",
		])
		await Dialog.finished
		_teleport("r104_door", "plate_104")
		Sfx.heartbeat(true)
		_door_slam_104()

## 进 104 后大门在身后猛地关上 + 灯光骤降
func _door_slam_104() -> void:
	if done or door_104_inner == null: return
	await get_tree().create_timer(0.6).timeout
	Sfx.play("door")
	door_104_inner.rotation.y = PI + 1.2
	var ts := create_tween()
	ts.tween_property(door_104_inner, "rotation:y", PI, 0.14)
	for li in room_lights:
		li.light_energy = 0.15
	await get_tree().create_timer(0.5).timeout
	for li in room_lights:
		li.light_energy = 1.1

func _on_elevator() -> void:
	if Game.phase == Game.Phase.NIGHT:
		Dialog.say([
			"电梯停在4楼。门没有开。",
			"（楼层显示屏闪了一下，跳出一个不存在的数字：4444。）",
		])
	else:
		Dialog.say(["电梯正常运行中。液晶屏上有个怎么也擦不掉的指印。"])

func _on_wang() -> void:
	if Game.day >= 4:
		Dialog.say(["（王大妈常坐的那个位置空着。小马扎上落了一层薄灰。）", "（她不见了。从第四天早晨开始。）"])
		return
	if Game.phase == Game.Phase.NIGHT:
		Dialog.say(["（走廊里空荡荡的。王大妈早就睡了。）"])
		return
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
		Dialog.say([["王大妈", "晚上去看她的时候，温柔点。那姑娘，生前没被温柔对待过。"]])

# ================= 104 事件 =================
func _start_anomaly() -> void:
	if is_instance_valid(anomaly_timer):
		anomaly_timer.wait_time = randf_range(14.0, 26.0)
		anomaly_timer.start()

## 走廊随机恐怖事件（夜晚）：鬼影闪现 / 灯光全线闪烁
func _on_corridor_event() -> void:
	if Game.phase == Game.Phase.NIGHT:
		corridor_evt_timer.start(randf_range(22.0, 40.0))
	if Game.phase != Game.Phase.NIGHT: return
	if player == null or abs(player.position.y - CORRIDOR_Y) > 3.0: return
	if Dialog.active or Game.ui_locked(): return
	if randf() < 0.45:
		# 走廊尽头的红影，一闪而过
		var ahead := clampf(player.position.x + 6.5, -10.5, 10.8)
		corridor_ghost.position = Vector3(ahead, CORRIDOR_Y, randf_range(-0.6, 0.6))
		corridor_ghost.rotation.y = -PI/2
		_set_ghost_face("ghost_face_hair")
		corridor_ghost.show()
		Sfx.play("static")
		await get_tree().create_timer(0.35).timeout
		corridor_ghost.hide()
	else:
		# 灯光全线闪烁
		Sfx.play("static")
		for i in 7:
			for li in lamps:
				li.light_energy = 0.06 if i % 2 == 0 else (0.3 if not lamp_fixed else 0.9)
			await get_tree().create_timer(0.09).timeout
		for i in lamps.size():
			lamps[i].light_energy = 0.3 if (i != 1 or lamp_fixed) else 0.12
		if lamp_fixed and lamps.size() > 1:
			lamps[1].light_energy = 0.9

func _on_anomaly() -> void:
	if done: return
	Sfx.play("static")
	var l := Label3D.new()
	l.text = COMMENTS[randi() % COMMENTS.size()]
	l.font = Game.font
	l.font_size = 42
	l.modulate = Color(0.85, 0.3, 0.3, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(randf_range(-2.0, 2.0), R104_Y + randf_range(1.2, 2.0), randf_range(-2.5, 1.5))
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y + 0.6, 2.6)
	t.tween_property(l, "modulate:a", 0.0, 2.6)
	t.chain().tween_callback(l.queue_free)
	_start_anomaly()

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
	# 衣柜门滑开
	Sfx.play("door")
	var tw := create_tween()
	tw.tween_property(wardrobe_door, "position:x", wardrobe_door.position.x + 0.58, 0.5)
	await tw.finished
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
		ghost.position = Vector3(2.55, R104_Y + 0.0, -0.9)
		ghost.rotation.y = -PI/2     # 面朝房内（从镜中探出）
		ghost_head.rotation = Vector3.ZERO
		_set_ghost_face("ghost_face_hair")
		ghost.show()
		Dialog.say(["（镜子里站着她。红裙子，长头发，背对着你。）"])
		await Dialog.finished
		_set_ghost_face("ghost_face_smile")
		Sfx.play("static")
		# 猛歪头（惊吓演出）
		var tt := create_tween()
		tt.tween_property(ghost_head, "rotation:z", 0.5, 0.16).set_trans(Tween.TRANS_BACK)
		tt.tween_property(ghost_head, "rotation:z", 0.42, 0.4)
		Dialog.say([
			"（你刚要退后——她忽然转过头。）",
			"（她在微笑。）",
			["？？？", "你也觉得，是我的错吗？"],
		])
	else:
		Dialog.say(["（她还在镜子里看着你，等着你的答案。）"])

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
	Dialog.say_center(["短信发出去了。", "没有人收到。但全世界都该收到。"])
	await Dialog.finished
	# 红色退潮：灯光转暖白、血迹淡出、墙面地板褪色、环境变暖
	var t := create_tween().set_parallel(true)
	for li in room_lights:
		t.tween_property(li, "light_color", Color(1.0, 0.95, 0.85), 2.8)
	for bd in blood_decals:
		t.tween_property(bd, "transparency", 1.0, 2.8)
	for hm in heal_mats:
		t.tween_property(hm[0], "albedo_color", hm[1], 2.8)
	var env := world_env.environment
	t.tween_property(env, "ambient_light_color", Color(0.75, 0.68, 0.6), 2.8)
	t.tween_property(env, "ambient_light_energy", 0.35, 2.8)
	await t.finished
	# 她换上白睡衣，在房间中央鞠躬
	var dress_mesh := ghost.get_node("Dress") as MeshInstance3D
	var gown := StandardMaterial3D.new()
	gown.albedo_texture = _tex("ghost_gown")
	gown.roughness = 0.95
	dress_mesh.material_override = gown
	ghost.position = Vector3(0, R104_Y + 0.0, -0.5)
	ghost.rotation.y = 0.0         # 面朝门口的玩家
	ghost_head.rotation = Vector3.ZERO
	_set_ghost_face("ghost_face_calm")
	ghost.show()
	var tb := create_tween()
	tb.tween_property(ghost_head, "rotation:x", 0.62, 1.6)   # 深深鞠躬（低头）
	tb.parallel().tween_property(ghost, "rotation:x", 0.18, 1.6)
	await tb.finished
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

func _on_leave() -> void:
	if done:
		Sfx.play("door")
		Dialog.say(["（你在管理员室的沙发上沉沉睡去。这一夜，楼里很安静。）"])
		await Dialog.finished
		Game.next_morning()
		Game.save_game(-1, "res://src/scenes/world_3d.tscn")
		Game.lock_ui("teleport")
		await SceneFlow.fade_out(0.5)
		_apply_phase_lighting(false)
		_spawn_at("admin_door")
		if player: player.set_flashlight(false)
		Sfx.music_day()
		await SceneFlow.fade_in(0.6)
		Game.unlock_ui("teleport")
	else:
		var idx: int = await RitualUI.ask("现在离开？今晚的探索会中断，线索会保留。", ["离开104", "再待一会儿"])
		if idx == 0:
			Sfx.heartbeat(false)
			_teleport("corridor_from_104")

# ================= 新道具互动 =================
func _on_sofa() -> void:
	var key := "sofa_%d_%d" % [Game.day, Game.phase]
	if not Game.flags.has(key):
		Game.flags[key] = true
		Game.battery = minf(100.0, Game.battery + 25.0)
		Dialog.say([
			"（你在沙发上坐了一会儿。弹簧硌得慌，但腿总算歇了口气。）",
			"（手电的电量恢复了一些。）",
		])
	else:
		Dialog.say(["（沙发还是那个沙发。坐再久，也坐不出安全感。）"])

func _on_cabinet() -> void:
	Sfx.play("paper")
	var t := create_tween()
	t.tween_property(cabinet_drawer, "position:z", cabinet_drawer.position.z + 0.34, 0.3)
	t.tween_property(cabinet_drawer, "position:z", cabinet_drawer.position.z, 0.3).set_delay(1.2)
	if not Game.flags.has("cabinet_note"):
		Game.flags["cabinet_note"] = true
		Dialog.say([
			"（抽屉卡了一下才拉开。里面没有文件，只有一张对折的便签。）",
			"“如果你看到这张纸，说明我已经走了。第三天开始，走廊里听到背后有脚步声，别回头。”",
			"（落款：第七任管理员。）",
			"（你数了数钥匙板上的旧钥匙圈——你是第八任。）",
		])
		Game.add_journal("前任管理员留字条：第三天起，走廊听到脚步声别回头。我是第八任。")
	else:
		Dialog.say(["（抽屉里只剩下一层灰，和便签压出来的印子。）"])

func _on_bookshelf() -> void:
	Sfx.play("paper")
	if not Game.flags.has("shelf_log"):
		Game.flags["shelf_log"] = true
		Dialog.say([
			"（你抽出一本《楼志》。书脊脆得一翻就掉渣。）",
			"“幸福苑落成于1987年。电梯只到4楼——图纸上的5楼，从来没有建过。”",
			"（可是电梯的按钮上，明明有一个磨得发亮的「5」。）",
		])
		Game.add_journal("《楼志》：这栋楼从来没有5楼。但电梯按钮上有个「5」。")
	else:
		Dialog.say(["（《楼志》剩下的内容被人撕掉了。断口很整齐，是用尺子比着撕的。）"])

func _on_meter() -> void:
	if Game.phase == Game.Phase.NIGHT and not lamp_fixed:
		Sfx.play("door")
		lamp_fixed = true
		if lamps.size() > 1:
			lamps[1].light_energy = 0.9
		Dialog.say([
			"（电表箱嗡嗡作响，第二盏灯忽明忽暗。）",
			"（你对着箱子拍了两下——灯，稳住了。老楼的设备都吃这一套。）",
		])
	else:
		Dialog.say(["电表箱。电线像老人的血管一样盘在里面。", "（有一根电线通向不存在的5楼。）"])

func _on_drawer() -> void:
	Sfx.play("paper")
	var t := create_tween()
	t.tween_property(drawer_104, "position:z", drawer_104.position.z + 0.3, 0.3)
	t.tween_property(drawer_104, "position:z", drawer_104.position.z, 0.3).set_delay(1.2)
	if not Game.flags.has("drawer_104"):
		Game.flags["drawer_104"] = true
		Dialog.say([
			"（抽屉里有一板止痛药，一粒都没少。）",
			"（说明书背面写着一行字：）",
			"“疼可以忍。我不想吃了药睡过去，错过回消息。”",
		])
		Game.add_journal("104抽屉：止痛药一粒没动。她怕睡过去，错过别人回她消息。")
	else:
		Dialog.say(["（止痛药还在原地。她到最后都没吃。）"])

func _on_under_bed() -> void:
	Sfx.play("paper")
	if not Game.flags.has("under_bed"):
		Game.flags["under_bed"] = true
		Dialog.say([
			"（你跪下来，把纸箱从床底拖出来。箱子很轻。）",
			"（里面是一本相册。前几页是海边的照片，她穿着那条红裙子，笑得很用力。）",
			"（后面的页码全是空的。相册停在了确诊的那一年。）",
		])
		Game.add_journal("104床底相册：穿红裙子的她在海边笑。相册停在了确诊那年。")
	else:
		Dialog.say(["（相册你放回去了。海边那页，你没敢再看第二遍。）"])

func _on_rug() -> void:
	if done:
		Dialog.say(["（地毯平平整整。下面什么都没有了。）"])
		return
	if not Game.flags.has("rug_104"):
		Game.flags["rug_104"] = true
		Dialog.say([
			"（你掀开地毯的一角。）",
			"（地板上有一行用指甲刻出来的字，刻痕里嵌着暗红色：）",
			"“对不起。”",
		])
	else:
		Dialog.say(["（刻字还在。你轻轻把地毯盖了回去。）"])

# ================= 进入 104 时启动异常 =================
func enter_room104_effects() -> void:
	if not done:
		_start_anomaly()
