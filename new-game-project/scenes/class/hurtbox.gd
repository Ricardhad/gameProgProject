# HurtBox.gd (TEMPORARY DEBUGGING VERSION)
class_name HurtBox
extends Area2D

signal received_damage(damage: int)

@export var health: Health

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# --- Step 1: Do we detect the collision at all? ---
	print("HURTBOX: An area entered me! Its name is '", area.name, "' and its class is '", area.get_class(), "'")

	# --- Step 2: Is the area in the correct group? ---
	if area.is_in_group("damage_sources"):
		print("HURTBOX: SUCCESS! The area is in the 'damage_sources' group.")
		
		# --- Step 3: Is the Health component connected? ---
		if health != null:
			print("HURTBOX: SUCCESS! The Health component is assigned.")
			

			# --- Step 4: Does the area have a damage variable? ---
			if area.has_method("get") and area.get("damage") != null:
				var damage_amount = area.get("damage")
				print("HURTBOX: SUCCESS! Found damage value: ", damage_amount)
				
				# --- Step 5: Apply the damage ---
				health.health -= damage_amount
				print("HURTBOX: DAMAGE APPLIED! New health: ", health.health)
				received_damage.emit(damage_amount)

			else:
				printerr("HURTBOX FAILED at Step 4: The object '", area.name, "' is in the damage group but has no 'damage' variable!")
		else:
			printerr("HURTBOX FAILED at Step 3: Health component not assigned! Please drag the Health node into this HurtBox's inspector slot.")
	else:
		printerr("HURTBOX FAILED at Step 2: The area '", area.name, "' is NOT in the 'damage_sources' group. Check for typos or if you added it to the group panel.")
