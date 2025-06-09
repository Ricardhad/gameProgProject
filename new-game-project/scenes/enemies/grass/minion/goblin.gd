extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D # Ground detection ahead (for cliffs)
@onready var ray_cast_2d_2: RayCast2D = $RayCast2D2 # Wall detection (in front)
@onready var ray_cast_2d_jump_check: RayCast2D = $RayCast2DJumpCheck # For jump landing check

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurt_box_collision_shape: CollisionShape2D = $HurtBox/CollisionShape2D # Renamed for clarity
@onready var player_detect_area: Area2D = $PlayerDetect # Corrected: Reference the Area2D directly
@onready var hit_box_area: Area2D = $HitBox # Corrected: Reference the Area2D directly

@onready var health: Health = $Health
@export var coin_scene: PackedScene

@onready var field_of_view: Area2D = $FieldOfView
@onready var proximity_sense: Area2D = $ProximitySense


# Attack variables
const ATTACK_COOLDOWN = 1.0 # Time in seconds between attacks
var attack_timer = 0.0 # Timer to track cooldown
var is_attacking = false # Flag to indicate if an attack animation is currently playing
var has_attacked_this_animation = false # Ensures damage is dealt only once per attack animation

var is_dead = false
const GRAVITY = 800.0
const SPEED = 50.0
const JUMP_VELOCITY = -300.0 # Adjust this value for higher/lower jumps

var direction = -1 # -1 for left, 1 for right
var is_walking = true # This is mostly for patrol mode
var state_timer = 0.0
var next_state_time = 0.0
var can_jump = true

var raycast_original_x = 0.0
var raycast_original_x1 = 0.0
var raycast_original_x_jump_check = 0.0

var raycast2_target_original_x = 0.0
var raycast2_target_original_x_jump_check = 0.0

var collision_shape_original_x = 0.0
var hurt_box_original_x = 0.0 # Original x for HurtBox's collision shape (if needed, otherwise just HurtBox's Area2D position)
var player_detect_original_x = 0.0 # Original x for PlayerDetect Area2D
var hit_box_original_x = 0.0 # Original x for HitBox Area2D

var hitbox_shift = 7.5 # Keep if used for raycasts, otherwise remove if not needed for collision shapes
var current_animation: String = ""
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_FORCE = 200.0

const CHASE_SPEED = 100.0
const CHASE_DURATION = 5.0
var is_chasing = false
var chase_timer = 0.0
var is_stopped_chasing = false # Represents a temporary pause in movement while chasing

var is_player_in_proximity = false # Flag for player in proximity (e.g., for maintaining chase)

const CHASE_LOSE_COOLDOWN = 1.5 # Time in seconds before truly stopping chase (was 0.5)
var losing_sight_timer = 0.0

# Variables for smoother turning
const TURN_THRESHOLD = 5.0 # How far the player must be from goblin's center to trigger turn in chase
const TURN_COOLDOWN_CHASE = 0.2 # Cooldown for turning while chasing
const TURN_COOLDOWN_PATROL = 0.5 # NEW: Cooldown for turning while patrolling
var turn_timer = 0.0 # Single timer used for both, managed differently

func _ready() -> void:
	randomize()
	_set_next_state_time()
	raycast_original_x = abs(ray_cast_2d.position.x)
	raycast_original_x1 = abs(ray_cast_2d_2.position.x)
	raycast_original_x_jump_check = abs(ray_cast_2d_jump_check.position.x)

	raycast2_target_original_x = abs(ray_cast_2d_2.target_position.x)
	raycast2_target_original_x_jump_check = abs(ray_cast_2d_jump_check.target_position.x)

	collision_shape_original_x = abs(collision_shape.position.x)
	hurt_box_original_x = abs(hurt_box_collision_shape.position.x)
	player_detect_original_x = abs(player_detect_area.position.x)
	hit_box_original_x = abs(hit_box_area.position.x)

	health.health_changed.connect(_on_health_changed)

	#field_of_view.body_entered.connect(_on_field_of_view_body_entered)
	field_of_view.body_exited.connect(_on_field_of_view_body_exited)
	proximity_sense.body_entered.connect(_on_proximity_sense_body_entered)
	proximity_sense.body_exited.connect(_on_proximity_sense_body_exited)
	
	#player_detect_area.body_entered.connect(_on_player_detect_body_entered)
	#player_detect_area.body_exited.connect(_on_player_detect_body_exited)
	hit_box_area.body_entered.connect(_on_hit_box_area_body_entered)

