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


func _on_options_pressed() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	$OptionsPopup.popup_centered(Vector2(screen_size.x * 0.9, screen_size.y * 0.9)) # 90% dari layar


func _on_CheckBoxNoSound_toggled(button_pressed: bool) -> void:
	if button_pressed:
		print("No Sound enabled")
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		print("No Sound disabled")
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

func _on_exit_pressed() -> void:
	#$VBoxContainer/Button4/PopupExit.popup_centered()
	get_tree().quit()
