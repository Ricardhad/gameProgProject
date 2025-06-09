extends Control

@onready var text_box = $TextBox
@onready var image_holder = $ImageHolder
@onready var timer = $Timer
@onready var fade_panel = $FadePanel
@onready var sfx_player = $SFXPlayer

var dialogues = [
	{ "text": "In the beginning, there was only darkness...", "image": "res://assets/selecting_menu/img1.jpg" },
	{ "text": "Then a light shone through the void.", "image": "res://assets/selecting_menu/img2.jpg" },
	{ "text": "And thus... your journey begins.", "image": "res://assets/selecting_menu/img1.jpg" },
	{ "text": "Guardian Pixel", "image": "res://assets/selecting_menu/img2.jpg" }  # Final slide
]

var current_index = 0
var char_index = 0
var is_typing = false
var full_text = ""

func _ready() -> void:
	# Set stream jika belum diset di editor
	if sfx_player.stream == null:
		sfx_player.stream = load("res://assets/sfx/RichardEdit.mp3")

	fade_in()
	show_next_line()
	Bgm.play_music_cutscene1()

func fade_in():
	fade_panel.visible = true
	fade_panel.modulate.a = 1.0
	var fade = create_tween()
	fade.tween_property(fade_panel, "modulate:a", 0.0, 1.5)

func fade_out_and_change_scene():
	var fade = create_tween()
	fade_panel.visible = true
	fade_panel.modulate.a = 0.0
	fade.tween_property(fade_panel, "modulate:a", 1.0, 1.5)
	fade.tween_callback(Callable(self, "_go_to_next_scene"))

func _go_to_next_scene():
	get_tree().change_scene_to_file("res://scenes/ui/CutScene2.tscn")

func show_next_line():
	if current_index >= dialogues.size():
		fade_out_and_change_scene()
		return

	var dialogue = dialogues[current_index]
	full_text = dialogue["text"]
	text_box.text = ""
	image_holder.texture = load(dialogue["image"])
	is_typing = true
	char_index = 0
	timer.start()

func _on_Timer_timeout() -> void:
	if is_typing:
		if char_index < full_text.length():
			text_box.text += full_text[char_index]

			# Play SFX
			if sfx_player.playing:
				sfx_player.stop()
			sfx_player.play()

			char_index += 1
		else:
			is_typing = false
			timer.stop()

			# Auto next line after short delay
			await get_tree().create_timer(1.5).timeout
			current_index += 1
			show_next_line()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			text_box.text = full_text
			is_typing = false
			timer.stop()
			sfx_player.stop()  # Stop SFX jika skip
		else:
			current_index += 1
			show_next_line()

func _on_button_skip_pressed() -> void:
	# Hentikan semua proses yang sedang berjalan untuk transisi yang bersih.
	is_typing = false
	timer.stop()
	sfx_player.stop()
	
	# Buat tween untuk efek fade out.
	var fade = create_tween()
	fade_panel.visible = true
	fade_panel.modulate.a = 0.0 # Pastikan mulai dari transparan
	fade.tween_property(fade_panel, "modulate:a", 1.0, 1.5)

	# Tunggu sampai animasi fade out selesai
	await fade.finished
	
	# Pindah ke scene berikutnya setelah layar menjadi hitam
	get_tree().change_scene_to_file("res://scenes/ui/CutScene2.tscn")
	pass # Replace with function body.
