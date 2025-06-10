extends Control

@onready var popup_detail = $PopUpDetail
@onready var label_stage = popup_detail.get_node("Label_Stage")
@onready var label_difficulty = popup_detail.get_node("Label_Difficulty")
@onready var label_total_enemy = popup_detail.get_node("Label_TotalEnemy")
@onready var label_encounter = popup_detail.get_node("Label_Encounter")
@onready var confirm_button = popup_detail.get_node("Confirm")

var selected_stage_id = ""  # Untuk simpan stage yang sedang dipilih

func _ready() -> void:
	var stage_data = {
		"Stage1(1)": {"stage": "Grass", "difficulty": "1", "total_enemy": "12", "encounter": ["Goblin", "Orc"]},
		"Stage1(2)": {"stage": "Forest", "difficulty": "2", "total_enemy": "13", "encounter": ["Goblin", "Orc"]},
		"Stage2(1)": {"stage": "Cave", "difficulty": "3", "total_enemy": "14", "encounter": ["Goblin", "Skeleton"]},
		"Stage2(2)": {"stage": "Snow", "difficulty": "4", "total_enemy": "15", "encounter": ["Orc", "Skeleton"]},
		"Stage3(1)": {"stage": "Desert", "difficulty": "5", "total_enemy": "17", "encounter": ["Orc", "Skeleton"]},
		"Boss": {"stage": "Obsidian Kingdom", "difficulty": "6", "total_enemy": "20", "encounter": ["Goblin", "Orc", "Skeleton"]},
		"RestStop1": {"stage": "Rest Stop", "difficulty": "-", "total_enemy": "0", "encounter": []},
		"RestStop2": {"stage": "Rest Stop", "difficulty": "-", "total_enemy": "0", "encounter": []},
		"RestStop3": {"stage": "Rest Stop", "difficulty": "-", "total_enemy": "0", "encounter": []},
	}
	
	for name in stage_data.keys():
		var button = $Panel.get_node_or_null(name)
		if button:
			button.connect("pressed", Callable(self, "_on_stage_pressed").bind(name, stage_data[name]))
	# Hubungkan tombol Confirm
	confirm_button.connect("pressed", Callable(self, "_on_confirm_pressed"))
	
	Bgm.play_music_maproute()

func _on_stage_pressed(stage_id: String, data: Dictionary) -> void:
	selected_stage_id = stage_id

	label_stage.text = "Stage: %s" % data["stage"]
	label_difficulty.text = "Difficulty: %s" % data["difficulty"]
	label_total_enemy.text = "Total Enemy: %s" % data["total_enemy"]

	label_encounter.text = "Encounter:\n"
	for enemy in data["encounter"]:
		label_encounter.text += "- %s\n" % enemy

	popup_detail.visible = true

func _on_confirm_pressed() -> void:
	match selected_stage_id:
		"Stage1(1)":
			get_tree().change_scene_to_file("res://scenes/map/grass/map1.tscn")
			GlobalVar.current_stage = "1-1"
		"Stage1(2)":
			get_tree().change_scene_to_file("res://scenes/map/forest/map1.tscn")
			GlobalVar.current_stage = "1-1"
		"Stage2(1)":
			get_tree().change_scene_to_file("res://scenes/map/cave/map1.tscn")
			GlobalVar.current_stage = "2-1"
		"Stage2(2)":
			get_tree().change_scene_to_file("res://scenes/map/snow/map1.tscn")
			GlobalVar.current_stage = "2-1"
		"Stage3(1)":
			get_tree().change_scene_to_file("res://scenes/map/desert/map1.tscn")
			GlobalVar.current_stage = "3-1"
		"Boss":
			get_tree().change_scene_to_file("res://scenes/map/kingdom/map1.tscn")
			GlobalVar.current_stage = "4-1"
		"RestStop1":
			get_tree().change_scene_to_file("res://scenes/map/tavern/map.tscn")
		"RestStop2":
			get_tree().change_scene_to_file("res://scenes/map/tavern/map.tscn")
		"RestStop3":
			get_tree().change_scene_to_file("res://scenes/map/tavern/map.tscn")
		_:
			print("Stage '%s' belum memiliki scene untuk dipindahkan." % selected_stage_id)
