# PhaseTrigger.gd
# (Previously LootDropper.gd)
# This script triggers an action once when the parent's health is depleted.
# Useful for starting a boss's next phase.
extends Node

## The scene to instantiate when the phase triggers. 
## This could be a cutscene trigger, an effect, or an empty node with a script.
@export var next_phase_trigger_scene: PackedScene

@onready var health_component: Node = get_parent().get_node("Health")


func _ready() -> void:
	if health_component:  
		# Connect to the signal with the CONNECT_ONE_SHOT flag.
		# This ensures trigger_next_phase() is only ever called once.
		# We also keep CONNECT_DEFERRED to avoid issues during the physics frame.
		health_component.health_depleted.connect(trigger_next_phase, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	else:
		printerr("PhaseTrigger Error: Health component not found on parent!")


func trigger_next_phase() -> void:
	print("Health depleted, triggering next phase...")

	# Check if a scene is assigned in the Inspector.
	if next_phase_trigger_scene == null:
		printerr("PhaseTrigger Error: Next Phase Trigger Scene not assigned!")
		return

	# Instantiate the scene that will handle the phase change logic.
	var phase_trigger = next_phase_trigger_scene.instantiate()
	
	# Add the trigger scene to the level (the boss's parent).
	# You might want to add it as a child of the boss itself, depending on your needs.
	# If so, change get_parent().get_parent() to just get_parent().
	get_parent().get_parent().add_child(phase_trigger)
	
	# Position the instantiated scene at the boss's location.
	phase_trigger.global_position = get_parent().global_position
