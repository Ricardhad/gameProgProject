# StateMachine.gd (Definitive Final Version)
class_name StateMachine
extends Node

enum State { IDLE, PATROL, CHASE, PREPARE_ATTACK, ATTACK, COOLDOWN, RETREAT, HURT, DEAD }
signal state_changed(new_state: State, previous_state: State)
enum Behavior { KITER, BRAWLER, HYBRID }

@export var enemy_behavior = Behavior.HYBRID
# --- State Variables ---
var current_state: State = State.IDLE
var player_target: Node2D = null
var last_attack_type: String = ""
var can_make_attack_decision: bool = true

# --- Constants & Timers ---
const PREPARE_DURATION = 0.5
const ATTACK_COOLDOWN_DURATION = 0.4
@export var RETREAT_DURATION = 0.8 # Increased duration for more effective retreat
const DECISION_DELAY_DURATION = 0.2
@export var CHASE_DURATION = 5.0
const CHASE_LOSE_COOLDOWN = 5.0
const TURN_COOLDOWN_PATROL = 0.5
@export var SHOOTING_RANGE = 80.0
@export var MINIMUM_SHOOTING_RANGE = 50.0

var prepare_attack_timer = 0.0
var chase_timer = 0.0
var losing_sight_timer = 0.0
var turn_timer = 0.0

# --- Node References ---
@onready var senses: Node = %Senses
@onready var player_detect: Area2D = %AttackController.get_node("PlayerDetect")
@onready var attack_controller: AttackController = %AttackController
@onready var health_component: Health = %Health
@onready var parent_character = get_parent() # Renamed for clarity
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var retreat_timer: Timer = $RetreatTimer
@onready var decision_delay_timer: Timer = $DecisionDelayTimer

func _ready() -> void:
	health_component.health_depleted.connect(func(): change_state(State.DEAD))
	attack_controller.attack_finished.connect(_on_attack_finished)
	senses.get_node("FieldOfView").body_entered.connect(_on_fov_entered)
	health_component.health_changed.connect(_on_health_changed)
	
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	retreat_timer.timeout.connect(_on_retreat_timer_timeout)
	decision_delay_timer.timeout.connect(_on_decision_delay_timer_timeout)
	
	change_state(State.PATROL)

func _process(delta: float) -> void:
	if turn_timer > 0: turn_timer -= delta

	match current_state:
		State.IDLE:
			parent_character.stop_movement()

		State.PATROL:
			parent_character.set_movement_speed(parent_character.SPEED)
			if turn_timer <= 0 and parent_character.is_patrol_obstacle_detected():
				parent_character.turn_around()
				turn_timer = TURN_COOLDOWN_PATROL
				
# In StateMachine.gd, replace the old CHASE block
# In StateMachine.gd

# Replace your ENTIRE "State.CHASE" block with this one
		State.CHASE:
			if not is_instance_valid(player_target):
				change_state(State.PATROL); return
			
			var distance_to_player = player_target.global_position.distance_to(parent_character.global_position)
			
			# --- Decision-making logic block ---
			if attack_controller.is_ready_to_attack() and can_make_attack_decision:
				
				# These booleans make the logic below much cleaner
				var can_shoot = attack_controller.can_perform_attack("shoot")
				var can_melee = attack_controller.can_perform_attack("attack") || attack_controller.can_perform_attack("attack1") || attack_controller.can_perform_attack("attack2")|| attack_controller.can_perform_attack("attack3")

				# Use a match statement for clean, readable behavior control
				match enemy_behavior:
					Behavior.BRAWLER:
						# Brawlers want to melee. They only shoot if they can't melee yet.
						if can_melee and player_detect.overlaps_body(player_target):
							var chosen_attack = attack_controller._get_random_melee_attack()
							_prepare_to_attack(chosen_attack)
						elif can_shoot and distance_to_player < SHOOTING_RANGE:
							_prepare_to_attack("shoot")
					
					Behavior.KITER:
						# Kiters want to shoot. They only melee if cornered and it's their only option.
						# They will retreat if they can to get back into shooting range.
						if can_shoot and distance_to_player < MINIMUM_SHOOTING_RANGE:
							change_state(State.RETREAT)
						elif can_melee and distance_to_player < MINIMUM_SHOOTING_RANGE:
							var chosen_attack = attack_controller._get_random_melee_attack()
							_prepare_to_attack(chosen_attack) # Cornered! No choice but to melee.
						elif can_shoot and distance_to_player < SHOOTING_RANGE:
							_prepare_to_attack("shoot")

					# The "hybrid" behavior can be an alias for "kiter", or you can give it unique logic.
					# Using a comma lets both strings use the same logic block.
					Behavior.HYBRID:
						# We'll make the default Hybrid act like a Kiter.
						if can_shoot and distance_to_player < MINIMUM_SHOOTING_RANGE:
							change_state(State.RETREAT)
						elif can_melee and distance_to_player < MINIMUM_SHOOTING_RANGE:
							var chosen_attack = attack_controller._get_random_melee_attack()
							_prepare_to_attack(chosen_attack)
						elif can_shoot and distance_to_player < SHOOTING_RANGE:
							_prepare_to_attack("shoot")

					_: # Default case if the string is misspelled or empty
						print("Enemy behavior not recognized! Defaulting to kiter logic.")
						# Defaulting to kiter logic as it's the most versatile
						if can_shoot and distance_to_player < MINIMUM_SHOOTING_RANGE:
							change_state(State.RETREAT)
						elif can_melee and distance_to_player < MINIMUM_SHOOTING_RANGE:
							var chosen_attack = attack_controller._get_random_melee_attack()
							_prepare_to_attack(chosen_attack)
						elif can_shoot and distance_to_player < SHOOTING_RANGE:
							_prepare_to_attack("shoot")

			# If no attack decision was made, continue chasing the player.
			if current_state == State.CHASE:
				parent_character.set_movement_speed(parent_character.CHASE_SPEED)
				parent_character.move_towards(player_target.global_position)

		State.PREPARE_ATTACK:
			parent_character.stop_movement()
			prepare_attack_timer -= delta
			
			if not player_detect.overlaps_body(player_target) and last_attack_type == "attack":
				change_state(State.CHASE)
			elif prepare_attack_timer <= 0:
				change_state(State.ATTACK)

		State.ATTACK:
			parent_character.stop_movement()
		
		State.COOLDOWN:
			parent_character.stop_movement()

		State.RETREAT:
			if not is_instance_valid(player_target):
				change_state(State.PATROL); return
			parent_character.retreat_from(player_target.global_position)

