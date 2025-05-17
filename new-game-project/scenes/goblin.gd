extends RigidBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var is_dead = false

func _process(delta: float) -> void:
	if is_dead:
		return
	animated_sprite_2d.animation = "idle"

func _on_health_health_depleted() -> void:
	is_dead = true
	animated_sprite_2d.play("dead")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "dead":
		queue_free()
