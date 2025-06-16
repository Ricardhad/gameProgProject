extends Node2D

@onready var music_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider
@onready var sfx_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider2

# --- Referensi Node untuk Buff List (dengan path ATK yang sudah benar) ---
@onready var tex_agi: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect
@onready var label_agi: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect/Label
@onready var tex_def: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect2
@onready var label_def: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect2/Label
@onready var tex_potion: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect3
@onready var label_potion: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect3/Label
@onready var tex_hp: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect4
@onready var label_hp: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect4/Label
@onready var tex_luck: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect5
@onready var label_luck: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect5/Label
@onready var tex_coin: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect6
@onready var label_coin: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect6/Label
@onready var tex_atk: TextureRect = $CanvasLayer/PanelPause/LabelBuffList/TextureRect7
@onready var label_atk: Label = $CanvasLayer/PanelPause/LabelBuffList/TextureRect7/Label


func _ready() -> void:
	# Atur process mode untuk seluruh panel pause dan semua turunannya
	_set_process_mode_recursively($CanvasLayer/PanelPause, Node.PROCESS_MODE_ALWAYS)
	
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false
	
	var music_db = AudioServer.get_bus_volume_db(1)
	music_slider.value = db_to_linear(music_db)
	var sfx_db = AudioServer.get_bus_volume_db(2)
	sfx_slider.value = db_to_linear(sfx_db)

# Fungsi baru untuk mengatur process mode secara rekursif
func _set_process_mode_recursively(node, mode):
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursively(child, mode)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			$CanvasLayer/PanelPause.visible = true
			get_tree().paused = true
			update_buff_display()
			# _refresh_stats_labels() # Untuk item, bisa diaktifkan jika path sudah benar
		else:
			$CanvasLayer/PanelPause.visible = false
			get_tree().paused = false

func update_buff_display():
	var color_dim = Color.from_string("808080", 1)
	var color_active = Color.WHITE

	# Membaca dari variabel GlobalVar..._duration yang benar
	# HP
	if GlobalVar.hp_buff_duration > 0:
		tex_hp.modulate = color_active
		label_hp.text = str(GlobalVar.hp_buff_duration)
	else:
		tex_hp.modulate = color_dim
		label_hp.text = "0"
		
	# ATK
	if GlobalVar.atk_buff_duration > 0:
		tex_atk.modulate = color_active
		label_atk.text = str(GlobalVar.atk_buff_duration)
	else:
		tex_atk.modulate = color_dim
		label_atk.text = "0"
		
	# DEF
	if GlobalVar.def_buff_duration > 0:
		tex_def.modulate = color_active
		label_def.text = str(GlobalVar.def_buff_duration)
	else:
		tex_def.modulate = color_dim
		label_def.text = "0"

	# AGI
	if GlobalVar.agi_buff_duration > 0:
		tex_agi.modulate = color_active
		label_agi.text = str(GlobalVar.agi_buff_duration)
	else:
		tex_agi.modulate = color_dim
		label_agi.text = "0"

	# Lanjutkan untuk Luck, Potion, Coin
	# Luck
	if GlobalVar.luck_buff_duration > 0:
		tex_luck.modulate = color_active
		label_luck.text = str(GlobalVar.luck_buff_duration)
	else:
		tex_luck.modulate = color_dim
		label_luck.text = "0"
	# Potion
	if GlobalVar.potion_buff_duration > 0:
		tex_potion.modulate = color_active
		label_potion.text = str(GlobalVar.potion_buff_duration)
	else:
		tex_potion.modulate = color_dim
		label_potion.text = "0"
	# Coin
	if GlobalVar.coin_buff_duration > 0:
		tex_coin.modulate = color_active
		label_coin.text = str(GlobalVar.coin_buff_duration)
	else:
		tex_coin.modulate = color_dim
		label_coin.text = "0"

# --- (Sisa kode Anda yang lain tidak perlu diubah) ---
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

func _on_Resumebtn_pressed() -> void:
	$CanvasLayer/PanelPause.visible = false
	get_tree().paused = false
	$CanvasLayer/PanelPause/PanelPauseOption.visible = false
	
func _on_Exitbtn_pressed() -> void:
	GlobalVar.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _refresh_stats_labels() -> void:
	pass
