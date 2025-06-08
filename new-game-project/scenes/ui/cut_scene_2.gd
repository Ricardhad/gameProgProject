extends Node2D

# Referensi ke node-node dengan jalur yang benar
@onready var hero_animation: AnimatedSprite2D = $HeroAnimation
@onready var panel_text_box_hero: Panel = $HeroAnimation/PanelTextBoxHero
@onready var label_text_box_hero: Label = $HeroAnimation/PanelTextBoxHero/LabelTextBoxHero

@onready var king_animation: AnimatedSprite2D = $KingAnimation
@onready var panel_text_box_king: Panel = $KingAnimation/PanelTextBoxKing
@onready var label_text_box_king: Label = $KingAnimation/PanelTextBoxKing/LabelTextBoxKing

@onready var queen_animation: AnimatedSprite2D = $QueenAnimation
@onready var panel_text_box_queen: Panel = $QueenAnimation/PanelTextBoxQueen
@onready var label_text_box_queen: Label = $QueenAnimation/PanelTextBoxQueen/LabelTextBoxQueen

@onready var dialogue_timer: Timer = $DialogueTimer

func _ready() -> void:
	# Sembunyikan semua panel dialog pada awalnya
	panel_text_box_hero.hide()
	panel_text_box_king.hide()
	panel_text_box_queen.hide()

	# Mulai cutscene
	start_cutscene()

func start_cutscene():
	# --- BAGIAN BARU: HERO BERLARI DARI LUAR LAYAR ---
	
	# 1. Tentukan posisi awal dan akhir
	# Posisi target adalah posisi Hero saat ini di editor
	var target_position = hero_animation.global_position
	# Posisi awal adalah di luar layar sebelah kanan
	var start_position = Vector2(get_viewport_rect().size.x + 100, target_position.y)

	# Pindahkan Hero ke posisi awal sebelum scene dimulai
	hero_animation.global_position = start_position

	# 2. Mainkan animasi lari
	hero_animation.play("run")

	# 3. Buat dan jalankan Tween untuk pergerakan
	var tween = create_tween()
	# Animasikan properti 'global_position' dari posisi awal ke posisi target selama 2 detik
	tween.tween_property(hero_animation, "global_position", target_position, 2.0)
	
	# Tunggu sampai pergerakan (tween) selesai
	await tween.finished

	# 4. Ganti animasi ke "idle" setelah sampai
	hero_animation.play("idle")

	# --- PERCAKAPAN DIMULAI SETELAH HERO TIBA ---

	# 5. Hero berbicara terlebih dahulu
	show_dialogue(label_text_box_hero, panel_text_box_hero, "Hosh... Hosh... Akhirnya aku sampai!")
	# Mainkan animasi dialog jika ada
	hero_animation.play("dialog")
	
	dialogue_timer.start(3)
	await dialogue_timer.timeout
	hide_dialogue(panel_text_box_hero)
	hero_animation.play("idle")

	# 6. Raja merespon
	king_animation.play("dialog")
	show_dialogue(label_text_box_king, panel_text_box_king, "Kerja bagus, pahlawan! Kami menunggumu.")

	dialogue_timer.start(3)
	await dialogue_timer.timeout
	hide_dialogue(panel_text_box_king)
	king_animation.play("idle")

	# 7. Ratu melanjutkan
	queen_animation.play("dialog")
	show_dialogue(label_text_box_queen, panel_text_box_queen, "Semoga perjalananmu menyenangkan.")

	dialogue_timer.start(3)
	await dialogue_timer.timeout
	hide_dialogue(panel_text_box_queen)
	queen_animation.play("idle")


func show_dialogue(label: Label, panel: Panel, text: String):
	"""Fungsi untuk menampilkan dialog."""
	label.text = text
	panel.show()

func hide_dialogue(panel: Panel):
	"""Fungsi untuk menyembunyikan dialog."""
	panel.hide()
