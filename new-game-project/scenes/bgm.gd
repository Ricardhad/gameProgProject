extends AudioStreamPlayer

const mainMenu_music = preload("res://assets/music/Menu.mp3")
const grassland_music = preload("res://assets/music/Grass.mp3")
const grasslandboss_music = preload("res://assets/music/GrassBoss.mp3")
const forest_music = preload("res://assets/music/Forest.mp3")
const forestboss_music = preload("res://assets/music/ForestBoss.mp3")
const cave_music = preload("res://assets/music/Cave.mp3")
const caveboss_music = preload("res://assets/music/CaveBoss.mp3")
const snow_music = preload("res://assets/music/Snow.mp3")
const snowboss_music = preload("res://assets/music/SnowBoss.mp3")
const desert_music = preload("res://assets/music/Desert.mp3")
const desertboss_music = preload("res://assets/music/Desert.mp3")
const kingdom_music = preload("res://assets/music/Kingdom.mp3")
const kingdomboss_music = preload("res://assets/music/Kingdom.mp3")

const cutscene1_music = preload("res://assets/music/Cut1.mp3")
const cutscene2_music = preload("res://assets/music/Cut2.mp3")
const maproute_music = preload("res://assets/music/mapRoute.mp3")
const tavern_music = preload("res://assets/music/ShopOrTavern.mp3")

func play_music(music: AudioStream, volume = -10.0):
	if stream == music:
		return
	stream = music
	stream.loop = true
	volume_db = volume
	volume_db = -100
	play()

func play_music_level():
	play_music(mainMenu_music)

func play_music_grassland():
	play_music(grassland_music)

func play_music_grasslandboss():
	play_music(grasslandboss_music)

func play_music_forest():
	play_music(forest_music)

func play_music_forestboss():
	play_music(forestboss_music)

func play_music_cave():
	play_music(cave_music)

func play_music_caveboss():
	play_music(caveboss_music)

func play_music_snow():
	play_music(snow_music)

func play_music_snowboss():
	play_music(snowboss_music)

func play_music_desert():
	play_music(desert_music)

func play_music_desertboss():
	play_music(desertboss_music)

func play_music_kingdom():
	play_music(kingdom_music)

func play_music_kingdomboss():
	play_music(kingdomboss_music)



func play_music_cutscene1():
	play_music(cutscene1_music)

func play_music_cutscene2():
	play_music(cutscene2_music)

func play_music_maproute():
	play_music(maproute_music)

func play_music_tavern():
	play_music(tavern_music)
