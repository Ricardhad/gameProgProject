# StateMachine.gd (Corrected and Final Version)
class_name StateMachine
extends Node

enum State { IDLE, PATROL, CHASE, PREPARE_ATTACK, ATTACK, COOLDOWN, HURT, DEAD }
signal state_changed(new_state: State, previous_state: State)

var current_state: State = State.IDLE
var player_target: Node2D = null

# ✅ FIX #1: This variable will store our chosen attack type.
var next_attack_type: String = ""

# Timers and constants
const PREPARE_DURATION = 0.5
const ATTACK_COOLDOWN_DURATION = 0.4
const CHASE_DURATION = 5.0
const CHASE_LOSE_COOLDOWN = 5.0
const TURN_COOLDOWN_PATROL = 0.5
const SHOOTING_RANGE = 300.0

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
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	health_component.health_changed.connect(_on_health_changed)
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
				
				# ✅ FIX #2: ALL attack logic is now in one unified block.
				# This replaces the old logic completely.
				if attack_controller.is_ready_to_attack():
					# ✅ FIX #3: Calculate distance to player HERE, every frame.
					var distance_to_player = player_target.global_position.distance_to(parent_goblin.global_position)
					
					# If player is far away, decide to shoot
					if distance_to_player > SHOOTING_RANGE:
						next_attack_type = "shoot"
						change_state(State.PREPARE_ATTACK) # Go to PREPARE, not ATTACK
					# If player is close, decide to do a melee attack
					elif player_detect.overlaps_body(player_target):
						next_attack_type = "attack"
						change_state(State.PREPARE_ATTACK) # Go to PREPARE, not ATTACK
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
			
			if not player_detect.overlaps_body(player_target) and next_attack_type == "attack":
				change_state(State.CHASE)
			elif prepare_attack_timer <= 0:
				change_state(State.ATTACK)

		State.ATTACK:
			parent_goblin.stop_movement()
		
		State.COOLDOWN:
			# ✅ FIX #4: Removed the logic that allowed the cooldown to be cancelled.
			# The goblin MUST wait for its cooldown to finish.
			parent_goblin.stop_movement()

func change_state(new_state: State):
	if new_state == current_state: return
	
	var previous_state = current_state
	current_state = new_state
	
	emit_signal("state_changed", new_state, previous_state)

	match new_state:
		State.PREPARE_ATTACK:
			prepare_attack_timer = PREPARE_DURATION
		
		State.ATTACK:
			# ✅ FIX #5: Call our new, non-random attack function.
			_perform_chosen_attack()
			
		State.COOLDOWN:
			cooldown_timer.wait_time = ATTACK_COOLDOWN_DURATION
			cooldown_timer.start()

# ✅ FIX #7: This function is now deterministic, not random.
func _perform_chosen_attack():
	# Perform the attack that was decided on in the CHASE state.
	if next_attack_type != "":
		attack_controller.initiate_attack(next_attack_type)
	else:
		# Failsafe in case something went wrong
		change_state(State.CHASE)

# --- Signal Handlers ---

func _on_fov_entered(body: Node2D):
	if body.is_in_group("player") and (current_state == State.PATROL or current_state == State.IDLE):
		player_target = body
		chase_timer = CHASE_DURATION
		losing_sight_timer = CHASE_LOSE_COOLDOWN
		change_state(State.CHASE)

func _on_attack_finished():
	if current_state == State.ATTACK:
		change_state(State.COOLDOWN)

func _on_cooldown_timer_timeout():
	attack_controller.reset_attack_cooldown()
	if is_instance_valid(player_target):
		change_state(State.CHASE)
	else:
		change_state(State.PATROL)

func _on_health_changed(diff: int):
	if diff < 0:
		if current_state != State.DEAD and current_state != State.ATTACK:
			change_state(State.HURT)
