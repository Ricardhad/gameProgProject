class_name AttackController
extends Node2D

signal attack_finished

@export var available_attacks: Array[String] = ["attack"]
## The frame of the attack animation on which to enable the hitbox.
## For example, if your swing connects on the 3rd frame, set this to 2 (since frames are 0-indexed).
@export var damage_frame: int = 1

var can_attack: bool = true

@onready var animated_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")
@onready var hitbox_shape: CollisionShape2D = $HitBox/CollisionShape2D


func _ready():
	# Connect to the signals from the sprite.
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	
	hitbox_shape.disabled = true


func initiate_attack(attack_name: String):
	if not can_attack:
		return

	can_attack = false
	animated_sprite.play(attack_name)
	
	# IMPORTANT: We no longer enable the hitbox here.
	# It will be enabled on the specific damage_frame instead.


# This function runs every time the animation frame changes.
func _on_frame_changed():
	var current_animation = animated_sprite.animation
	
	# Check if we're in an attack animation and on the correct frame.
	if current_animation in available_attacks and animated_sprite.frame == damage_frame:
		# Enable the hitbox only on the specific frame for damage.
		hitbox_shape.disabled = false


func _on_animation_finished():
	var finished_animation_name = animated_sprite.animation

	if finished_animation_name in available_attacks:
		# Always disable the hitbox when the animation is done.
		hitbox_shape.disabled = true
		
		# Tell the StateMachine to start its cooldown.
		emit_signal("attack_finished")


# The StateMachine calls this function AFTER its cooldown timer finishes.
func reset_attack_cooldown():
	can_attack = true


func is_ready_to_attack() -> bool:
	return can_attack
