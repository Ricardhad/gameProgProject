extends Node

var maxhealth_player = 15
var health_player = 15
var coin_collected = 0
var damage_player = 1

func add_coin():
	coin_collected += 1
	print(coin_collected)
