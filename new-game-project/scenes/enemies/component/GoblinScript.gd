# Goblin.gd
extends CharacterBody2D

signal jumped
signal landed

# Constants
const GRAVITY = 800.0
const PATROL_SPEED = 50.0
const CHASE_SPEED = 100.0
const JUMP_VELOCITY = -300.0
const KNOCKBACK_FORCE = 200.0

# Movement variables
var movement_direction = 1 # -1 for left, 1 for right
var target_node: Node2D = null
var current_speed = PATROL_SPEED
var knockback_velocity = Vector2.ZERO

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: Node = $StateMachine
# Add all your RayCasts here
@onready var cliff_check_ray: RayCast2D = $RayCast2D
@onready var wall_check_ray: RayCast2D = $RayCast2D2

func _ready() -> void:
	# Connect to signals from the State Machine
	state_machine.set_movement_direction.connect(set_patrol_direction)
	state_machine.set_chase_target.connect(set_chase_target)
	state_machine.stop_movement.connect(stop_movement)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Apply knockback if there is any
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
		move_and_slide()
		return # Don't allow other movement during knockback
		
	# Based on the target node, decide velocity
	if target_node: # Chasing
		var direction_to_target = (target_node.global_position - global_position).normalized()
		movement_direction = sign(direction_to_target.x)
		velocity.x = current_speed * movement_direction
	else: # Patrolling
		# Check for obstacles/cliffs during patrol
		if (not cliff_check_ray.is_colliding() or wall_check_ray.is_colliding()) and is_on_floor():
			movement_direction *= -1 # Turn around
		
		velocity.x = current_speed * movement_direction

	# Apply movement
	move_and_slide()
	
	# Update visuals
	update_visual_direction()

func update_visual_direction() -> void:
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0
		# You can put the logic to flip all your other nodes here too

# --- Public functions called by StateMachine ---

func set_patrol_direction(direction: int) -> void:
	target_node = null # Ensure we are not chasing
	current_speed = PATROL_SPEED
	movement_direction = direction
	velocity.x = current_speed * movement_direction

func set_chase_target(target: Node2D) -> void:
	target_node = target
	current_speed = CHASE_SPEED

func stop_movement() -> void:
	target_node = null
	velocity.x = 0
