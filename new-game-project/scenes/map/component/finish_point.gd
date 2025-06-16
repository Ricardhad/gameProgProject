extends Node2D

# This line creates the "parameter" in the Godot Inspector.
# It allows you to assign a scene file to it.
@export var target_scene: PackedScene
@export var next_scene: String
@onready var fade_rect: ColorRect = $ColorRect

func _on_body_entered(body: Node2D):
	# Cek jika scene target sudah diatur
	if not target_scene:
		return
	
	# Cek jika yang masuk adalah pemain
	if body.is_in_group("player"):
		
		# ▼▼▼ TAMBAHKAN KONDISI INI ▼▼▼
		# Hanya proses akhir stage jika scene berikutnya BUKAN "OutOfTavern"
		GlobalVar.process_end_of_stage()
		
		# Sisa kode untuk pindah scene tetap berjalan
		if next_scene != "":
			GlobalVar.current_stage = next_scene
		Transition1.change_scene(target_scene.resource_path)
