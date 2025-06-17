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
var base_jump_cd = 2.0
var base_dash_cd = 2.0
var jump_cd = 2.0
var dash_cd = 2.0

# --- Player State Variables ---
enum PlayerState {
	IDLE, RUN, JUMP, FALL, DASH, ATTACK, HEAVY_ATTACK, HEAL, HANG, CLIMB_UP, DROP_DOWN
}
var current_state: PlayerState = PlayerState.IDLE

var is_hanging = false
var hang_grace_timer = 0.0
var dash_time = 0.0
var jump_count = 0
var max_jumps = 2
var current_attack_index = 0
var attack_animations = ["attack", "attack1"]
var air_attack_animation = "air_attack"

# --- Node References ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var attack_area_1: CollisionShape2D = $HitBox/Attack
@onready var attack_area_2: CollisionShape2D = $HitBox2/Attack
@onready var health: Health = $Health
@onready var hud = get_node("/root/game/Hud")
@onready var hurtbox: HurtBox = $HurtBox

var respawn_position = Vector2(150, 150)
var original_attack_offset_x = 0.0
var original_attack2_offset_x = 0.0

func _ready():
	original_attack_offset_x = attack_area_1.position.x
	original_attack2_offset_x = attack_area_2.position.x
	randomize()
	
	$HitBox.damage = GlobalVar.damage_player
	$HitBox2.damage = GlobalVar.damage_player * 2
	health.sync_with_global = true
	health.set_max_health(GlobalVar.maxhealth_player)
	health.set_health(GlobalVar.health_player)
	
	# Connect the health depletion signal
	health.connect("health_depleted", Callable(self, "_on_health_depleted"))

	health.connect("health_depleted", Callable(self, "_on_health_depleted"))
	animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	hurtbox.received_damage.connect(_on_hurtbox_received_damage)
	GlobalVar.agility_buff_changed.connect(_on_agility_buff_changed)
	
	_update_agility_status()
	
	set_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
	# --- 1. Handle Cooldown Timers (Always run) ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if jump_cooldown_timer > 0:
		jump_cooldown_timer -= delta

	# --- 2. Handle Game State Overrides (e.g., Respawn) ---
	if global_position.y > 1000:
		global_position = respawn_position
		velocity = Vector2.ZERO
		set_state(PlayerState.IDLE)
		return

	match current_state:
		PlayerState.IDLE, PlayerState.RUN, PlayerState.JUMP, PlayerState.FALL:
			handle_normal_movement(delta)
		PlayerState.DASH:
			handle_dash_state(delta)
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			handle_attack_state(delta)
		PlayerState.HEAL:
			handle_heal_state()
		PlayerState.HANG:
			handle_hang_state()
		PlayerState.CLIMB_UP, PlayerState.DROP_DOWN:
			velocity.y += get_gravity().y * delta

	move_and_slide()

