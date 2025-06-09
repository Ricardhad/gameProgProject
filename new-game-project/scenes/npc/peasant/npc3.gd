# NPC.gd
class_name NPC
extends CharacterBody2D

# A signal to announce that the NPC has been interacted with.
# You can connect this to a dialogue manager or quest system.
signal interacted

# --- Node References ---
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# This variable will track if the player is currently inside the interaction zone.
var player_in_range = false

func _ready():
	# Hide the "F" prompt by default.
	interaction_prompt.visible = false
	# Connect the Area2D's signals to our functions.
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	# Play the NPC's idle animation.
	animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	# This function listens for any input that hasn't been handled yet.
	
	# We only care about input if the player is in range.
	if player_in_range:
		# Check if the button just pressed was our "interact" action (the F key).
		if event.is_action_pressed("interact"):
			# Announce that we've been interacted with!
			emit_signal("interacted")
			print("Player interacted with NPC!")
			# Optional: Prevent further input from being processed this frame.
			get_viewport().set_input_as_handled()

func _on_interaction_area_body_entered(body: Node2D):
	# Check if the body that entered is the player.
	if body.is_in_group("player"):
		print("Player entered interaction range.")
		player_in_range = true
		# Show the "F" prompt.
		interaction_prompt.visible = true

func _on_interaction_area_body_exited(body: Node2D):
	# Check if the body that left is the player.
	if body.is_in_group("player"):
		print("Player left interaction range.")
		player_in_range = false
		# Hide the "F" prompt.
		interaction_prompt.visible = false
