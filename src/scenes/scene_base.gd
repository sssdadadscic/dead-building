extends Node2D
class_name SceneBase
## 场景基类：背景/围墙/玩家生成/互动物注册

const PlayerScene := preload("res://src/player/player.tscn")
const InteractableScript := preload("res://src/objects/interactable.gd")

var player: Player

func add_bg(path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.z_index = -10
	add_child(s)
	return s

func add_walls(rects: Array) -> void:
	var body := StaticBody2D.new()
	for r in rects:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(r.size.x, r.size.y)
		col.shape = shape
		col.position = Vector2(r.position.x + r.size.x / 2.0, r.position.y + r.size.y / 2.0)
		body.add_child(col)
	add_child(body)

## 默认围墙：可走区域 y 150-330
func default_walls() -> void:
	add_walls([
		Rect2(0, 0, 640, 148),
		Rect2(0, 332, 640, 28),
		Rect2(0, 0, 16, 360),
		Rect2(624, 0, 16, 360),
	])

func spawn_player(default_pos: Vector2, spawns := {}) -> Player:
	player = PlayerScene.instantiate()
	var pos := default_pos
	if SceneFlow.pending_spawn != "" and spawns.has(SceneFlow.pending_spawn):
		pos = spawns[SceneFlow.pending_spawn]
	SceneFlow.pending_spawn = ""
	player.position = pos
	add_child(player)
	return player

func add_interactable(pos: Vector2, evt: String, radius := 18.0) -> Area2D:
	var a := Area2D.new()
	a.set_script(InteractableScript)
	a.setup(pos, evt, radius)
	a.used.connect(_on_used)
	add_child(a)
	return a

func add_dark(color: Color) -> CanvasModulate:
	var cm := CanvasModulate.new()
	cm.color = color
	add_child(cm)
	return cm

func _on_used(_node: Area2D) -> void:
	pass  # 子类覆写
