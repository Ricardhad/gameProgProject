extends Node2D

@onready var label_text_box = $PanelTextBoxHero/LabelTextBoxHero
@onready var panel_face      = $PanelTextBoxHero/PanelFace
@onready var dialogue_timer  = $DialogueTimer      # timer huruf-per-huruf
@onready var auto_next_timer = $AutoNextTimer      # timer jeda antar-dialog
@onready var fade_rect: ColorRect = $ColorRect

# texture wajah
var face_hero  : Texture
var face_king  : Texture
var face_queen : Texture
var face_prajurit: Texture # Menambahkan wajah untuk prajurit

# dialog list
var dialogues         = []
var dialogue_index    = 0
var char_index        = 0
var current_text      = ""

func _ready() -> void:
	# load wajah
	face_hero  = load("res://assets/selecting_menu/knight.png")
	face_king  = load("res://assets/selecting_menu/king.png")
	face_queen = load("res://assets/selecting_menu/queen.png")
	# Asumsi path untuk wajah prajurit, silakan ganti jika perlu
	face_prajurit = load("res://assets/selecting_menu/soldier.png") 

	# daftar dialog dari narasi baru
	dialogues = [
		{ "text": "Permaisuriku, ada berita buruk dari perbatasan. Pasukan Obsidian sudah mulai membakar desa-desa di utara. Keadaan semakin gawat.", "face": face_king },
		{ "text": "Aku tahu. Pasukan kita sudah berjuang keras, tapi musuh terlalu kuat dan banyak. Kita butuh bantuan.", "face": face_queen },
		{ "text": "Aku dengar ada ksatria hebat dari Emerald Kingdom, namanya The Brave Knight. Katanya dia sangat kuat.", "face": face_king },
		{ "text": "Apa dia mau membantu kita? Apa imbalan yang bisa kita tawarkan?", "face": face_queen },
		{ "text": "Aku sudah mengirim utusan untuk menawarinya imbalan yang pantas. Mudah-mudahan dia segera datang.", "face": face_king },
		{ "text": "Paduka Raja, Ratu. The Brave Knight sudah tiba di gerbang. Dia ingin bertemu.", "face": face_prajurit },
		{ "text": "Persilakan dia masuk. Harapan kita ada padanya.", "face": face_king },
		{ "text": "Salam, Paduka. Saya The Brave Knight. Saya datang memenuhi panggilan Anda.", "face": face_hero },
		{ "text": "Terima kasih sudah datang, Ksatria. Negeri kami dalam bahaya besar. Pasukan Obsidian menyerang dengan kejam, dan pasukan kami tidak sanggup lagi menahan mereka.", "face": face_king },
		{ "text": "Kami dengar kau sangat hebat. Sekaranglah waktunya untuk menunjukkan kemampuanmu itu.", "face": face_queen },
		{ "text": "Saya di sini bukan untuk mencari harta. Saya melawan kejahatan. Katakan saja, siapa yang harus saya hadapi?", "face": face_hero },
		{ "text": "Musuh utama kita adalah seorang Jenderal yang menggunakan sihir gelap. Dia memimpin tiga pasukan besar dan bisa memanggil monster-monster mengerikan.", "face": face_king },
		{ "text": "Sihir gelap, ya... Saya mengerti. Untuk melawan mereka, saya butuh peta wilayah dan informasi penting lainnya. Saya juga butuh izin untuk merekrut bantuan di sepanjang jalan.", "face": face_hero },
		{ "text": "Tentu. Semua yang kau butuhkan akan kami siapkan. Kami percaya sepenuhnya padamu.", "face": face_queen },
		{ "text": "Baiklah. Ini akan jadi pertarungan yang berat, tapi aku berjanji akan melakukan yang terbaik. Kerajaan ini tidak akan jatuh.", "face": face_hero }
	]

	# timer ketik
	dialogue_timer.wait_time = 0.05
	dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)

	# timer auto-next (satu-shot, 1 detik)
	auto_next_timer.one_shot  = true
	auto_next_timer.wait_time = 1.0
	auto_next_timer.timeout.connect(_next_dialogue)

	start_dialogue()    # mulai dialog pertama


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
		auto_next_timer.start()        # jeda 1 detik lalu lanjut otomatis


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


func _on_button_skip_pressed() -> void:
	_end_cutscene()
	pass # Replace with function body.
