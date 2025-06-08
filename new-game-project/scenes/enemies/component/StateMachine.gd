# StateMachine.gd
class_name StateMachine
extends Node
# In StateMachine.gd, at the top
enum State { IDLE, PATROL, CHASE, PREPARE_ATTACK, ATTACK, HURT, DEAD } # <-- Added PREPARE_ATTACK
signal state_changed(new_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null
# In StateMachine.gd, with your other variables
const PREPARE_DURATION = 0.3
var prepare_attack_timer = 0.0
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
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	
	change_state(State.PATROL)

func _process(delta: float) -> void:
	# Update timers
	if chase_timer > 0: chase_timer -= delta
	if losing_sight_timer > 0: losing_sight_timer -= delta
	if turn_timer > 0: turn_timer -= delta

	match current_state:
		State.IDLE:
			parent_goblin.stop_movement()
			# If the player is in melee range AND we can attack (cooldown is over)...
			if player_detect.overlaps_body(player_target) and attack_controller.can_attack():
				# ...then attack again!
				change_state(State.ATTACK)
			# If the player is NOT in melee range, but still visible...
			elif not player_detect.overlaps_body(player_target) and senses.get_node("FieldOfView").overlaps_body(player_target):
				# ...then go back to chasing.
				change_state(State.CHASE)
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
			
			# ✅ CHANGE #2: Let's check these booleans separately for debugging
			var is_in_fov = fov_area.overlaps_body(player_target)
			var is_in_proximity = proximity_area.overlaps_body(player_target)
			var can_see_player = is_in_fov or is_in_proximity
			
			# This print will tell us exactly what the goblin sees
			# print("In FOV: ", is_in_fov, " | In Proximity: ", is_in_proximity)

			if can_see_player:
				# If we see the player, always reset the "losing sight" timer
				losing_sight_timer = CHASE_LOSE_COOLDOWN
				
				parent_goblin.set_movement_speed(parent_goblin.CHASE_SPEED)
				parent_goblin.move_towards(player_target.global_position)
				
				if player_detect.overlaps_body(player_target) and attack_controller.can_attack():
					change_state(State.PREPARE_ATTACK)
			else:
				# If we CAN'T see the player in either sense, start the grace period timer
				losing_sight_timer -= delta
				
				# Continue to the player's last known position
				parent_goblin.move_towards(player_target.global_position)
				
				if losing_sight_timer <= 0:
					print("Lost sight of player. Reverting to patrol.")
					player_target = null
					change_state(State.PATROL)
			
			chase_timer -= delta
			if chase_timer <= 0:
				print("Chase timer ran out. Reverting to patrol.")
				player_target = null
				change_state(State.PATROL)
	
		State.PREPARE_ATTACK:
			parent_goblin.stop_movement()
			prepare_attack_timer -= delta

		# If the player runs away during the wind-up, go back to chasing
			if not player_detect.overlaps_body(player_target):
				change_state(State.CHASE)
				# If the timer finishes and the player is still here, attack!
			elif prepare_attack_timer <= 0:
				change_state(State.ATTACK)

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
	if new_state == State.PREPARE_ATTACK:
		prepare_attack_timer = PREPARE_DURATION
	# The rest of the function...
	if new_state == State.ATTACK:
		attack_controller.initiate_attack()

func _on_fov_entered(body: Node2D):
	print("DEBUG MESSAGE 2: StateMachine has received the fov_entered signal.") # <-- ADD THIS LINE
	if body.is_in_group("player") and current_state == State.PATROL:
		player_target = body
		chase_timer = CHASE_DURATION
		change_state(State.CHASE)

#func _on_fov_exited(body: Node2D):
	#if body == player_target:
		#losing_sight_timer = CHASE_LOSE_COOLDOWN
		
# Inside StateMachine.gd

func _on_attack_finished():
	print("DEBUG: StateMachine received 'attack_finished' signal.")
	
	# After an attack, don't chase immediately. Go IDLE and wait.
	# The logic in the IDLE state will decide what to do next.
	if player_target != null:
		print("DEBUG: Attack has finished. Entering IDLE to wait for cooldown.")
		change_state(State.IDLE)
	else:
		print("DEBUG: Attack has finished, player lost. Returning to PATROL.")
		change_state(State.PATROL)
