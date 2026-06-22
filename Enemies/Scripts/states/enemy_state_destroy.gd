class_name EnemyStateDestroy
extends EnemyState

@export var animation_name: String = "destroy"
@export var knockback_speed: float = 200.0
@export var decelerate_speed: float = 10.0

var _direction: Vector2
var damage_position: Vector2


#what happens when we init this state?
func init() -> void:
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	pass


#what happens when enemy enters this state?
func enter() -> void:
	enemy.invulnerable = true
	_direction = enemy.global_position.direction_to(damage_position)
	enemy.set_direction(_direction)
	enemy.velocity = _direction * -knockback_speed
	enemy.update_animation(animation_name)
	enemy.animation_player.animation_finished.connect(_on_animation_finished)
	disable_hurt_box()
	pass


#what happens when enemy exits this state?
func exit() -> void:
	pass


#what happens during the _process update in this state?
func process(_delta: float) -> EnemyState:
	enemy.velocity -= enemy.velocity * decelerate_speed * _delta
	return null


#what happens during the _physics_process update in this state?
func physics(_delta: float) -> EnemyState:
	return null


func _on_enemy_destroyed(hurt_box: HurtBox) -> void:
	damage_position = hurt_box.global_position
	state_machine.change_state(self)
	pass


func _on_animation_finished(_a: String):
	enemy.queue_free()

func disable_hurt_box() -> void:
	var hurt_box : HurtBox = enemy.get_node_or_null("HurtBox")
	if hurt_box:
		hurt_box.monitoring = false