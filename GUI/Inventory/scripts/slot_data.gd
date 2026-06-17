class_name SlotData
extends Resource

@export var item_data: ItemData
@export var quantity: int = 0 : set = set_quantity

func set_quantity(new_quantity : int)-> void:
	quantity = new_quantity
	if quantity < 1:
		emit_changed()
