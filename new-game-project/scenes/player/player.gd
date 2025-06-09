extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
var dash_cooldown_timer = 0.0
var jump_cooldown_timer = 0.0
var jump_cd = 2
var dash_cd = 2
var is_hanging = false
var hang_grace_timer = 0.0
const HANG_GRACE_TIME = 0.2

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
var respawn_position = Vector2(150, 150)

var is_attacking = false
var is_guarding = false
var current_attack_index = 0
var attack_animations = ["attack", "attack1", "attack2"]
var air_attack_animation = "air_attack"


const DASH_SPEED = 350.0
const DASH_DURATION = 0.3
var is_dashing = false
var dash_time = 0.0

var max_jumps = 2
var jump_count = 0

@onready var attack_area_1: CollisionShape2D = $HitBox/Attack12
@onready var attack_area_2: CollisionShape2D = $HitBox/Attack3
var original_attack_offset_x = 0.0
var original_attack2_offset_x = 0.0

@onready var health: Health = $Health


@onready var hud = get_node("/root/game/Hud")

func _ready():
	original_attack_offset_x = attack_area_1.position.x
	original_attack2_offset_x = attack_area_2.position.x
	randomize()
	
	# Set HitBox damage from GlobalVar
	$HitBox.damage = GlobalVar.damage_player
	health.sync_with_global = true
	health.set_max_health(GlobalVar.maxhealth_player)
	health.set_health(GlobalVar.health_player)
	
	# Connect the health depletion signal
	health.connect("health_depleted", Callable(self, "_on_health_depleted"))
	

func _physics_process(delta: float) -> void:
	# Reduce cooldown timers
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if jump_cooldown_timer > 0:
		jump_cooldown_timer -= delta
		
	# Dash logic
	if is_dashing:
		dash_time -= delta
		if dash_time <= 0:
			is_dashing = false
		else:
			# apply gravity while dashing
			velocity.y += get_gravity().y * delta
			move_and_slide()
			return
	if dash_time <= 0:
		is_dashing = false
		velocity.x = 0  # stop horizontal speed after dash

	# Ledge logic
	if is_on_wall():
		hang_grace_timer = HANG_GRACE_TIME
	else:
		hang_grace_timer -= delta

	if not is_on_floor() and not is_attacking and not is_guarding and not is_dashing:
		if not is_hanging:
			if can_hang():
				is_hanging = true
				velocity = Vector2.ZERO
				animated_sprite_2d.animation = "hang"
				return
		else:
			# While hanging, listen for climb/drop input
			if Input.is_action_just_pressed("jump"):
				print("climbing")
				climb_ledge()
				return
			elif Input.is_action_just_pressed("down"):
				print("drop")
				drop_ledge()
				return
				
	if is_hanging:
		return

	# --- Pengecekan Input dari HUD dan Keyboard ---
	var jump_intent = Input.is_action_just_pressed("jump") or (hud and hud.jump_button_pressed)
	if hud and hud.jump_button_pressed:
		hud.jump_button_pressed = false # Reset penanda

	var dash_intent = Input.is_action_just_pressed("dash") or (hud and hud.dash_button_pressed)
	if hud and hud.dash_button_pressed:
		hud.dash_button_pressed = false # Reset penanda
	# ----------------------------------------------

	if dash_intent and not is_attacking and not is_guarding and dash_cooldown_timer <= 0:
		var direction = Input.get_axis("left", "right")
		if direction == 0:
			direction = -1 if animated_sprite_2d.flip_h else 1
			
		dash(direction)
		dash_cooldown_timer = dash_cd  # Reset cooldown
		if hud:
			hud.set_dash_button_pressed() # Efek visual dash
		return

	if global_position.y > 1000:
		global_position = respawn_position
		velocity = Vector2.ZERO
		is_attacking = false
		is_guarding = false
		current_attack_index = 0
		animated_sprite_2d.animation = "idle"
		return
		
	if Input.is_action_pressed("guard") and not is_attacking:
		if not is_guarding:
			is_guarding = true
			animated_sprite_2d.animation = "guard"
			animated_sprite_2d.frame = 0
		velocity.x = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	elif is_guarding:
		is_guarding = false

	if Input.is_action_just_pressed("attack") and not is_attacking and not is_guarding:
		if is_on_floor():
			perform_ground_attack()
		else:
			perform_air_attack()
		return

	if is_attacking:
		var current_anim = animated_sprite_2d.animation
		var is_last_frame = animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count(current_anim) - 1
		
		if is_last_frame:
			is_attacking = false
			current_attack_index = (current_attack_index + 1) % attack_animations.size()
			attack_area_1.disabled = true
			attack_area_2.disabled = true
			if hud:
				hud.set_attack_button_pressed(false)  # Reset tombol attack setelah selesai
		else:
			if not is_on_floor():
				velocity.x *= 0.95
				velocity.y += get_gravity().y * delta
			else:
				velocity.x = 0
			move_and_slide()
			return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jump_count = 0
	if is_on_floor() and Input.is_action_pressed("down") and jump_intent:
		print("going down")
		# Setting a small positive y velocity is enough to pass through one-way platforms.
		global_position.y += 10
		velocity.y = 150.0
		
	elif jump_intent and jump_count < max_jumps:
		# First jump: no cooldown
		if jump_count == 0:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			if hud:
				hud.set_jump_button_pressed() # Efek visual lompat
		# Second jump: check cooldown
		elif jump_count == 1 and jump_cooldown_timer <= 0:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			jump_cooldown_timer = jump_cd
			if hud:
				hud.set_jump_button_pressed() # Efek visual lompat

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
		attack_area_1.position.x = -original_attack_offset_x if animated_sprite_2d.flip_h else original_attack_offset_x
		attack_area_2.position.x = -original_attack2_offset_x if animated_sprite_2d.flip_h else original_attack2_offset_x
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
		
	move_and_slide()

	if not is_attacking and not is_guarding:
		if not is_on_floor():
			animated_sprite_2d.animation = "jump"
		elif abs(velocity.x) > 1:
			animated_sprite_2d.animation = "run"
		else:
			animated_sprite_2d.animation = "idle"

