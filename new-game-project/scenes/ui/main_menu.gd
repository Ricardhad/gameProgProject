extends Control

@onready var fade_rect = $VBoxContainer/ButtonStart/ColorRect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bgm.play_music_level()
	
	fade_rect.visible = false
	fade_rect.color = Color.BLACK  # Pastikan warna hitam
	fade_rect.modulate.a = 0.0  # Transparan dari awal
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if GlobalVar.transition_fade_in:
		GlobalVar.transition_fade_in = false  # Reset flag

		fade_rect.visible = true
		fade_rect.modulate.a = 1.0  # Mulai dari hitam

		var fade_in = create_tween()
		fade_in.tween_property(fade_rect, "modulate:a", 0.0, 1.0)  # Fade-out dari hitam
	else:
		fade_rect.visible = false  # Jika bukan transisi
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	#print("Button start pressed")

	GlobalVar.transition_fade_in = true  # Aktifkan flag untuk fade-in di scene selanjutnya

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var fade_out = create_tween()
	#fade_out.tween_property(fade_rect, "modulate:a", 1.0, 1.0) #comment lek gk perlu transisi
	fade_out.tween_callback(Callable(self, "_change_scene"))

func _change_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/CutScene2.tscn")
	#get_tree().change_scene_to_file("res://scenes/ui/CutScene1.tscn")

func _on_load_pressed() -> void:
	pass # Replace with function body.

func _on_options_pressed() -> void:
	$OptionPanel.visible = true
	AudioServer.set_bus_volume_db(1, linear_to_db($OptionPanel/MusicSlider.value))
	AudioServer.set_bus_volume_db(2, linear_to_db($OptionPanel/SFXSlider.value))

func _on_ButtonBack_pressed() -> void:
	print("Back button pressed")
	$OptionPanel.visible = false

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


func _on_music_slider_mouse_exited() -> void:
	release_focus()

func _on_sfx_slider_mouse_exited() -> void:
	release_focus()

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),linear_to_db(value))
