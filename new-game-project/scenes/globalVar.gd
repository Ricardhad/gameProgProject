extends Node

var maxhealth_player = 15
var health_player = 15
var coin_collected = 0
var damage_player = 1

var transition_fade_in := false

func add_coin():
	coin_collected += 1
	print(coin_collected)
