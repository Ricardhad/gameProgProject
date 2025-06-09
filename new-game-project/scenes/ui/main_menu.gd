extends Control

@onready var music_slider: HSlider = $OptionPanel/MusicSlider
@onready var sfx_slider: HSlider = $OptionPanel/SFXSlider

@onready var fade_rect = $VBoxContainer/ButtonStart/ColorRect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bgm.play_music_level()
	
	fade_rect.visible = false
	fade_rect.color = Color.BLACK  # Pastikan warna hitam
	fade_rect.modulate.a = 0.0  # Transparan dari awal
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	pass # Replace with function body.
	
	var music_db = AudioServer.get_bus_volume_db(1)
	music_slider.value = db_to_linear(music_db)

	var sfx_db = AudioServer.get_bus_volume_db(2)
	sfx_slider.value = db_to_linear(sfx_db)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	Transition1.change_scene("res://scenes/ui/selecting_chr.tscn")

func _on_load_pressed() -> void:
	pass # Replace with function body.

func _on_options_pressed() -> void:
	$OptionPanel.visible = true

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
	AudioServer.set_bus_volume_db(1,linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2,linear_to_db(value))
