extends Node2D

# --- DATA DESKRIPSI ---
const BUFF_DESCRIPTIONS = {
	"hp": "Buff HP: Meningkatkan maksimal HP sebesar 10 selama 1 stage.",
	"atk": "Buff ATK: Meningkatkan serangan sebesar 2 selama 1 stage.",
	"def": "Buff DEF: Meningkatkan pertahanan sebesar 3 selama 1 stage.",
	"agi": "Buff AGI: Meningkatkan kecepatan gerak dan mengurangi cooldown dash & lompat selama 1 stage.",
	"potion": "Buff Potion: Meningkatkan jumlah pemulihan HP dari potion selama 1 stage.",
	"luck": "Buff LUCK: Meningkatkan kemungkinan mendapatkan koin bonus setelah mengalahkan musuh.",
	"coin": "Buff COIN: Dijamin mendapatkan koin bonus setelah mengalahkan musuh."
}
const ITEM_DESCRIPTIONS = {
	"maxpot": "Item Potion+: Menambah jumlah maksimal potion yang bisa dibawa secara permanen.",
	"atk": "Item Pedang: Menambah statistik serangan dasar secara permanen.",
	"agi": "Item Sepatu: Menambah statistik kecepatan gerak secara permanen.",
	"def": "Item Zirah: Menambah statistik pertahanan dasar secara permanen.",
	"hp": "Item Hati: Menambah maksimal HP secara permanen."
}

# --- REFERENSI NODE (PASTIKAN SEMUA PATH INI 100% BENAR) ---
@onready var music_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider
@onready var sfx_slider: HSlider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider2
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
@onready var item_atk: TextureRect = $CanvasLayer/PanelPause/LabelItems/TextureRectCard/TextureAtk
@onready var item_agi: TextureRect = $CanvasLayer/PanelPause/LabelItems/TextureRectCard2/TextureAgi
@onready var item_def: TextureRect = $CanvasLayer/PanelPause/LabelItems/TextureRectCard3/TextureDef
@onready var item_hp: TextureRect = $CanvasLayer/PanelPause/LabelItems/TextureRectCard4/TextureHp
@onready var item_maxpot: TextureRect = $CanvasLayer/PanelPause/LabelItems/TextureRectCard5/TextureMaxPot
@onready var panel_detail: Panel = $CanvasLayer/PanelPause/PanelDetail
@onready var label_detail: Label = $CanvasLayer/PanelPause/PanelDetail/Label

func _ready() -> void:
	# Pengecekan keamanan sebelum mengakses node
	if is_instance_valid($CanvasLayer/PanelPause):
		_set_process_mode_recursively($CanvasLayer/PanelPause, Node.PROCESS_MODE_ALWAYS)
		$CanvasLayer/PanelPause.visible = false
	
	if is_instance_valid(panel_detail):
		panel_detail.visible = false
	
	get_tree().paused = false
	
	# Menghubungkan sinyal dengan pengecekan keamanan
	_connect_signal(tex_atk, "_on_icon_gui_input", ["atk", "buff"])
	_connect_signal(tex_def, "_on_icon_gui_input", ["def", "buff"])
	_connect_signal(tex_agi, "_on_icon_gui_input", ["agi", "buff"])
	_connect_signal(tex_hp, "_on_icon_gui_input", ["hp", "buff"])
	_connect_signal(tex_potion, "_on_icon_gui_input", ["potion", "buff"])
	_connect_signal(tex_luck, "_on_icon_gui_input", ["luck", "buff"])
	_connect_signal(tex_coin, "_on_icon_gui_input", ["coin", "buff"])
	_connect_signal(item_atk, "_on_icon_gui_input", ["atk", "item"])
	_connect_signal(item_agi, "_on_icon_gui_input", ["agi", "item"])
	_connect_signal(item_def, "_on_icon_gui_input", ["def", "item"])
	_connect_signal(item_hp, "_on_icon_gui_input", ["hp", "item"])
	_connect_signal(item_maxpot, "_on_icon_gui_input", ["maxpot", "item"])

	if is_instance_valid(music_slider):
		var music_db = AudioServer.get_bus_volume_db(1)
		music_slider.value = db_to_linear(music_db)
	if is_instance_valid(sfx_slider):
		var sfx_db = AudioServer.get_bus_volume_db(2)
		sfx_slider.value = db_to_linear(sfx_db)

