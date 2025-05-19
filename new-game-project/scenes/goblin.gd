extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

var is_dead = false
const GRAVITY = 800.0
const SPEED = 50.0

var direction = -1
var is_walking = true
var state_timer = 0.0
var next_state_time = 0.0

var raycast_original_x = 0.0
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_shape1: CollisionShape2D = $HurtBox/CollisionShape2D
var collision_shape_original_x = 0.0
var collision_shape_1_original_x = 0.0

func _ready() -> void:
	randomize()
	_set_next_state_time()
	raycast_original_x = abs(ray_cast_2d.position.x)
	collision_shape_original_x = abs(collision_shape.position.x)
	collision_shape_1_original_x = abs(collision_shape1.position.x)

var hitbox_shift = 7.5  # tweak this value to control how much left the hitbox moves when facing right

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.y += GRAVITY * delta

	state_timer += delta
	if state_timer >= next_state_time:
		is_walking = !is_walking
		state_timer = 0.0
		_set_next_state_time()

	if is_walking:
		if not ray_cast_2d.is_colliding():
			direction *= -1

		animated_sprite_2d.flip_h = direction < 0

		# RayCast2D position
		if direction < 0:
			ray_cast_2d.position.x = -raycast_original_x
		else:
			ray_cast_2d.position.x = raycast_original_x - hitbox_shift

		# CollisionShape2D position (first one)
		if direction < 0:
			collision_shape.position.x = -collision_shape_original_x
		else:
			collision_shape.position.x = collision_shape_original_x - hitbox_shift

		# CollisionShape2D position (second one - collision_shape_2d)
		if direction < 0:
			collision_shape1.position.x = -collision_shape_1_original_x
		else:
			collision_shape1.position.x = collision_shape_1_original_x - hitbox_shift

		velocity.x = SPEED * direction
	else:
		velocity.x = 0.0

	move_and_slide()

func _process(delta: float) -> void:
	if is_dead:
		return

	# Animation based on state
	animated_sprite_2d.animation = "walk" if is_walking else "idle"

func _on_health_health_depleted() -> void:
	print("Health depleted")
	is_dead = true
	animated_sprite_2d.play("dead")
	velocity = Vector2.ZERO

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "dead":
		queue_free()

func _set_next_state_time() -> void:
	# Random time between 1 and 3 seconds
	next_state_time = randf_range(1.0, 3.0)
