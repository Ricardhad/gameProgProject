# AttackController.gd (Updated)
class_name AttackController
extends Node2D

signal attack_finished

# Set the cooldown to exactly 1 second
const ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0
var is_attacking = false

@onready var hitbox: Area2D = $HitBox
@onready var animated_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float):
	if attack_timer > 0:
		attack_timer -= delta

func initiate_attack():
	# Only attack if not already on cooldown
	if not can_attack(): return
	
	is_attacking = true
	attack_timer = ATTACK_COOLDOWN
	hitbox.get_node("CollisionShape2D").disabled = false

func _on_animation_finished():
	if animated_sprite.animation == "attack":
		hitbox.get_node("CollisionShape2D").disabled = true
		is_attacking = false
		emit_signal("attack_finished")

# NEW: A helper function to easily check the cooldown status
func can_attack() -> bool:
	return attack_timer <= 0
