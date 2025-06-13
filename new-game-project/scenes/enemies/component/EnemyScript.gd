#to be used on normal ground enemy
extends CharacterBody2D

signal jumped
@export_group("Movement Properties")
@export var SPEED: float = 50.0
@export var CHASE_SPEED: float = 100.0
@export var GRAVITY: float = 800.0

@export_group("Combat Properties")
@export var KNOCKBACK_FORCE: float = 150.0

@export_group("Jump Properties")
@export var JUMP_VELOCITY: float = -300.0
@export var can_jump: bool = true

# --- Movement variables ---
var movement_direction = 1 # -1 for left, 1 for right
var movement_speed = SPEED
var knockback_velocity = Vector2.ZERO
const TURN_DEAD_ZONE = 10.0
#var can_jump = true # // NEW: Added this back

# --- Component and Node References ---
@onready var senses = %Senses
@onready var state_machine = %StateMachine
@onready var atk_controller = %AttackController
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Health = %Health
@onready var movement_checker: MovementChecker = %MovementChecker

# REMOVED: The initial_..._x variables are no longer needed here.

func _ready():
	health_component.health_changed.connect(_on_health_changed)
	# NOTE: You may need more connections here, like for the Senses.
	#senses.get_node("FieldOfView").body_entered.connect(state_machine._on_fov_entered)
	#atk_controller.attack_finished.connect(state_machine._on_attack_finished)

func _physics_process(delta: float):
	# Gravity always applies
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		# You can only jump if you are on the floor
		can_jump = true
	
	# --- KNOCKBACK LOGIC ---
	if knockback_velocity != Vector2.ZERO:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
	# --- NORMAL MOVEMENT LOGIC ---
	else:
		# --- JUMP LOGIC ---
		if state_machine.current_state == StateMachine.State.CHASE and can_jump and is_on_floor():
			var is_obstacle = movement_checker.is_obstacle_ahead()
			# This debug print will run constantly while chasing on the ground
			#print("Checking for obstacles... Is there an obstacle? ", is_obstacle)

			if is_obstacle:
				var is_safe = movement_checker.is_safe_to_jump()
				# This will only print when an obstacle is detected
				print("Obstacle detected! Is it safe to jump? ", is_safe)
				
				if is_safe:
					print("SAFE TO JUMP! PERFORMING JUMP!")
					perform_jump()
		# Apply horizontal movement
		velocity.x = movement_speed * movement_direction

	move_and_slide()
	update_visuals()

func perform_jump():
	velocity.y = JUMP_VELOCITY
	can_jump = false
	emit_signal("jumped")

# --- Public functions that the StateMachine can call ---
func set_movement_speed(speed: float):
	movement_speed = speed

func stop_movement():
	movement_speed = 0

func turn_around():
	movement_direction *= -1

func move_towards(target_position: Vector2):
	var horizontal_distance = target_position.x - global_position.x
	
	if abs(horizontal_distance) > TURN_DEAD_ZONE:
		movement_direction = sign(horizontal_distance)

func is_patrol_obstacle_detected() -> bool:
	return movement_checker.is_obstacle_ahead() and is_on_floor()

func update_visuals():
	var direction_sign = sign(movement_direction)
	if direction_sign != 0:
		animated_sprite.flip_h = (direction_sign < 0)
		senses.scale.x = direction_sign
		atk_controller.scale.x = direction_sign
		
		# Tell the movement checker which way we are facing
		movement_checker.update_direction(direction_sign)
		
func _on_health_changed(diff: int):
	if diff < 0: # Took damage
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = sign(global_position.x - player.global_position.x)
			knockback_velocity = Vector2(KNOCKBACK_FORCE * dir, -100)
