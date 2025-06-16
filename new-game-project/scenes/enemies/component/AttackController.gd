# AttackController.gd (Updated for projectiles)
class_name AttackController
extends Node2D

signal attack_finished

@export var available_attacks: Array[String] = ["attack", "shoot"] # Added "shoot"
@export var damage_frame: int = 1

# ✅ CHANGE #1: Add new properties for shooting
@export_group("Shooting Properties")
@export var shoot_frame: int = 1 # The frame of the "shoot" animation to fire on
@export var projectile_scene: PackedScene
@export var projectile_spawn_point: Marker2D

var can_attack: bool = true

@onready var animated_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	hitbox_shape.disabled = true
	
func initiate_attack(attack_name: String):
	# ✅ THE FIX: First, check if the requested attack is in our list of available attacks.
	if attack_name not in available_attacks:
		# This attack is not allowed for this enemy, so do nothing.
		# The print statement is great for debugging to see if your AI is trying to call an invalid attack.
		print("Attempted to use unavailable attack: '", attack_name, "' on ", get_parent().name)
		return

	if not can_attack:
		return
		
	can_attack = false
	animated_sprite.play(attack_name)


func _on_frame_changed():
	var current_animation = animated_sprite.animation

	# --- Melee Logic ---
	if current_animation == "attack" and animated_sprite.frame == damage_frame:
		hitbox_shape.disabled = false
	if current_animation == "attack1" and animated_sprite.frame == damage_frame:
		hitbox_shape.disabled = false
	if current_animation == "attack2" and animated_sprite.frame == damage_frame:
		hitbox_shape.disabled = false	
	if current_animation == "special" and animated_sprite.frame == damage_frame:
		hitbox_shape.disabled = false	
	# ✅ CHANGE #2: Add logic for spawning a projectile on a specific frame
	if current_animation == "shoot" and animated_sprite.frame == shoot_frame:
		_spawn_projectile()

func _on_animation_finished():
	var finished_animation_name = animated_sprite.animation
	if finished_animation_name in available_attacks:
		hitbox_shape.disabled = true
		emit_signal("attack_finished")

# ✅ CHANGE #3: Add the function to do the spawning
func _spawn_projectile():
	if not projectile_scene or not projectile_spawn_point:
		print("ERROR: Projectile Scene or Spawn Point not set in AttackController.")
		return

	# Create an instance of the projectile
	var new_projectile = projectile_scene.instantiate()

	# Add it to the main scene tree (not as a child of the goblin)
	get_tree().get_root().add_child(new_projectile)

	# Call its start function to set its position, rotation, and direction
	new_projectile.start(projectile_spawn_point.global_transform)

func reset_attack_cooldown():
	can_attack = true

func is_ready_to_attack() -> bool:
	return can_attack
	
func can_perform_attack(attack_name: String) -> bool:
	return attack_name in available_attacks
	
func _get_random_melee_attack() -> String:
	var possible_melee_attacks = available_attacks
	
	var available_melee_attacks = []

	# Check which melee attacks this enemy can actually perform
	for attack_name in possible_melee_attacks:
		print("is available = " ,attack_name)
		if can_perform_attack(attack_name):
			available_melee_attacks.append(attack_name)

	# If we found any, pick one at random and return its name
	if not available_melee_attacks.is_empty():
		return available_melee_attacks.pick_random()

	# Return an empty string if no melee attacks were available
	return ""
