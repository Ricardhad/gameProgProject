extends Area2D

@export var speed = 100.0
var player: Node2D
var attracted = false

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if global_position.distance_to(player.global_position) < 15:
		attracted = true

	if attracted:
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * speed * delta

func _on_area_entered(area: Area2D) -> void:
	print("collected")
	queue_free()
