class_name HurtBox
extends Area2D

signal received_damage(damage: int)

@export var health: Health

func _ready():
	# This connection is correct.
	connect("area_entered", _on_area_entered)

# ✅ FIX #1: Change the parameter type to the generic Area2D.
func _on_area_entered(area: Area2D) -> void:
	
	# ✅ FIX #2: Check if the area that entered IS a HitBox before using it.
	if area is HitBox:
		# We can now safely treat 'area' as a HitBox.
		# For convenience, you can assign it to a new variable.
		var hitbox: HitBox = area

		# The rest of your logic is perfect.
		# Make sure the health component has been assigned in the editor.
		if health != null:
			print("HP before : ", health.health)
			health.health -= hitbox.damage
			print("HP after : ", health.health)
			received_damage.emit(hitbox.damage)
		else:
			printerr("HurtBox Error: Health component not assigned!")
