extends CharacterBody2D

# --- Konstanta Murni Aksi Player ---
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 350.0
const DASH_DURATION = 0.3
const HANG_GRACE_TIME = 0.2

# --- Variabel Internal Player ---
var dash_cooldown_timer = 0.0
var jump_cooldown_timer = 0.0
var heavy_atk_charges = 0
var heavy_atk_recharge_timer = 0.0
var is_hanging = false
var hang_grace_timer = 0.0
var dash_time = 0.0
var jump_count = 0
var max_jumps = 2
var current_attack_index = 0
var attack_animations = ["attack", "attack1"]

# --- Player State Variables ---
enum PlayerState {
	IDLE, RUN, JUMP, FALL, DASH, ATTACK, HEAVY_ATTACK, HEAL, HANG, CLIMB_UP, DROP_DOWN
}
var current_state: PlayerState = PlayerState.IDLE

# --- Node References ---
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var attack_area_1: CollisionShape2D = $HitBox/Attack
@onready var attack_area_2: CollisionShape2D = $HitBox2/Attack
@onready var health: Health = $Health
@onready var hud = get_node("/root/game/Hud")
@onready var hurtbox: HurtBox = $HurtBox

var respawn_position = Vector2(150, 150)
var original_attack_offset_x = 0.0
var original_attack2_offset_x = 0.0
var original_sprite_position := Vector2.ZERO

func _ready():
	original_attack_offset_x = attack_area_1.position.x
	original_attack2_offset_x = attack_area_2.position.x
	original_sprite_position = animated_sprite_2d.position
	randomize()
	
	# Inisialisasi dari GlobalVar
	$HitBox.damage = GlobalVar.damage_player
	$HitBox2.damage = GlobalVar.damage_player * 2
	health.sync_with_global = true
	health.set_max_health(GlobalVar.maxhealth_player)
	health.set_health(GlobalVar.health_player)
	
	heavy_atk_charges = GlobalVar.MAX_HEAVY_ATK_CHARGES
	if hud:
		hud.update_heavy_attack_charges(heavy_atk_charges, GlobalVar.MAX_HEAVY_ATK_CHARGES)
		hud.update_potion_count(GlobalVar.current_potions, GlobalVar.max_potions)
	
	# Koneksi Sinyal
	health.connect("health_depleted", Callable(self, "_on_health_depleted"))
	animated_sprite_2d.animation_finished.connect(Callable(self, "_on_animated_sprite_2d_animation_finished"))
	hurtbox.received_damage.connect(_on_player_damaged)
	
	set_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0: dash_cooldown_timer -= delta
	if jump_cooldown_timer > 0: jump_cooldown_timer -= delta
	
	if heavy_atk_charges < GlobalVar.MAX_HEAVY_ATK_CHARGES:
		heavy_atk_recharge_timer += delta
		if heavy_atk_recharge_timer >= GlobalVar.HEAVY_ATK_COOLDOWN_PER_CHARGE:
			heavy_atk_charges += 1
			heavy_atk_recharge_timer = 0.0
			if hud:
				hud.update_heavy_attack_charges(heavy_atk_charges, GlobalVar.MAX_HEAVY_ATK_CHARGES)
				
	if global_position.y > 1000:
		global_position = respawn_position; velocity = Vector2.ZERO
		set_state(PlayerState.IDLE); return

	match current_state:
		PlayerState.IDLE, PlayerState.RUN, PlayerState.JUMP, PlayerState.FALL:
			handle_normal_movement(delta)
		PlayerState.DASH:
			handle_dash_state(delta)
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			handle_attack_state(delta)
		PlayerState.HEAL:
			handle_heal_state(delta)
		PlayerState.HANG:
			handle_hang_state()
		PlayerState.CLIMB_UP:
			handle_climb_up_state(delta)
		PlayerState.DROP_DOWN:
			handle_drop_down_state(delta)

	move_and_slide()

