extends Node

# --- STATS ASLI ANDA ---
var maxhealth_player = 10
var health_player = 10
var coin_collected = 0
var damage_player = 1
var score = 0
var kill_count = 0
var current_stage = "1-1"

# --- ITEMS PERMANEN (DARI FUNGSI add_item) ---
var hp = 0
var atk = 0
var def = 0
var agi = 0
var maxPot = 0

# --- BUFF PERMANEN (DARI FUNGSI add_buff LAMA) ---
var hp_buff = 0
var atk_buff = 0
var def_buff= 0
var agi_buff = 0

# --- DATA UNTUK BUFF SEMENTARA (BARU) ---
# Menyimpan durasi buff (dalam jumlah stage)
var hp_buff_duration = 0
var atk_buff_duration = 0
var def_buff_duration = 0
var agi_buff_duration = 0
var luck_buff_duration = 0
var potion_buff_duration = 0
var coin_buff_duration = 0

# --- FUNGSI-FUNGSI ASLI ANDA ---

func add_coin():
	coin_collected += 1 # Tambah 1 koin dasar
	
	# Cek apakah buff koin aktif, lalu tambah bonus acak
	if coin_buff_duration > 0:
		var bonus_coin = randi_range(1, 5)
		coin_collected += bonus_coin
		print("Buff COIN aktif! Mendapat bonus %d koin." % bonus_coin)
		
	print("Total koin: ", coin_collected)

func reset_game():
	# Reset stats dasar
	maxhealth_player = 10
	health_player = 10
	coin_collected = 0
	damage_player = 1
	score = 0
	kill_count = 0
	current_stage = "1-1"
	
	# Reset items permanen
	hp = 0
	atk = 0
	def = 0
	agi = 0
	maxPot = 0
	
	# Reset buff permanen
	hp_buff = 0
	atk_buff = 0
	def_buff = 0
	agi_buff = 0
	
	# Reset semua durasi buff sementara
	hp_buff_duration = 0
	atk_buff_duration = 0
	def_buff_duration = 0
	agi_buff_duration = 0
	luck_buff_duration = 0
	potion_buff_duration = 0
	coin_buff_duration = 0

func add_item(itemName: String):
	if(itemName == "hp"):
		hp += 1
		maxhealth_player += 3
		health_player += 3
	elif(itemName == "atk"):
		atk += 1
		damage_player += 2
	# ... dst ...

func add_buff(buffName: String):
	if(buffName == "hp_buff"):
		hp_buff += 1
		maxhealth_player += 5
		health_player += 5
	elif(buffName == "atk_buff"):
		atk_buff += 1
		damage_player += 4
	# ... dst ...


#=============================================================
#== SISTEM BUFF SEMENTARA (IMPLEMENTASI BARU YANG BENAR)
#=============================================================

# Fungsi ini dipanggil dari TOKO untuk mendapatkan buff
func acquire_temporary_buff(buff_id: String):
	match buff_id:
		"hp_buff":
			var bonus_value = 10
			if hp_buff_duration == 0: # Hanya tambah Max HP di tumpukan pertama
				maxhealth_player += bonus_value
			health_player = min(maxhealth_player, health_player + bonus_value) # Sembuhkan & jangan melebihi Max HP
			hp_buff_duration += 1 # Selalu tambah durasi
			print("Buff HP didapat! Durasi sekarang: %d stage" % hp_buff_duration)

		"atk_buff":
			var bonus_value = 2 # Bonus damage
			if atk_buff_duration == 0: # Hanya tambah damage di tumpukan pertama
				damage_player += bonus_value
			atk_buff_duration += 1
			print("Buff ATK didapat! Durasi sekarang: %d stage" % atk_buff_duration)

		"def_buff":
			def_buff_duration += 1
			print("Buff DEF didapat! Durasi sekarang: %d stage" % def_buff_duration)
			
		"agi_buff":
			agi_buff_duration += 1
			print("Buff AGI didapat! Durasi sekarang: %d stage" % agi_buff_duration)
			
		"luck_buff":
			luck_buff_duration += 1
			print("Buff LUCK didapat! Durasi sekarang: %d stage" % luck_buff_duration)

		"potion_buff":
			potion_buff_duration += 1
			print("Buff POTION didapat! Durasi sekarang: %d stage" % potion_buff_duration)
			
		"coin_buff":
			coin_buff_duration += 1
			print("Buff COIN didapat! Durasi sekarang: %d stage" % coin_buff_duration)


# Fungsi ini dipanggil dari FINISH LINE di akhir stage
func process_end_of_stage():
	print("Memproses akhir stage, mengurangi durasi buff...")
	
	if current_stage != "1-1" and current_stage != "2-1" and current_stage != "3-1" and current_stage != "4-1":
		# Proses Buff HP
		if hp_buff_duration > 0:
			hp_buff_duration -= 1
			if hp_buff_duration == 0:
				maxhealth_player -= 10
				health_player = min(health_player, maxhealth_player)
				print("Buff HP SEMENTARA telah habis.")
				
		# Proses Buff ATK
		if atk_buff_duration > 0:
			atk_buff_duration -= 1
			if atk_buff_duration == 0:
				damage_player -= 2
				print("Buff ATK SEMENTARA telah habis.")
				
		# Proses Buff DEF
		if def_buff_duration > 0:
			def_buff_duration -= 1
			if def_buff_duration == 0:
				print("Buff DEF SEMENTARA telah habis.")

		# Proses Buff AGI
		if agi_buff_duration > 0:
			agi_buff_duration -= 1
			if agi_buff_duration == 0:
				print("Buff AGI SEMENTARA telah habis.")
				
		# Proses Buff LUCK
		if luck_buff_duration > 0:
			luck_buff_duration -= 1
			if luck_buff_duration == 0:
				print("Buff LUCK SEMENTARA telah habis.")

		# Proses Buff POTION
		if potion_buff_duration > 0:
			potion_buff_duration -= 1
			if potion_buff_duration == 0:
				print("Buff POTION SEMENTARA telah habis.")

		# Proses Buff COIN
		if coin_buff_duration > 0:
			coin_buff_duration -= 1
			if coin_buff_duration == 0:
				print("Buff COIN SEMENTARA telah habis.")
