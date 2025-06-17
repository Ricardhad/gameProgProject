# This script is on your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var special_attack_cooldown: float = 5.0
@export var walk_speed: float = 80.0
@export var fly_speed: float = 120.0
@export var flight_duration: float = 10.0
@export var ground_duration: float = 15.0
@export var fly_height_offset: float = 200.0 

# --- Node References ---
@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attack_timer = $AttackTimer
@onready var phase_timer = $PhaseTimer
@onready var health_component = $Health # Reference to the Health node
@onready var hurtbox = $HurtBox # Reference to the HurtBox
@onready var hitbox_pivot = $HitBox # Reference to the pivot for hitboxes

# --- State Management ---
enum State { IDLE, WALK, ATTACK, RISE, FLYING, SPECIAL_ATTACK, LANDING, DEAD }
var current_state = State.IDLE

# --- Private Variables ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player = null
var ground_y_position: float = 0.0
var target_fly_y: float = 0.0
var fly_patrol_direction = 1

# --- Godot Functions ---

func _ready():
	# Connect signals for timers and health changes
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	
	# Connect to the health signals from your Health.gd script
	health_component.health_changed.connect(_on_health_changed)
	# CORRECTED: The signal name is "health_depleted", not "no_health"
	health_component.health_depleted.connect(_on_health_depleted)

	attack_timer.wait_time = attack_cooldown
	phase_timer.wait_time = ground_duration
	phase_timer.start()
	
	change_state(State.IDLE)
	ground_y_position = global_position.y

func _physics_process(delta):
	# If we are dead, do nothing else.
	if current_state == State.DEAD:
		return

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

# --- Signal Callback Functions ---

func _on_phase_timer_timeout():
	if is_airborne():
		change_state(State.LANDING)
	else:
		ground_y_position = global_position.y
		target_fly_y = ground_y_position - fly_height_offset
		change_state(State.RISE)

func _on_health_changed(new_health):
	# Optional: You can add logic here, like flashing the sprite red.
	pass

# CORRECTED: Renamed function to match the signal from Health.gd
func _on_health_depleted():
	# This is called when health reaches zero.
	if current_state != State.DEAD: # Prevent this from being called multiple times
		change_state(State.DEAD)

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
	var target_y_pos = Vector2(global_position.x, target_fly_y)
	global_position = global_position.lerp(target_y_pos, delta * 2.0)

	if abs(global_position.y - target_fly_y) < 10:
		if attack_timer.is_stopped():
			change_state(State.SPECIAL_ATTACK)
		
		velocity.x = fly_speed * fly_patrol_direction
		sprite.flip_h = (fly_patrol_direction < 0)
		hitbox_pivot.scale.x = -1 if sprite.flip_h else 1 # Flip hitbox pivot with sprite
		
		if global_position.x > 1000:
			fly_patrol_direction = -1
		elif global_position.x < 150:
			fly_patrol_direction = 1

func handle_landing_state(delta):
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
			velocity = Vector2.ZERO
			# Disable collisions so the dragon doesn't block things while dead
			$CollisionShape2D.disabled = true
			hurtbox.monitoring = false
			animation_player.play("dead")
			# Optional: wait for death animation to finish then remove the body
			# await animation_player.animation_finished
			# queue_free()

# --- Helper Functions ---

func is_player_in_range() -> bool:
	if player:
		return global_position.distance_to(player.global_position) <= attack_range
	return false

func is_airborne() -> bool:
	return current_state in [State.RISE, State.FLYING, State.SPECIAL_ATTACK, State.LANDING]

func update_facing_direction():
	if player:
		# If player is to the right of the dragon, don't flip.
		if player.global_position.x > global_position.x:
			sprite.flip_h = false
			hitbox_pivot.scale.x = -1 # Face right
		# If player is to the left, flip.
		else:
			sprite.flip_h = true
			hitbox_pivot.scale.x = 1 # Face left
