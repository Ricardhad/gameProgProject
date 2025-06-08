# AnimationController.gd
extends AnimatedSprite2D

@onready var state_machine: Node = get_parent().get_node("Statemachine")
@onready var goblin: CharacterBody2D = get_parent()
@onready var health_component: Node = get_parent().get_node("Health")

var last_state = StateMachine.State.IDLE

func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	health_component.health_depleted.connect(_on_death)
	self.animation_finished.connect(_on_animation_finished)

func _on_state_changed(new_state: StateMachine.State, previous_state: StateMachine.State) -> void:
	last_state = previous_state
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
	play("dead")

func _on_animation_finished() -> void:
	# After hurt animation, return to previous state
	if animation == "hurt":
		_on_state_changed(last_state, StateMachine.State.HURT)
	
	if animation == "dead":
		get_parent().queue_free() # The goblin can free itself after the animation