func set_state(new_state: PlayerState):
	if current_state == new_state: return

	match current_state:
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			attack_area_1.disabled = true
			attack_area_2.disabled = true
			if hud:
				hud.set_attack_button_pressed(false)
		PlayerState.DASH:
			pass # No specific exit actions needed besides velocity.x = 0 which is in handle_dash_state
		PlayerState.HEAL:
			pass # Await in perform_heal handles cleanup
		# Add any other states that require cleanup when exiting (e.g., stopping a continuous sound)

	current_state = new_state

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
			# Direction for dash is set in handle_normal_movement before calling set_state
			animated_sprite_2d.animation = "run" # Or "dash" if you have a unique one
			animated_sprite_2d.play()

		PlayerState.ATTACK:
			animated_sprite_2d.play(attack_animations[current_attack_index])
			attack_sound.play()
			update_attack_hitboxes(animated_sprite_2d.animation)
			if hud: hud.set_attack_button_pressed(true)
		PlayerState.HEAVY_ATTACK:
			animated_sprite_2d.animation = "attack2"
			animated_sprite_2d.frame = 0
			animated_sprite_2d.play()
			attack_sound.play()
			attack_area_2.disabled = false
			attack_area_1.disabled = true # Ensure other attack hitbox is disabled
			if hud:
				hud.set_attack_button_pressed(true)

		PlayerState.HEAL:
			# Check heal condition here before starting animation
			if health.health < health.max_health:
				animated_sprite_2d.animation = "heal"
				animated_sprite_2d.frame = 0
				animated_sprite_2d.play()
				velocity = Vector2.ZERO # Stop all movement
				
				# Apply healing effect here, or at a specific animation frame via AnimationPlayer's call method.
				health.heal(10) 
				
				# Start an asynchronous operation to wait for animation and then transition
				_await_heal_animation_completion()
			else:
				# If no healing is needed, immediately revert to idle
				set_state(PlayerState.IDLE)

		PlayerState.HANG:
			animated_sprite_2d.animation = "hang"
			animated_sprite_2d.play()
			velocity = Vector2.ZERO # Stop all movement when hanging

		PlayerState.CLIMB_UP:
			is_hanging = false # Pindahkan ini ke atas agar logikanya jelas
			
			# --- PERBAIKAN BUG DIMULAI DI SINI ---
			
			# Tentukan seberapa jauh player harus digeser agar pas di atas tebing.
			# Nilai ini mungkin perlu Anda sesuaikan sedikit!
			var climb_offset_x = 20.0 
			var climb_offset_y = -16.0 # Geser sedikit ke atas untuk menghindari nyangkut di sudut

			# Jika player menghadap ke kiri (flipped), geser ke arah sebaliknya.
			if animated_sprite_2d.flip_h:
				climb_offset_x = -climb_offset_x

			# Terapkan pergeseran posisi pada player SEBELUM animasi/velocity.
			global_position.x += climb_offset_x
			global_position.y += climb_offset_y
			
			# --- PERBAIKAN BUG SELESAI ---

			# Sekarang baru kita mainkan animasi dan berikan velocity
			animated_sprite_2d.play("pull_up")
			velocity.y = JUMP_VELOCITY
		PlayerState.DROP_DOWN:
			# Can reuse fall animation or have a dedicated drop one
			animated_sprite_2d.animation = "jump" # or "fall"
			animated_sprite_2d.play()
			global_position.y += 10 # Move down slightly to pass through one-way platform
			velocity.y = 150.0 # Initial downward velocity


# --- State Handler Functions ---

