# StateMachine.gd
class_name HellHoundStateMachine
extends Node

## PHASE MANAGEMENT
enum Phase { PHASE_1, PHASE_2, PHASE_3 }
var current_phase: Phase = Phase.PHASE_1

## UPDATED STATES FOR A BOSS
enum State { IDLE, CHASING, COOLDOWN, HURT, DEAD,
			# Specific attack states
			CLAW_SWIPE,
			FIRE_SPIT,
			LUNGE }

signal state_changed(new_state: State, previous_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null

# Timers and constants
const COOLDOWN_DURATION = 1.5 # Time between attacks

# Node references
@onready var senses: Node = %Senses
@onready var attack_controller: AttackController = %AttackController
@onready var health_component: Health = %Health
@onready var parent_entity = get_parent()
@onready var cooldown_timer: Timer = $CooldownTimer # ## ACTION NEEDED: Add a Timer node named "CooldownTimer" as a child of this StateMachine node.

func _ready() -> void:
	# Connect signals from other components
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	health_component.health_changed.connect(_on_health_changed)
	attack_controller.attack_finished.connect(_on_attack_finished)
	senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	cooldown_timer.timeout.connect(_decide_next_action) # ## Connect the new timer's timeout signal

	change_state(State.IDLE) # Boss starts in idle, waiting for player.

func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			parent_entity.stop_movement()
			# Waits for player to enter field of view

		State.CHASING:
			if not is_instance_valid(player_target):
				change_state(State.IDLE)
				return
			
			parent_entity.set_movement_speed(parent_entity.CHASE_SPEED)
			parent_entity.move_towards(player_target.global_position)
			
			# If we get close enough, stop chasing and decide what to do
			if parent_entity.global_position.distance_to(player_target.global_position) < 150: # Adjust this attack range
				_decide_next_action()
		
		State.COOLDOWN:
			parent_entity.stop_movement()
			# We are just waiting for the CooldownTimer to finish.

func change_state(new_state: State):
	if new_state == current_state: return
	
	var previous_state = current_state
	current_state = new_state
	emit_signal("state_changed", new_state, previous_state)
	
	# If we enter any attack state, tell the AttackController to perform it.
	match new_state:
		State.CLAW_SWIPE:
			attack_controller.initiate_attack("attack1")
		State.LUNGE:
			attack_controller.initiate_attack("lunge")
		State.FIRE_SPIT:
			attack_controller.initiate_attack("fire_spit")
		# ## ACTION NEEDED: Add more cases here for your other attacks.


## -- BOSS LOGIC FUNCTIONS --

func _decide_next_action():
	if current_state == State.DEAD: return

	# ## This is the BOSS's BRAIN. It decides what to do next.
	var distance_to_player = parent_entity.global_position.distance_to(player_target.global_position)
	
	# Simple logic: If too far, chase. If close enough, attack.
	if distance_to_player > 160: # Must be greater than the attack range in CHASING
		change_state(State.CHASING)
		return

	# If close enough, choose a random attack based on the current phase
	var available_attacks = []
	match current_phase:
		Phase.PHASE_1:
			available_attacks = [State.CLAW_SWIPE, State.LUNGE]
		Phase.PHASE_2:
			available_attacks = [State.CLAW_SWIPE, State.LUNGE, State.FIRE_SPIT] # Add new attacks here
		Phase.PHASE_3:
			available_attacks = [State.LUNGE, State.FIRE_SPIT] # Maybe remove some basic attacks to be more aggressive
	
	# Pick a random attack from the available list and execute it
	if not available_attacks.is_empty():
		change_state(available_attacks.pick_random())

func _change_phase(new_phase: Phase):
	if new_phase == current_phase: return
	
	current_phase = new_phase
	print("BOSS ENTERING ", new_phase)
	
	# ## ACTION NEEDED: Add phase transition logic here!
	# Example: Play a "roar" animation, become immortal for 2 seconds.
	# parent_entity.play("roar_animation")
	# health_component.set_temporary_immortality(2.0)


## -- SIGNAL HANDLERS --

func _on_fov_entered(body: Node2D):
	if body.is_in_group("player") and player_target == null:
		player_target = body
		_decide_next_action() # Start the fight!
		
func _on_attack_finished():
	# When any attack is finished, go into cooldown.
	change_state(State.COOLDOWN)
	cooldown_timer.start(COOLDOWN_DURATION)

func _on_health_changed(diff: int):
	# Handle phase changes
	var health_percent = float(health_component.health) / float(health_component.max_health)
	if current_phase == Phase.PHASE_1 and health_percent < 0.7:
		_change_phase(Phase.PHASE_2)
	elif current_phase == Phase.PHASE_2 and health_percent < 0.3:
		_change_phase(Phase.PHASE_3)

	# Handle getting hurt
	if diff < 0:
		if current_state != State.DEAD: # Allow getting hurt during an attack to interrupt it
			change_state(State.HURT)
