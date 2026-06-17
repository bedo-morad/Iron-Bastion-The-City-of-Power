class_name InventorySlotUI extends Button

var slot_data : SlotData: set = set_slot_data

@onready var texture_rect : TextureRect = $TextureRect
@onready var label : Label = $Label


func _ready() -> void:
	texture_rect.texture = null
	label.text = ""
	focus_entered.connect( item_focused )
	focus_exited.connect( item_unfocused )

func set_slot_data(data : SlotData) -> void:
	slot_data = data
	if slot_data == null:
		return
	texture_rect.texture = slot_data.itemData.texture
	label.text = str(slot_data.quantity)

func item_focused() -> void:
	if slot_data != null && slot_data.itemData != null:
		PauseMenu.update_item_description(slot_data.itemData.description)

func item_unfocused() -> void:
	PauseMenu.update_item_description("")
