extends CharacterBody2D

# --- AI Behavior & Stats ---
@export_group("Movement")
@export var speed: float = 75.0
@export var jump_power: float = -400.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@export_group("AI Parameters")
@export var attack_range: float = 60.0         # How close to be for a basic attack
@export var jump_distance_threshold: float = 250.0 # Player distance to trigger jump attack
@export var rush_duration: float = 6.0         # How long the rush attack lasts

# --- Node References ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var hitbox = $HitBox
@onready var hurtbox = $HurtBox
@onready var health_component= %Health # Strongly typed reference to your Health script
@onready var phase_timer = $PhaseTimer
@onready var decision_timer = $DecisionTimer

# --- Private Variables ---
var player = null
var current_state: String = "idle"
var rush_target_position: Vector2

# Change this:
# func _ready():

# To this:
func _ready():
	# And add this line at the very top:
	await get_tree().process_frame

	# Find the player (ensure your player is in the "player" group)
	player = get_tree().get_first_node_in_group("player")

	# Connect all necessary signals
	connect_signals()

	# Start the AI loop
	transition_to("idle")
	phase_timer.start()

func connect_signals():
	if not player:
		print("GOLEM AI: Player not found! AI will be disabled.")
		set_physics_process(false)
		return
		
	# Connect to your Health component's signal
	health_component.health_depleted.connect(_on_health_depleted)
	
	# Connect to the hurtbox to detect incoming damage
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	
	# Connect timers to their functions
	decision_timer.timeout.connect(_decide_next_action)
	phase_timer.timeout.connect(_on_phase_timer_timeout)

func _physics_process(delta):
	# Always apply gravity if in the air
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# State-based movement logic
	if current_state == "follow" or current_state == "rush":
		move_and_slide()
	elif current_state == "jump_attack":
		# Minimal horizontal control during jump, just let gravity do the work
		velocity.x = move_toward(velocity.x, 0, 25 * delta)
		move_and_slide()
	else:
		# For states like idle, hurt, attack, stop horizontal movement
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()

# --- AI Decision Making ---

func _decide_next_action():
	if current_state != "idle" or not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > jump_distance_threshold:
		transition_to("jump_attack")
	else:
		transition_to("follow")

func _on_phase_timer_timeout():
	if current_state == "idle" or current_state == "follow":
		transition_to("rush")

# --- State Machine ---
# --- State Machine ---

func transition_to(new_state: String):
	if current_state == new_state or current_state == "dead":
		return
	
	current_state = new_state
	
	match new_state:
		"idle":
			animation_player.play("idle")
			decision_timer.start()

		"follow":
			animation_player.play("run")
			var direction = (player.global_position - global_position).normalized()
			face_direction(direction)
			
			if global_position.distance_to(player.global_position) <= attack_range:
				transition_to("basic_attack")
			else:
				velocity.x = direction.x * speed
				await get_tree().create_timer(0.8).timeout
				if current_state == "follow":
					transition_to("idle")

		"basic_attack":
			animation_player.play("attack1")

		"jump_attack":
			animation_player.play("jump")
			var direction = (player.global_position - global_position).normalized()
			face_direction(direction)
			velocity.x = direction.x * speed * 2
			velocity.y = jump_power
			set_hitbox_active(true)
			
			while not is_on_floor():
				await get_tree().physics_frame
			
			set_hitbox_active(false)
			if current_state == "jump_attack":
				transition_to("idle")

		"rush":
			decision_timer.stop()
			animation_player.play("run")
			
			var screen_size = get_viewport_rect().size
			var start_x = 50
			var end_x = screen_size.x - 50
			
			# --- THIS IS THE CORRECTED LOGIC ---
			# We no longer teleport. We just decide the target.
			if global_position.x < screen_size.x / 2:
				# If we are on the left side, our target is the right edge.
				rush_target_position = Vector2(end_x, global_position.y)
			else:
				# If we are on the right side, our target is the left edge.
				rush_target_position = Vector2(start_x, global_position.y)
			# --- END OF CORRECTION ---

			var direction = (rush_target_position - global_position).normalized()
			face_direction(direction)
			velocity = direction * speed * 2.5
			set_hitbox_active(true)
			
			await get_tree().create_timer(rush_duration).timeout
			set_hitbox_active(false)
			if current_state == "rush":
				phase_timer.start()
				transition_to("idle")

		"hurt":
			decision_timer.stop()
			animation_player.play("hurt")
			await animation_player.animation_finished
			if current_state == "hurt":
				transition_to("idle")
		
		"dead":
			decision_timer.stop()
			phase_timer.stop()
			animation_player.play("dead")
			set_physics_process(false)
			hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)
			hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_hurtbox_entered(area):
	if area.is_in_group("player_hitbox"):
		health_component.set_health(health_component.get_health() - 25)
		if health_component.get_health() > 0 and current_state != "hurt":
			if not health_component.get_immortality():
				transition_to("hurt")

func _on_health_depleted():
	transition_to("dead")

func _activate_attack_hitbox():
	set_hitbox_active(true)

func _attack_finished():
	set_hitbox_active(false)
	if current_state == "basic_attack":
		transition_to("idle")

# --- Helper Functions ---

func set_hitbox_active(is_active: bool):
	hitbox.get_node("CollisionShape2D").disabled = not is_active

func face_direction(direction: Vector2):
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
