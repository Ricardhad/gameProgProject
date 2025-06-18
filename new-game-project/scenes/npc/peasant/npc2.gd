extends CharacterBody2D

signal interacted

# --- Referensi Node ---
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: TextureButton = $ButtonATK
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var panel_chat: Panel = $PanelChatNPC
@onready var label_chat: Label = $PanelChatNPC/LabelChatNPC

var player_in_range: bool = false
var has_rewarded: bool = false  # ✅ Tambahkan flag untuk interaksi pertama kali

func _ready():
	interaction_prompt.visible = false
	panel_chat.visible = false
	
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if panel_chat.visible:
			panel_chat.visible = false
		else:
			trigger_dialogue()
		get_viewport().set_input_as_handled()

func trigger_dialogue():
	var dialog_text = ""
	
	if not has_rewarded:
		# Interaksi pertama: beri hadiah dan dialog terima kasih
		GlobalVar.coin_collected += 10
		dialog_text = "Terima kasih sudah membantuku! Ini 10 koin untukmu."
		has_rewarded = true
	else:
		# Interaksi berikutnya
		dialog_text = "Aku ketakutan... Pahlawan, Obsidian Kingdom sedang kacau. Kau harus menyelamatkannya!"

	label_chat.text = dialog_text
	panel_chat.visible = true
	
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
		panel_chat.visible = false
