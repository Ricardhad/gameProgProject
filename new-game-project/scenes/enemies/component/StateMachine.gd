# StateMachine.gd
class_name StateMachine
extends Node

enum State { IDLE, PATROL, CHASE, PREPARE_ATTACK, ATTACK, HURT, DEAD }
signal state_changed(new_state: State, previous_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null

# Timers and constants
const PREPARE_DURATION = 0.3
var prepare_attack_timer = 0.0
const CHASE_DURATION = 5.0
# ✅ CHANGE #1: The grace period for losing sight is now 5 seconds.
const CHASE_LOSE_COOLDOWN = 5.0 
var chase_timer = 0.0
var losing_sight_timer = 0.0
var turn_timer = 0.0
const TURN_COOLDOWN_PATROL = 0.5

# Node references
# Using % is safer once you have set them up as unique in the editor
@onready var senses: Node = %Senses
@onready var player_detect: Area2D = %AttackController.get_node("PlayerDetect")
@onready var attack_controller: AttackController = %AttackController
@onready var health_component: Health = %Health
@onready var parent_goblin = get_parent()

func _ready() -> void:
	# Connect signals from other components
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	health_component.health_changed.connect(_on_health_changed)

	# Start the goblin in patrol mode
	change_state(State.PATROL)

func _process(delta: float) -> void:
	# Update timers
	if chase_timer > 0: chase_timer -= delta
	if turn_timer > 0: turn_timer -= delta

	match current_state:
		State.IDLE:
			parent_goblin.stop_movement()
			# This state is now mostly for pausing. We could add logic
			# here to go back to patrol after a certain time.

		State.PATROL:
			parent_goblin.set_movement_speed(parent_goblin.SPEED)
			if turn_timer <= 0 and parent_goblin.is_patrol_obstacle_detected():
				parent_goblin.turn_around()
				turn_timer = TURN_COOLDOWN_PATROL

		State.CHASE:
			if not is_instance_valid(player_target):
				change_state(State.PATROL)
				return
			
			var fov_area = senses.get_node("FieldOfView")
			var proximity_area = senses.get_node("ProximitySense")
			var can_see_player = fov_area.overlaps_body(player_target) or proximity_area.overlaps_body(player_target)

			if can_see_player:
				# If we see the player, always reset the "losing sight" timer
				losing_sight_timer = CHASE_LOSE_COOLDOWN
				
				parent_goblin.set_movement_speed(parent_goblin.CHASE_SPEED)
				parent_goblin.move_towards(player_target.global_position)
				
				if player_detect.overlaps_body(player_target) and attack_controller.can_attack():
					change_state(State.PREPARE_ATTACK)
			else:
				# If we CAN'T see the player, the 5-second grace period timer starts
				losing_sight_timer -= delta
				
				# Continue to the player's last known position
				parent_goblin.move_towards(player_target.global_position)
				
				if losing_sight_timer <= 0:
					print("Lost sight of player. Reverting to patrol.")
					player_target = null
					change_state(State.PATROL)
			
			# Also, if the main chase timer runs out, give up
			if chase_timer <= 0:
				print("Chase timer ran out. Reverting to patrol.")
				player_target = null
				change_state(State.PATROL)
	
		State.PREPARE_ATTACK:
			parent_goblin.stop_movement()
			prepare_attack_timer -= delta
			
			if not player_detect.overlaps_body(player_target):
				change_state(State.CHASE)
			elif prepare_attack_timer <= 0:
				change_state(State.ATTACK)

		State.ATTACK:
			parent_goblin.stop_movement()

func change_state(new_state: State):
	if new_state == current_state: return
	
	var previous_state = current_state 
	current_state = new_state
	
	emit_signal("state_changed", new_state, previous_state)

	if new_state == State.PREPARE_ATTACK:
		prepare_attack_timer = PREPARE_DURATION
	
	if new_state == State.ATTACK:
		attack_controller.initiate_attack()

func _on_fov_entered(body: Node2D):
	if body.is_in_group("player") and current_state == State.PATROL:
		player_target = body
		chase_timer = CHASE_DURATION
		change_state(State.CHASE)
		
func _on_attack_finished():
	print("DEBUG: StateMachine received 'attack_finished' signal.")
	
	# ✅ CHANGE #2: After an attack, immediately go back to chasing the player.
	# This makes the goblin much more relentless.
	if player_target != null:
		print("DEBUG: Attack has finished. Immediately returning to CHASE state.")
		change_state(State.CHASE)
	else:
		print("DEBUG: Attack has finished, player lost. Returning to PATROL.")
		change_state(State.PATROL)
func _on_health_changed(diff: int):
	# 'diff' will be a negative number when taking damage.
	if diff < 0:
		# We only want to enter the HURT state if we aren't already dead or attacking.
		if current_state != State.DEAD and current_state != State.ATTACK:
			change_state(State.HURT)
