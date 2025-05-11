extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
var respawn_position = Vector2(100, 100)

var is_attacking = false
var is_guarding = false
var current_attack_index = 0
var was_running = false
var attack_animations = ["attack", "attack1", "attack2"]

func _ready():
	randomize()

func _physics_process(delta: float) -> void:
	if global_position.y > 2000:
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
		if abs(velocity.x) > 0.1 and is_on_floor():
			# Running attack
			animated_sprite_2d.animation = "runattack"
			animated_sprite_2d.frame = 0
			is_attacking = true
			was_running = true
		else:
			# Normal combo attack
			var current_attack_animation = attack_animations[current_attack_index]
			animated_sprite_2d.animation = current_attack_animation
			animated_sprite_2d.frame = 0
			is_attacking = true
			was_running = false

		attack_sound.play()
		return

	if is_attacking:
		var current_anim = animated_sprite_2d.animation
		var is_last_frame = animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count(current_anim) - 1

		if is_last_frame:
			is_attacking = false
			if current_anim == "runattack":
				# Stop momentum after runattack and reset combo
				velocity.x = 0
				current_attack_index = 0
			else:
				current_attack_index = (current_attack_index + 1) % attack_animations.size()
		else:
			# Maintain momentum only for runattack
			if current_anim != "runattack":
				velocity.x = 0
			if not is_on_floor():
				velocity += get_gravity() * delta
			move_and_slide()
			return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
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
