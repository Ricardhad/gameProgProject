extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


#func _physics_process(delta: float) -> void:
	## Add the gravity.


@onready var animation_tree = $AnimationTree
@onready var attack_timer = $AttackTimer
@onready var player_detect: Area2D = %AttackController.get_node("PlayerDetect")
func _ready():
	animation_tree.active = true

func _physics_process(delta):
	var should_walk = false
	if player_is_in_range and attack_timer.is_stopped():
		# Tell the AnimationTree to fire the trigger
		animation_tree.set("parameters/Triggers/trigger_attack1", true)
		attack_timer.start(3) # Start a 3-second cooldown
	# Put your logic here. For example:
	# if player is close enough:
	#     should_walk = true
		#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
	# This is the line that controls everything.
	# Notice the path includes "Conditions" as shown in your screenshot.
	animation_tree.set("parameters/Conditions/is_walking", should_walk)

	# If we are walking, apply movement
	if should_walk:
		pass
		 #Your move_and_slide() code here
	else:
		# Your stop-moving code here
		pass
