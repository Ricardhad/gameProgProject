# AnimationController.gd
extends AnimatedSprite2D

@onready var state_machine: HellHoundStateMachine = %HellHoundStateMachine
@onready var health_component: Health = %Health

# This variable will store the state the goblin was in before being hurt.
var last_state_before_hurt = HellHoundStateMachine.State.IDLE

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	health_component.health_depleted.connect(_on_death)
	self.animation_finished.connect(_on_animation_finished)

func _on_state_changed(new_state: HellHoundStateMachine.State, previous_state: HellHoundStateMachine.State) -> void:
	# Keep track of what we were doing before we got hurt.
	if new_state != HellHoundStateMachine.State.HURT:
		last_state_before_hurt = new_state
	
	match new_state:
		HellHoundStateMachine.State.IDLE:
			play("idle")
		HellHoundStateMachine.State.COOLDOWN: # ## Play idle during cooldown
			play("idle")
		HellHoundStateMachine.State.CHASING:
			play("run")
		HellHoundStateMachine.State.HURT:
			play("hurt")
		HellHoundStateMachine.State.DEAD:
			play("dead")

		# ## ACTION NEEDED: Add cases for your specific attack animations
		HellHoundStateMachine.State.CLAW_SWIPE:
			play("claw_swipe")
		HellHoundStateMachine.State.LUNGE:
			play("lunge")
		HellHoundStateMachine.State.FIRE_SPIT:
			play("fire_spit")


func _on_death() -> void:
	state_machine.change_state(HellHoundStateMachine.State.DEAD)

func _on_animation_finished() -> void:
	# If the "hurt" animation has just finished, decide what to do next.
	if animation == "hurt":
		# Instead of just going back to chase, let the boss decide its next move.
		# This feels more natural than immediately resuming a chase.
		state_machine._decide_next_action()
	
	if animation == "dead":
		get_parent().call_deferred("queue_free")
