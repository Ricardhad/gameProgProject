# This script is on your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var walk_speed: float = 80.0
@export var flight_duration: float = 10.0 # How long the dragon stays in the air
@export var ground_duration: float = 5.0 # How long the dragon stays on the ground
@export var fly_height: float = 100.0 # How high up the screen the dragon flies

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
	attack_timer.wait_time = attack_cooldown
	phase_timer.wait_time = ground_duration
	phase_timer.start()
	change_state(State.IDLE)

func _physics_process(delta):
	# Apply gravity ONLY if the dragon is on the ground.
	if not is_airborne():
		if not is_on_floor():
			velocity.y += gravity * delta
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			velocity.x = 0
			move_and_slide()
			return
			
	# --- Main State Logic ---
	match current_state:
		State.IDLE, State.WALK:
			handle_ground_state()
		State.FLYING:
			handle_flying_state(delta)
		State.ATTACK, State.RISE, State.SPECIAL_ATTACK, State.LANDING, State.DEAD:
			# In these states, we are waiting for an animation to finish, so we do nothing here.
			pass
			
	move_and_slide()

# --- State Logic Functions ---

func handle_ground_state():
	# This function handles all ground-based logic (idle and walk)
	if phase_timer.is_stopped(): # Time to change phase!
		change_state(State.RISE)
		return

	var player_in_range = is_player_in_range()
	if player_in_range:
		change_state(State.IDLE)
		if attack_timer.is_stopped():
			change_state(State.ATTACK)
	else:
		change_state(State.WALK)
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * walk_speed

func handle_flying_state(delta):
	# This function handles all air-based logic
	if phase_timer.is_stopped(): # Time to change phase!
		change_state(State.LANDING)
		return

	# Move towards the target flying height
	var target_pos = Vector2(global_position.x, fly_height)
	global_position = global_position.lerp(target_pos, delta * 2.0)
	# Add some horizontal flying movement logic here if you want
	# e.g., velocity.x = 100
	
	# Decide to use special attack
	if attack_timer.is_stopped():
		change_state(State.SPECIAL_ATTACK)

# --- Main State-Changing Function ---

func change_state(new_state):
	if current_state == new_state and new_state != State.ATTACK:
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
			velocity = Vector2.ZERO # Stop all movement to rise
			animation_player.play("rise")
			await animation_player.animation_finished
			phase_timer.wait_time = flight_duration # Set the timer for how long to fly
			phase_timer.start()
			change_state(State.FLYING)

		State.FLYING:
			animation_player.play("flying")
			
		State.SPECIAL_ATTACK:
			animation_player.play("special")
			await animation_player.animation_finished
			attack_timer.start() # Start cooldown after special attack
			change_state(State.FLYING) # Go back to flying after the attack

		State.LANDING:
			animation_player.play("landing")
			await animation_player.animation_finished
			phase_timer.wait_time = ground_duration # Set timer for how long to be on ground
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
	# A helper to check if we are in any of the flying-related states
	return current_state in [State.RISE, State.FLYING, State.SPECIAL_ATTACK, State.LANDING]
