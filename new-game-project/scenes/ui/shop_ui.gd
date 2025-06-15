# ShopUI.gd
extends PanelContainer

# Referensi ke scene kartu yang akan kita buat instance-nya
const ItemCardScene = preload("res://scenes/ui/ItemCard.tscn") # GANTI DENGAN PATH ANDA

# Referensi ke container yang akan menampung kartu-kartu
@onready var card_container: HBoxContainer = $HBoxContainer

# Daftar data untuk semua barang di toko.
# Anda bisa mengubah daftar ini dengan mudah untuk mengganti isi toko.
var shop_inventory = [
	{
		"type": "hp_buff",
		"texture_path": "res://assets/item&buff/buff/HP.png",
		"description": "Max HP +3",
		"cost": 15
	},
	{
		"type": "atk_buff",
		"texture_path": "res://assets/item&buff/buff/Str.png",
		"description": "Damage +2",
		"cost": 25
	},
	{
		"type": "def_buff",
		"texture_path": "res://assets/item&buff/buff/Def.png",
		"description": "Defense +1",
		"cost": 20
	},
	{
		"type": "agi_buff",
		"texture_path": "res://assets/item&buff/buff/Agi.png",
		"description": "Agility +5",
		"cost": 20
	}
]


func _ready():
	generate_shop_items()


# Fungsi untuk membuat kartu secara dinamis berdasarkan data di shop_inventory
func generate_shop_items():
	# Hapus kartu lama jika ada, untuk mencegah duplikat
	for child in card_container.get_children():
		child.queue_free()

	# Ulangi setiap item di inventaris
	for item_data in shop_inventory:
		# Buat instance baru dari scene kartu
		var card = ItemCardScene.instantiate()

		# Atur data kartu menggunakan variabel export-nya
		card.buff_type = item_data.type
		card.buff_texture = load(item_data.texture_path)
		card.buff_description = item_data.description
		card.cost = item_data.cost

		# Tambahkan kartu yang sudah jadi ke dalam container
		card_container.add_child(card)
