# StateMachine.gd (Corrected Version)
class_name StateMachine
extends Node

# ✅ CHANGE #1: Added the COOLDOWN state
enum State { IDLE, PATROL, CHASE, PREPARE_ATTACK, ATTACK, COOLDOWN, HURT, DEAD }
signal state_changed(new_state: State, previous_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null

# Timers and constants
const PREPARE_DURATION = 0.5
const ATTACK_COOLDOWN_DURATION = 0.4 # How long to wait after an attack
const CHASE_DURATION = 5.0
const CHASE_LOSE_COOLDOWN = 5.0
const TURN_COOLDOWN_PATROL = 0.5

var prepare_attack_timer = 0.0
var chase_timer = 0.0
var losing_sight_timer = 0.0
var turn_timer = 0.0

# Node references
@onready var senses: Node = %Senses
@onready var player_detect: Area2D = %AttackController.get_node("PlayerDetect")
@onready var attack_controller: AttackController = %AttackController
@onready var health_component: Health = %Health
@onready var parent_goblin = get_parent()
# ✅ CHANGE #2: Added a reference to the new timer
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	health_component.health_changed.connect(_on_health_changed)
	# ✅ CHANGE #3: Connect the cooldown timer's timeout signal
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)

	change_state(State.PATROL)

func _process(delta: float) -> void:
	if turn_timer > 0: turn_timer -= delta

	match current_state:
		State.IDLE:
			parent_goblin.stop_movement()

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
				losing_sight_timer = CHASE_LOSE_COOLDOWN
				chase_timer = CHASE_DURATION
				parent_goblin.set_movement_speed(parent_goblin.CHASE_SPEED)
				parent_goblin.move_towards(player_target.global_position)
				
				# We check the AttackController directly if it's ready
				if player_detect.overlaps_body(player_target) and attack_controller.is_ready_to_attack():
					change_state(State.PREPARE_ATTACK)
			else:
				losing_sight_timer -= delta
				parent_goblin.move_towards(player_target.global_position)
				
				if losing_sight_timer <= 0:
					player_target = null
					change_state(State.PATROL)
			
			if chase_timer > 0:
				chase_timer -= delta
				if chase_timer <= 0:
					player_target = null
					change_state(State.PATROL)
	
		State.PREPARE_ATTACK:
			parent_goblin.stop_movement()
			prepare_attack_timer -= delta
			
			if not player_detect.overlaps_body(player_target):
				change_state(State.CHASE)
			elif prepare_attack_timer <= 0:
				change_state(State.ATTACK) # Transition to the ATTACK state

		State.ATTACK:
			# Logic now happens when we enter this state via change_state()
			# We just wait here until the animation finishes.
			parent_goblin.stop_movement()
		
		State.COOLDOWN:
			# Waiting for the cooldown timer to finish. We can add logic
			# here if the player runs away during the cooldown.
			parent_goblin.stop_movement()
			if not player_detect.overlaps_body(player_target):
				change_state(State.CHASE)

func change_state(new_state: State):
	if new_state == current_state: return
	
	var previous_state = current_state
	current_state = new_state
	
	emit_signal("state_changed", new_state, previous_state)

	# Handle logic for ENTERING a new state
	match new_state:
		State.PREPARE_ATTACK:
			prepare_attack_timer = PREPARE_DURATION
		
		State.ATTACK:
			# ✅ CHANGE #4: The attack is now initiated when we enter the ATTACK state
			_perform_random_attack()
			
		State.COOLDOWN:
			# ✅ CHANGE #5: When we enter COOLDOWN, start the timer
			cooldown_timer.wait_time = ATTACK_COOLDOWN_DURATION
			cooldown_timer.start()

func _on_fov_entered(body: Node2D):
	# Only react if we are in patrol or idle
	if body.is_in_group("player") and (current_state == State.PATROL or current_state == State.IDLE):
		player_target = body
		chase_timer = CHASE_DURATION
		losing_sight_timer = CHASE_LOSE_COOLDOWN
		change_state(State.CHASE)

# ✅ CHANGE #6: Simplified logic. When the attack animation finishes, start the cooldown.
func _on_attack_finished():
	if current_state == State.ATTACK:
		change_state(State.COOLDOWN)

# ✅ CHANGE #7: This is the new, critical function.
# When the CooldownTimer finishes, this function is called.
func _on_cooldown_timer_timeout():
	# Now we tell the AttackController it is allowed to attack again.
	attack_controller.reset_attack_cooldown()
	
	# After cooldown, go back to chasing the player.
	if is_instance_valid(player_target):
		change_state(State.CHASE)
	else:
		change_state(State.PATROL)

func _on_health_changed(diff: int):
	if diff < 0:
		if current_state != State.DEAD and current_state != State.ATTACK:
			change_state(State.HURT)
			
func _perform_random_attack():
	var attack_list = attack_controller.available_attacks
	if attack_list.is_empty():
		change_state(State.CHASE)
		return

	var chosen_attack = attack_list.pick_random()
	attack_controller.initiate_attack(chosen_attack)
