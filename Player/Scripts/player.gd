class_name Player
extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var invulnerable: bool = false
var hp: int = 10
var max_hp: int = 10
const DIR_4: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hit_box: HitBox = $HitBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer

signal direction_changed(new_direction: Vector2)
signal player_damaged(hurt_box: HurtBox)


func _ready():
	PlayerManager.player = self
	state_machine.initialize(self)
	hit_box.damaged.connect(take_damage)
	update_hp(0)


func _process(_delta):
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down"),
	)


func _physics_process(_delta):
	move_and_slide()


func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false

	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_direction: Vector2 = DIR_4[direction_id]
	if new_direction == cardinal_direction:
		return false

	cardinal_direction = new_direction

	#signal the change in direction to other scripts
	direction_changed.emit(new_direction)

	#scaling is better to mirror the whole visual transform space
	#(for example, sprite plus attached child visuals aligned to left/right).
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true


func update_animation(state) -> void:
	animation_player.play(state + "_" + animation_direction())


func animation_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"


func take_damage(hurt_box: HurtBox) -> void:
	if invulnerable:
		return
	update_hp(-hurt_box.damage)
	if hp > 0:
		player_damaged.emit(hurt_box)
	else:
		player_damaged.emit(hurt_box)
		update_hp(99)
	pass


func update_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, max_hp)
	PlayerHud.update_hp(hp, max_hp)
	pass


func make_invulnerable(duration: float = 1.0) -> void:
	invulnerable = true
	hit_box.monitoring = false
	await get_tree().create_timer(duration).timeout
	invulnerable = false
	hit_box.monitoring = true
	pass
