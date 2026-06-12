class_name EnemyStateStun extends EnemyState

@export var animation_name : String = "stun"
@export var knockback_speed : float = 200.0
@export var decelerate_speed : float = 10.0

@export_category("AI")
@export var next_state : EnemyState

var _damadge_position : Vector2 
var _direction : Vector2 
var _animation_finished : bool = false 

#what happens when we init this state?
func init() -> void:
	enemy.enemy_damaged.connect( _on_enemy_damaged )
	pass

#what happens when enemy enters this state?
func enter() -> void:
	enemy.invulnerable = true
	_animation_finished = false
	_direction = enemy.global_position.direction_to( _damadge_position)
	enemy.set_direction(_direction)
	enemy.velocity = _direction * - knockback_speed
	enemy.update_animation(animation_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	pass

#what happens when enemy exits this state?
func exit() -> void:
	enemy.invulnerable = false
	enemy.animation_player.animation_finished.disconnect(_on_animation_finished)
	pass

#what happens during the _process update in this state?
func process(_delta:float) -> EnemyState:
	if _animation_finished:
		return next_state
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null

#what happens during the _physics_process update in this state?
func physics(_delta:float) -> EnemyState:
	return null

func _on_enemy_damaged(hurt_box: HurtBox) -> void :
	_damadge_position = hurt_box.global_position
	
	state_machine.change_state( self )
	pass

func _on_animation_finished(_a:String):
	_animation_finished = true
	pass