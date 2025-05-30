extends Node2D


@onready var label = $Label
@onready var tween = create_tween()

func _ready() -> void:
	label.text = ""
	label.modulate.a = 0.0  # Mulai transparan
	show_text("Hello World")
	pass # Replace with function body.

func show_text(text: String) -> void:
	label.text = text
	label.modulate.a = 0.0
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 2.0)  # Fade-in selama 2 detik
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
