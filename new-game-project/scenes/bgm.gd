extends AudioStreamPlayer

const mainMenu_music = preload("res://assets/music/Menu.mp3")
const grassland_music = preload("res://assets/music/Grassland.mp3")

func play_music(music: AudioStream, volume = -10.0):
	if stream == music:
		return
	stream = music
	stream.loop = true
	volume_db = volume
	play()

func play_music_level():
	play_music(mainMenu_music)

func play_music_grassland():
	play_music(grassland_music)
