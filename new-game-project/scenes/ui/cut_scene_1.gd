extends Control

var knight_scene = preload("res://scenes/player/player.tscn")
#var ninja_scene = preload("res://Ninja.tscn")

var current_player = knight_scene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_character(current_player)
	pass # Replace with function body.

func spawn_character(character_scene: PackedScene):
	var player = character_scene.instantiate()
	player.global_position = Vector2(100, 200)
	player.scale = Vector2(2, 2)
	current_player = player
	add_child(player)
	player.add_to_group("player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
