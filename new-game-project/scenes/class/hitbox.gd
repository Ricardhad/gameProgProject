class_name HitBox
extends Area2D

@export var damage: int = GlobalVar.damage_player : set = set_damage, get = get_damage

func set_damage(value: int):
	damage = value

func get_damage() -> int:
	return damage
