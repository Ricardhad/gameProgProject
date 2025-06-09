extends Node2D

# This line creates the "parameter" in the Godot Inspector.
# It allows you to assign a scene file to it.
@export var target_scene: PackedScene
@export var next_scene: String
@onready var fade_rect: ColorRect = $ColorRect

func _on_body_entered(body: Node2D):
	# First, check if a scene has even been assigned in the editor.
	if not target_scene:
		#print("ERROR: No target scene assigned to this goal!")
		return
	
	# Check if the body that entered is the player.
	if body.is_in_group("player"):
		GlobalVar.current_stage = next_scene
		get_tree().change_scene_to_file(target_scene.resource_path)
		
