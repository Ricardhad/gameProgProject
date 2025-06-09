# transition.gd
# Script ini akan kita jadikan Autoload (Singleton) dengan nama "Transition".
extends Control

# Fungsi _ready dan _process bisa dibiarkan kosong karena logika utama ada di fungsi custom.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# --- FUNGSI FADE-IN ---
# Fungsi ini dipanggil di _ready() pada scene yang BARU dimuat.
# Memerlukan node ColorRect dari scene tersebut.
func fade_in(fade_rect: ColorRect, duration: float = 1.0):
	if not is_instance_valid(fade_rect):
		printerr("Transisi Gagal: ColorRect untuk fade_in tidak valid.")
		return
	
	# Memastikan transisi dimulai dari layar hitam pekat.
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0

	# Membuat tween untuk menganimasikan alpha (transparansi).
	var tween = fade_rect.create_tween()
	tween.set_ease(Tween.EASE_OUT) # Animasi lebih halus di akhir
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	
	# Setelah animasi selesai, sembunyikan ColorRect agar tidak menghalangi mouse.
	await tween.finished
	fade_rect.visible = false


# --- FUNGSI FADE-OUT & GANTI SCENE ---
# Fungsi ini dipanggil saat tombol ditekan (misalnya tombol "Start").
# Memerlukan ColorRect dari scene saat ini dan path ke scene tujuan.
func fade_out_and_change_scene(fade_rect: ColorRect, scene_path: String, duration: float = 1.0):
	if not is_instance_valid(fade_rect):
		printerr("Transisi Gagal: ColorRect untuk fade_out tidak valid.")
		return
		
	# Memastikan transisi dimulai dari layar transparan.
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	# Membuat tween untuk menganimasikan alpha menjadi pekat.
	var tween = fade_rect.create_tween()
	tween.set_ease(Tween.EASE_IN) # Animasi lebih halus di awal
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	
	# Tunggu sampai animasi fade-out selesai.
	await tween.finished
	
	# Setelah layar menjadi hitam, ganti scene.
	get_tree().change_scene_to_file(scene_path)
