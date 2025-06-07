extends Area2D

@export var target_scene: PackedScene


func _on_body_entered(body: Node2D):
	# First, check if a scene has even been assigned in the editor.
	if not target_scene:
		print("ERROR: No target scene assigned to this goal!")
		return

	# Check if the body that entered is the player.
	if body.is_in_group("player"):
		print("Goal reached! Loading scene: ", target_scene.resource_path)
		
		# Change to the scene that was assigned in the Inspector.
		get_tree().change_scene_to_file(target_scene.resource_path)
