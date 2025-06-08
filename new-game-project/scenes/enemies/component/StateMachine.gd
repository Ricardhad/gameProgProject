# StateMachine.gd
extends Node

# Define the states the goblin can be in
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

# Signals to command the other components
signal state_changed(new_state: State, previous_state: State)
signal set_movement_direction(direction: int)
signal set_chase_target(target: Node2D)
signal stop_movement
signal initiate_attack

var current_state: State = State.PATROL
var player_target: Node2D = null

# Timers and constants
const CHASE_DURATION = 5.0
const CHASE_LOSE_COOLDOWN = 1.5
var chase_timer = 0.0
var losing_sight_timer = 0.0
var is_player_in_proximity = false

# Node references
@onready var fov: Area2D = get_parent().get_node("Senses/FieldOfView")
@onready var proximity_sense: Area2D = get_parent().get_node("Senses/ProximitySense")
@onready var player_detect: Area2D = get_parent().get_node("Senses/PlayerDetect")
@onready var attack_controller: Node = get_parent().get_node("AttackController")
@onready var health_component: Node = get_parent().get_node("Health")

func _ready() -> void:
	# Connect to signals from other nodes
	fov.body_entered.connect(_on_fov_entered)
	fov.body_exited.connect(_on_fov_exited)
	proximity_sense.body_entered.connect(_on_proximity_entered)
	proximity_sense.body_exited.connect(_on_proximity_exited)
	player_detect.body_entered.connect(_on_player_detect_entered)
	attack_controller.attack_finished.connect(_on_attack_finished)
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	
	# Start by patrolling
	change_state(State.PATROL)

func _process(delta: float) -> void:
	# Handle timers that can force a state change
	if current_state == State.CHASE:
		if losing_sight_timer > 0:
			losing_sight_timer -= delta
			if losing_sight_timer <= 0:
				print("StateMachine: Lost sight of player. Reverting to patrol.")
				player_target = null
				change_state(State.PATROL)
		
		chase_timer -= delta
		if chase_timer <= 0:
			print("StateMachine: Chase timer ran out. Reverting to patrol.")
			player_target = null
			change_state(State.PATROL)

func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	
	var previous_state = current_state
	current_state = new_state
	emit_signal("state_changed", current_state, previous_state)
	
	# Logic to execute ONCE when entering a new state
	match current_state:
		State.PATROL:
			player_target = null
			emit_signal("set_movement_direction", 1) # Start by moving right
		State.CHASE:
			chase_timer = CHASE_DURATION
			emit_signal("set_chase_target", player_target)
		State.ATTACK:
			emit_signal("stop_movement")
			emit_signal("initiate_attack")
		State.HURT:
			emit_signal("stop_movement") # The main body will handle knockback
		State.DEAD:
			emit_signal("stop_movement")
		State.IDLE:
			emit_signal("stop_movement")

# --- Signal Handlers ---

func _on_fov_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state != State.DEAD:
		player_target = body
		losing_sight_timer = 0.0 # Reset timer if player re-enters
		change_state(State.CHASE)

func _on_fov_exited(body: Node2D) -> void:
	if body == player_target:
		# Don't lose chase if player is still in proximity
		if not is_player_in_proximity:
			losing_sight_timer = CHASE_LOSE_COOLDOWN

func _on_proximity_entered(body: Node2D) -> void:
	if body == player_target:
		is_player_in_proximity = true
		losing_sight_timer = 0.0 # Never lose sight up close

func _on_proximity_exited(body: Node2D) -> void:
	if body == player_target:
		is_player_in_proximity = false

func _on_player_detect_entered(body: Node2D) -> void:
	if body == player_target and current_state == State.CHASE:
		change_state(State.ATTACK)

func _on_attack_finished() -> void:
	# After attacking, decide what to do next
	if player_target and player_detect.overlaps_body(player_target):
		change_state(State.ATTACK) # Attack again if player is still in range
	elif player_target:
		change_state(State.CHASE) # Otherwise, go back to chasing
	else:
		change_state(State.PATROL)

func _on_health_changed(diff: int) -> void:
	if diff < 0 and current_state != State.DEAD:
		change_state(State.HURT)
		# A timer would be needed here to transition out of HURT state

func _on_health_depleted() -> void:
	change_state(State.DEAD)
