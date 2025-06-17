extends CharacterBody2D

# --- Player Movement Constants ---
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 350.0
const DASH_DURATION = 0.3
const HANG_GRACE_TIME = 0.2

# --- Cooldowns ---
var dash_cooldown_timer = 0.0
var jump_cooldown_timer = 0.0
var jump_cd = 2.0 # Use float for consistency with delta
var dash_cd = 2.0 # Use float for consistency with delta

# Heavy Attack Bar System
var heavy_atk_charges = 0 # Current number of heavy attack charges
const MAX_HEAVY_ATK_CHARGES = 3 # Maximum charges
var heavy_atk_recharge_timer = 0.0 # Timer for recharging a single charge
const HEAVY_ATK_RECHARGE_TIME_PER_CHARGE = 2.0 # Time to recharge one charge (2 seconds)

# --- Player State Variables ---
# Define all possible states for the player
enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH,
	ATTACK,
	HEAVY_ATTACK,
	HEAL,
	HANG,
	CLIMB_UP, # When performing the pull_up animation
	DROP_DOWN # When actively dropping through a platform
}
var current_state: PlayerState = PlayerState.IDLE # Initialize starting state

var is_hanging = false # Keep for convenience with can_hang() helper function
var hang_grace_timer = 0.0
var dash_time = 0.0
var jump_count = 0
var max_jumps = 2

var current_attack_index = 0
var attack_animations = ["attack", "attack1"] # Ground attacks sequence
var air_attack_animation = "air_attack" # If you have a unique air attack animation (not currently used by your code, but kept for potential)


# --- Node References ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var attack_area_1: CollisionShape2D = $HitBox/Attack
@onready var attack_area_2: CollisionShape2D = $HitBox2/Attack
@onready var health: Health = $Health
@onready var hud = get_node("/root/game/Hud") # Make sure your HUD node path is correct

var respawn_position = Vector2(150, 150)
var original_attack_offset_x = 0.0
var original_attack2_offset_x = 0.0

func _ready():
	original_attack_offset_x = attack_area_1.position.x
	original_attack2_offset_x = attack_area_2.position.x
	randomize()
	
	# Set HitBox damage from GlobalVar
	$HitBox.damage = GlobalVar.damage_player
	$HitBox2.damage = GlobalVar.damage_player * 2
	health.sync_with_global = true
	health.set_max_health(GlobalVar.maxhealth_player)
	health.set_health(GlobalVar.health_player)
	
	# Initialize heavy attack charges
	heavy_atk_charges = MAX_HEAVY_ATK_CHARGES
	# If you want to update HUD immediately, assuming HUD has a method for this:
	if hud: 
		hud.update_heavy_attack_charges(heavy_atk_charges,MAX_HEAVY_ATK_CHARGES)
		hud.set_player_node(self) # <-- Corrected: Pass 'self' here
	# Connect the health depletion signal
	health.connect("health_depleted", Callable(self, "_on_health_depleted"))

	# Connect animation finished signal once for all states that need it
	animated_sprite_2d.animation_finished.connect(Callable(self, "_on_animated_sprite_2d_animation_finished"))
	
	# Set initial state
	set_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
	# --- 1. Handle Cooldown Timers (Always run) ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if jump_cooldown_timer > 0:
		jump_cooldown_timer -= delta
	
	# --- Heavy Attack Bar Recharge Logic ---
	if heavy_atk_charges < MAX_HEAVY_ATK_CHARGES:
		heavy_atk_recharge_timer += delta
		if heavy_atk_recharge_timer >= HEAVY_ATK_RECHARGE_TIME_PER_CHARGE:
			heavy_atk_charges += 1
			heavy_atk_recharge_timer = 0.0 # Reset timer for the next charge
			# Update HUD to show new charge count
			if hud:
				hud.update_heavy_attack_charges(heavy_atk_charges, MAX_HEAVY_ATK_CHARGES) # <-- Add this line
	# --- 2. Handle Game State Overrides (e.g., Respawn) ---
	if global_position.y > 1000:
		global_position = respawn_position
		velocity = Vector2.ZERO
		set_state(PlayerState.IDLE) # Reset state on respawn
		return # Exit early after respawn, new frame will process from new state

	# --- 3. Process Player State Machine ---
	# The 'match' statement ensures only one state's logic runs per frame.
	match current_state:
		PlayerState.IDLE, PlayerState.RUN, PlayerState.JUMP, PlayerState.FALL:
			handle_normal_movement(delta)
			handle_normal_animations() # Update animations based on normal movement
		PlayerState.DASH:
			handle_dash_state(delta)
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			handle_attack_state(delta)
		PlayerState.HEAL:
			handle_heal_state(delta)
		PlayerState.HANG:
			handle_hang_state()
		PlayerState.CLIMB_UP:
			handle_climb_up_state(delta)
		PlayerState.DROP_DOWN:
			handle_drop_down_state(delta)

	# --- 4. Final Movement Execution (Always run once per frame) ---
	# This ensures move_and_slide is called regardless of the current state.
	# The velocity will have been set by the active state handler.
	move_and_slide()


