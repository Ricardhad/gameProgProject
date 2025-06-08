# AttackController.gd
extends Node

# Emitted when the attack animation is finished
signal attack_finished

const ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0
var is_attacking = false
var has_attacked_this_animation = false

@onready var hitbox: Area2D = get_parent().get_node("HitBox")
@onready var animated_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta

func initiate_attack() -> void:
	if attack_timer > 0: # Still on cooldown
		return
	
	is_attacking = true
	has_attacked_this_animation = false
	attack_timer = ATTACK_COOLDOWN
	# The animation controller will handle playing the animation

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_attacking and not has_attacked_this_animation:
		print("AttackController: Hit player!")
		# Here you would call the player's take_damage method
		# if body.has_method("take_damage"):
		#     body.take_damage(10)
		has_attacked_this_animation = true

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		emit_signal("attack_finished")
