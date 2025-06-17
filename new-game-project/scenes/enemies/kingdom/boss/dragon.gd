# This script is on your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var walk_speed: float = 80.0
@export var flight_duration: float = 10.0
@export var ground_duration: float = 15.0
@export var fly_height: float = 100.0 # This is a Y-coordinate on the screen

# --- Node References ---
@onready var animation_player = $AnimationPlayer
@onready var attack_timer = $AttackTimer
@onready var phase_timer = $PhaseTimer

# --- State Management ---
enum State { IDLE, WALK, ATTACK, RISE, FLYING, SPECIAL_ATTACK, LANDING, DEAD }
var current_state = State.IDLE

# --- Private Variables ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null

# --- Godot Functions ---

func _ready():
	# Connect the timer's timeout signal to our phase-changing function
	phase_timer.timeout.connect(_on_phase_timer_timeout)

	attack_timer.wait_time = attack_cooldown
	phase_timer.wait_time = ground_duration
	phase_timer.start()
	
	change_state(State.IDLE)


func _physics_process(delta):
	# Apply gravity ONLY when not in an airborne state.
	if not is_airborne():
		if not is_on_floor():
			velocity.y += gravity * delta
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			velocity.x = 0
			move_and_slide()
			return
	
	# The decision to change phase is now handled by the timer's signal.
	# The AI brain is now much simpler.
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.WALK:
			handle_walk_state()
		State.FLYING:
			handle_flying_state(delta)

	move_and_slide()

# --- Signal Callback Function ---

func _on_phase_timer_timeout():
	# This function is ONLY called when the PhaseTimer finishes.
	print("--- PHASE TIMER TIMEOUT ---")
	if is_airborne():
		change_state(State.LANDING)
	else:
		change_state(State.RISE)

# --- State Logic Functions ---

func handle_idle_state():
	if not is_player_in_range():
		change_state(State.WALK)
	elif attack_timer.is_stopped():
		change_state(State.ATTACK)

func handle_walk_state():
	if is_player_in_range():
		change_state(State.IDLE)
	else:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * walk_speed

func handle_flying_state(delta):
	# Move towards the target flying height
	var target_pos = Vector2(global_position.x, fly_height)
	# Lerp smoothly moves the dragon towards the target position over time
	global_position = global_position.lerp(target_pos, delta * 2.0)

	# Decide to use special attack
	if attack_timer.is_stopped():
		change_state(State.SPECIAL_ATTACK)

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
			var attack_name = ["attack1", "attack2"].pick_random()
			animation_player.play(attack_name)
			await animation_player.animation_finished
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
			velocity = Vector2.ZERO # Stop gravity/falling while flying
			
		State.SPECIAL_ATTACK:
			animation_player.play("special")
			await animation_player.animation_finished
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
