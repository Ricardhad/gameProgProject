# NPC.gd

extends CharacterBody2D

signal interacted

# --- Referensi Node ---
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: TextureButton = $ButtonATK
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Tambahkan referensi untuk panel dan label chat
@onready var panel_chat: Panel = $PanelChatNPC
@onready var label_chat: Label = $PanelChatNPC/LabelChatNPC

var player_in_range: bool = false

func _ready():
	# Sembunyikan semua elemen UI pada awalnya
	interaction_prompt.visible = false
	panel_chat.visible = false # Sembunyikan panel chat juga
	
	#interaction_prompt.mouse_filter = MOUSE_FILTER_IGNORE
	
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	# Hanya proses input jika pemain ada di jangkauan
	if player_in_range and event.is_action_pressed("interact"):
		# Jika panel chat sedang terlihat, sembunyikan saja.
		if panel_chat.visible:
			panel_chat.visible = false
		# Jika tidak, jalankan logika interaksi.
		else:
			# Panggil fungsi untuk memulai dialog dan memberi hadiah
			trigger_dialogue()
		
		# Tandai input sudah ditangani
		get_viewport().set_input_as_handled()

# Fungsi baru untuk mengelola dialog dan hadiah
func trigger_dialogue():
	# 1. Tambahkan koin ke variabel global
	GlobalVar.coin_collected += 10
	
	# 2. Buat teks dialog
	#    Gunakan format string untuk memasukkan jumlah koin saat ini.
	var dialog_text = "Terima kasih sudah membantuku! Kamu mendapatkan 10 koin. Total koinmu sekarang: %s" % GlobalVar.coin_collected
	
	# 3. Tampilkan teks di label dan munculkan panelnya
	label_chat.text = dialog_text
	panel_chat.visible = true
	
	# 4. Pancarkan sinyal (jika masih diperlukan untuk sistem lain)
	emit_signal("interacted")
	print("Dialog ditampilkan. Koin pemain sekarang: %s" % GlobalVar.coin_collected)

func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
		# Sembunyikan juga panel chat jika pemain menjauh
		panel_chat.visible = false
