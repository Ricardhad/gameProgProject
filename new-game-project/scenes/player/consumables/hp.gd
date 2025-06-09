extends Area2D

@export var speed = 160.0
var player: Node2D
var attracted = false
var collect_delay = 0.3
var time_alive = 0.0

#func _ready() -> void:
	#connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	if not attracted and to_player.length() < 80:
		attracted = true	
	elif to_player.length() > 80:
		attracted = false

	if attracted:
		var direction = to_player.normalized()
		global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GlobalVar.add_item("hp")
		$AudioStreamPlayer2D.play()
		#$CollisionShape2D.disabled = true
		#get_tree().get_current_scene().update_coin_label()
		self.visible = false
		await get_tree().create_timer(0.5).timeout
		queue_free()
