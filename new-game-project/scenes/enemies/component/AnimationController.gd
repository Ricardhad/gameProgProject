# AnimationController.gd (Corrected Version)
extends AnimatedSprite2D

# PRO-TIP: Using % is safer than get_node() once you have them set up as unique.
@onready var state_machine: StateMachine = %StateMachine
@onready var health_component: Health = %Health

# This variable will store the state the goblin was in before being hurt.
var last_state = StateMachine.State.IDLE

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	health_component.health_depleted.connect(_on_death)
	self.animation_finished.connect(_on_animation_finished)


# This function now correctly accepts BOTH arguments from the signal.
func _on_state_changed(new_state: StateMachine.State, previous_state: StateMachine.State) -> void:
	# If the new state isn't HURT, we can update our "last_state" memory.
	# This ensures we don't forget we were chasing if we get hurt.
	if new_state != StateMachine.State.HURT:
		last_state = new_state
	
	match new_state:
		StateMachine.State.IDLE:
			play("idle")
		StateMachine.State.PATROL:
			play("walk")
		StateMachine.State.CHASE:
			play("run")
		StateMachine.State.ATTACK:
			play("attack")
		StateMachine.State.HURT:
			play("hurt")
		StateMachine.State.DEAD:
			play("dead")

func _on_death() -> void:
	# We can just call our state change function directly.
	# The StateMachine is the source of truth, so we command IT to change state.
	state_machine.change_state(StateMachine.State.DEAD)

func _on_animation_finished() -> void:
	# If the "hurt" animation has just finished...
	
	if animation == "hurt":
		# ...tell the StateMachine to go back to whatever it was doing before.
		# This is much cleaner. The AnimationController requests a change,
		# and the StateMachine handles the logic.
		state_machine.change_state(last_state)
	
	if animation == "dead":
		get_parent().queue_free()
