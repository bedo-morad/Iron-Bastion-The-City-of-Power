extends Node

const PLAYER = preload("uid://cks32sa15nuch")

var player: Player
var player_spawned: bool = false


func _ready() -> void:
	add_player_instance()
	await get_tree().create_timer(0.5).timeout
	player_spawned = true


func add_player_instance() -> void:
	player = PLAYER.instantiate()
	add_child(player)

func set_hp(_hp: int, _max_hp: int) -> void:
	player.max_hp = _max_hp
	player.hp = _hp
	player.update_hp(0)

func set_player_position(_new_position: Vector2) -> void:
	player.global_position = _new_position


func set_as_parent(node: Node2D) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	node.add_child( player )


func unparent_player(node: Node2D) -> void:
	node.remove_child(player)
