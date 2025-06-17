# This script is on your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var special_attack_cooldown: float = 5.0 # Separate cooldown for special attack
@export var walk_speed: float = 80.0
@export var fly_speed: float = 120.0
@export var flight_duration: float = 10.0
@export var ground_duration: float = 15.0
# MODIFIED: This is now how FAR UP the dragon flies from its starting point.
@export var fly_height_offset: float = 200.0 

# --- Node References ---
@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D # IMPORTANT: Make sure this is your Sprite2D/AnimatedSprite2D node name
@onready var attack_timer = $AttackTimer
@onready var phase_timer = $PhaseTimer

# --- State Management ---
enum State { IDLE, WALK, ATTACK, RISE, FLYING, SPECIAL_ATTACK, LANDING, DEAD }
var current_state = State.IDLE

# --- Private Variables ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var ground_y_position: float = 0.0
var target_fly_y: float = 0.0 # NEW: Stores the calculated target flight Y-coordinate.
var fly_patrol_direction = 1 # 1 for right, -1 for left

# --- Godot Functions ---

func _ready():
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	attack_timer.wait_time = attack_cooldown
	phase_timer.wait_time = ground_duration
	phase_timer.start()
	change_state(State.IDLE)
	# Store the initial position in case the dragon starts on the ground.
	ground_y_position = global_position.y

func _physics_process(delta):
	# Apply gravity ONLY when not in an airborne state.
	if not is_airborne() and not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			velocity.x = 0
			move_and_slide()
			return
	
	# The AI brain runs the logic for the current state.
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.WALK:
			handle_walk_state()
		State.FLYING:
			handle_flying_state(delta)
		State.LANDING:
			handle_landing_state(delta)

	move_and_slide()

# --- Signal Callback Function ---

func _on_phase_timer_timeout():
	print("--- PHASE TIMER TIMEOUT ---")
	if is_airborne():
		change_state(State.LANDING)
	else:
		# When it's time to take off:
		# 1. Store our current ground position so we know where to land.
		ground_y_position = global_position.y
		# 2. Calculate the absolute Y coordinate to fly to.
		target_fly_y = ground_y_position - fly_height_offset
		# 3. Start the rise sequence.
		change_state(State.RISE)

# --- State Logic Functions ---

func handle_idle_state():
	update_facing_direction()
	if not is_player_in_range():
		change_state(State.WALK)
	elif attack_timer.is_stopped():
		change_state(State.ATTACK)

func handle_walk_state():
	update_facing_direction()
	if is_player_in_range():
		change_state(State.IDLE)
	else:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * walk_speed

func handle_flying_state(delta):
	# --- Vertical Movement ---
	# CORRECTED: Move towards the pre-calculated 'target_fly_y' position.
	var target_y_pos = Vector2(global_position.x, target_fly_y)
	global_position = global_position.lerp(target_y_pos, delta * 2.0)

	# --- Attack Logic ---
	# The 'abs()' function calculates the absolute (positive) difference.
	if abs(global_position.y - target_fly_y) < 10:
		# Decide to use special attack
		if attack_timer.is_stopped():
			change_state(State.SPECIAL_ATTACK)
		
		# --- Horizontal Patrol Movement ---
		velocity.x = fly_speed * fly_patrol_direction
		sprite.flip_h = (fly_patrol_direction < 0)
		
		# Flip direction if near screen edges
		if global_position.x > 1000:
			fly_patrol_direction = -1
		elif global_position.x < 150:
			fly_patrol_direction = 1

func handle_landing_state(delta):
	# Smooth landing movement.
	var target_pos = Vector2(global_position.x, ground_y_position)
	global_position = global_position.lerp(target_pos, delta * 2.5)
	velocity.x = 0

# --- Main State-Changing Function ---

func change_state(new_state):
	if current_state == new_state and new_state != State.ATTACK and new_state != State.SPECIAL_ATTACK:
		return

	print("Changing state from ", State.keys()[current_state], " to ", State.keys()[new_state])
	current_state = new_state
	
	match new_state:
		State.IDLE:
			animation_player.play("idle")
			velocity.x = 0
		
		State.WALK:
			animation_player.play("walk")
		
		State.ATTACK:
			velocity.x = 0
			update_facing_direction()
			var attack_name = ["attack1", "attack2"].pick_random()
			animation_player.play(attack_name)
			await animation_player.animation_finished
			attack_timer.wait_time = attack_cooldown
			attack_timer.start()
			change_state(State.IDLE)
			
		State.RISE:
			velocity = Vector2.ZERO
			animation_player.play("rise")
			await animation_player.animation_finished
			phase_timer.wait_time = flight_duration
			phase_timer.start()
			change_state(State.FLYING)

		State.FLYING:
			animation_player.play("flying")
			if attack_timer.is_stopped():
				attack_timer.wait_time = 0.5
				attack_timer.start()
			
		State.SPECIAL_ATTACK:
			velocity.x = 0
			animation_player.play("special")
			await animation_player.animation_finished
			attack_timer.wait_time = special_attack_cooldown
			attack_timer.start()
			change_state(State.FLYING)

		State.LANDING:
			animation_player.play("landing")
			await animation_player.animation_finished
			phase_timer.wait_time = ground_duration
			phase_timer.start()
			change_state(State.IDLE)
			
		State.DEAD:
			animation_player.play("dead")

# --- Helper Functions ---

func is_player_in_range() -> bool:
	if player:
		return global_position.distance_to(player.global_position) <= attack_range
	return false

func is_airborne() -> bool:
	return current_state in [State.RISE, State.FLYING, State.SPECIAL_ATTACK, State.LANDING]

func update_facing_direction():
	if player:
		if player.global_position.x > global_position.x:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
