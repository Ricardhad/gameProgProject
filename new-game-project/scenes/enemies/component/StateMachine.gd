# StateMachine.gd
class_name StateMachine
extends Node

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

signal state_changed(new_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null

# Timers and constants
const CHASE_DURATION = 5.0
const CHASE_LOSE_COOLDOWN = 1.5
var chase_timer = 0.0
var losing_sight_timer = 0.0
var turn_timer = 0.0
const TURN_COOLDOWN_PATROL = 0.5

# Node references
@onready var senses: Node = get_parent().get_node("Senses")
@onready var player_detect: Area2D = get_parent().get_node("AttackController/PlayerDetect")
@onready var attack_controller: AttackController = get_parent().get_node("AttackController")
#@onready var health_component: Health = get_parent().get_node("Health") as Health
@onready var health_component: Health = %Health
@onready var parent_goblin = get_parent()

func _ready() -> void:
	print("Attempting to connect signals. The Health node is: ", %Health) # <-- ADD THIS LINE

	#senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	senses.get_node("FieldOfView").body_exited.connect(_on_fov_exited)
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	
	change_state(State.PATROL)

func _process(delta: float) -> void:
	# Update timers
	if chase_timer > 0: chase_timer -= delta
	if losing_sight_timer > 0: losing_sight_timer -= delta
	if turn_timer > 0: turn_timer -= delta

	match current_state:
		State.PATROL:
			parent_goblin.set_movement_speed(parent_goblin.SPEED)
			if turn_timer <= 0 and parent_goblin.is_patrol_obstacle_detected():
				parent_goblin.turn_around()
				turn_timer = TURN_COOLDOWN_PATROL
		State.CHASE:
			if player_target:
				parent_goblin.set_movement_speed(parent_goblin.CHASE_SPEED)
				parent_goblin.move_towards(player_target.global_position)
				if player_detect.overlaps_body(player_target):
					change_state(State.ATTACK)
			if chase_timer <= 0 or (losing_sight_timer <= 0 and not senses.get_node("FieldOfView").overlaps_body(player_target)):
				change_state(State.PATROL)
		State.ATTACK:
			parent_goblin.stop_movement()

# Inside StateMachine.gd

func change_state(new_state: State):
	if new_state == current_state: return
	
	# Store the old state before we change it
	var previous_state = current_state 
	current_state = new_state
	
	# This is the line to fix. Make sure you are sending BOTH arguments.
	emit_signal("state_changed", new_state, previous_state)

	# The rest of the function...
	if new_state == State.ATTACK:
		attack_controller.initiate_attack()

func _on_fov_entered(body: Node2D):
	print("DEBUG MESSAGE 2: StateMachine has received the fov_entered signal.") # <-- ADD THIS LINE
	if body.is_in_group("player"):
		player_target = body
		chase_timer = CHASE_DURATION
		change_state(State.CHASE)

func _on_fov_exited(body: Node2D):
	if body == player_target:
		losing_sight_timer = CHASE_LOSE_COOLDOWN
		
# Inside StateMachine.gd

func _on_attack_finished():
	print("DEBUG: StateMachine received 'attack_finished' signal.")
	
	# After an attack, ALWAYS go back to chasing if the target still exists.
	# The logic in the CHASE state will then decide if it should attack again.
	if player_target != null:
		print("DEBUG: Attack has finished. Returning to CHASE state.")
		change_state(State.CHASE)
	else:
		# This happens if the player was defeated or disappeared during the attack
		print("DEBUG: Attack has finished, but player target was lost. Returning to PATROL.")
		change_state(State.PATROL)
