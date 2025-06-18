extends Control

@onready var text_box = $TextBox
@onready var image_holder = $ImageHolder
@onready var timer = $Timer
@onready var fade_panel = $FadePanel
@onready var sfx_player = $SFXPlayer

var dialogues = [
	{
		"text": "Perjalanan panjang dan penuh tantangan akhirnya membuahkan hasil. Ketiga kerajaan - Sapphire, Emerald, dan Ruby, berhasil diselamatkan sepenuhnya dari ancaman yang mengintai.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Pasukan kegelapan berhasil dikalahkan, dan kekuatan gelap yang menguasai Obsidian Kingdom akhirnya menghilang.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Raja dan Pangeran Obsidian yang sebelumnya dikuasai oleh roh jahat, kini telah kembali menjadi diri mereka yang sebenarnya.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Dengan penuh penyesalan, mereka berdua bersumpah untuk memperbaiki kerajaannya dan membangun kembali kepercayaan antar kerajaan.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Ketiga kerajaan lainnya menyambut permintaan maaf itu dengan hati terbuka. Mereka pun sepakat untuk menjalin perdamaian yang lebih kuat dari sebelumnya.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Obsidian Kingdom mulai membenahi diri, membangun kembali istana dan desa-desa yang rusak, serta membuka hubungan diplomatik dengan kerajaan lain.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
		"text": "Crystallia kini kembali damai. Cahaya harapan menerangi dunia, dan kisah para pahlawan ini pun menjadi legenda yang akan terus dikenang.",
		"image": "res://assets/selecting_menu/black.png"
	},
	{
	"text": "T H E   E N D",
	"image": "res://assets/selecting_menu/black.png"
	}	
	
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
	get_tree().change_scene_to_file("res://scenes/ui/GameOver.tscn")

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


func _on_timer_timeout() -> void:
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
	pass # Replace with function body.
