# MovementChecker.gd
class_name MovementChecker
extends Node2D

@onready var cliff_check: RayCast2D = $CliffCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var jump_check: RayCast2D = $JumpCheck

var initial_cliff_check_x: float
var initial_wall_check_x: float
var initial_wall_check_target_x: float
var initial_jump_check_x: float
var initial_jump_check_target_x: float
func _ready():
	# Store the initial positions so we can flip them correctly
	initial_cliff_check_x = cliff_check.position.x
	initial_wall_check_x = wall_check.position.x
	initial_wall_check_target_x = wall_check.target_position.x
	initial_jump_check_x = jump_check.position.x
	initial_jump_check_target_x = jump_check.target_position.x
	#print("WallCheck node initial position from editor is: ", wall_check.position)
	#print("Stored 'initial_wall_check_x' is now: ", initial_wall_check_x)

# The parent (Goblin) will call this function to tell us which way it's facing
func update_direction(direction: int) -> void:
	var direction_sign = sign(direction)
	if direction_sign != 0:
		cliff_check.position.x = initial_cliff_check_x * direction_sign
		wall_check.position.x = initial_wall_check_x * direction_sign
		wall_check.target_position.x = initial_wall_check_target_x * direction_sign
		jump_check.position.x = initial_jump_check_x * direction_sign
		jump_check.target_position.x = initial_jump_check_target_x * direction_sign	
		
		#print("--- WallCheck Update ---")
		#print("Current Direction Sign: ", direction_sign)
		#print("Using Initial Wall Check X: ", initial_wall_check_x)
		#
		#var new_x_pos = initial_wall_check_x * direction_sign
		#print("Calculated New X Position: ", new_x_pos)
		#
		#wall_check.position.x = new_x_pos
		#print("WallCheck position was set. It is now: ", wall_check.position)
		#print("----------------------")
# --- Public functions to answer questions ---

func is_obstacle_ahead() -> bool:
	# An obstacle is either a wall in front or the edge of a cliff
	return wall_check.is_colliding() or not cliff_check.is_colliding()

func is_safe_to_jump() -> bool:
	jump_check.force_raycast_update() # We must force an update to get the latest data
	return jump_check.is_colliding()
