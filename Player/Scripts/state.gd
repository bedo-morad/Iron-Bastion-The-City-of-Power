class_name State
extends Node

#stores a refrence to the player that this state belongs to
static var player: Player
static var state_machine: PlayerStateMachine


func _ready():
	pass


#what happens when this state is initialized?
func init():
	pass


#what happens when the player enters this state?
func enter() -> void:
	pass


#what happens when the player exits this state?
func exit() -> void:
	pass


#what happens during the _process update in this state?
func process(_delta: float) -> State:
	return null


#what happens during the _physics_process update in this state?
func physics(_delta: float) -> State:
	return null


#what happens with input events in this state
func handle_input(_event: InputEvent) -> State:
	return null
