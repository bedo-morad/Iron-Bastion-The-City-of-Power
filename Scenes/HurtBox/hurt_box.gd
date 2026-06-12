class_name HurtBox extends Area2D

@export var damage : int = 1

func _ready():
	area_entered.connect( area_entering )

func area_entering(area2d: Area2D) -> void :
	if area2d is HitBox:
		area2d.take_damage(self)
	pass