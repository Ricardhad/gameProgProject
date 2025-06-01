extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var ray_cast_2d_2: RayCast2D = $RayCast2D2
@onready var ray_cast_2d_3: RayCast2D = $RayCast2D3
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_shape1: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var collision_shape2: CollisionShape2D = $PlayerDetect/CollisionShape2D
@onready var collision_shape3: CollisionShape2D = $HitBox/CollisionShape2D
@onready var health: Health = $Health
@export var coin_scene: PackedScene

var is_dead = false
const GRAVITY = 800.0
const SPEED = 50.0

var direction = -1
var is_walking = true
var state_timer = 0.0
var next_state_time = 0.0

var raycast_original_x = 0.0
var raycast_original_x1 = 0.0
var raycast_original_x2 = 0.0
var raycast2_target_original_x = 0.0
var raycast2_target_original_x1 = 0.0
var collision_shape_original_x = 0.0
var collision_shape_1_original_x = 0.0
var collision_shape_2_original_x = 0.0

var hitbox_shift = 7.5
var current_animation: String = ""
#knockback var
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_FORCE = 200.0

const CHASE_SPEED = 100.0
const CHASE_DURATION = 5.0
var is_chasing = false
var chase_timer = 0.0
var is_stopped_chasing = false

func _ready() -> void:
	randomize()
	_set_next_state_time()
	raycast_original_x = abs(ray_cast_2d.position.x)
	raycast_original_x1 = abs(ray_cast_2d_2.position.x)
	raycast_original_x2 = abs(ray_cast_2d_3.position.x)
	raycast2_target_original_x = abs(ray_cast_2d_2.target_position.x)
	raycast2_target_original_x1 = abs(ray_cast_2d_3.target_position.x)
	collision_shape_original_x = abs(collision_shape.position.x)
	collision_shape_1_original_x = abs(collision_shape1.position.x)
	collision_shape_2_original_x = abs(collision_shape2.position.x)
	health.health_changed.connect(_on_health_changed)

func _on_health_changed(diff: int) -> void:
	if is_dead:
		return

	if diff < 0 and current_animation != "attack":
		play_animation("hurt", true)

		# Knockback direction logic (assuming player is assigned)
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = sign(global_position.x - player.global_position.x)  # push away from player
			knockback_velocity.x = KNOCKBACK_FORCE * dir