# --- State Transition Function ---
# This is the ONLY function that should change the player's 'current_state'.
func set_state(new_state: PlayerState):
	if current_state == new_state:
		return # No state change needed

	# --- Exit Logic for Previous State ---
	# Perform any cleanup when leaving a state.
	match current_state:
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			attack_area_1.disabled = true
			attack_area_2.disabled = true
			if hud:
				hud.set_attack_button_pressed(false) # Reset button visual (if applicable)
		PlayerState.DASH:
			pass
		PlayerState.HEAL:
			pass
		# Add any other states that require cleanup when exiting

	current_state = new_state # Update the state

	# --- Entry Logic for New State ---
	# Set up animations, initial velocities, enable/disable collision, etc.
	match current_state:
		PlayerState.IDLE:
			animated_sprite_2d.animation = "idle"
			animated_sprite_2d.play() # Ensure animation starts playing
			velocity.x = 0 # Ensure stops on idle

		PlayerState.RUN:
			animated_sprite_2d.animation = "run"
			animated_sprite_2d.play()

		PlayerState.JUMP:
			animated_sprite_2d.animation = "jump"
			animated_sprite_2d.play()

		PlayerState.FALL:
			animated_sprite_2d.animation = "jump" # Re-use jump animation for fall, or create a "fall" one
			animated_sprite_2d.play()

		PlayerState.DASH:
			animated_sprite_2d.animation = "run" # Or "dash" if you have a unique one
			animated_sprite_2d.play()

		PlayerState.ATTACK:
			animated_sprite_2d.animation = attack_animations[current_attack_index]
			animated_sprite_2d.frame = 0 # Start animation from beginning
			animated_sprite_2d.play()
			attack_sound.play()
			update_attack_hitboxes(animated_sprite_2d.animation)
			if hud:
				hud.set_attack_button_pressed(true)

		PlayerState.HEAVY_ATTACK:
			# Check for charges here before proceeding with the attack
			if heavy_atk_charges > 0:
				heavy_atk_charges -= 1 # Consume a charge
				# Update HUD to show new charge count
				if hud:
					hud.update_heavy_attack_charges(heavy_atk_charges, MAX_HEAVY_ATK_CHARGES) # <-- Add this line

				animated_sprite_2d.animation = "attack2"
				animated_sprite_2d.frame = 0
				animated_sprite_2d.play()
				attack_sound.play()
				attack_area_2.disabled = false
				attack_area_1.disabled = true # Ensure other attack hitbox is disabled
				if hud:
					hud.set_attack_button_pressed(true)
			else:
				# Not enough charges, revert to IDLE or appropriate state
				set_state(PlayerState.IDLE)
				printerr("Not enough heavy attack charges!") # Debug message
				return # Prevent further execution of this state's entry logic

		PlayerState.HEAL:
			# Check heal condition here before starting animation
			if health.health < health.max_health:
				animated_sprite_2d.animation = "heal"
				animated_sprite_2d.frame = 0
				animated_sprite_2d.play()
				velocity = Vector2.ZERO # Stop all movement
				
				health.heal(10) # Apply healing effect
				
				_await_heal_animation_completion()
			else:
				set_state(PlayerState.IDLE)

		PlayerState.HANG:
			animated_sprite_2d.animation = "hang"
			animated_sprite_2d.play()
			velocity = Vector2.ZERO

		PlayerState.CLIMB_UP:
			animated_sprite_2d.animation = "pull_up"
			animated_sprite_2d.play()
			velocity.y = JUMP_VELOCITY # Give a vertical push for climbing up

		PlayerState.DROP_DOWN:
			animated_sprite_2d.animation = "jump" # or "fall"
			animated_sprite_2d.play()
			global_position.y += 10 # Move down slightly to pass through one-way platform
			velocity.y = 150.0 # Initial downward velocity


# --- State Handler Functions ---

