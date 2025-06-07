extends Node2D


#func _ready() -> void:
	#var slider = $CanvasLayer/PanelPause/PanelPauseOption/HSlider
	#slider.min_value = 0.0
	#slider.max_value = 1.0
	#slider.step = 0.01
	#slider.value = db_to_linear(Bgm.volume_db)
	#$CanvasLayer/PanelPause.process_mode = Node.PROCESS_MODE_ALWAYS
	#for child in $CanvasLayer/PanelPause.get_children():
		#child.process_mode = Node.PROCESS_MODE_ALWAYS


func update_coin_label():
	#print("Updating coin label:", GlobalVar.coin_collected)
	$CanvasLayer2/Panel/Label_coin.text = str(GlobalVar.coin_collected)
	$CanvasLayer2/Panel/HealthBar.value = GlobalVar.health_player
	$CanvasLayer2/Panel/HealthBar.max_value = GlobalVar.maxhealth_player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_coin_label()
	pass
