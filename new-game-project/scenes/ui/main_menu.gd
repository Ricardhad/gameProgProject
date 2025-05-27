extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bgm.play_music_level()
	$OptionPanel/CheckButton.button_pressed = Bgm.stream_paused
	
	var slider = $OptionPanel/HSlider
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = db_to_linear(Bgm.volume_db)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/selecting_chr.tscn")


func _on_load_pressed() -> void:
	pass # Replace with function body.


func _on_options_pressed() -> void:
	$OptionPanel.visible = true

func _on_ButtonBack_pressed() -> void:
	print("Back button pressed")
	$OptionPanel.visible = false


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	print("CheckButton toggled:", button_pressed)
	Bgm.stream_paused = button_pressed

func _on_HSliderMusic_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	Bgm.volume_db = db
	print("Volume set to:", db, "dB")

func _on_CheckButton2_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_exit_pressed() -> void:
	$AreYouSure.visible = true

func _on_ButtonYes_pressed() -> void:
	print("User confirmed exit.")
	get_tree().quit()


func _on_ButtonNo_pressed() -> void:
	print("User canceled exit.")
	$AreYouSure.visible = false  # Sembunyikan popup
