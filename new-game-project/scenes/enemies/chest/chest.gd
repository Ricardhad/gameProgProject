extends CharacterBody2D

const COIN = preload("res://scenes/player/consumables/coin.tscn")
@export var min_coins: int = 10
@export var max_coins: int = 20

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: TextureButton = $ButtonATK

var player_in_range: bool = false
var is_opened: bool = false

func _ready():
	interaction_prompt.visible = false
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	animated_sprite_2d.play("closed")

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not is_opened:
		open_chest()
		get_viewport().set_input_as_handled()

func open_chest():
	print("CHEST: I'm opened. Playing animation and dropping coins!")
	is_opened = true
	interaction_prompt.visible = false

	animated_sprite_2d.play("open")
	await animated_sprite_2d.animation_finished

	drop_coins()
	queue_free()

func drop_coins():
	var coins_to_drop = randi_range(min_coins, max_coins)
	print("CHEST: Dropping %d coins." % coins_to_drop)

	GlobalVar.coin_collected += coins_to_drop
	print("Player total coins: %d" % GlobalVar.coin_collected)

	for i in range(coins_to_drop):
		var coin_instance = COIN.instantiate()
		get_parent().add_child(coin_instance)
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		coin_instance.global_position = global_position + offset

func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		if not is_opened:
			interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
