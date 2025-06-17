# Attach this script to your main Dragon (CharacterBody2D) node.
extends CharacterBody2D

# --- Variables ---
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 3.0
@export var walk_speed: float = 80.0

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
	# 1. FIND THE PLAYER
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			velocity = Vector2.ZERO # No player, so don't move.
			move_and_slide()
			return # Wait until the next frame.

	# --- AI LOGIC ---
	var player_in_range = is_player_in_range()
	var cooldown_ready = attack_timer.is_stopped()
	
	# This one line tells the AnimationTree whether to be in the "walk" or "idle" state.
	# It becomes 'true' when the player is NOT in range.
	# The path must EXACTLY match your parameter in the editor.
	animation_tree.set("parameters/conditions/walk", not player_in_range)

	# --- MOVEMENT AND ATTACK LOGIC ---
	if player_in_range:
		# Player is close. Stop moving and prepare to attack.
		animation_tree.set("parameters/conditions/idle", player_in_range)
		velocity = Vector2.ZERO
		
		# If cooldown is ready, execute an attack.
		if cooldown_ready:
			execute_random_attack()
	else:
		# Player is far away. Chase them.
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * walk_speed
	
	# Apply movement at the end
	move_and_slide()


# --- Helper Functions ---

func is_player_in_range() -> bool:
	return global_position.distance_to(player.global_position) <= attack_range

func execute_random_attack():
	# This randomly chooses an attack and triggers it in the AnimationTree.
	var available_attacks = ["attack1", "attack2"]
	var chosen_attack = available_attacks.pick_random()
	
	# The path must EXACTLY match your setup.
	var parameter_path = "parameters/conditions/" + chosen_attack
	
	animation_tree.set(parameter_path, true)
	attack_timer.start()