func play_animation(anim: String, force: bool = false):
	if current_animation == "dead":
		return
	if not force and current_animation in ["attack", "hurt"]:
		return
	current_animation = anim
	animated_sprite_2d.play(anim)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.y += GRAVITY * delta

	# Stop movement during attack or hurt animations
	if current_animation in ["attack", "hurt"]:
		velocity.x = 0.0
		if current_animation == "hurt":
			velocity.x = knockback_velocity.x
			knockback_velocity.x = move_toward(knockback_velocity.x, 0, 800 * delta)
		move_and_slide()
		return

	# Detect player to start chasing (use ray_cast_2d_3)
	if ray_cast_2d_3.is_colliding() and not is_chasing:
		is_chasing = true
		chase_timer = CHASE_DURATION
		print("Chasing player!")

	if is_chasing:
		chase_timer -= delta
		if chase_timer <= 0.0:
			is_chasing = false
			print("Stopped chasing")

		var player = get_tree().get_first_node_in_group("player")
		if player:
			var diff_x = player.global_position.x - global_position.x
			direction = sign(diff_x)
			if direction == 0:
				direction = 1

			# Update raycasts and collision shapes for current direction
			if direction < 0:
				ray_cast_2d.position.x = -raycast_original_x
				ray_cast_2d_2.position.x = raycast_original_x1
				ray_cast_2d_2.target_position.x = -raycast2_target_original_x
				ray_cast_2d_3.position.x = raycast_original_x2
				ray_cast_2d_3.target_position.x = -raycast2_target_original_x1

				collision_shape.position.x = -collision_shape_original_x
				collision_shape1.position.x = -collision_shape_1_original_x
				collision_shape2.position.x = -collision_shape_2_original_x
				collision_shape3.position.x = -collision_shape_2_original_x

				animated_sprite_2d.flip_h = true
			else:
				ray_cast_2d.position.x = raycast_original_x - hitbox_shift
				ray_cast_2d_2.position.x = -raycast_original_x1 - hitbox_shift
				ray_cast_2d_2.target_position.x = raycast2_target_original_x
				ray_cast_2d_3.position.x = -raycast_original_x2 - hitbox_shift
				ray_cast_2d_3.target_position.x = raycast2_target_original_x1

				collision_shape.position.x = collision_shape_original_x - hitbox_shift
				collision_shape1.position.x = collision_shape_1_original_x - hitbox_shift
				collision_shape2.position.x = collision_shape_2_original_x - hitbox_shift
				collision_shape3.position.x = collision_shape_2_original_x - hitbox_shift

				animated_sprite_2d.flip_h = false

			# Instead of turning around, just stop moving when no ground ahead
			if ray_cast_2d.is_colliding():
				velocity.x = CHASE_SPEED * direction
				is_stopped_chasing = false
			else:
				# No ground ahead: stop movement but keep facing same direction and don't flip
				velocity.x = 0
				is_stopped_chasing = true
	else:
		# Patrol logic here as before
		if is_walking:
			if not ray_cast_2d.is_colliding() or ray_cast_2d_2.is_colliding():
				direction *= -1
			animated_sprite_2d.flip_h = direction < 0

			if direction < 0:
				ray_cast_2d.position.x = -raycast_original_x
				ray_cast_2d_2.position.x = raycast_original_x1
				ray_cast_2d_2.target_position.x = -raycast2_target_original_x
				ray_cast_2d_3.position.x = raycast_original_x2
				ray_cast_2d_3.target_position.x = -raycast2_target_original_x1

				collision_shape.position.x = -collision_shape_original_x
				collision_shape1.position.x = -collision_shape_1_original_x
				collision_shape2.position.x = -collision_shape_2_original_x
				collision_shape3.position.x = -collision_shape_2_original_x
			else:
				ray_cast_2d.position.x = raycast_original_x - hitbox_shift
				ray_cast_2d_2.position.x = -raycast_original_x1 - hitbox_shift
				ray_cast_2d_2.target_position.x = raycast2_target_original_x
				ray_cast_2d_3.position.x = -raycast_original_x2 - hitbox_shift
				ray_cast_2d_3.target_position.x = raycast2_target_original_x1

				collision_shape.position.x = collision_shape_original_x - hitbox_shift
				collision_shape1.position.x = collision_shape_1_original_x - hitbox_shift
				collision_shape2.position.x = collision_shape_2_original_x - hitbox_shift
				collision_shape3.position.x = collision_shape_2_original_x - hitbox_shift
			velocity.x = SPEED * direction
		else:
			velocity.x = 0.0

	move_and_slide()

func _process(delta: float) -> void:
	if is_dead or current_animation in ["attack", "hurt", "dead"]:
		return
	var new_anim = ""
	if is_chasing:
		if is_stopped_chasing:
			new_anim = "idle"
		else:
			new_anim = "run"
	elif ray_cast_2d.is_colliding() and ray_cast_2d_2.is_colliding():
		new_anim = "idle"
	else:
		new_anim = "walk"
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
	elif animated_sprite_2d.animation == "dead":
		drop_coins()
		queue_free()

func _set_next_state_time() -> void:
	next_state_time = randf_range(1.0, 3.0)

func _on_player_detect_body_entered(body: Node2D) -> void:
	if body == self:
		return  # prevent self-detection

	if current_animation != "attack":
		play_animation("attack")
		
func drop_coins() -> void:
	if coin_scene == null:
		print("Coin scene not assigned!")
		return

	var coin_count = randi_range(1, 5)
	for i in coin_count:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-8, 8), -8)
		
		# Find and assign the player
		var player = get_tree().get_first_node_in_group("player")
		if player:
			coin.player = player
			print("finding player")


func _on_player_detect_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body.is_in_group("player"):
		# Player left attack area
		#if current_animation == "attack":
			#current_animation = ""  # Allow animation reset
		# Optionally stop chasing or change state here
		is_chasing = false
