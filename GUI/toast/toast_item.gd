extends PanelContainer

@onready var label: Label = $MarginContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)


func play_message(message: String) -> void:
	label.text = message
	animation_player.play("show_toast")


func _on_animation_finished(_anim: StringName) -> void:
	queue_free()
