# GoblinProjectile.gd
class_name Projectile
extends Area2D

var speed: float = 300.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 10

func _ready():
	# Connect the area's body_entered signal to our hit detection function.
	body_entered.connect(_on_body_entered)

	# Get the screen notifier and connect its screen_exited signal for cleanup.
	var screen_notifier = $VisibleOnScreenNotifier2D
	screen_notifier.screen_exited.connect(queue_free)

# We will call this function from the AttackController when spawning the projectile.
func start(spawn_transform: Transform2D):
	self.global_transform = spawn_transform
	self.direction = Vector2.RIGHT.rotated(spawn_transform.get_rotation())

func _physics_process(delta: float):
	# Move the projectile every frame.
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D):
	# Check if we hit the player.
	if body.is_in_group("player"):
		# If the player has a method to take damage, call it.
		if body.has_method("take_damage"):
			body.take_damage(damage)

	# The projectile should be destroyed when it hits the player or any static obstacle.
	# We check if the body is NOT in the "enemy" group to avoid projectiles hitting each other.
	if not body.is_in_group("enemy"):
		queue_free()
