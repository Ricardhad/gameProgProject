# This script is on your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var walk_speed: float = 80.0

# NEW: We get the project's gravity setting.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Node References ---
@onready var animation_tree = $AnimationTree
@onready var attack_timer = $AttackTimer

# --- Private Variables ---
var player = null

func _ready():
	# Make sure the timer's wait time is set from our cooldown variable
	attack_timer.wait_time = attack_cooldown
	# Ensure the AnimationTree is active
	animation_tree.active = true

func _physics_process(delta):
	# 1. APPLY GRAVITY
	# Add gravity every frame if the dragon is not on the floor.
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. FIND THE PLAYER
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			# If there's no player, the dragon should just stand still and be affected by gravity.
			velocity.x = 0 
			move_and_slide()
			return

	# --- AI LOGIC ---
	var player_in_range = is_player_in_range()
	var cooldown_ready = attack_timer.is_stopped()
	
	# This line correctly controls the walk/idle animation state.
	animation_tree.set("parameters/Conditions/is_walking", not player_in_range)

	# --- MOVEMENT AND ATTACK LOGIC ---
	if player_in_range:
		# Player is close. Stop horizontal movement and prepare to attack.
		velocity.x = 0 # MODIFIED: We only stop horizontal movement.
		
		# If cooldown is ready, execute an attack.
		if cooldown_ready:
			execute_random_attack()
	else:
		# Player is far away. Chase them horizontally.
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * walk_speed # MODIFIED: We only set horizontal velocity.
	
	# Apply all movement (horizontal chase + vertical gravity) at the end
	move_and_slide()


# --- Helper Functions ---

func is_player_in_range() -> bool:
	return global_position.distance_to(player.global_position) <= attack_range

func execute_random_attack():
	# This randomly chooses an attack and triggers it in the AnimationTree.
	var available_attacks = ["Trigger Attack 1", "Trigger Attack 2"]
	var chosen_attack = available_attacks.pick_random()
	
	# The path must EXACTLY match your setup.
	var parameter_path = "parameters/Conditions/" + chosen_attack
	
	animation_tree.set(parameter_path, true)
	attack_timer.start()
