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
	if not can_attack:
		return
	can_attack = false
	animated_sprite.play(attack_name)

func _on_frame_changed():
	var current_animation = animated_sprite.animation

	# --- Melee Logic ---
	if current_animation == "attack" and animated_sprite.frame == damage_frame:
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
