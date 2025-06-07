extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var slider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = db_to_linear(Bgm.volume_db)
	$CanvasLayer/PanelPause.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in $CanvasLayer/PanelPause.get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false

func _on_HSliderMusic_value_changed_tutotrial1(value: float) -> void:
	var db = linear_to_db(value)
	Bgm.volume_db = db
	#print("Volume set to:", db, "dB")

func _on_HSliderMusic_value_changed_tutotrial2(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db($CanvasLayer/PanelPause/PanelPauseOption/HSlider2.value))
	#print("Volume set to:", db, "dB")

func _on_CheckButton2_toggled1(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_options_pressed1() -> void:
	var option_panel = $CanvasLayer/PanelPause/PanelPauseOption
	option_panel.visible = not option_panel.visible



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			$CanvasLayer/PanelPause.visible = true
			get_tree().paused = true
		else:
			$CanvasLayer/PanelPause.visible = false
			get_tree().paused = false

func _on_Resumebtn_pressed() -> void:
	print("Resume pressed")
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false
	


func _on_Exitbtn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
