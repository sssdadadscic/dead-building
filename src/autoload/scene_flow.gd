extends Node
## 场景切换：黑场淡入淡出 + 出生点传递

var pending_spawn := ""
var _layer: CanvasLayer
var _rect: ColorRect
var _busy := false

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	_layer.add_child(_rect)
	add_child(_layer)

func goto(scene_path: String, spawn := "") -> void:
	if _busy: return
	_busy = true
	pending_spawn = spawn
	Sfx.play("door")
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 1.0, 0.4)
	await t.finished
	get_tree().change_scene_to_file(scene_path)
	# 等两帧让新场景 _ready 完成
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_rect, "modulate:a", 0.0, 0.5)
	await t2.finished
	_busy = false

func instant_black() -> void:
	_rect.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 0.0, 0.8)

## 场景内传送用：公开淡入淡出
func fade_out(dur := 0.3) -> void:
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 1.0, dur)
	await t.finished

func fade_in(dur := 0.45) -> void:
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 0.0, dur)
	await t.finished
