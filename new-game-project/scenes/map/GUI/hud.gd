extends Node2D

# Variabel penanda untuk setiap aksi
var jump_button_pressed = false
var dash_button_pressed = false

# Fungsi ini dipanggil saat sinyal 'pressed' dari ButtonJump diterima
func _on_ButtonJump_pressed():
	jump_button_pressed = true

# Fungsi ini dipanggil saat sinyal 'pressed' dari ButtonDash diterima
func _on_ButtonDash_pressed():
	dash_button_pressed = true

# Fungsi untuk mengubah tampilan tombol Attack
func set_attack_button_pressed(is_pressed: bool):
	var button = $CanvasLayer2/Panel/ButtonATK
	if button:
		button.set_pressed(is_pressed)

# Fungsi untuk efek visual tombol Jump
func set_jump_button_pressed():
	# Ganti "ButtonJump" dengan nama node tombol lompat Anda jika berbeda
	var button = $CanvasLayer2/Panel/ButtonJump
	if not button:
		return

	button.set_pressed(true)
	await get_tree().create_timer(0.15).timeout
	button.set_pressed(false)

# Fungsi untuk efek visual tombol Dash
func set_dash_button_pressed():
	# Ganti "ButtonDash" dengan nama node tombol dash Anda jika berbeda
	var button = $CanvasLayer2/Panel/ButtonDash
	if not button:
		return

	button.set_pressed(true)
	await get_tree().create_timer(0.15).timeout
	button.set_pressed(false)

func _process(delta: float) -> void:
	update_coin_label()
	
func update_coin_label():
	$CanvasLayer2/Panel/Label_coin.text = str(GlobalVar.coin_collected)
	$CanvasLayer2/Panel/HealthBar.value = GlobalVar.health_player
	$CanvasLayer2/Panel/HealthBar.max_value = GlobalVar.maxhealth_player
