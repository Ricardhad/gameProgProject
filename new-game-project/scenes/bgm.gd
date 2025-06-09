extends AudioStreamPlayer

const mainMenu_music = preload("res://assets/music/Menu.mp3")
const grassland_music = preload("res://assets/music/Grass.mp3")
const forest_music = preload("res://assets/music/Forest.mp3")
const cave_music = preload("res://assets/music/Cave.mp3")

const cutscene1_music = preload("res://assets/music/Cut1.mp3")
const cutscene2_music = preload("res://assets/music/Cut2.mp3")
const maproute_music = preload("res://assets/music/mapRoute.mp3")

func play_music(music: AudioStream, volume = -10.0):
	if stream == music:
		return
	stream = music
	stream.loop = true
	volume_db = volume
	#volume_db = -100
	play()

func play_music_level():
	play_music(mainMenu_music)

func play_music_grassland():
	play_music(grassland_music)

func play_music_forest():
	play_music(forest_music)

func play_music_cave():
	play_music(cave_music)

func play_music_cutscene():
	play_music(cutscene_music)

func play_music_maproute():
	play_music(maproute_music)
