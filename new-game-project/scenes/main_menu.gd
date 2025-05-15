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
	$OptionPanel.visible = true

func _on_ButtonBack_pressed() -> void:
	print("Back button pressed")
	$OptionPanel.visible = false


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	print("CheckButton toggled:", button_pressed)
	if button_pressed:
		$AudioStreamPlayer.stream_paused = true
	else:
		$AudioStreamPlayer.stream_paused = false


func _on_exit_pressed() -> void:
	#$VBoxContainer/Button4/PopupExit.popup_centered()
	get_tree().quit()
