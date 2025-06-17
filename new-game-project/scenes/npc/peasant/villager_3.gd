# NPC.gd
class_name Villager
extends CharacterBody2D

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: TextureButton = $ButtonChat
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var panel_chat: Panel = $PanelChatNPC
@onready var label_chat: Label = $PanelChatNPC/LabelChatNPC
@onready var button_yes: TextureButton = $PanelChatNPC/ButtonYes
@onready var button_no: TextureButton = $PanelChatNPC/ButtonNo

var player_in_range: bool = false
var offered_quest: Dictionary = {}

const QUEST_LIST = [
	{ "hud_text": "Kalahkan Monster", "description": "Aku butuh bantuanmu membasmi 15 monster. Sanggup?", "kill_target": 15, "reward_coin": 50 },
	{ "hud_text": "Bantai Monster", "description": "Area ini semakin berbahaya. Tolong, kalahkan 30 monster.", "kill_target": 30, "reward_coin": 100 },
	{ "hud_text": "Pahlawan Monster", "description": "Seorang pahlawan sepertimu pasti bisa. Kalahkan 50 monster!", "kill_target": 50, "reward_coin": 150 }
]

func _ready():
	interaction_prompt.visible = false
	panel_chat.visible = false
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	button_yes.pressed.connect(_on_button_yes_pressed)
	button_no.pressed.connect(_on_button_no_pressed)
	animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if panel_chat.visible:
			panel_chat.visible = false
		else:
			offer_quest_dialogue()
		get_viewport().set_input_as_handled()

func offer_quest_dialogue():
	if GlobalVar.is_quest_active:
		label_chat.text = "Bagaimana perkembangan misimu? Selesaikan dengan baik dan temui aku lagi!"
		button_yes.visible = false
		button_no.visible = true
	else:
		offered_quest = QUEST_LIST.pick_random()
		var quest_text = "%s\n\nImbalan: %d Koin" % [offered_quest.description, offered_quest.reward_coin]
		label_chat.text = quest_text
		button_yes.visible = true
		button_no.visible = true
	panel_chat.visible = true

func _on_button_yes_pressed():
	if not offered_quest.is_empty():
		GlobalVar.is_quest_active = true
		GlobalVar.active_quest_data = offered_quest
		GlobalVar.initial_kill_count_on_accept = GlobalVar.kill_count
		label_chat.text = "Bagus! Selesaikan misinya!"
		button_yes.visible = false
		button_no.visible = false
		await get_tree().create_timer(2.0).timeout
		panel_chat.visible = false
		offered_quest.clear()

func _on_button_no_pressed():
	if not offered_quest.is_empty():
		label_chat.text = "Sayang sekali. Mungkin lain kali."
		button_yes.visible = false
		button_no.visible = false
		await get_tree().create_timer(2.0).timeout
		panel_chat.visible = false
		offered_quest.clear()
	else:
		panel_chat.visible = false

func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
		panel_chat.visible = false
