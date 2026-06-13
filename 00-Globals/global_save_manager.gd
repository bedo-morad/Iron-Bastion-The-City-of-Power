extends Node

const SAVE_PATH = "user://"

signal game_saved
signal game_loaded

var current_save : Dictionary = {
	scene_path = "",
	player = {
		hp = 1,
		max_hp = 1,
		pos_x = 0,
		pos_y = 0,
	},
	items = [],
	persistence = [],
	quests = []
}

func save_game()-> void:
	update_player_data()
	update_scene_path()
	var file := FileAccess.open(SAVE_PATH + "save.sav",FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line( save_json )
	game_saved.emit()
	print("save") 
	
func load_game()-> void:
	var file := FileAccess.open(SAVE_PATH + "save.sav",FileAccess.READ)
	var json := JSON.new()
	json.parse( file.get_line())
	current_save = json.get_data() as Dictionary
	LevelManager.load_new_level( current_save.scene_path, "" , Vector2.ZERO)

	await LevelManager.level_load_started

	PlayerManager.set_player_position(Vector2(current_save.player.pos_x,current_save.player.pos_y))
	PlayerManager.set_hp(current_save.player.hp,current_save.player.max_hp)

	await LevelManager.level_loaded

	game_loaded.emit()
	
	print("load")

func update_player_data() -> void:
	var player : Player = PlayerManager.player
	current_save.player.hp = player.hp
	current_save.player.max_hp = player.max_hp
	current_save.player.pos_x = player.global_position.x
	current_save.player.pos_y = player.global_position.y

func update_scene_path()-> void:
	for c in get_tree().root.get_children():
		if c is Level:
			current_save.scene_path = c.scene_file_path