func _on_health_changed(diff: int) -> void:
	if is_dead:
		return

	if diff < 0 and current_animation != "attack":
		play_animation("hurt", true)

		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = sign(global_position.x - player.global_position.x)
			knockback_velocity.x = KNOCKBACK_FORCE * dir

func play_animation(anim: String, force: bool = false):
	if current_animation == "dead":
		return
	if animated_sprite_2d.animation == anim and not force:
		return # Animation is already playing, do nothing, don't restart it unless forced

	if force or animated_sprite_2d.animation != anim:
		current_animation = anim
		animated_sprite_2d.play(anim)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.y += GRAVITY * delta

	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	if turn_timer > 0:
		turn_timer -= delta
	
	# Check losing sight cooldown
	if is_chasing and losing_sight_timer > 0:
		losing_sight_timer -= delta
		if losing_sight_timer <= 0:
			is_chasing = false
			is_player_in_proximity = false
			is_stopped_chasing = false
			velocity.x = 0
			print("Stopped chasing due to losing sight cooldown.")

	if is_on_floor():
		can_jump = true
		if current_animation == "jump":
			current_animation = "" # Allow _process to set idle/run/walk after landing

	# --- Handle fixed movement for attack/hurt states ---
	if current_animation in ["attack", "hurt"]:
		velocity.x = 0.0 # Always stop horizontal movement during these
		if current_animation == "hurt":
			velocity.x = knockback_velocity.x
			knockback_velocity.x = move_toward(knockback_velocity.x, 0, 800 * delta)
		move_and_slide()
		return # Crucial: Skip AI logic if actively attacking or hurt

	# --- Determine Desired Horizontal Velocity (before applying) ---
	var desired_x_velocity = 0.0
	var player_node = get_tree().get_first_node_in_group("player") # Get player once per frame

	# Main AI State Machine: Chasing vs. Patrolling
	if is_chasing:
		# Reset losing sight timer if player is in range
		if is_player_in_proximity or (player_node and field_of_view.overlaps_body(player_node)):
			losing_sight_timer = 0.0

		chase_timer -= delta
		if chase_timer <= 0.0:
			is_chasing = false
			is_player_in_proximity = false
			is_stopped_chasing = false
			desired_x_velocity = 0.0
			print("Stopped chasing due to chase timer.")

		if player_node: # Ensure player still exists before accessing
			var player_relative_x = player_node.global_position.x - global_position.x
			var target_direction = sign(player_relative_x)

			# --- Turning Logic for Chasing ---
			# NEW: Simplified turning logic to reduce `is_stopped_chasing` fluctuations
			if not is_attacking:
				if target_direction != direction and turn_timer <= 0 and target_direction != 0:
					direction = target_direction
					_update_raycasts_and_collision_shapes(direction)
					is_stopped_chasing = true # Pause for turning
					turn_timer = TURN_COOLDOWN_CHASE
				elif is_stopped_chasing and turn_timer <= 0: # If was stopped for turning and cooldown over
					is_stopped_chasing = false # Allow movement again
			else: # If attacking, ensure stopped state
				is_stopped_chasing = true
			# --- End Turning Logic ---

			# --- Chasing Movement and Jump Logic ---
			# Only calculate movement if not stopped AND not attacking
			if not is_stopped_chasing and not is_attacking:
				# Check for WALL/OBSTACLE
				if ray_cast_2d_2.is_colliding() and is_on_floor() and can_jump and current_animation != "jump":
					ray_cast_2d_jump_check.force_raycast_update()
					if ray_cast_2d_jump_check.is_colliding():
						play_animation("jump", true)
						velocity.y = JUMP_VELOCITY
						can_jump = false
						print("Chasing: Jumping over WALL/OBSTACLE")
						desired_x_velocity = CHASE_SPEED * direction
					else:
						# Cannot jump over wall safely, stop.
						desired_x_velocity = 0.0
						print("Chasing: Cannot jump over wall, stopping.") # Don't set is_stopped_chasing here
				# Check for CLIFF
				elif not ray_cast_2d.is_colliding() and is_on_floor() and can_jump and current_animation != "jump":
					ray_cast_2d_jump_check.force_raycast_update()
					if ray_cast_2d_jump_check.is_colliding():
						play_animation("jump", true)
						velocity.y = JUMP_VELOCITY
						can_jump = false
						print("Chasing: Jumping over CLIFF")
						desired_x_velocity = CHASE_SPEED * direction
					else:
						# Cannot jump over cliff safely, stop.
						desired_x_velocity = 0.0
						print("Chasing: Cannot jump over cliff, stopping.") # Don't set is_stopped_chasing here
				# Continue running if no obstacles / jumps needed
				else:
					desired_x_velocity = CHASE_SPEED * direction
			else: # If stopped_chasing or is_attacking, halt velocity
				desired_x_velocity = 0.0
		else: # Player node not found, revert to patrol
			is_chasing = false
			is_player_in_proximity = false
			is_stopped_chasing = false
			desired_x_velocity = 0.0
			print("Player lost (target disappeared), stopping chase.")

	else: # Not chasing (Patrol Mode)
		_update_raycasts_and_collision_shapes(direction)

		is_player_in_proximity = false # Clear proximity flags when patrolling

		if is_walking:
			# Apply cooldown for patrol turning
			if turn_timer <= 0 and (not ray_cast_2d.is_colliding() or ray_cast_2d_2.is_colliding()):
				direction *= -1
				turn_timer = TURN_COOLDOWN_PATROL # Start cooldown
				print("Patrol: Obstacle/cliff detected, turning around.")
				desired_x_velocity = 0.0 # Stop movement immediately while turning
			# If on cooldown AND still hitting obstacle/cliff, stay still
			elif turn_timer > 0 and (not ray_cast_2d.is_colliding() or ray_cast_2d_2.is_colliding()):
				desired_x_velocity = 0.0
			# Continue walking if no obstacle or not on cooldown
			else:
				desired_x_velocity = SPEED * direction
		else: # if not walking, velocity is 0
			desired_x_velocity = 0.0

	# Apply the determined horizontal velocity
	velocity.x = desired_x_velocity
	move_and_slide() # This MUST be at the very end of _physics_process

