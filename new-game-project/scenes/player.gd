extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
var respawn_position = Vector2(100, 100)

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

@onready var attack_area_1: CollisionShape2D = $Sword/Attack12
@onready var attack_area_2: CollisionShape2D = $Sword/Attack3
var original_attack_offset_x = 0.0
var original_attack2_offset_x = 0.0

func _ready():
	original_attack_offset_x = attack_area_1.position.x
	original_attack2_offset_x = attack_area_2.position.x
	randomize()

func _physics_process(delta: float) -> void:
	# Dash logic
	if is_dashing:
		dash_time -= delta
		if dash_time <= 0:
			is_dashing = false
		else:
			move_and_slide()
			return

	if Input.is_action_just_pressed("dash") and not is_attacking and not is_guarding:
		var direction = Input.get_axis("left", "right")
		if direction != 0:
			dash(direction)
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

	if Input.is_action_just_pressed("jump") and jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
		attack_area_1.position.x = -original_attack_offset_x + 17.5 if animated_sprite_2d.flip_h else original_attack_offset_x
		attack_area_2.position.x = -original_attack2_offset_x + 17.5 if animated_sprite_2d.flip_h else original_attack2_offset_x

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

func perform_air_attack():
	var current_attack_animation = attack_animations[current_attack_index]
	animated_sprite_2d.animation = current_attack_animation
	animated_sprite_2d.frame = 0
	is_attacking = true
	update_attack_hitboxes(current_attack_animation)
	attack_sound.play()

func dash(direction: float):
	is_dashing = true
	dash_time = DASH_DURATION
	velocity.x = direction * DASH_SPEED
	animated_sprite_2d.animation = "run"
