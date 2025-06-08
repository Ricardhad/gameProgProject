# The new, smaller Goblin.gd
extends CharacterBody2D

# Constants
const SPEED = 50.0
const CHASE_SPEED = 100.0
const GRAVITY = 800.0
const KNOCKBACK_FORCE = 200.0

var movement_direction = 1 # -1 for left, 1 for right
var movement_speed = SPEED
var knockback_velocity = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Health = $Health
@onready var cliff_check: RayCast2D = $RayCast2D
@onready var wall_check: RayCast2D = $RayCast2D2

func _ready():
	health_component.health_changed.connect(_on_health_changed)

func _physics_process(delta: float):
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Apply knockback
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
	
	# Apply normal velocity
	velocity.x = movement_speed * movement_direction
	
	move_and_slide()
	update_visuals()

# --- Public functions that the StateMachine can call ---

func set_movement_speed(speed: float):
	movement_speed = speed

func stop_movement():
	movement_speed = 0

func turn_around():
	movement_direction *= -1

func move_towards(target_position: Vector2):
	movement_direction = sign(target_position.x - global_position.x)

func is_patrol_obstacle_detected() -> bool:
	return (not cliff_check.is_colliding() or wall_check.is_colliding()) and is_on_floor()

func update_visuals():
	if movement_direction != 0:
		animated_sprite.flip_h = movement_direction < 0
		# You can add logic here to flip other nodes if needed
	
func _on_health_changed(diff: int):
	if diff < 0: # Took damage
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = sign(global_position.x - player.global_position.x)
			knockback_velocity = Vector2(KNOCKBACK_FORCE * dir, -100)
