extends Node
@onready var fade_rect = $ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if GlobalVar.transition_fade_in:
		GlobalVar.transition_fade_in = false  # Reset flag

		fade_rect.visible = true
		fade_rect.modulate.a = 1.0  # Mulai dari hitam

		var fade_in = create_tween()
		fade_in.tween_property(fade_rect, "modulate:a", 0.0, 1.0)  # Fade-out dari hitam
	else:
		fade_rect.visible = false  # Jika bukan transisi
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/tutorial.tscn")

func _on_backbtn_pressed() -> void:
	GlobalVar.transition_fade_in = true  # Aktifkan flag untuk fade-in di scene selanjutnya

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	fade_out.tween_callback(Callable(self, "_change_scene1"))

func _change_scene1() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
