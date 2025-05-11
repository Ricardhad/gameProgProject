extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_load_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed():
	$OptionsPopup.popup_centered()

func _on_options_popup_id_pressed(id):
	match id:
		0:
			print("Graphics Settings selected")
		1:
			print("Audio Settings selected")
		2:
			print("Controls selected")
			
func _on_exit_pressed() -> void:
	#$VBoxContainer/Button4/PopupExit.popup_centered()
	get_tree().quit()
