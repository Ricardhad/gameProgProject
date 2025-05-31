class_name HurtBox
extends Area2D

signal received_damage(damage: int)

@export var health: Health

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox != null:
		print("HP before : ", health.health)
		health.health -= hitbox.damage
		print("HP after : ", health.health)
		received_damage.emit(hitbox.damage)
