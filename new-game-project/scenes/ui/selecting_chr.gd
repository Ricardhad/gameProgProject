extends Node

@onready var fade_rect = $ColorRect
@onready var knight: AnimatedSprite2D = $Knight
@onready var archer: AnimatedSprite2D = $Archer
@onready var wizard: AnimatedSprite2D = $Wizard

@onready var label_name: Label = $PanelBackGround/PanelDetail/LabelName
@onready var label_hp: Label = $PanelBackGround/PanelDetail/LabelHP
@onready var label_stamina: Label = $PanelBackGround/PanelDetail/LabelStamina
@onready var label_passive: Label = $PanelBackGround/PanelDetail/LabelPassive

var player := 1

func _ready() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_character_display()

func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	Transition1.change_scene("res://scenes/ui/CutScene1.tscn")
	GlobalVar.hero_kontol = player

func _on_backbtn_pressed() -> void:
	Transition1.change_scene("res://scenes/ui/main_menu.tscn")

func _on_leftbtn_pressed() -> void:
	player -= 1
	if player < 1:
		player = 3
	_update_character_display()

func _on_rightbtn_pressed() -> void:
	player += 1
	if player > 3:
		player = 1
	_update_character_display()

func _update_character_display() -> void:
	# Tampilkan hanya karakter yang dipilih
	knight.visible = (player == 1)
	archer.visible = (player == 2)
	wizard.visible = (player == 3)

	# Update label sesuai karakter
	match player:
		1:
			label_name.text = "Knight"
			label_hp.text = "HP: 150"
			label_stamina.text = "Mana: 70"
			label_passive.text = "Passive: More Health"
		2:
			label_name.text = "Archer"
			label_hp.text = "HP: 100"
			label_stamina.text = "Mana: 100"
			label_passive.text = "Passive: Melee and Projectile"
		3:
			label_name.text = "Wizard"
			label_hp.text = "HP: 80"
			label_stamina.text = "Mana: 150"
			label_passive.text = "Passive: Fire Magic"
