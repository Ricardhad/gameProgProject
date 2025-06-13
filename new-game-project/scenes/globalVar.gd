extends Node

var maxhealth_player = 10
var health_player = 10
var coin_collected = 0
var damage_player = 1
var score = 0
var kill_count = 0
var current_stage = "1-1"

var hp = 0
var atk = 0
var def = 0
var agi = 0
var maxPot = 0
var buff = [0,0,0,0,0,0,0]

func add_coin():
	coin_collected += 1
	print(coin_collected)

func reset_game():
	maxhealth_player = 10
	health_player = 10
	coin_collected = 0
	damage_player = 1
	score = 0
	kill_count = 0
	current_stage = "1-1"
	
	hp = 0
	atk = 0
	def = 0
	agi = 0
	maxPot = 0
	buff = [0,0,0,0,0,0,0]

func add_item(itemName: String):
	if(itemName == "hp"):
		hp += 1
		maxhealth_player += 3
		health_player += 3
	elif(itemName == "atk"):
		atk += 1
		damage_player += 2
	elif(itemName == "def"):
		def += 1
	elif(itemName == "agi"):
		agi += 1
	elif(itemName == "maxPot"):
		maxPot += 1
