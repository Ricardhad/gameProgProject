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
@onready var label_upgrade: Label = $CanvasLayer/PanelSmith/ButtonUpgrade/LabelUpgrade
@onready var button_left: TextureButton = $CanvasLayer/PanelSmith/ButtonLeft
@onready var button_right: TextureButton = $CanvasLayer/PanelSmith/ButtonRight
@onready var button_back: TextureButton = $CanvasLayer/PanelSmith/ButtonBack
@onready var label_message: Label = $CanvasLayer/PanelSmith/LabelMessage

@onready var cards = [
	{ "button": $CanvasLayer/PanelSmith/ButtonCard1, "texture": $CanvasLayer/PanelSmith/ButtonCard1/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard1/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard1/LabelCoin },
	{ "button": $CanvasLayer/PanelSmith/ButtonCard2, "texture": $CanvasLayer/PanelSmith/ButtonCard2/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard2/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard2/LabelCoin },
	{ "button": $CanvasLayer/PanelSmith/ButtonCard3, "texture": $CanvasLayer/PanelSmith/ButtonCard3/TextureRect, "label_detail": $CanvasLayer/PanelSmith/ButtonCard3/LabelDetail, "label_cost": $CanvasLayer/PanelSmith/ButtonCard3/LabelCoin }
]

var player_in_range: bool = false
var selected_card_slot: int = -1

var upgradeable_items = [
	{"id": "hp", "name": "HP", "path": "res://assets/item&buff/item/hp.png", "purchase_cost": 10, "base_cost": 10, "cost_increase": 3, "desc": "Max HP"},
	{"id": "atk", "name": "ATK", "path": "res://assets/item&buff/item/atk.png", "purchase_cost": 10, "base_cost": 10, "cost_increase": 3, "desc": "ATK"},
	{"id": "def", "name": "DEF", "path": "res://assets/item&buff/item/def.png", "purchase_cost": 10, "base_cost": 10, "cost_increase": 3, "desc": "DEF"},
	{"id": "agi", "name": "AGI", "path": "res://assets/item&buff/item/agi.png", "purchase_cost": 10, "base_cost": 10, "cost_increase": 3, "desc": "AGI"},
	{"id": "maxPot", "name": "Max Potion", "path": "res://assets/item&buff/item/maxPot.png", "purchase_cost": 10, "base_cost": 10, "cost_increase": 3, "desc": "Max Potion"}
]
var current_page = 1

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_process_mode_recursively(panel_smith, Node.PROCESS_MODE_ALWAYS)
	close_all_panels()
	animated_sprite.play("idle")
	# Hubungkan sinyal
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	button_go_to_smith.pressed.connect(_on_go_to_smith_pressed)
	button_upgrade.pressed.connect(_on_upgrade_pressed)
	button_left.pressed.connect(_on_left_pressed)
	button_right.pressed.connect(_on_right_pressed)
	button_back.pressed.connect(close_all_panels)
	for i in range(cards.size()):
		cards[i].button.pressed.connect(func(): _on_card_selected(i))

# --- (Fungsi-fungsi dasar tidak berubah) ---
func _set_process_mode_recursively(node, mode):#...
	node.process_mode = mode
	for child in node.get_children():_set_process_mode_recursively(child, mode)
func _unhandled_input(event: InputEvent):#...
	if player_in_range and event.is_action_pressed("interact"):
		if panel_smith.visible or panel_chat_npc.visible: close_all_panels()
		else: panel_chat_npc.visible = true
	if event.is_action_pressed("ui_cancel"):
		if panel_smith.visible: close_all_panels()
		elif panel_chat_npc.visible: panel_chat_npc.visible = false
func close_all_panels():#...
	panel_smith.visible = false; panel_chat_npc.visible = false
	if get_tree().is_paused(): get_tree().paused = false
func _on_go_to_smith_pressed():#...
	panel_chat_npc.visible = false; open_smith_panel()
func open_smith_panel():#...
	panel_smith.visible = true; get_tree().paused = true
	label_shop_coin.text = str(GlobalVar.coin_collected)
	current_page = 1; populate_smith_panel()
func show_message(text: String, duration: float = 2.0):#...
	label_message.text = text; label_message.visible = true
	var timer = get_tree().create_timer(duration, true); await timer.timeout
	label_message.visible = false
# --- (Akhir dari fungsi dasar) ---


# --- LOGIKA BARU YANG LEBIH AMAN ---

