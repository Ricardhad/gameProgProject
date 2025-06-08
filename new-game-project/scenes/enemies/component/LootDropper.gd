# LootDropper.gd
extends Node

@export var coin_scene: PackedScene
@onready var health_component: Node = get_parent().get_node("Health")

func _ready() -> void:
	# Connect to the Health component's signal
	health_component.health_depleted.connect(drop_coins)

func drop_coins() -> void:
	if coin_scene == null:
		print("LootDropper: Coin scene not assigned!")
		return

	var coin_count = randi_range(1, 5)
	for i in coin_count:
		var coin = coin_scene.instantiate()
		# Add the coin to the Goblin's parent (the main level)
		get_parent().get_parent().add_child(coin)
		coin.global_position = get_parent().global_position + Vector2(randf_range(-8, 8), -8)

		var player = get_tree().get_first_node_in_group("player")
		if player:
			coin.player = player