func handle_normal_movement(delta: float):
	# Input from HUD and Keyboard
	var jump_intent = Input.is_action_just_pressed("jump") or (hud and hud.jump_button_pressed)
	if hud and hud.jump_button_pressed:
		hud.jump_button_pressed = false

	var dash_intent = Input.is_action_just_pressed("dash") or (hud and hud.dash_button_pressed)
	if hud and hud.dash_button_pressed:
		hud.dash_button_pressed = false

	# --- Prioritized Input Checks for State Transitions ---

	if dash_intent and dash_cooldown_timer <= 0:
		var direction = Input.get_axis("left", "right")
		if direction == 0:
			direction = -1 if animated_sprite_2d.flip_h else 1
		velocity.x = direction * DASH_SPEED
		dash_time = DASH_DURATION
		dash_cooldown_timer = dash_cd
		if hud:
			hud.set_dash_button_pressed()
		set_state(PlayerState.DASH)
		return

	if Input.is_action_just_pressed("attack"):
		set_state(PlayerState.ATTACK)
		return

	# Only allow heavy attack if charges are available
	if Input.is_action_just_pressed("heavy_attack") and heavy_atk_charges > 0:
		set_state(PlayerState.HEAVY_ATTACK)
		return

	if Input.is_action_just_pressed("heal"):
		set_state(PlayerState.HEAL)
		return

	# --- Ledge Hanging Detection ---
	if not is_on_floor():
		if is_on_wall():
			hang_grace_timer = HANG_GRACE_TIME
		else:
			hang_grace_timer -= delta

		if can_hang():
			is_hanging = true
			set_state(PlayerState.HANG)
			return

	# --- Apply Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta
		if current_state == PlayerState.JUMP && velocity.y > 0:
			set_state(PlayerState.FALL)
		elif current_state == PlayerState.IDLE || current_state == PlayerState.RUN:
			set_state(PlayerState.FALL)
	else:
		jump_count = 0
		if current_state == PlayerState.JUMP || current_state == PlayerState.FALL:
			if abs(velocity.x) > 1:
				set_state(PlayerState.RUN)
			else:
				set_state(PlayerState.IDLE)


	# --- Handle Jumping / Double Jumping ---
	if is_on_floor() and Input.is_action_pressed("down") and jump_intent:
		print("going down")
		set_state(PlayerState.DROP_DOWN)
		
	elif jump_intent and jump_count < max_jumps:
		if jump_count == 0:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			if hud:
				hud.set_jump_button_pressed()
			set_state(PlayerState.JUMP)
		elif jump_count == 1 and jump_cooldown_timer <= 0:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			jump_cooldown_timer = jump_cd
			if hud:
				hud.set_jump_button_pressed()
			set_state(PlayerState.JUMP)


	# --- Handle Horizontal Movement ---
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
		# Update attack area offsets based on flip
		attack_area_1.position.x = -original_attack_offset_x if animated_sprite_2d.flip_h else original_attack_offset_x
		attack_area_2.position.x = -original_attack2_offset_x if animated_sprite_2d.flip_h else original_attack2_offset_x
		if is_on_floor() and current_state != PlayerState.RUN:
			set_state(PlayerState.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
		if is_on_floor() and current_state != PlayerState.IDLE && abs(velocity.x) < 1:
			set_state(PlayerState.IDLE)


func handle_normal_animations():
	# Animation setting is now primarily handled in set_state().
	# This function can be simplified or removed if set_state handles all animation logic.
	pass


func handle_dash_state(delta: float):
	dash_time -= delta
	if dash_time <= 0:
		velocity.x = 0
		if is_on_floor():
			set_state(PlayerState.IDLE)
		else:
			set_state(PlayerState.FALL)
	else:
		velocity.y += get_gravity().y * delta


func handle_attack_state(delta: float):
	if not is_on_floor():
		velocity.x *= 0.95
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0


func handle_heal_state(delta: float):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0


func handle_hang_state():
	is_hanging = true
	if Input.is_action_just_pressed("jump"):
		is_hanging = false
		set_state(PlayerState.CLIMB_UP)
	elif Input.is_action_just_pressed("down"):
		is_hanging = false
		set_state(PlayerState.DROP_DOWN)


func handle_climb_up_state(delta: float):
	velocity.y += get_gravity().y * delta


func handle_drop_down_state(delta: float):
	velocity.y += get_gravity().y * delta


# --- Animation Signal Handler ---
func _on_animated_sprite_2d_animation_finished():
	print("Animation finished: {animated_sprite_2d.animation}")

	match animated_sprite_2d.animation:
		"heal":
			pass # Handled by _await_heal_animation_completion

		"pull_up":
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL)

		"attack", "attack1":
			current_attack_index = (current_attack_index + 1) % attack_animations.size()
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL)

		"attack2":
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL)


# --- Asynchronous Helper for Healing Animation ---
func _await_heal_animation_completion():
	if animated_sprite_2d:
		print("Awaiting heal animation completion...")
		await animated_sprite_2d.animation_finished
		print("Heal animation finished! Transitioning to IDLE.")
		set_state(PlayerState.IDLE)
	else:
		printerr("AnimatedSprite2D node is not valid for heal await.")


# --- Helper Functions ---
func update_attack_hitboxes(current_anim: String):
		attack_area_1.disabled = false
	elif current_anim == "attack2":
		attack_area_2.disabled = false


func can_hang():
	if not is_on_wall():
		return false

	var hanging_left = $WallRayCast/LedgeCheckLeft.is_colliding() and not $WallRayCast/CheckFloorAboveLeft.is_colliding()
	var hanging_right = $WallRayCast/LedgeCheckRight.is_colliding() and not $WallRayCast/CheckFloorAboveRight.is_colliding()

	if hang_grace_timer > 0 and (hanging_left or hanging_right):
		return true
	
	return false


func _on_health_depleted():
	Transition1.change_scene("res://scenes/ui/GameOver.tscn")
