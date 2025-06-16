# NPC.gd (Final dengan visual feedback modulate)
extends CharacterBody2D

# --- Referensi Node ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var button_chat: TextureButton = $ButtonChat
@onready var panel_chat_npc: Panel = $PanelChatNPC
@onready var label_chat_npc: Label = $PanelChatNPC/LabelChatNPC
@onready var button_open_shop: TextureButton = $PanelChatNPC/ButtonBuy
@onready var panel_shop: Panel = $CanvasLayer/PanelShop
@onready var label_shop_coin: Label = $CanvasLayer/PanelShop/LabelShopCoin
@onready var button_card_1: TextureButton = $CanvasLayer/PanelShop/ButtonCard1
@onready var label_detail_1: Label = $CanvasLayer/PanelShop/ButtonCard1/LabelDetail
@onready var texture_rect_1: TextureRect = $CanvasLayer/PanelShop/ButtonCard1/TextureRect
@onready var label_coin_1: Label = $CanvasLayer/PanelShop/ButtonCard1/LabelCoin
@onready var button_card_2: TextureButton = $CanvasLayer/PanelShop/ButtonCard2
@onready var label_detail_2: Label = $CanvasLayer/PanelShop/ButtonCard2/LabelDetail
@onready var texture_rect_2: TextureRect = $CanvasLayer/PanelShop/ButtonCard2/TextureRect
@onready var label_coin_2: Label = $CanvasLayer/PanelShop/ButtonCard2/LabelCoin
@onready var button_card_3: TextureButton = $CanvasLayer/PanelShop/ButtonCard3
@onready var label_detail_3: Label = $CanvasLayer/PanelShop/ButtonCard3/LabelDetail
@onready var texture_rect_3: TextureRect = $CanvasLayer/PanelShop/ButtonCard3/TextureRect
@onready var label_coin_3: Label = $CanvasLayer/PanelShop/ButtonCard3/LabelCoin
@onready var button_confirm_buy: TextureButton = $CanvasLayer/PanelShop/ButtonBuy
@onready var button_refresh: TextureButton = $CanvasLayer/PanelShop/ButtonRefresh
@onready var button_back: TextureButton = $CanvasLayer/PanelShop/ButtonBack
@onready var label_message: Label = $CanvasLayer/PanelShop/LabelMessage

var player_in_range: bool = false
var selected_card_id: int = 0

var all_available_buffs = [
	{"id": "hp_buff", "desc": "Max HP +10", "cost": 25, "path": "res://assets/item&buff/buff/HP.png"},
	{"id": "atk_buff", "desc": "Damage +2", "cost": 25, "path": "res://assets/item&buff/buff/Str.png"},
	{"id": "def_buff", "desc": "Defense +1", "cost": 20, "path": "res://assets/item&buff/buff/Def.png"},
	{"id": "agi_buff", "desc": "Agility +5", "cost": 20, "path": "res://assets/item&buff/buff/Agi.png"},
	{"id": "luck_buff", "desc": "Luck +10%", "cost": 30, "path": "res://assets/item&buff/buff/Luck.png"},
	{"id": "potion_buff", "desc": "Extra Potion", "cost": 50, "path": "res://assets/item&buff/buff/Potion.png"},
	{"id": "coin_buff", "desc": "Extra Coin", "cost": 40, "path": "res://assets/item&buff/buff/ExtraCoin.png"}
]
var current_shop_items = []

func _ready():
	close_all_ui()
	var nodes_to_process = [
		panel_shop, button_card_1, button_card_2, button_card_3, 
		button_confirm_buy, button_refresh, button_back
	]
	for node in nodes_to_process:
		node.process_mode = Node.PROCESS_MODE_ALWAYS
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	button_open_shop.pressed.connect(_on_open_shop_pressed)
	button_confirm_buy.pressed.connect(_on_confirm_purchase_pressed)
	button_refresh.pressed.connect(_on_refresh_pressed)
	button_back.pressed.connect(close_all_ui)
	button_card_1.pressed.connect(func(): _on_card_selected(1))
	button_card_2.pressed.connect(func(): _on_card_selected(2))
	button_card_3.pressed.connect(func(): _on_card_selected(3))
	animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if not panel_chat_npc.visible and not panel_shop.visible:
			start_dialogue()
		else:
			close_all_ui()
	if panel_chat_npc.visible and event.is_action_pressed("open_shop"):
		_on_open_shop_pressed()
	if event.is_action_pressed("ui_cancel"):
		if panel_shop.visible or panel_chat_npc.visible:
			close_all_ui()

