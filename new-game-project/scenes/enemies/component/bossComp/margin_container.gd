# BossHealthBar.gd
extends MarginContainer

# Get references to the nodes we need to change.
@onready var progress_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var label: Label = $VBoxContainer/Label

# This function will be called by the boss to update the health bar.
# It takes the boss's current health and max health as arguments.
func update_health(current_health: float, max_health: float):
	# Calculate the health percentage.
	# We use max() to prevent division by zero if max_health is somehow 0.
	var health_percent = 100.0 * (current_health / max(1.0, max_health))
	
	# Set the progress bar's value. The bar automatically handles the visuals.
	progress_bar.value = health_percent

# A function to set the boss's name on the label.
func set_boss_name(boss_name: String):
	label.text = boss_name

# We can also add simple show/hide functions for convenience.
func show_bar():
	show()

func hide_bar():
	hide()