# Fungsi bantuan untuk menghubungkan sinyal dengan aman
func _connect_signal(node, function_name, binds_array):
	if is_instance_valid(node):
		node.gui_input.connect(Callable(self, function_name).bindv(binds_array))
	else:
		print("PERINGATAN: Node tidak ditemukan dan sinyal tidak terhubung untuk ", node)

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
		else:
			$CanvasLayer/PanelPause.visible = false
			if is_instance_valid(panel_detail):
				panel_detail.visible = false
			get_tree().paused = false

func _on_icon_gui_input(event: InputEvent, key: String, type: String):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_show_detail(key, type)

func _show_detail(key: String, type: String):
	var description_text = "Deskripsi tidak ditemukan."
	if type == "buff":
		if BUFF_DESCRIPTIONS.has(key):
			description_text = BUFF_DESCRIPTIONS[key]
	elif type == "item":
		if ITEM_DESCRIPTIONS.has(key):
			description_text = ITEM_DESCRIPTIONS[key]
	
	if is_instance_valid(label_detail):
		label_detail.text = description_text
	if is_instance_valid(panel_detail):
		panel_detail.visible = true

func update_buff_display():
	var color_dim = Color.from_string("808080", 1)
	var color_active = Color.WHITE

	if is_instance_valid(tex_hp) and is_instance_valid(label_hp):
		if GlobalVar.hp_buff_duration > 0: tex_hp.modulate = color_active; label_hp.text = str(GlobalVar.hp_buff_duration)
		else: tex_hp.modulate = color_dim; label_hp.text = "0"
	if is_instance_valid(tex_atk) and is_instance_valid(label_atk):
		if GlobalVar.atk_buff_duration > 0: tex_atk.modulate = color_active; label_atk.text = str(GlobalVar.atk_buff_duration)
		else: tex_atk.modulate = color_dim; label_atk.text = "0"
	if is_instance_valid(tex_def) and is_instance_valid(label_def):
		if GlobalVar.def_buff_duration > 0: tex_def.modulate = color_active; label_def.text = str(GlobalVar.def_buff_duration)
		else: tex_def.modulate = color_dim; label_def.text = "0"
	if is_instance_valid(tex_agi) and is_instance_valid(label_agi):
		if GlobalVar.agi_buff_duration > 0: tex_agi.modulate = color_active; label_agi.text = str(GlobalVar.agi_buff_duration)
		else: tex_agi.modulate = color_dim; label_agi.text = "0"
	if is_instance_valid(tex_luck) and is_instance_valid(label_luck):
		if GlobalVar.luck_buff_duration > 0: tex_luck.modulate = color_active; label_luck.text = str(GlobalVar.luck_buff_duration)
		else: tex_luck.modulate = color_dim; label_luck.text = "0"
	if is_instance_valid(tex_potion) and is_instance_valid(label_potion):
		if GlobalVar.potion_buff_duration > 0: tex_potion.modulate = color_active; label_potion.text = str(GlobalVar.potion_buff_duration)
		else: tex_potion.modulate = color_dim; label_potion.text = "0"
	if is_instance_valid(tex_coin) and is_instance_valid(label_coin):
		if GlobalVar.coin_buff_duration > 0: tex_coin.modulate = color_active; label_coin.text = str(GlobalVar.coin_buff_duration)
		else: tex_coin.modulate = color_dim; label_coin.text = "0"


func _on_HSliderMusic_value_changed_tutotrial1(value: float) -> void:
	if is_instance_valid(music_slider): AudioServer.set_bus_volume_db(1, linear_to_db(value))
func _on_HSliderMusic_value_changed_tutotrial2(value: float) -> void:
	if is_instance_valid(sfx_slider): AudioServer.set_bus_volume_db(2, linear_to_db(value))
func _on_CheckButton2_toggled1(button_pressed: bool) -> void:
	if button_pressed: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
func _on_options_pressed1() -> void:
	var option_panel = $CanvasLayer/PanelPause/PanelPauseOption
	if is_instance_valid(option_panel): option_panel.visible = not option_panel.visible
func _on_Resumebtn_pressed() -> void:
	$CanvasLayer/PanelPause.visible = false
	if is_instance_valid(panel_detail): panel_detail.visible = false
	get_tree().paused = false
	$CanvasLayer/PanelPause/PanelPauseOption.visible = false
func _on_Exitbtn_pressed() -> void:
	GlobalVar.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
func _refresh_stats_labels() -> void:
	pass