# FUNGSI 1: Mengisi data dan status awal kartu
func populate_smith_panel():
	# Reset pilihan dan tombol upgrade utama
	selected_card_slot = -1
	button_upgrade.disabled = true
	label_upgrade.text = "---"
	
	# Loop untuk 3 slot kartu
	for i in range(cards.size()):
		var card_ui = cards[i]
		var item_index = i
		if current_page == 2:
			item_index += 3
		
		# Cek dulu apakah ada item untuk slot ini
		if item_index < upgradeable_items.size():
			card_ui.button.visible = true
			var item_data = upgradeable_items[item_index]
			
			# Mengisi data (teks, harga, gambar)
			var item_level = GlobalVar.get(item_data.id)
			card_ui.texture.texture = load(item_data.path)
			if item_level == 0: # Tahap BELI
				card_ui.label_detail.text = "Beli: " + item_data.desc
				card_ui.label_cost.text = str(item_data.purchase_cost)
				card_ui.texture.modulate = Color.WHITE # Bisa dibeli, warna normal
				card_ui.button.disabled = false # Bisa dipilih
			else: # Tahap UPGRADE
				card_ui.label_detail.text = item_data.desc + "\nLevel: " + str(item_level)
				var upgrade_cost = item_data.base_cost + ((item_level - 1) * item_data.cost_increase)
				card_ui.label_cost.text = str(upgrade_cost)
				card_ui.texture.modulate = Color.WHITE
				card_ui.button.disabled = false
		else:
			# Jika tidak ada item, sembunyikan kartunya
			card_ui.button.visible = false
			
		# Pastikan status tertekan di-reset
		card_ui.button.button_pressed = false

	# Atur status tombol navigasi
	if current_page == 1:
		button_left.disabled = true
	else:
		button_left.disabled = false
		
	if current_page == 2 or upgradeable_items.size() <= 3:
		button_right.disabled = true
	else:
		button_right.disabled = false

# FUNGSI 2: Hanya mencatat pilihan dan mengubah visual
func _on_card_selected(card_slot: int):
	if card_slot == selected_card_slot:
		selected_card_slot = -1 # Batal pilih
	else:
		selected_card_slot = card_slot
		
	# Update visual semua kartu
	for i in range(cards.size()):
		cards[i].button.button_pressed = (i == selected_card_slot)
	
	# Update tombol Upgrade/Buy utama
	if selected_card_slot != -1:
		button_upgrade.disabled = false
		var item_index = selected_card_slot + (3 if current_page == 2 else 0)
		var item_id = upgradeable_items[item_index].id
		if GlobalVar.get(item_id) == 0:
			label_upgrade.text = "Buy"
		else:
			label_upgrade.text = "Upgrade"
	else:
		button_upgrade.disabled = true
		label_upgrade.text = "---"

# FUNGSI 3 & 4: Navigasi halaman
func _on_left_pressed():
	if current_page > 1:
		current_page = 1
		populate_smith_panel()
func _on_right_pressed():
	if current_page == 1 and upgradeable_items.size() > 3:
		current_page = 2
		populate_smith_panel()

# FUNGSI 5: Aksi Upgrade/Beli
func _on_upgrade_pressed():
	if selected_card_slot == -1:
		show_message("Pilih item terlebih dahulu!")
		return
	
	var item_index: int
	if current_page == 1:
		item_index = selected_card_slot
	else:
		item_index = selected_card_slot + 3

	# Pengecekan keamanan ini seharusnya tidak pernah gagal dengan logika baru, tapi tetap disimpan
	if item_index >= upgradeable_items.size():
		show_message("Item tidak valid!")
		return
		
	var item_data = upgradeable_items[item_index]
	var item_id = item_data.id
	var item_level = GlobalVar.get(item_id)
	
	var cost: int
	var is_buying = (item_level == 0)
	
	if is_buying:
		cost = item_data.purchase_cost
	else:
		cost = item_data.base_cost + ((item_level - 1) * item_data.cost_increase)
		
	if GlobalVar.coin_collected >= cost:
		GlobalVar.coin_collected -= cost
		GlobalVar.add_item(item_id)
		
		var action_text = "dibeli" if is_buying else "di-upgrade"
		show_message("Berhasil %s: %s" % [action_text, item_data.name])
		label_shop_coin.text = str(GlobalVar.coin_collected)
		populate_smith_panel()
	else:
		show_message("Koin tidak cukup!")

# --- FUNGSI INTERAKSI PLAYER ---
func _on_interaction_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		interaction_prompt.visible = true
func _on_interaction_area_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		interaction_prompt.visible = false
		close_all_panels()
