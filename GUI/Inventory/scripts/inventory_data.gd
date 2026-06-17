class_name InventoryData
extends Resource

@export var slots: Array[SlotData]

func _init() -> void:
	connect_slots()

func add_item(_item_data: ItemData, count: int = 1) -> bool:
	for s in slots:
		if s:
			if s.item_data == _item_data:
				s.quantity += count
				return true
	for i in slots.size():
		if slots[i] == null:
			var new_slot_data := SlotData.new()
			new_slot_data.item_data = _item_data
			new_slot_data.quantity = count
			slots[i] = new_slot_data
			new_slot_data.changed.connect( slot_changed )
			return true
	ToastManager.push_message("Inventory is full")
	return false

func connect_slots() -> void:
	for slot in slots:
		if slot:
			slot.changed.connect( slot_changed ) 

func slot_changed() -> void:
	for slot in slots:
		if slot:
			if slot.quantity < 1:
				slot.changed.disconnect(slot_changed)
				var index = slots.find( slot )
				slots [index] = null
				emit_changed()
				