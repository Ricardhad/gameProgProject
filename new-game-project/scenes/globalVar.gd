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
