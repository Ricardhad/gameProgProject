# ItemCard.gdd
# Pastikan node root 'ItemCard' Anda adalah tipe Control atau Node2D
extends Control

## ------------------------------------------------------------------
## PENGATURAN KARTU - Atur ini dari Inspector untuk setiap kartu
## ------------------------------------------------------------------
@export_group("Data Buff")
# Tipe buff yang akan dipanggil di Global.gd (contoh: "hp_buff", "atk_buff")
@export var buff_type: String = "hp_buff"

# Gambar utama yang akan ditampilkan di kartu
@export var buff_texture: Texture2D

# Deskripsi yang muncul di kartu (contoh: "Max HP +3")
@export var buff_description: String = "Max HP +3"

# Harga untuk membeli buff ini
@export var cost: int = 25


## ------------------------------------------------------------------
## REFERENSI NODE - Hubungan ke node-node di dalam scene
## ------------------------------------------------------------------
@onready var button: Button = $ButtonLoad
@onready var label_detail: Label = $LabelDetail
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_coin: Label = $LabelCoin


## ------------------------------------------------------------------
## FUNGSI UTAMA
## ------------------------------------------------------------------
func _ready():
	# 1. Atur tampilan visual kartu berdasarkan variabel di atas
	label_detail.text = buff_description
	texture_rect.texture = buff_texture
	label_coin.text = str(cost)
	
	# 2. Hubungkan sinyal saat tombol ditekan ke fungsi pembelian
	button.pressed.connect(_on_purchase_pressed)


# Fungsi ini berjalan ketika pemain menekan tombol pada kartu
func _on_purchase_pressed():
	# Cek di skrip Global apakah koin cukup
	if GlobalVar.coin_collected >= cost:
		# Jika cukup, kurangi koin dan panggil fungsi buff
		GlobalVar.coin_collected -= cost
		GlobalVar.add_buff(buff_type)
		
		# Nonaktifkan kartu agar tidak bisa dibeli lagi
		button.disabled = true
		modulate = Color.GRAY # Membuat kartu jadi redup sebagai tanda
		print("Pembelian sukses: ", buff_type)
	else:
		# Jika koin tidak cukup
		print("Koin tidak cukup untuk membeli: ", buff_type)
		# Di sini Anda bisa menambahkan animasi atau suara "gagal"
