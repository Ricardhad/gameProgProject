# AttackController.gd
class_name AttackController
extends Node

signal attack_finished

const ATTACK_COOLDOWN = 1.0
var attack_timer = 0.0

# These nodes are now children of this AttackController
@onready var player_detect: Area2D = $PlayerDetect
@onready var hitbox: Area2D = $HitBox

func _ready() -> void:
	player_detect.body_entered.connect(_on_player_detect_body_entered)
	# The hitbox dealing damage is handled by its own script, which is great!
	# We just need to enable/disable its collision shape.
	
func _process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta

func initiate_attack() -> void:
	if attack_timer <= 0:
		# Tell the animation controller to play the attack
		# For now, we'll just enable the hitbox. The animation controller will handle the visuals.
		$HitBox/CollisionShape2D.disabled = false
		attack_timer = ATTACK_COOLDOWN
		# After a short time, disable the hitbox and finish the attack
		var tween = create_tween()
		tween.tween_interval(0.5) # How long the hitbox is active
		tween.tween_callback(finish_attack)

func finish_attack():
	$HitBox/CollisionShape2D.disabled = true
	emit_signal("attack_finished")

# This is NO LONGER needed here, because the StateMachine will tell us when to attack.
# We'll call initiate_attack() from the StateMachine instead.
func _on_player_detect_body_entered(body: Node2D) -> void:
	# This function is now just for information, the StateMachine handles the logic.
	pass