func handle_normal_movement(delta: float):
	# Input from HUD and Keyboard
	var jump_intent = Input.is_action_just_pressed("jump") or (hud and hud.jump_button_pressed)
	if hud and hud.jump_button_pressed:
		hud.jump_button_pressed = false # Reset marker

	var dash_intent = Input.is_action_just_pressed("dash") or (hud and hud.dash_button_pressed)
	if hud and hud.dash_button_pressed:
		hud.dash_button_pressed = false # Reset marker

	if dash_intent and dash_cooldown_timer <= 0:
		var direction = Input.get_axis("left", "right")
		if direction == 0:
			direction = -1 if animated_sprite_2d.flip_h else 1 # Default direction if no horizontal input
		velocity.x = direction * DASH_SPEED # Set initial dash velocity
		dash_time = DASH_DURATION # Set dash duration
		dash_cooldown_timer = dash_cd # Start cooldown
		if hud:
			hud.set_dash_button_pressed() # Visual effect
		set_state(PlayerState.DASH) # Transition to Dash state
		return # Exit early, as state changed

	if Input.is_action_just_pressed("attack"):
		set_state(PlayerState.ATTACK) # Transition to Attack state
		return # Exit early

	if Input.is_action_just_pressed("heavy_attack"):
		set_state(PlayerState.HEAVY_ATTACK) # Transition to Heavy Attack state
		return # Exit early

	if Input.is_action_just_pressed("heal"):
		set_state(PlayerState.HEAL) # Transition to Heal state
		return # Exit early

	# --- Ledge Hanging Detection (only if not already hanging) ---
	if not is_on_floor(): # Only check for hanging if in the air
		# Updated hang_grace_timer logic
		if is_on_wall():
			hang_grace_timer = HANG_GRACE_TIME # Reset timer while on wall
		else:
			hang_grace_timer -= delta # Decrement if not on wall

		if can_hang():
			is_hanging = true # Update convenience flag
			set_state(PlayerState.HANG) # Transition to Hang state
			return # Exit early

	# --- Apply Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta
		# If currently in a normal movement state and falling, set to FALL state
		if current_state == PlayerState.JUMP && velocity.y > 0:
			set_state(PlayerState.FALL)
		elif current_state == PlayerState.IDLE || current_state == PlayerState.RUN: # If player walks off a ledge
			set_state(PlayerState.FALL)
	else: # On floor
		jump_count = 0 # Reset jump count
		# If currently in air states (JUMP/FALL) and lands, transition to IDLE/RUN
		if current_state == PlayerState.JUMP || current_state == PlayerState.FALL:
			if abs(velocity.x) > 1:
				set_state(PlayerState.RUN)
			else:
				set_state(PlayerState.IDLE)

	if is_on_floor() and Input.is_action_pressed("down") and jump_intent:
		print("going down")
		# set_state(PlayerState.DROP_DOWN) handles actual position/velocity
		set_state(PlayerState.DROP_DOWN) # Transition to explicit drop state
		
	elif jump_intent and jump_count < max_jumps:
		if jump_count == 0 or (jump_count == 1 and jump_cooldown_timer <= 0):
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			if hud:
				hud.set_jump_button_pressed()
			set_state(PlayerState.JUMP) # Transition to Jump state
		elif jump_count == 1 and jump_cooldown_timer <= 0:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			jump_cooldown_timer = jump_cd
			if hud:
				hud.set_jump_button_pressed()
			set_state(PlayerState.JUMP) # Or a specific PlayerState.DOUBLE_JUMP

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
		# Update attack area offsets based on flip
		attack_area_1.position.x = -original_attack_offset_x if animated_sprite_2d.flip_h else original_attack_offset_x
		attack_area_2.position.x = -original_attack2_offset_x if animated_sprite_2d.flip_h else original_attack2_offset_x
		if is_on_floor() and current_state != PlayerState.RUN: # Only switch to run if on floor and not already running
			set_state(PlayerState.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, 30) # Apply friction/deceleration
		if is_on_floor() and current_state != PlayerState.IDLE && abs(velocity.x) < 1: # Only switch to idle if on floor and not already idle
			set_state(PlayerState.IDLE)


func handle_normal_animations():
	# This function is now mostly handled by set_state
	# and the if/else if/else block for `if not is_attacking and not is_healing:`
	# in the original code is no longer needed here as set_state manages animation setting.
	# You can leave this empty or remove it if you are confident set_state handles all animation changes.
	# The general animation logic is now integrated directly into set_state.
	pass


func handle_dash_state(delta: float):
	dash_time -= delta
	velocity.y += get_gravity().y * delta
	if dash_time <= 0:
		velocity.x = 0 # Stop horizontal speed after dash
		# Determine next state after dash based on if on floor or in air
		if is_on_floor():
			set_state(PlayerState.IDLE)
		else:
			set_state(PlayerState.FALL) # Go to fall after dash ends in air
	else:
		velocity.y += get_gravity().y * delta # Apply gravity during dash


func handle_attack_state(delta: float):
	# Attack animations are set in set_state and play to finish (non-looping).
	# During attack, apply gravity and possibly slow horizontal movement.
	if not is_on_floor():
		velocity.x *= 0.95 # Slow down horizontal movement in air
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0 # Stop horizontal movement on ground during attack
	# State transition out of attack happens via _on_animated_sprite_2d_animation_finished


func handle_heal_state(delta: float):
	# Healing animation is set in set_state.
	# Apply gravity if in air, stop horizontal movement if on ground.
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.x = 0
	# State transition out of heal happens via _await_heal_animation_completion (which calls set_state)


func handle_heal_state(): pass
func handle_hang_state():
	is_hanging = true # Maintain this flag for helper can_hang()
	# Hanging has no physics movement, velocity is ZERO set in set_state.
	# Listen for climb/drop input to transition out.
	if Input.is_action_just_pressed("jump"):
		is_hanging = false # Reset flag when leaving hang state
		set_state(PlayerState.CLIMB_UP)
	elif Input.is_action_just_pressed("down"):
		is_hanging = false # Reset flag when leaving hang state
		set_state(PlayerState.DROP_DOWN)