# Helper function to update raycasts and collision shapes based on direction
func _update_raycasts_and_collision_shapes(current_direction: int) -> void:
	var current_x_sign = float(current_direction)

	ray_cast_2d.position.x = raycast_original_x * current_x_sign
	ray_cast_2d_2.position.x = raycast_original_x1 * current_x_sign
	ray_cast_2d_2.target_position.x = raycast2_target_original_x * current_x_sign
	ray_cast_2d_jump_check.position.x = raycast_original_x_jump_check * current_x_sign
	ray_cast_2d_jump_check.target_position.x = raycast2_target_original_x_jump_check * current_x_sign

	collision_shape.position.x = collision_shape_original_x * current_x_sign
	hurt_box_collision_shape.position.x = hurt_box_original_x * current_x_sign
	
	player_detect_area.position.x = player_detect_original_x * current_x_sign
	hit_box_area.position.x = hit_box_original_x * current_x_sign

	animated_sprite_2d.flip_h = current_direction < 0

	field_of_view.scale.x = current_x_sign
	proximity_sense.scale.x = current_x_sign

func _process(delta: float) -> void:
	# Block _process from overriding specific animations
	if is_dead or current_animation in ["attack", "hurt", "dead", "jump"]:
		return

	var new_anim = ""
	# Determine if actually moving horizontally for animation purposes
	var is_actually_moving_horizontally = abs(velocity.x) > 0.1 and is_on_floor()

	if is_chasing:
		if is_attacking:
			new_anim = "attack"
		elif is_stopped_chasing: # Goblin is paused (e.g., turning)
			new_anim = "idle"
		elif not is_on_floor(): # In air (jump or fall)
			new_anim = "jump"
		elif is_actually_moving_horizontally:
			new_anim = "run"
		else: # Chasing but standing still on ground
			new_anim = "idle"
	else: # Patrolling
		if turn_timer > 0 and (not ray_cast_2d.is_colliding() or ray_cast_2d_2.is_colliding()):
			new_anim = "idle" # Play idle while waiting to turn
		elif not is_on_floor():
			new_anim = "idle" # Or "fall" if you have one
		elif is_actually_moving_horizontally:
			new_anim = "walk"
		else: # Not moving on ground
			new_anim = "idle"

	if animated_sprite_2d.animation != new_anim:
		play_animation(new_anim)

