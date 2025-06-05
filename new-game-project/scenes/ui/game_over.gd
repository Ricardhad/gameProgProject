extends Control

#kontol
#mau seberapa banyak di push???

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/Label.text = "Stage : 1-1"
	$VBoxContainer/Label2.text = "Coins collected : " + str(GlobalVar.coin_collected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	GlobalVar.maxhealth_player = 10
	GlobalVar.health_player = 10
	GlobalVar.coin_collected = 0