func start_dialogue():
	label_chat_npc.text = "Halo, petualang! Daganganku selalu baru setiap saat."
	panel_chat_npc.visible = true
	button_open_shop.visible = true

func _on_open_shop_pressed():
	panel_chat_npc.visible = false
	button_open_shop.visible = false
	panel_shop.visible = true
	get_tree().paused = true
	update_coin_label()
	refresh_shop()

func close_all_ui():
	panel_chat_npc.visible = false
	panel_shop.visible = false
	button_open_shop.visible = false
	label_message.visible = false
	button_chat.visible = player_in_range
	if get_tree().paused:
		get_tree().paused = false

func update_coin_label():
	label_shop_coin.text = str(GlobalVar.coin_collected)

func show_message(text: String, duration: float = 2.0):
	label_message.text = text
	label_message.visible = true
	await get_tree().create_timer(duration).timeout
	label_message.visible = false

func _on_refresh_pressed():
	var refresh_cost = 5
	if GlobalVar.coin_collected >= refresh_cost:
		GlobalVar.coin_collected -= refresh_cost
		update_coin_label()
		refresh_shop()
	else:
		show_message("Butuh %d koin untuk refresh!" % refresh_cost)

func refresh_shop():
	selected_card_id = 0
	button_card_1.visible = true; button_card_2.visible = true; button_card_3.visible = true
	button_card_1.button_pressed = false; button_card_2.button_pressed = false; button_card_3.button_pressed = false
	button_card_1.modulate = Color.WHITE; button_card_2.modulate = Color.WHITE; button_card_3.modulate = Color.WHITE
	
	all_available_buffs.shuffle()
	current_shop_items = all_available_buffs.slice(0, 3)
	
	update_card_display(1, current_shop_items[0])
	update_card_display(2, current_shop_items[1])
	update_card_display(3, current_shop_items[2])

func update_card_display(card_slot: int, item_data: Dictionary):
	var label_detail: Label; var texture_rect: TextureRect; var label_coin: Label
	match card_slot:
		1: label_detail = label_detail_1; texture_rect = texture_rect_1; label_coin = label_coin_1
		2: label_detail = label_detail_2; texture_rect = texture_rect_2; label_coin = label_coin_2
		3: label_detail = label_detail_3; texture_rect = texture_rect_3; label_coin = label_coin_3
	label_detail.text = item_data.desc; texture_rect.texture = load(item_data.path); label_coin.text = str(item_data.cost)

func _on_card_selected(card_id: int):
	var color_normal = Color.WHITE
	var color_selected = Color.from_string("878476", 1)

	if card_id == selected_card_id:
		selected_card_id = 0
	else:
		selected_card_id = card_id
	
	button_card_1.button_pressed = (selected_card_id == 1)
	button_card_1.modulate = color_selected if selected_card_id == 1 else color_normal
	
	button_card_2.button_pressed = (selected_card_id == 2)
	button_card_2.modulate = color_selected if selected_card_id == 2 else color_normal

	button_card_3.button_pressed = (selected_card_id == 3)
	button_card_3.modulate = color_selected if selected_card_id == 3 else color_normal

func _on_confirm_purchase_pressed():
	if selected_card_id == 0:
		show_message("Pilih item terlebih dahulu!")
		return
	var item_to_buy = current_shop_items[selected_card_id - 1]
	var cost = item_to_buy.cost
	var buff_name = item_to_buy.id
	if GlobalVar.coin_collected >= cost:
		GlobalVar.coin_collected -= cost
		GlobalVar.acquire_temporary_buff(buff_name)
		update_coin_label()
		show_message("Pembelian %s berhasil!" % item_to_buy.desc)
		var selected_button = get_node("CanvasLayer/PanelShop/ButtonCard" + str(selected_card_id))
		selected_button.visible = false
		selected_card_id = 0
		# Reset warna setelah beli
		button_card_1.modulate = Color.WHITE; button_card_2.modulate = Color.WHITE; button_card_3.modulate = Color.WHITE
	else:
		show_message("Koin tidak cukup.")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		button_chat.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		button_chat.visible = false
		close_all_ui()
