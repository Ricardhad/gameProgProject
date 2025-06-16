# class_name Villager
extends CharacterBody2D

# --- Referensi Node ---
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: TextureButton = $ButtonChat
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var panel_chat_npc: Panel = $PanelChatNPC
@onready var button_go_to_smith: TextureButton = $PanelChatNPC/ButtonUpgrade
@onready var panel_smith: Panel = $CanvasLayer/PanelSmith
@onready var label_shop_coin: Label = $CanvasLayer/PanelSmith/LabelShopCoin
@onready var button_upgrade: TextureButton = $CanvasLayer/PanelSmith/ButtonUpgrade
@onready var button_left: TextureButton = $CanvasLayer/PanelSmith/ButtonLeft
@onready var button_right: TextureButton = $CanvasLayer/PanelSmith/ButtonRight
@onready var button_back: TextureButton = $CanvasLayer/PanelSmith/ButtonBack

@onready var cards = [
	{ "button": $CanvasLayer/PanelSmith/ButtonCard1, "texture": $CanvasLayer/PanelSmith/ButtonCard1/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard1/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard1/LabelCoin },
	{ "button": $CanvasLayer/PanelSmith/ButtonCard2, "texture": $CanvasLayer/PanelSmith/ButtonCard2/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard2/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard2/LabelCoin },
	{ "button": $CanvasLayer/PanelSmith/ButtonCard3, "texture": $CanvasLayer/PanelSmith/ButtonCard3/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard3/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard3/LabelCoin }
]

var player_in_range: bool = false
var selected_card_slot: int = -1

var upgradeable_items = [
	{"id": "hp", "name": "HP", "path": "res://assets/item&buff/item/hp.png", "base_cost": 10, "cost_increase": 5, "desc": "Upgrade Max HP (+3)"},
	{"id": "atk", "name": "ATK", "path": "res://assets/item&buff/item/atk.png", "base_cost": 15, "cost_increase": 10, "desc": "Upgrade ATK (+2)"},
	{"id": "def", "name": "DEF", "path": "res://assets/item&buff/item/def.png", "base_cost": 10, "cost_increase": 5, "desc": "Upgrade DEF"},
	{"id": "agi", "name": "AGI", "path": "res://assets/item&buff/item/agi.png", "base_cost": 10, "cost_increase": 5, "desc": "Upgrade AGI"},
	{"id": "maxPot", "name": "Max Potion", "path": "res://assets/item&buff/item/maxPot.png", "base_cost": 25, "cost_increase": 25, "desc": "Tambah Max Potion"}
]
var current_page = 1

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_process_mode_recursively(panel_smith, Node.PROCESS_MODE_ALWAYS)
	
	close_all_panels()
	animated_sprite.play("idle")
	
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	
	button_go_to_smith.pressed.connect(_on_go_to_smith_pressed)
	button_upgrade.pressed.connect(_on_upgrade_pressed)
	button_left.pressed.connect(_on_left_pressed)
	button_right.pressed.connect(_on_right_pressed)
	button_back.pressed.connect(close_all_panels)
	
	for i in range(cards.size()):
		cards[i].button.pressed.connect(func(): _on_card_selected(i))

func _set_process_mode_recursively(node, mode):
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursively(child, mode)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if panel_smith.visible or panel_chat_npc.visible:
			close_all_panels()
		else:
			panel_chat_npc.visible = true
			
	if event.is_action_pressed("ui_cancel"):
		if panel_smith.visible or panel_chat_npc.visible:
			close_all_panels()

func close_all_panels():
	panel_smith.visible = false
	panel_chat_npc.visible = false
	if get_tree().is_paused():
		get_tree().paused = false

func _on_go_to_smith_pressed():
	panel_chat_npc.visible = false
	open_smith_panel()

func open_smith_panel():
	panel_smith.visible = true
	get_tree().paused = true
	label_shop_coin.text = str(GlobalVar.coin_collected)
	current_page = 1
	populate_smith_panel()

func _update_card_ui(card_ui: Dictionary, item_data: Dictionary):
	var item_id = item_data.id
	var item_level = GlobalVar.get(item_id)
	if item_level > 0:
		card_ui.button.disabled = false
		card_ui.texture.modulate = Color.WHITE
		card_ui.texture.texture = load(item_data.path)
		card_ui.label_detail.text = item_data.desc + "\nLevel: " + str(item_level)
		var upgrade_cost = item_data.base_cost + (item_level * item_data.cost_increase)
		card_ui.label_cost.text = str(upgrade_cost)
	else:
		card_ui.button.disabled = true
		card_ui.texture.modulate = Color.GRAY
		card_ui.texture.texture = load(item_data.path)
		card_ui.label_detail.text = "Item belum ditemukan"
		card_ui.label_cost.text = "???"

func populate_smith_panel():
	_on_card_selected(-1)
	if current_page == 1:
		_update_card_ui(cards[0], upgradeable_items[0])
		_update_card_ui(cards[1], upgradeable_items[1])
		_update_card_ui(cards[2], upgradeable_items[2])
		cards[2].button.visible = true
	elif current_page == 2:
		_update_card_ui(cards[0], upgradeable_items[3])
		_update_card_ui(cards[1], upgradeable_items[4])
		cards[2].button.visible = false
	
	if current_page == 1:
		button_left.disabled = true
	else:
		button_left.disabled = false
		
	if current_page == 2 or upgradeable_items.size() <= 3:
		button_right.disabled = true
	else:
		button_right.disabled = false

func _on_left_pressed():
	if current_page > 1:
		current_page -= 1
		populate_smith_panel()

func _on_right_pressed():
	if current_page == 1 and upgradeable_items.size() > 3:
		current_page = 2
		populate_smith_panel()

func _on_card_selected(card_slot: int):
	if card_slot == selected_card_slot:
		selected_card_slot = -1
	else:
		selected_card_slot = card_slot
		
	for i in range(cards.size()):
		if i == selected_card_slot:
			cards[i].button.button_pressed = true
		else:
			cards[i].button.button_pressed = false

func _on_upgrade_pressed():
	if selected_card_slot == -1:
		print("Pilih item untuk di-upgrade!")
		return

	# --- PERBAIKAN FINAL: LOGIKA IF/ELSE DIBUAT JELAS ---
	var item_index: int
	if current_page == 1:
		item_index = selected_card_slot
	else: # Ini berarti current_page adalah 2
		item_index = selected_card_slot + 3

	if item_index >= upgradeable_items.size():
		print("Error: Index item tidak valid!")
		return

	var item_data = upgradeable_items[item_index]
	var item_id = item_data.id
	var item_level = GlobalVar.get(item_id)
	var upgrade_cost = item_data.base_cost + (item_level * item_data.cost_increase)

	if GlobalVar.coin_collected >= upgrade_cost:
		GlobalVar.coin_collected -= upgrade_cost
		GlobalVar.add_item(item_id)
		
		print("Berhasil upgrade %s!" % item_data.name)
		label_shop_coin.text = str(GlobalVar.coin_collected)
		populate_smith_panel()
	else:
		print("Koin tidak cukup untuk upgrade!")

func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
		close_all_panels()
