# FINAL CORRECTED GOLEM SCRIPT
extends CharacterBody2D

# --- AI Behavior & Stats ---
@export_group("Movement")
@export var speed: float = 75.0
@export var jump_power: float = -400.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@export_group("AI Parameters")
@export var attack_range: float = 60.0
@export var jump_distance_threshold: float = 250.0
@export var rush_duration: float = 6.0
@export var attack_cooldown: float = 2.0 #
# --- Node References ---
@onready var pivot = $Pivot # ✅ GET THE PIVOT NODE
@onready var animation_player = $AnimationPlayer
@onready var hitbox = $Pivot/HitBox # Note: Path might change if HitBox is inside Pivot
@onready var hurtbox = $Pivot/HurtBox # Note: Path might change if HurtBox is inside Pivot
@onready var health_component = %Health
@onready var phase_timer = $PhaseTimer      # Controls timing between ground and rush phases
@onready var decision_timer = $DecisionTimer  # Controls how often the AI "thinks" when idle
@onready var attack_timer = $AttackTimer     

# --- Private Variables ---
var player = null
var current_state: String = "idle"
var rush_target_position: Vector2
var is_on_stuck_cooldown: bool = false
var can_attack: bool = true 

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	connect_signals()
	transition_to("idle")
	phase_timer.start()

func connect_signals():
	if not player:
		print("GOLEM AI: Player not found! AI will be disabled.")
		set_physics_process(false)
		return
	health_component.health_depleted.connect(_on_health_depleted)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	decision_timer.timeout.connect(_decide_next_action)
	phase_timer.timeout.connect(_on_phase_timer_timeout)
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _on_attack_timer_timeout():
	can_attack = true # Allow the Golem to attack again

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	# State-based logic that runs every frame
	match current_state:
		"idle":
			if player:
				face_direction(player.global_position - global_position)
			velocity.x = move_toward(velocity.x, 0, speed)
		"follow":
			if player:
				face_direction(player.global_position - global_position)
			if global_position.distance_to(player.global_position) <= attack_range and can_attack:
				velocity.x = 0
				transition_to("basic_attack")
			else:
				velocity.x = pivot.scale.x * speed
		"jump_attack":
			velocity.x = move_toward(velocity.x, 0, 25 * delta)
		"basic_attack", "hurt":
			velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

	if current_state == "follow" and is_on_floor() and is_on_wall():
		face_direction(Vector2(-pivot.scale.x, 0))
		is_on_stuck_cooldown = true
		get_tree().create_timer(1.0).timeout.connect(func(): is_on_stuck_cooldown = false)
		transition_to("idle")

# --- AI Decision Making ---
func _decide_next_action():
	if current_state != "idle" or not player or is_on_stuck_cooldown:
		return

	var horizontal_distance = abs(player.global_position.x - global_position.x)
	
	if horizontal_distance > jump_distance_threshold:
		transition_to("jump_attack")
	else:
		transition_to("follow")

func _on_phase_timer_timeout():
	if current_state in ["dead", "hurt", "rush"]:
		return
	transition_to("rush")

# --- State Machine ---
func transition_to(new_state: String):
	if current_state == new_state or current_state == "dead":
		return
	
	decision_timer.stop()
	current_state = new_state
	
	match new_state:
		"idle":
			animation_player.play("idle")
			decision_timer.start()
		"follow":
			animation_player.play("run")
		"basic_attack":
			animation_player.play("attack1")
		"jump_attack":
			animation_player.play("jump")
			if player:
				face_direction(player.global_position - global_position)
			
			var estimated_air_time = (jump_power / gravity) * -2.0
			var horizontal_distance = player.global_position.x - global_position.x
			var required_speed = clamp(horizontal_distance / estimated_air_time, -speed * 2.5, speed * 2.5)
			
			velocity.x = required_speed
			velocity.y = jump_power
			
			set_hitbox_active(true)
			await get_tree().create_timer(0.1).timeout
			while not is_on_floor():
				await get_tree().physics_frame
			set_hitbox_active(false)
			if current_state == "jump_attack":
				transition_to("idle")
		"rush":
			animation_player.play("run")
			var screen_size = get_viewport_rect().size
			var start_x = 50
			var end_x = screen_size.x - 50
			if global_position.x < screen_size.x / 2:
				rush_target_position = Vector2(end_x, global_position.y)
			else:
				rush_target_position = Vector2(start_x, global_position.y)
			var direction = (rush_target_position - global_position).normalized()
			face_direction(direction)
			velocity = direction * speed * 2.5
			set_hitbox_active(true)
			await get_tree().create_timer(rush_duration).timeout
			if current_state == "rush":
				set_hitbox_active(false)
				phase_timer.start()
				transition_to("idle")
		"hurt":
			animation_player.play("hurt")
			await animation_player.animation_finished
			if current_state == "hurt":
				transition_to("idle")
		"dead":
			phase_timer.stop()
			decision_timer.stop()
			animation_player.play("dead")
			set_physics_process(false)
			hurtbox.get_node("CollisionShape2D").set_deferred("disabled", true)
			hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

# --- Signal Callbacks & Helpers ---
func _on_hurtbox_entered(area):
	if area.is_in_group("player_hitbox"):
		health_component.set_health(health_component.get_health() - 25) # Example damage
		if health_component.get_health() > 0 and current_state != "hurt":
			if not health_component.get_immortality():
				transition_to("hurt")

func _on_health_depleted():
	transition_to("dead")

func _attack_finished():
	if current_state == "basic_attack":
		transition_to("idle")

func set_hitbox_active(is_active: bool):
	hitbox.get_node("CollisionShape2D").disabled = not is_active

# ✅ THIS IS NOW THE ONLY FUNCTION FOR TURNING
func face_direction(direction: Vector2):
	if direction.x > 0:
		pivot.scale.x = -1 # Face right
	elif direction.x < 0:
		pivot.scale.x = 1 # Face left
