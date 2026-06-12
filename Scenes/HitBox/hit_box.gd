class_name HitBox extends Area2D

signal damaged (damage : int)

func take_damage (hurt_box: HurtBox) -> void:
	damaged.emit(hurt_box)