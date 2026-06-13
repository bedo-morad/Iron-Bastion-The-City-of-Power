extends CanvasLayer

@onready var button_resume : Button = $VBoxContainer/Button_Resume
@onready var button_save : Button = $VBoxContainer/Button_Save
@onready var button_load : Button = $VBoxContainer/Button_Load
@onready var button_quit : Button = $VBoxContainer/Button_Quit

var is_paused: bool = false


func _ready():
	hide_pause_menu()
	button_resume.pressed.connect( _on_resume_pressed )
	button_save.pressed.connect( _on_save_pressed )
	button_load.pressed.connect( _on_load_pressed )
	button_quit.pressed.connect( _on_quit_pressed )


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused == false:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()


func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	button_resume.grab_focus()


func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false

func _on_save_pressed()-> void:
	if is_paused == false:
		return
	else:
		SaveManager.save_game()
		hide_pause_menu()
	
func _on_load_pressed()-> void:
	if is_paused == false:
		return
	else:
		SaveManager.load_game()
		await LevelManager.level_load_started
		hide_pause_menu()

func _on_resume_pressed()-> void:
	hide_pause_menu()
	pass

func _on_quit_pressed()-> void:
	get_tree().quit()
	pass
