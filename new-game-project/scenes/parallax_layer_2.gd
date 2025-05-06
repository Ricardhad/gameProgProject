extends ParallaxLayer

@export var CLOUD_SPEED = -15

func _process(delta: float) -> void:
	self.motion_offset.x += CLOUD_SPEED * delta

func _ready() -> void:
	pass
