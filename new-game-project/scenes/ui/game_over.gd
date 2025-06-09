extends Control

#kontol
#mau seberapa banyak di push???

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel/Panel/Label2.text = "Score : " + str(GlobalVar.score)
	$Panel/Panel/Label3.text = "Stage : " + GlobalVar.current_stage
	$Panel/Panel/Label4.text = "Total Kills : " + str(GlobalVar.kill_count)
	$Panel/Panel/Label5.text = "Coins : " + str(GlobalVar.coin_collected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	
