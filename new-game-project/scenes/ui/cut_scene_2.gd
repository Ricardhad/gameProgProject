extends Node2D

@onready var label_text_box = $PanelTextBoxHero/LabelTextBoxHero
@onready var panel_face      = $PanelTextBoxHero/PanelFace
@onready var dialogue_timer  = $DialogueTimer
@onready var auto_next_timer = $AutoNextTimer
@onready var fade_rect: ColorRect = $ColorRect
# texture wajah
var face_hero  : Texture
var face_king  : Texture
var face_queen : Texture

# dialog list
var dialogues        = []
var dialogue_index   = 0
var char_index       = 0
var current_text     = ""

func _ready() -> void:
	# load wajah
	face_hero  = load("res://assets/selecting_menu/knight.png")
	face_king  = load("res://assets/selecting_menu/king.png")
	face_queen = load("res://assets/selecting_menu/queen.png")

	# daftar dialog
	dialogues = [
		{ "text":"Hello, I am the hero.",            "face": face_hero  },
		{ "text":"Welcome to the castle!",            "face": face_king  },
		{ "text":"Please help us, brave warrior!",    "face": face_queen }
	]

	# timer ketik
	dialogue_timer.wait_time = 0.05
	dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)

	# timer auto-next (satu-shot, 1 detik)
	auto_next_timer.one_shot  = true
	auto_next_timer.wait_time = 1.0
	auto_next_timer.timeout.connect(_next_dialogue)

	start_dialogue()   # mulai dialog pertama


# ────────────────────────────────────────────────────────────────
func start_dialogue() -> void:
	if dialogue_index >= dialogues.size():
		_end_cutscene()
		return

	current_text = dialogues[dialogue_index]["text"]
	panel_face.texture = dialogues[dialogue_index]["face"]

	label_text_box.text = ""
	char_index = 0
	dialogue_timer.start()


func _on_dialogue_timer_timeout() -> void:
	if char_index < current_text.length():
		label_text_box.text += current_text[char_index]
		char_index += 1
	else:
		dialogue_timer.stop()
		auto_next_timer.start()

func _next_dialogue() -> void:
	dialogue_index += 1
	start_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if dialogue_timer.is_stopped():
			# sudah selesai → skip jeda & lanjut
			auto_next_timer.stop()
			_next_dialogue()
		else:
			# sedang mengetik → tampilkan cepat
			dialogue_timer.stop()
			label_text_box.text = current_text
			auto_next_timer.start()

func _end_cutscene() -> void:
	#print("Semua dialog selesai – ganti scene di sini jika perlu")
	# Ganti dengan path scene yang dituju
	Transition1.change_scene("res://scenes/map/grass/map1.tscn")
	
# Fungsi untuk dihubungkan ke sinyal 'pressed' dari ButtonSkip

func _on_button_skip_pressed() -> void:
	_end_cutscene()
	pass # Replace with function body.
