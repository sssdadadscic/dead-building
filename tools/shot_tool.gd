extends SceneTree
## 截图工具（需要带显示运行，非 headless）：
## godot --path dead_building -s res://tools/shot_tool.gd
var shots := [
	"res://src/scenes/title.tscn",
	"res://src/scenes/admin_room.tscn",
	"res://src/scenes/corridor.tscn",
	"res://src/scenes/room_104.tscn",
]

func _initialize() -> void:
	await process_frame
	await process_frame
	var Game = root.get_node("Game")
	Game.new_game()
	for sc in shots:
		change_scene_to_file(sc)
		for i in 30:
			await process_frame
		var img: Image = root.get_texture().get_image()
		var name: String = sc.get_file().get_basename()
		img.save_png("user://shot_%s.png" % name)
		print("saved shot_", name)
	print("=== shots done ===")
	quit(0)