func set_state(new_state: PlayerState):
	if current_state == new_state: return

	match current_state:
		PlayerState.ATTACK, PlayerState.HEAVY_ATTACK:
			attack_area_1.disabled = true
			attack_area_2.disabled = true
			if hud: hud.set_attack_button_pressed(false)

	current_state = new_state

	match current_state:
		PlayerState.IDLE:
			animated_sprite_2d.play("idle")
			velocity.x = 0
			animated_sprite_2d.position = original_sprite_position
		PlayerState.RUN: animated_sprite_2d.play("run")
		PlayerState.JUMP, PlayerState.FALL: animated_sprite_2d.play("jump")
		PlayerState.DASH: animated_sprite_2d.play("run")
		PlayerState.ATTACK:
			animated_sprite_2d.animation = attack_animations[current_attack_index]
			animated_sprite_2d.frame = 0; animated_sprite_2d.play()
			attack_sound.play()
			update_attack_hitboxes(animated_sprite_2d.animation)
			if hud: hud.set_attack_button_pressed(true)
		PlayerState.HEAVY_ATTACK:
			if heavy_atk_charges > 0:
				heavy_atk_charges -= 1
				if hud: hud.update_heavy_attack_charges(heavy_atk_charges, GlobalVar.MAX_HEAVY_ATK_CHARGES)
				animated_sprite_2d.animation = "attack2"
				animated_sprite_2d.frame = 0; animated_sprite_2d.play()
				attack_sound.play()
				attack_area_2.disabled = false; attack_area_1.disabled = true
				if hud: hud.set_attack_button_pressed(true)
			else:
				set_state(PlayerState.IDLE); printerr("Not enough heavy attack charges!")
		PlayerState.HEAL:
			if health.health < health.max_health and GlobalVar.current_potions > 0:
				GlobalVar.current_potions -= 1
				if hud: hud.update_potion_count(GlobalVar.current_potions, GlobalVar.max_potions)
				animated_sprite_2d.animation = "heal"
				animated_sprite_2d.frame = 0; animated_sprite_2d.play()
				velocity = Vector2.ZERO
				_await_heal_animation_completion()
			else:
				printerr("Cannot heal! HP is full or no potions left.")
				set_state(PlayerState.IDLE)
		PlayerState.HANG:
			animated_sprite_2d.play("hang")
			velocity = Vector2.ZERO
			var hang_offset = Vector2(2, 2)
			if animated_sprite_2d.flip_h:
				hang_offset.x = -hang_offset.x
			animated_sprite_2d.position = original_sprite_position + hang_offset
		PlayerState.CLIMB_UP:
			is_hanging = false
			var climb_offset_x = 10.0
			var climb_offset_y = -16.0
			if animated_sprite_2d.flip_h: climb_offset_x = -climb_offset_x
			global_position.x += climb_offset_x; global_position.y += climb_offset_y
			animated_sprite_2d.play("pull_up")
			velocity = Vector2.ZERO
		PlayerState.DROP_DOWN:
			animated_sprite_2d.play("jump")
			global_position.y += 10; velocity.y = 150.0

