extends Node
## 《死楼》全局状态：天数/相位/线索/遗物/存档/输入映射/字体

signal battery_changed(value: float)
signal state_changed

enum Phase { MORNING, DAY, NIGHT }
const PHASE_NAMES := { Phase.MORNING: "早晨", Phase.DAY: "白天", Phase.NIGHT: "夜晚" }

var day: int = 1
var phase: int = Phase.MORNING
var battery: float = 100.0
var clues: Dictionary = {}          # clue_id -> true
var clue_details: Dictionary = {}   # clue_id -> {title, desc}
var relics: Array = []
var healed: Array = []
var flags: Dictionary = {}
var journal_entries: Array = []     # [{day, text}]
var hud_visible := false

var font: Font
var font_bold: Font

const SAVE_PATHS := {
	-1: "user://autosave.json",
	1: "user://save_1.json",
	2: "user://save_2.json",
	3: "user://save_3.json",
}

func _ready() -> void:
	font = load("res://assets/fonts/NotoSansSC-Regular.ttf")
	font_bold = load("res://assets/fonts/NotoSansSC-Bold.ttf")
	_setup_input()

# ---------- 输入映射（运行时注册，避免手写 project.godot 事件表） ----------
func _setup_input() -> void:
	_reg("move_left", [KEY_A, KEY_LEFT])
	_reg("move_right", [KEY_D, KEY_RIGHT])
	_reg("move_up", [KEY_W, KEY_UP])
	_reg("move_down", [KEY_S, KEY_DOWN])
	_reg("interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	_reg("journal", [KEY_TAB])
	_reg("flashlight", [KEY_F])
	_reg("pause", [KEY_ESCAPE])

func _reg(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

# ---------- UI 锁（对话框/日志/菜单打开时禁止移动与互动） ----------
var _locks := {}
const MOUSE_KEEP_LOCKS := ["dialog", "teleport"]   # 键盘驱动的锁，不改变鼠标状态

func lock_ui(name: String) -> void:
	_locks[name] = true
	_update_mouse_mode()
func unlock_ui(name: String) -> void:
	_locks.erase(name)
	_update_mouse_mode()
func ui_locked() -> bool:
	return not _locks.is_empty()

## 有 UI 打开时释放鼠标供点击；无锁且在 3D 场景时锁定鼠标
func _update_mouse_mode() -> void:
	for k in _locks:
		if not (k in MOUSE_KEEP_LOCKS):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
	var tree := get_tree()
	if tree != null and tree.current_scene is Node3D:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# ---------- 状态操作 ----------
func new_game() -> void:
	day = 1
	phase = Phase.MORNING
	battery = 100.0
	clues.clear()
	clue_details.clear()
	relics.clear()
	healed.clear()
	flags.clear()
	journal_entries.clear()
	add_journal("我收到了一封没有署名的邀请函。\n“诚邀您担任幸福苑公寓临时管理员。任期7天。期满后可继承本楼产权。”\n失业第三个月，我别无选择。")

func set_phase(p: int) -> void:
	phase = p
	emit_signal("state_changed")

func next_morning() -> void:
	day += 1
	phase = Phase.MORNING
	battery = 100.0
	emit_signal("battery_changed", battery)
	emit_signal("state_changed")

func add_clue(id: String, title: String, desc: String) -> void:
	clues[id] = true
	clue_details[id] = {"title": title, "desc": desc}
	add_journal("【线索】" + title + "——" + desc)
	emit_signal("state_changed")

func clue_count(ids: Array) -> int:
	var n := 0
	for i in ids:
		if clues.has(i): n += 1
	return n

func add_journal(text: String) -> void:
	journal_entries.append({"day": day, "text": text})

func add_relic(name: String, desc: String) -> void:
	relics.append({"name": name, "desc": desc})
	add_journal("【遗物】" + name + "——" + desc)
	emit_signal("state_changed")

func drain_battery(v: float) -> void:
	battery = maxf(0.0, battery - v)
	emit_signal("battery_changed", battery)

# ---------- 存档 ----------
func collect_state(scene_path: String) -> Dictionary:
	return {
		"version": 1,
		"day": day, "phase": phase, "battery": battery,
		"clues": clues, "clue_details": clue_details,
		"relics": relics, "healed": healed, "flags": flags,
		"journal": journal_entries, "scene": scene_path,
		"saved_at": Time.get_datetime_string_from_system(),
	}

func apply_state(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	phase = int(data.get("phase", Phase.MORNING))
	battery = float(data.get("battery", 100.0))
	clues = data.get("clues", {})
	clue_details = data.get("clue_details", {})
	relics = data.get("relics", [])
	# JSON 会把数字读成 float，统一转回 int 避免 Array.has 严格类型比较失败
	healed = []
	for h in data.get("healed", []):
		healed.append(int(h))
	flags = data.get("flags", {})
	journal_entries = data.get("journal", [])
	emit_signal("battery_changed", battery)
	emit_signal("state_changed")

func save_game(slot: int, scene_path: String) -> bool:
	var path: String = SAVE_PATHS[slot]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(collect_state(scene_path), "\t"))
	f.close()
	return true

func load_game(slot: int) -> Dictionary:
	var path: String = SAVE_PATHS[slot]
	if not FileAccess.file_exists(path): return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary: return data
	return {}

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_PATHS[slot])

# ---------- UI 控件工厂 ----------
func mk_label(text: String, size: int = 14, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func mk_button(text: String, size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	return b
