extends Node

var maxhealth_player = 5
var health_player = 5
var coin_collected = 0
var damage_player = 1
var score = 0
var kill_count = 0
var current_stage = "1-1"

var transition_fade_in := false

func add_coin():
	coin_collected += 1
	print(coin_collected)

func reset_game():
	maxhealth_player = 10
	health_player = 10
	coin_collected = 0
	kill_count = 0
	score = 0
	current_stage = "1-1"
