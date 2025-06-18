# BossHealthBar.gd
extends MarginContainer
@export var boss_name = "null"
@onready var progress_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var boss_label: Label = $VBoxContainer/Label
# The health bar will now store its own copy of the health values.
var current_health: int
var max_health: int

# A new function to set up the bar with the boss's starting health.
func initialize(start_max_health: int, start_current_health: int):
	boss_label.text = boss_name
	max_health = start_max_health
	current_health = start_current_health
	_update_bar() # Update the visuals immediately

# This function will be connected to the boss's health_changed signal.
# It receives the *difference* and applies it.
func on_health_changed(difference: int):
	current_health += difference
	_update_bar()

# This function will be connected to the boss's max_health_changed signal.
func on_max_health_changed(difference: int):
	max_health += difference
	# If current health is now higher than the new max, clamp it.
	if current_health > max_health:
		current_health = max_health
	_update_bar()

# A private helper function to handle the visual update.
func _update_bar():
	# Calculate the percentage and update the progress bar's value.
	if max_health > 0:
		progress_bar.value = (float(current_health) / float(max_health)) * 100.0
	else:
		progress_bar.value = 0