func handle_climb_up_state(delta: float):
	# This state is for the "pull_up" animation.
	# Gravity is still applied. After animation, it transitions to IDLE/FALL.
	velocity.y += get_gravity().y * delta # Still apply gravity


func handle_drop_down_state(delta: float):
	# This state applies the initial push down. Gravity will take over.
	# It will naturally transition to FALL once off the one-way platform.
	velocity.y += get_gravity().y * delta # Gravity ensures continuous fall


# --- Animation Signal Handler ---
# This function is ONLY for handling animations that complete and cause a state change.
func _on_animated_sprite_2d_animation_finished():
	# Print statements for debugging which animation finished
	print("Animation finished: {animated_sprite_2d.animation}")

	match animated_sprite_2d.animation:
		"heal":
			# This is now handled by the await in _await_heal_animation_completion,
			# but leaving it here for explicit clarity in the match statement
			# in case heal is interrupted or cancelled, though the await is safer.
			# set_state(PlayerState.IDLE) # Handled by _await_heal_animation_completion
			pass # No action needed here as _await_heal_animation_completion will handle it

		"pull_up": # Animation for climbing up a ledge
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL) # Go to fall if still in air after climb

		"attack", "attack1": # All ground attack animations
			current_attack_index = (current_attack_index + 1) % attack_animations.size()
			# After a regular attack, transition based on if on floor or in air
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL)

		"attack2": # Heavy attack animation
			# After heavy attack, transition based on if on floor or in air
			if is_on_floor():
				set_state(PlayerState.IDLE)
			else:
				set_state(PlayerState.FALL)

		# Add other animations that might need specific state resets here (e.g., death, unique skill animations)


# --- Asynchronous Helper for Healing Animation ---
func _await_heal_animation_completion():
	# Ensure the animated_sprite_2d is valid before awaiting
	if animated_sprite_2d:
		print("Awaiting heal animation completion...")
		await animated_sprite_2d.animation_finished
		print("Heal animation finished! Transitioning to IDLE.")
		set_state(PlayerState.IDLE) # Transition back to IDLE after heal animation finishes
	else:
		jump_cd = base_jump_cd
		dash_cd = base_dash_cd

func _on_agility_buff_changed(is_active: bool):
	_update_agility_status()

func _on_hurtbox_received_damage(damage_amount: int):
	var total_defense = base_defense + GlobalVar.get_total_defense_bonus()
	var final_damage = max(0, damage_amount - total_defense)
	if final_damage > 0:
		health.health -= final_damage

func update_attack_hitboxes(current_anim: String):
	# Disable both by default, then enable the one needed
	attack_area_1.disabled = true
	attack_area_2.disabled = true

	if current_anim == "attack" or current_anim == "attack1":
		attack_area_1.disabled = false
	elif current_anim == "attack2":
		attack_area_2.disabled = false


func can_hang():
	# If not on a wall or hang grace timer has run out, cannot hang.
	if not is_on_wall():
		return false

	# Raycasts to check for ledge. Make sure these are properly configured in your scene.
	# LedgeCheckLeft/Right should be horizontal rays pointing away from the character.
	# CheckFloorAboveLeft/Right should be vertical rays pointing up from the ledge check point.
	var hanging_left = $WallRayCast/LedgeCheckLeft.is_colliding() and not $WallRayCast/CheckFloorAboveLeft.is_colliding()
	var hanging_right = $WallRayCast/LedgeCheckRight.is_colliding() and not $WallRayCast/CheckFloorAboveRight.is_colliding()

	# Only allow hang if there's a ledge and within the grace period (if applicable)
	if hang_grace_timer > 0 and (hanging_left or hanging_right):
		return true
	
	return false # Cannot hang


func _on_health_depleted():
	# This function is called when health reaches 0 (from the Health node's signal)
	Transition1.change_scene("res://scenes/ui/GameOver.tscn")
	# If Transition1 is a global singleton, ensure it's properly set up.
	# If not, you might need get_tree().change_scene_to_file(...) directly.
