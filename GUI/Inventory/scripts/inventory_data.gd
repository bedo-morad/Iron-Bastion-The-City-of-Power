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

func get_save_data() -> Array:
	var item_save : Array = []
	for slot in slots:
		item_save.append(item_to_save(slot))
	return item_save

func item_to_save(slot:SlotData) -> Dictionary:
	var result = {
		item_resource_path = "",
		quantity = 0
	}
	if slot != null:
		result.quantity = slot.quantity
		if slot.item_data:
			result.item_resource_path = slot.item_data.resource_path
	return result

func parse_save_data(save_data : Array) -> void:
	var array_size = slots.size()
	slots.clear()
	slots.resize( array_size )
	for i in save_data.size():
		slots [i] = item_from_save( save_data [i])
	connect_slots()

func item_from_save(save_object : Dictionary) -> SlotData:
	if save_object.item_resource_path == "":
		return null
	var new_slot : SlotData = SlotData.new()
	new_slot.item_data = load(save_object.item_resource_path)
	new_slot.quantity = int(save_object.quantity)
	return new_slot
