extends Node2D

@onready var music_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider
@onready var sfx_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/PanelPause.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in $CanvasLayer/PanelPause.get_children():
		child.process_mode = Node.PROCESS_MODE_ALWAYS
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false
	
	var music_db = AudioServer.get_bus_volume_db(1)
	music_slider.value = db_to_linear(music_db)
	var sfx_db = AudioServer.get_bus_volume_db(2)
	sfx_slider.value = db_to_linear(sfx_db)

func _on_HSliderMusic_value_changed_tutotrial1(value: float) -> void:
	AudioServer.set_bus_volume_db(1,linear_to_db(value))

func _on_HSliderMusic_value_changed_tutotrial2(value: float) -> void:
	AudioServer.set_bus_volume_db(2,linear_to_db(value))

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
			_refresh_stats_labels()
		else:
			$CanvasLayer/PanelPause.visible = false
			get_tree().paused = false

func _on_Resumebtn_pressed() -> void:
	print("Resume pressed")
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false
	$CanvasLayer/PanelPause/PanelPauseOption.visible = false
	
func _on_Exitbtn_pressed() -> void:
	GlobalVar.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _refresh_stats_labels() -> void:
	$CanvasLayer/PanelPause/Label3/TextureRect/Label.text = str(GlobalVar.hp)
	$CanvasLayer/PanelPause/Label3/TextureRect2/Label.text = str(GlobalVar.atk)
	$CanvasLayer/PanelPause/Label3/TextureRect3/Label.text = str(GlobalVar.agi)
	$CanvasLayer/PanelPause/Label3/TextureRect4/Label.text = str(GlobalVar.def)
	$CanvasLayer/PanelPause/Label3/TextureRect5/Label.text = str(GlobalVar.maxPot)
