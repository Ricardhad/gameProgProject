extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_shape1: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var collision_shape2: CollisionShape2D = $PlayerDetect/CollisionShape2D

var is_dead = false
const GRAVITY = 800.0
const SPEED = 50.0

var direction = -1
var is_walking = true
var state_timer = 0.0
var next_state_time = 0.0

var raycast_original_x = 0.0
var collision_shape_original_x = 0.0
var collision_shape_1_original_x = 0.0
var collision_shape_2_original_x = 0.0

var hitbox_shift = 7.5
var current_animation: String = ""

func _ready() -> void:
	randomize()
	_set_next_state_time()
	raycast_original_x = abs(ray_cast_2d.position.x)
	collision_shape_original_x = abs(collision_shape.position.x)
	collision_shape_1_original_x = abs(collision_shape1.position.x)
	collision_shape_2_original_x = abs(collision_shape2.position.x)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.y += GRAVITY * delta

	# Don't move while attacking
	if current_animation == "attack":
		velocity.x = 0.0
		move_and_slide()
		return

	state_timer += delta
	if state_timer >= next_state_time:
		is_walking = !is_walking
		state_timer = 0.0
		_set_next_state_time()

	if is_walking:
		if not ray_cast_2d.is_colliding():
			direction *= -1

		animated_sprite_2d.flip_h = direction < 0

		if direction < 0:
			ray_cast_2d.position.x = -raycast_original_x
			collision_shape.position.x = -collision_shape_original_x
			collision_shape1.position.x = -collision_shape_1_original_x
			collision_shape2.position.x = -collision_shape_2_original_x
		else:
			ray_cast_2d.position.x = raycast_original_x - hitbox_shift
			collision_shape.position.x = collision_shape_original_x - hitbox_shift
			collision_shape1.position.x = collision_shape_1_original_x - hitbox_shift
			collision_shape2.position.x = collision_shape_2_original_x - hitbox_shift

		velocity.x = SPEED * direction
	else:
		velocity.x = 0.0

	move_and_slide()

func _process(delta: float) -> void:
	if is_dead or current_animation == "attack":
		return

	var new_anim = "walk" if is_walking else "idle"
	if animated_sprite_2d.animation != new_anim:
		animated_sprite_2d.play(new_anim)

func _on_health_health_depleted() -> void:
	print("Health depleted")
	is_dead = true
	current_animation = "dead"
	animated_sprite_2d.play("dead")
	velocity = Vector2.ZERO

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "dead":
		queue_free()
	elif animated_sprite_2d.animation == "attack":
		current_animation = ""

func _set_next_state_time() -> void:
	next_state_time = randf_range(1.0, 3.0)

func _on_player_detect_body_entered(body: Node2D) -> void:
	if body == self:
		return  # prevent self-detection

	if current_animation != "attack":
		current_animation = "attack"
		animated_sprite_2d.play("attack")
		print("Attack triggered")
