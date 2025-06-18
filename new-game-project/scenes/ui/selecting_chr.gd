extends Node

@onready var fade_rect = $ColorRect
@onready var knight: AnimatedSprite2D = $Knight
@onready var archer: AnimatedSprite2D = $Archer
@onready var wizard: AnimatedSprite2D = $Wizard

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
