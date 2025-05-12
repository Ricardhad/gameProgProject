extends RigidBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var dead = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if dead == false:
		animated_sprite_2d.animation = "idle"

func _on_body_entered(body: Node) -> void:
	print("Entered by:", body.name)
	if body.is_in_group("Sword"):
		print("hit")
		dead = true
		animated_sprite_2d.animation = "dead"

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "dead":
		queue_free()


func _on_collision_shape_2d_child_entered_tree(node: Node) -> void:
	print("Entered by:", node.name)
	if node.is_in_group("Sword"):
		print("hit")
		dead = true
		animated_sprite_2d.animation = "dead"