func handle_normal_movement(delta: float):
	var jump_intent = Input.is_action_just_pressed("jump") or (hud and hud.jump_button_pressed)
	var dash_intent = Input.is_action_just_pressed("dash") or (hud and hud.dash_button_pressed)
	if hud:
		hud.jump_button_pressed = false; hud.dash_button_pressed = false

	if dash_intent and dash_cooldown_timer <= 0:
		var direction = Input.get_axis("left", "right")
		if direction == 0: direction = -1 if animated_sprite_2d.flip_h else 1
		velocity.x = direction * DASH_SPEED
		dash_time = DASH_DURATION
		dash_cooldown_timer = GlobalVar.active_dash_cd # Baca dari GlobalVar
		if hud: hud.set_dash_button_pressed()
		set_state(PlayerState.DASH)
		return

	if Input.is_action_just_pressed("attack"): set_state(PlayerState.ATTACK); return
	if Input.is_action_just_pressed("heavy_attack") and heavy_atk_charges > 0: set_state(PlayerState.HEAVY_ATTACK); return
	if Input.is_action_just_pressed("heal"): set_state(PlayerState.HEAL); return

	if not is_on_floor():
		if is_on_wall(): hang_grace_timer = HANG_GRACE_TIME
		else: hang_grace_timer -= delta
		if can_hang(): is_hanging = true; set_state(PlayerState.HANG); return

	if not is_on_floor():
		velocity += get_gravity() * delta
		if current_state == PlayerState.JUMP && velocity.y > 0: set_state(PlayerState.FALL)
		elif current_state == PlayerState.IDLE || current_state == PlayerState.RUN: set_state(PlayerState.FALL)
	else:
		jump_count = 0
		if current_state == PlayerState.JUMP || current_state == PlayerState.FALL:
			set_state(PlayerState.IDLE if abs(velocity.x) < 1 else PlayerState.RUN)

	if is_on_floor() and Input.is_action_pressed("down") and jump_intent:
		set_state(PlayerState.DROP_DOWN)
	elif jump_intent and jump_count < max_jumps:
		if jump_count == 0 or (jump_count == 1 and jump_cooldown_timer <= 0):
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			if jump_count == 2: jump_cooldown_timer = GlobalVar.active_jump_cd # Baca dari GlobalVar
			if hud: hud.set_jump_button_pressed()
			set_state(PlayerState.JUMP)

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * GlobalVar.active_speed # Baca dari GlobalVar
		animated_sprite_2d.flip_h = direction < 0
		attack_area_1.position.x = -original_attack_offset_x if animated_sprite_2d.flip_h else original_attack_offset_x
		attack_area_2.position.x = -original_attack2_offset_x if animated_sprite_2d.flip_h else original_attack2_offset_x
		if is_on_floor() and current_state != PlayerState.RUN: set_state(PlayerState.RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
		if is_on_floor() and current_state != PlayerState.IDLE and abs(velocity.x) < 1: set_state(PlayerState.IDLE)

func handle_dash_state(delta: float):
	dash_time -= delta
	if dash_time <= 0:
		velocity.x = 0
		set_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)
	else:
		velocity.y += get_gravity().y * delta

func handle_attack_state(delta: float):
	velocity.x = 0 if is_on_floor() else velocity.x * 0.95
	velocity.y += get_gravity().y * delta

func handle_heal_state(delta: float):
	velocity.x = 0 if is_on_floor() else velocity.x
	velocity.y += get_gravity().y * delta

func handle_hang_state():
	is_hanging = true
	if Input.is_action_just_pressed("jump"): is_hanging = false; set_state(PlayerState.CLIMB_UP)
	elif Input.is_action_just_pressed("down"): is_hanging = false; set_state(PlayerState.DROP_DOWN)

func handle_climb_up_state(delta: float):
	velocity = Vector2.ZERO

func handle_drop_down_state(delta: float):
	velocity.y += get_gravity().y * delta

func _on_animated_sprite_2d_animation_finished():
	match animated_sprite_2d.animation:
		"heal": pass
		"pull_up":
			animated_sprite_2d.position = original_sprite_position  # Revert offset
			global_position.y -= 24
			global_position.x += 12 * (-1 if animated_sprite_2d.flip_h else 1)
			set_state(PlayerState.IDLE)
		"attack", "attack1":
			current_attack_index = (current_attack_index + 1) % attack_animations.size()
			set_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)
		"attack2":
			set_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)

func _await_heal_animation_completion():
	if animated_sprite_2d:
		await animated_sprite_2d.animation_finished
		health.heal(GlobalVar.active_heal_amount) # Baca dari GlobalVar
		set_state(PlayerState.IDLE)
	else:
		printerr("AnimatedSprite2D node is not valid for heal await.")

func _on_player_damaged(damage_amount: int):
	var blocked_damage = min(damage_amount, GlobalVar.active_defense) # Baca dari GlobalVar
	if blocked_damage > 0:
		health.heal(blocked_damage)
		print("Damage %d masuk, diblokir oleh defense %d" % [damage_amount, blocked_damage])

func update_attack_hitboxes(current_anim: String):
	if current_anim in ["attack", "attack1"]:
		attack_area_1.disabled = false
	elif current_anim == "attack2":
		attack_area_2.disabled = false

func can_hang() -> bool:
	if not is_on_wall(): return false
	var hanging_left = $WallRayCast/LedgeCheckLeft.is_colliding() and not $WallRayCast/CheckFloorAboveLeft.is_colliding()
	var hanging_right = $WallRayCast/LedgeCheckRight.is_colliding() and not $WallRayCast/CheckFloorAboveRight.is_colliding()
	return hang_grace_timer > 0 and (hanging_left or hanging_right)

func _on_health_depleted():
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")
