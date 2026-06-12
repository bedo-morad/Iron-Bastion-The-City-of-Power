class_name EnemyStateWonder extends EnemyState

@export var animation_name : String = "walk"
@export var wonder_speed : float = 20.0

@export_category("AI")
@export var state_animation_duration : float = 0.5
@export var state_cycles_min : int = 1
@export var state_cycles_max : int = 3
@export var next_state : EnemyState

var _timer : float = 0.0 
var _direction : Vector2 

#what happens when we init this state?
func init() -> void:
	pass

#what happens when enemy enters this state?
func enter() -> void:
	_timer = randi_range(state_cycles_min, state_cycles_max)
	_direction = enemy.DIR_4[randi_range(0,3)]
	enemy.velocity = _direction * wonder_speed
	enemy.set_direction(_direction)
	enemy.update_animation(animation_name)
	pass

#what happens when enemy exits this state?
func exit() -> void:
	pass

#what happens during the _process update in this state?
func process(_delta:float) -> EnemyState:
	_timer -= _delta
	if _timer < 0:
		return next_state
	return null

#what happens during the _physics_process update in this state?
func physics(_delta:float) -> EnemyState:
	return null