func change_state(new_state: State):
	if new_state == current_state: return
	current_state = new_state
	emit_signal("state_changed", new_state, current_state)

	match new_state:
		State.PREPARE_ATTACK:
			prepare_attack_timer = PREPARE_DURATION
		State.ATTACK:
			attack_controller.initiate_attack(last_attack_type)
		State.COOLDOWN:
			cooldown_timer.wait_time = ATTACK_COOLDOWN_DURATION
			cooldown_timer.start()
		State.RETREAT:
			retreat_timer.wait_time = RETREAT_DURATION
			retreat_timer.start()
		State.DEAD:
			_enter_dead_state()


# This new helper function makes the logic cleaner
func _prepare_to_attack(type: String):
	last_attack_type = type
	change_state(State.PREPARE_ATTACK)

# --- Signal Handler Functions ---

func _on_fov_entered(body: Node2D):
	if body.is_in_group("player") and (current_state == State.PATROL or current_state == State.IDLE):
		player_target = body
		change_state(State.CHASE)

func _on_attack_finished():
	if current_state == State.ATTACK:
		change_state(State.COOLDOWN)

func _on_cooldown_timer_timeout():
	# This print statement is the ultimate test.
	print("COOLDOWN FINISHED. The last attack was: '", last_attack_type, "'. Making decision...")
	
	attack_controller.reset_attack_cooldown()
	
	can_make_attack_decision = false
	decision_delay_timer.start(DECISION_DELAY_DURATION)
	
	if last_attack_type == "attack":
		change_state(State.RETREAT)
	else: # Assumes "shoot" or other ranged attacks
		if is_instance_valid(player_target):
			change_state(State.CHASE)
		else:
			change_state(State.PATROL)

func _on_retreat_timer_timeout():
	can_make_attack_decision = false
	decision_delay_timer.start(DECISION_DELAY_DURATION)
	if is_instance_valid(player_target):
		change_state(State.CHASE)
	else:
		change_state(State.PATROL)

func _on_decision_delay_timer_timeout():
	can_make_attack_decision = true

func _on_health_changed(diff: int):
	if diff < 0 and current_state != State.DEAD and current_state != State.ATTACK:
		change_state(State.HURT)
		
func _enter_dead_state():
	print("Entering DEAD state. Stopping all activity.")
	
	# Stop all timers immediately to prevent them from firing after death.
	cooldown_timer.stop()
	retreat_timer.stop()
	decision_delay_timer.stop()
	
	# Stop any movement.
	parent_character.stop_movement()
	
	# Disable the main collision shape so the dead body doesn't block other actors.
	# Make sure you have a CollisionShape2D node named "CollisionShape2D"
	#var collision_shape = parent_character.get_node("CollisionShape2D")
	#collision_shape.set_deferred("disabled", true)
	
	# The StateMachine now waits for the AnimationController to finish its animation.
	# This assumes your AnimationController is on a node named "AnimatedSprite2D".
	var anim_sprite = parent_character.get_node("AnimatedSprite2D")
	
	# The 'await' keyword pauses this function here until the signal is received.
	await anim_sprite.animation_finished 
	
	# Once the animation_finished signal is received, this line runs.
	print("Death animation finished. Removing character from game.")
	parent_character.queue_free()
# Add this function to your enemy's AI script
