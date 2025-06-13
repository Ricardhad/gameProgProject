# In your AnimationController.gd script

extends "res://scenes/enemies/component/AnimationController.gd" # Assuming this is your base class

# ✅ 1. DELETE THE OLD VARIABLE
# animation_play =  randi_range(1,3) # DELETE THIS LINE

func _ready() -> void:
	# ... (this function is fine as is)

func _on_state_changed(new_state: StateMachine.State, previous_state: StateMachine.State) -> void:
	# ... (last_state logic is fine)
	
	# ✅ 2. UPDATE THE MATCH STATEMENT
	match new_state:
		StateMachine.State.IDLE:
			play("idle")
		StateMachine.State.PATROL:
			play("walk")
		StateMachine.State.CHASE:
			play("run")
		
		# Replace the old ATTACK case with these new, specific cases
		StateMachine.State.ATTACK1:
			play("attack1")
		StateMachine.State.ATTACK2:
			play("attack2")
		StateMachine.State.ATTACK3:
			play("attack3")

		StateMachine.State.HURT:
			play("hurt")
		StateMachine.State.DEAD:
			play("dead")

# ... (the rest of your script is fine)
