class_name EnemyState extends Node

##stores a refrence to the enemy that this state belongs to
var enemy : Enemy
var state_machine: EnemyStateMachine

#what happens when we init this state?
func init() -> void:
	pass

#what happens when enemy enters this state?
func enter() -> void:
	pass

#what happens when enemy exits this state?
func exit() -> void:
	pass

#what happens during the _process update in this state?
func process(_delta:float) -> EnemyState:
	return null

#what happens during the _physics_process update in this state?
func physics(_delta:float) -> EnemyState:
	return null
