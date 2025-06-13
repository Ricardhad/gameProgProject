extends Node2D

#================================#
#     VARIABEL UNTUK MINIMAP     #
#================================#
# Path ke node-node penting di dalam scene HUD ini
@onready var sub_viewport: SubViewport = $CanvasLayer2/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $CanvasLayer2/SubViewportContainer/SubViewport/Camera2D
@onready var player_icon: ColorRect = $CanvasLayer2/SubViewportContainer/SubViewport/PlayerIcon


# Variabel lain
var player_node = null
var current_minimap_tilemap: TileMap = null
var jump_button_pressed = false
var dash_button_pressed = false


#================================#
#       FUNGSI INTI MINIMAP      #
#================================#

# Fungsi ini hanya bertugas menduplikasi peta ke dalam viewport
func setup_minimap(tilemap_from_world: TileMap):
	if is_instance_valid(current_minimap_tilemap):
		current_minimap_tilemap.queue_free()

	current_minimap_tilemap = tilemap_from_world.duplicate()
	sub_viewport.add_child(current_minimap_tilemap)
	
	# Atur Z Index agar ikon selalu di atas peta
	if is_instance_valid(player_icon):
		player_icon.z_index = 1


# Fungsi untuk menerima node player dari scene peta
func set_player_node(p_node):
	player_node = p_node


#================================#
# FUNGSI BAWAAN GODOT (_ready, _process) #
#================================#

func _ready():
	$"CanvasLayer2/Label_Stage-Level".text = "Stage " + GlobalVar.current_stage

func _process(delta: float):
	# Update UI Anda seperti biasa
	update_coin_label()
	
	# --- INI LOGIKA KUNCI NYA ---
	# Pastikan player sudah terhubung
	if is_instance_valid(player_node):
		# Atur posisi kamera minimap agar SELALU sama dengan posisi global player
		minimap_camera.position = player_node.global_position

#================================#
# FUNGSI UI LAINNYA              #
#================================#

func update_coin_label():
	$CanvasLayer2/Panel/Label_coin.text = str(GlobalVar.coin_collected)
	$CanvasLayer2/Panel/HealthBar.value = GlobalVar.health_player
	$CanvasLayer2/Panel/HealthBar.max_value = GlobalVar.maxhealth_player

func _on_ButtonJump_pressed():
	jump_button_pressed = true

func _on_ButtonDash_pressed():
	dash_button_pressed = true

# ... sisa fungsi tombol Anda tidak perlu diubah ...
func set_attack_button_pressed(is_pressed: bool):
	var button = $CanvasLayer2/Panel/ButtonATK
	if button:
		button.set_pressed(is_pressed)

func set_jump_button_pressed():
	var button = $CanvasLayer2/Panel/ButtonJump
	if not button:
		return
	button.set_pressed(true)
	await get_tree().create_timer(0.15).timeout
	button.set_pressed(false)

func set_dash_button_pressed():
	var button = $CanvasLayer2/Panel/ButtonDash
	if not button:
		return
	button.set_pressed(true)
	await get_tree().create_timer(0.15).timeout
	button.set_pressed(false)
