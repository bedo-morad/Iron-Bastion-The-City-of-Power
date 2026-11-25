class_name EnemyStateChase extends EnemyState

@export var animation_name : String = "chase"
@export var chase_speed : float = 40.0
@export var turn_rate: float = 0.25

@export_category("AI")
@export var vision_area : VisionArea
@export var attack_area : HurtBox
@export var state_aggro_duration : float = 0.5
@export var next_state : EnemyState

var _timer : float = 0.0 
var _direction : Vector2 
var _can_see_player : bool = false

#what happens when we init this state?
func init() -> void:
	if vision_area:
		vision_area.player_entered.connect(_on_player_enter)
		vision_area.player_exited.connect(_on_player_exit)
	pass

#what happens when enemy enters this state?
func enter() -> void:
	_timer = state_aggro_duration
	_can_see_player = vision_area != null and vision_area.overlaps_body(PlayerManager.player)
	enemy.update_animation(animation_name)
	if attack_area:
		attack_area.monitoring = true

#what happens when enemy exits this state?
func exit() -> void:
	if attack_area:
		attack_area.monitoring = false
	_can_see_player = false
	pass

#what happens during the _process update in this state?
func process(_delta:float) -> EnemyState:
	var new_direction : Vector2 = enemy.global_position.direction_to(PlayerManager.player.global_position)
	_direction = lerp( _direction, new_direction, turn_rate )
	enemy.velocity = _direction * chase_speed
	if enemy.set_direction(_direction):
		enemy.update_animation(animation_name)
	
	if _can_see_player == false:
		_timer -= _delta
		if _timer < 0:
			return next_state
	else: 
		_timer = state_aggro_duration
	return null

#what happens during the _physics_process update in this state?
func physics(_delta:float) -> EnemyState:
	return null


func _on_player_enter()-> void:
	_can_see_player = true
	if state_machine.current_state is EnemyStateStun:
		return
	state_machine.change_state(self)
	pass

func _on_player_exit()-> void:
	_can_see_player = false
	pass