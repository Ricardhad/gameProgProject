# LootDropper.gd
extends Node

@export var coin_scene: PackedScene
@export var coin_min_amount: int = 1 
@export var coin_max_amount: int = 6 

@onready var health_component: Node = get_parent().get_node("Health")



func _ready() -> void:
	# Connect to the Health component's signal
	randomize()
	
	#health_component.health_depleted.connect(drop_coins, CONNECT_DEFERRED)
	print("LootDropper ready for: ", get_parent().name, " with unique ID: ", self.get_instance_id())
	if health_component:
		health_component.health_depleted.connect(drop_coins, CONNECT_DEFERRED)
	else:
		# Print an error if the Health node is missing to make debugging easier.
		printerr("LootDropper Error: Health component not found on parent '", get_parent().name, "'!")

func drop_coins() -> void:
	GlobalVar.kill_count += 1
	GlobalVar.score += 100 
	if coin_scene == null:
		print("LootDropper: Coin scene not assigned!")
		return

	var coin_count = randi_range(coin_min_amount, coin_max_amount)
	for i in coin_count:
		var coin = coin_scene.instantiate()
		# Add the coin to the Goblin's parent (the main level)
		get_parent().get_parent().add_child(coin)
		coin.global_position = get_parent().global_position + Vector2(randf_range(-8, 8), -8)

		var player = get_tree().get_first_node_in_group("player")
		if player:
			coin.player = player
