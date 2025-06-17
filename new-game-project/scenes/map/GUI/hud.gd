extends Node2D

#================================#
#     VARIABEL UNTUK MINIMAP     #
#================================#
@onready var sub_viewport: SubViewport = $CanvasLayer2/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $CanvasLayer2/SubViewportContainer/SubViewport/Camera2D
@onready var player_icon: ColorRect = $CanvasLayer2/SubViewportContainer/SubViewport/PlayerIcon
# Variabel baru untuk label HP
@onready var health_bar_label: Label = $CanvasLayer2/Panel/HealthBar/Label


# Variabel lain
var player_node = null
var current_minimap_tilemap: TileMap = null
var jump_button_pressed = false
var dash_button_pressed = false


#================================#
#       FUNGSI INTI MINIMAP      #
#================================#
func setup_minimap(tilemap_from_world: TileMap):
	if is_instance_valid(current_minimap_tilemap):
		current_minimap_tilemap.queue_free()

	current_minimap_tilemap = tilemap_from_world.duplicate()
	sub_viewport.add_child(current_minimap_tilemap)
	
	if is_instance_valid(player_icon):
		player_icon.z_index = 1

func set_player_node(p_node):
	player_node = p_node


#================================#
# FUNGSI BAWAAN GODOT (_ready, _process) #
#================================#

func _ready():
	$"CanvasLayer2/Label_Stage-Level".text = "Stage " + GlobalVar.current_stage
	_update_hud() # Panggil sekali saat mulai untuk inisialisasi

func _process(delta: float):
	# Update seluruh HUD setiap frame
	_update_hud()
	
	if is_instance_valid(player_node):
		minimap_camera.position = player_node.global_position

#================================#
# FUNGSI UI LAINNYA              #
#================================#

# Nama fungsi diubah agar lebih jelas
func _update_hud():
	$CanvasLayer2/Panel/Label_coin.text = str(GlobalVar.coin_collected)
	$CanvasLayer2/Panel/HealthBar.value = GlobalVar.health_player
	$CanvasLayer2/Panel/HealthBar.max_value = GlobalVar.maxhealth_player
	
	# Perbarui teks label HP
	health_bar_label.text = "%d / %d" % [GlobalVar.health_player, GlobalVar.maxhealth_player]


# ... (sisa kode Anda tidak perlu diubah) ...
func _on_ButtonJump_pressed():
	jump_button_pressed = true

func _on_ButtonDash_pressed():
	dash_button_pressed = true

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
