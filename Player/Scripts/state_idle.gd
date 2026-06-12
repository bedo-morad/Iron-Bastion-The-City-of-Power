class_name StateIdle extends State
@onready var walk : State = $"../Walk"
@onready var attack : State = $"../Attack"

#what happens when the player enters this state?
func enter() -> void:
	player.update_animation("idle")
	pass

#what happens when the player exits this state?
func exit() -> void:
	pass

#what happens during the _process update in this state?
func process(_delta:float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null

#what happens during the _physics_process update in this state?
func physics(_delta:float) -> State:
	return null

#what happens with input events in this state
func handle_input(_event:InputEvent) -> State:
	if _event.is_action_pressed("attack"):
		return attack
	return null