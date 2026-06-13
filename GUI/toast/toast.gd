extends CanvasLayer

const TOAST_ITEM = preload("res://GUI/toast/toast_item.tscn")
@onready var vbox_container: BoxContainer = $VBoxContainer


func push_message(message: String) -> void:
	var item := TOAST_ITEM.instantiate()
	vbox_container.add_child(item)
	item.play_message(message)
