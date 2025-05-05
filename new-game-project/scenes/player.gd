extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer  # Reference to AudioStreamPlayer node

var is_attacking = false
var is_guarding = false
var current_attack_index = 0

var attack_animations = ["attack", "attack1", "attack2"]

func _ready():
	randomize()

func _physics_process(delta: float) -> void:
	# Handling Guard
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

	# Handling Attack
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_guarding:
		var current_attack_animation = attack_animations[current_attack_index]
		animated_sprite_2d.animation = current_attack_animation
		animated_sprite_2d.frame = 0
		is_attacking = true
		velocity.x = 0

		# Play attack sound effect
		attack_sound.play()  # Plays the attack sound

		return

	# If attacking, manage attack animation and movement
	if is_attacking:
		var current_attack_animation = attack_animations[current_attack_index]
		if animated_sprite_2d.animation == current_attack_animation and animated_sprite_2d.frame == animated_sprite_2d.sprite_frames.get_frame_count(current_attack_animation) - 1:
			is_attacking = false
			current_attack_index = (current_attack_index + 1) % attack_animations.size()
		else:
			velocity.x = 0
			if not is_on_floor():
				velocity += get_gravity() * delta
			move_and_slide()
			return

	# Handling Jump
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handling Movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0  # Flip character when moving left
	else:
		velocity.x = move_toward(velocity.x, 0, 30)

	# Move the character
	move_and_slide()

	# Update animations based on state
	if not is_attacking and not is_guarding:
		if not is_on_floor():
			animated_sprite_2d.animation = "jump"
		elif abs(velocity.x) > 1:
			animated_sprite_2d.animation = "run"
		else:
			animated_sprite_2d.animation = "idle"