func update_attack_hitboxes(current_anim: String):
	attack_area_1.disabled = not (current_anim == "attack" or current_anim == "attack1")
	attack_area_2.disabled = current_anim != "attack2"

func perform_ground_attack():
	var current_attack_animation = attack_animations[current_attack_index]
	animated_sprite_2d.animation = current_attack_animation
	animated_sprite_2d.frame = 0
	is_attacking = true
	update_attack_hitboxes(current_attack_animation)
	attack_sound.play()
	
	if hud:
		hud.set_attack_button_pressed(true)

func perform_air_attack():
	var current_attack_animation = attack_animations[current_attack_index]
	animated_sprite_2d.animation = current_attack_animation
	animated_sprite_2d.frame = 0
	is_attacking = true
	update_attack_hitboxes(current_attack_animation)
	attack_sound.play()
	
	if hud:
		hud.set_attack_button_pressed(true)

func dash(direction: float):
	is_dashing = true
	dash_time = DASH_DURATION
	velocity.x = direction * DASH_SPEED
	animated_sprite_2d.animation = "run"

func climb_ledge():
	is_hanging = false
	global_position.y -= 10
	velocity.y = JUMP_VELOCITY
	animated_sprite_2d.animation = "pull_up"
	
func drop_ledge():
	is_hanging = false
	global_position.y += 10
	velocity.y = 200
	
func can_hang():
	if not is_on_wall():
		return false

	var hanging_left = $WallRayCast/LedgeCheckLeft.is_colliding() and not $WallRayCast/CheckFloorAboveLeft.is_colliding()
	var hanging_right = $WallRayCast/LedgeCheckRight.is_colliding() and not $WallRayCast/CheckFloorAboveRight.is_colliding()

	if hang_grace_timer > 0 and (hanging_left or hanging_right):
		return true

func _on_health_depleted():
	Transition1.change_scene("res://scenes/ui/GameOver.tscn")
	#get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")