func _on_health_health_depleted() -> void:
	is_dead = true
	current_animation = "dead"
	animated_sprite_2d.play("dead")
	velocity = Vector2.ZERO

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation in ["attack", "hurt"]:
		current_animation = ""
		if animated_sprite_2d.animation == "attack":
			is_attacking = false
			has_attacked_this_animation = false # Reset damage flag for the next attack
	elif animated_sprite_2d.animation == "dead":
		drop_coins()
		queue_free()

func _set_next_state_time() -> void:
	next_state_time = randf_range(1.0, 3.0)

# --- Field of View: Triggers initial chase ---
func _on_field_of_view_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Only fully re-initialize chase state if not already actively chasing
		# This prevents resetting chase_timer and other flags if already chasing and just briefly left/re-entered FOV
		if not is_chasing or (is_chasing and losing_sight_timer > 0):
			is_chasing = true
			chase_timer = CHASE_DURATION # Reset chase timer
			losing_sight_timer = 0.0 # Clear any active losing sight timer
			is_stopped_chasing = false
			turn_timer = 0.0 # Reset turn timer when starting chase
			print("Player entered Field of View, chasing!")
		else:
			# Already actively chasing, just ensure losing_sight_timer is reset
			losing_sight_timer = 0.0
			print("Player re-entered FOV, but already actively chasing.")

func _on_field_of_view_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		losing_sight_timer = CHASE_LOSE_COOLDOWN # Start cooldown
		print("Player exited Field of View, starting lose sight cooldown.")

# --- Proximity Sense: Maintains chase when player is very close ---
func _on_proximity_sense_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_chasing:
		is_player_in_proximity = true
		losing_sight_timer = 0.0 # Reset losing sight timer to maintain chase
		print("Player entered Proximity Sense (while chasing) - Maintaining chase.")

func _on_proximity_sense_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_in_proximity = false
		print("Player exited Proximity Sense.")

# --- PlayerDetect (Area2D) - Triggers Attack Initiation ---
func _on_player_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_chasing and attack_timer <= 0 and not is_attacking:
		play_animation("attack", true) # Force attack animation
		is_attacking = true # Set attacking flag
		has_attacked_this_animation = false # Reset damage flag for next attack
		velocity.x = 0 # Stop to attack
		is_stopped_chasing = true # Halt chase movement
		attack_timer = ATTACK_COOLDOWN # Start attack cooldown
		print("Goblin: Initiating attack on player!")

func _on_player_detect_body_exited(body: Node2D) -> void:
	pass

# --- HitBox (Area2D) - Deals Damage ---
func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_attacking and not has_attacked_this_animation:
		print("Goblin attacked player! Dealing damage.")
		# Example:
		# if body.has_method("take_damage"):
		#     body.take_damage(10) # Adjust damage value as needed
		has_attacked_this_animation = true # Prevent repeated damage for this attack animation

func drop_coins() -> void:
	if coin_scene == null:
		print("Coin scene not assigned!")
		return

	var coin_count = randi_range(1, 5)
	for i in coin_count:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-8, 8), -8)

		var player = get_tree().get_first_node_in_group("player")
		if player:
			coin.player = player
			print("finding player")
