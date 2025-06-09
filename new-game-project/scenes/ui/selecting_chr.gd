extends Node
@onready var fade_rect = $ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	Transition.fade_in(fade_rect)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	Transition.fade_out_and_change_scene(fade_rect, "res://scenes/ui/CutScene1.tscn")

func _on_backbtn_pressed() -> void:
	Transition.fade_out_and_change_scene(fade_rect, "res://scenes/ui/main_menu.tscn")
