# AttackController.gd (Updated)
class_name HellHoundAttackController
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
# Inside AttackController.gd

# Inside AttackController.gd

# Change this function to accept an attack_name
#func initiate_attack(attack_name: String):
	#if not can_attack: return
		#can_attack = false
		## Now, you can use the name to decide which hitbox to enable
		## or which projectile to shoot.
		#match attack_name:
			#"claw_swipe":
			## Enable the claw hitbox
			## The AnimationPlayer will call a function to emit attack_finished
				#pass 
			#"lunge":
			## Do lunge logic
				#pass
			#"fire_spit":
			## Instantiate and shoot a fireball
				#pass

func _on_animation_finished():

	if animated_sprite.animation == "attack":
		hitbox.get_node("CollisionShape2D").disabled = true
		is_attacking = false
		emit_signal("attack_finished")

# NEW: A helper function to easily check the cooldown status
func can_attack() -> bool:
	return attack_timer <= 0
	
#func _finish_attack():
	## In a real game, this function would be called by your AnimationPlayer
	## using a "Call Method Track" at the end of the attack animation.
	#
	## Allow the controller to attack again.
	#can_attack = true
	#
	## Tell the StateMachine that the attack sequence is over, so it can
	## transition to the COOLDOWN state.
	#attack_finished.emit()
