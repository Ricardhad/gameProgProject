extends Node

# ===================================================================
# == BAGIAN 1: STATS PEMAIN (DASAR & AKTIF)
# ===================================================================

# --- STATS DASAR (NILAI ASLI, TIDAK BERUBAH) ---
const BASE_MAX_HEALTH = 10
const BASE_DAMAGE = 1
const BASE_DEFENSE = 0
const BASE_SPEED = 120.0
const BASE_JUMP_CD = 2.0
const BASE_DASH_CD = 2.0
const BASE_HEAL_AMOUNT = 5
const BASE_MAX_POTIONS = 2
const MAX_HEAVY_ATK_CHARGES = 4
const HEAVY_ATK_COOLDOWN_PER_CHARGE = 5.0

# --- STATS AKTIF (NILAI YANG DIGUNAKAN DALAM GAME & DIUBAH OLEH BUFF) ---
var maxhealth_player = BASE_MAX_HEALTH
var health_player = BASE_MAX_HEALTH
var damage_player = BASE_DAMAGE
var active_defense = BASE_DEFENSE
var active_speed = BASE_SPEED
var active_jump_cd = BASE_JUMP_CD
var active_dash_cd = BASE_DASH_CD
var active_heal_amount = BASE_HEAL_AMOUNT
var max_potions = BASE_MAX_POTIONS
var current_potions = BASE_MAX_POTIONS

# --- Variabel Lainnya ---
var coin_collected = 0
var score = 0
var kill_count = 0
var current_stage = "1-1"

# --- Variabel Durasi Buff ---
var hp_buff_duration = 0
var atk_buff_duration = 0
var def_buff_duration = 0
var agi_buff_duration = 0
var potion_buff_duration = 0
var coin_buff_duration = 0
var luck_buff_duration = 0

# --- Variabel Item & Buff Permanen (jika masih digunakan) ---
var hp = 0
var atk = 0
var def = 0
var agi = 0
var maxPot = 0
var hp_buff = 0
var atk_buff = 0
var def_buff= 0
var agi_buff = 0

# Status untuk tahu apakah ada quest yang sedang berjalan
var is_quest_active: bool = false
# Untuk menyimpan data quest yang sedang aktif (target, reward, dll.)
var active_quest_data: Dictionary = {}
# Untuk mencatat jumlah kill SAAT quest diterima, agar progres akurat
var initial_kill_count_on_accept: int = kill_count


# ===================================================================
# == BAGIAN 2: FUNGSI-FUNGSI UTAMA
# ===================================================================

func refill_potions():
	current_potions = max_potions
	print("Potions refilled. Current: %d/%d" % [current_potions, max_potions])

func add_coin(base_amount: int = 1):
	coin_collected += base_amount
	if coin_buff_duration > 0:
		var bonus_coin = randi_range(1, 5)
		coin_collected += bonus_coin
		print("Buff COIN aktif! Mendapat bonus %d koin." % bonus_coin)
	print("Total koin: ", coin_collected)

func reset_game():
	# Kembalikan semua stat aktif ke nilai dasarnya
	maxhealth_player = BASE_MAX_HEALTH
	health_player = BASE_MAX_HEALTH
	damage_player = BASE_DAMAGE
	active_defense = BASE_DEFENSE
	active_speed = BASE_SPEED
	active_jump_cd = BASE_JUMP_CD
	active_dash_cd = BASE_DASH_CD
	active_heal_amount = BASE_HEAL_AMOUNT
	max_potions = BASE_MAX_POTIONS
	refill_potions()
	
	# Reset variabel lainnya
	coin_collected = 0
	score = 0
	kill_count = 0
	current_stage = "1-1"
	
	# Reset semua durasi buff
	hp_buff_duration = 0
	atk_buff_duration = 0
	def_buff_duration = 0
	agi_buff_duration = 0
	potion_buff_duration = 0
	coin_buff_duration = 0
	luck_buff_duration = 0
	
	is_quest_active = false
	active_quest_data.clear()
	initial_kill_count_on_accept = kill_count
	
	print("Game has been reset.")

func add_item(itemName: String):
	if itemName == "hp":
		hp += 1
		# Efek permanen: Menambah max health
		maxhealth_player += 3
		health_player = maxhealth_player # Langsung sembuhkan penuh
		print("Item HP dibeli! Max HP sekarang: ", maxhealth_player)
		
	elif itemName == "atk":
		atk += 1
		# Efek permanen: Menambah damage dasar
		damage_player += 2
		print("Item ATK dibeli! Damage dasar sekarang: ", damage_player)

	# --- TAMBAHKAN ATAU GANTI DENGAN BLOK DI BAWAH INI ---
	elif itemName == "def":
		def += 1
		# Efek permanen: Menambah defense aktif
		active_defense += 1 
		print("Item DEF dibeli! Defense aktif sekarang: ", active_defense)
		
	elif itemName == "agi":
		agi += 1
		# Efek permanen: Menambah kecepatan aktif
		active_speed += 15.0 
		print("Item AGI dibeli! Kecepatan aktif sekarang: ", active_speed)
		
	elif itemName == "maxPot":
		maxPot += 1
		max_potions += 1
		refill_potions() # Langsung isi penuh potion saat max bertambah
		print("Item Max Potion dibeli! Max Potion sekarang: %d" % max_potions)
# ===================================================================
# == BAGIAN 3: LOGIKA UTAMA BUFF
# ===================================================================

func acquire_temporary_buff(buff_id: String):
	match buff_id:
		"hp_buff":
			if hp_buff_duration == 0: maxhealth_player += 10
			health_player = min(maxhealth_player, health_player + 10)
			hp_buff_duration += 1
			print("Buff HP didapat! Durasi: ", hp_buff_duration)
		"atk_buff":
			if atk_buff_duration == 0: damage_player += 2
			atk_buff_duration += 1
			print("Buff ATK didapat! Durasi: ", atk_buff_duration)
		"def_buff":
			if def_buff_duration == 0: active_defense += 3
			def_buff_duration += 1
			print("Buff DEF didapat! Defense aktif: ", active_defense)
		"agi_buff":
			if agi_buff_duration == 0:
				active_speed = 200.0
				active_jump_cd -= 1.0
				active_dash_cd -= 1.0
			agi_buff_duration += 1
			print("Buff AGI didapat! Speed aktif: ", active_speed)
		"potion_buff":
			if potion_buff_duration == 0: active_heal_amount = 10
			potion_buff_duration += 1
			print("Buff POTION didapat! Heal aktif: ", active_heal_amount)
		"luck_buff":
			luck_buff_duration += 1
			print("Buff LUCK didapat! Durasi: ", luck_buff_duration)
		"coin_buff":
			coin_buff_duration += 1
			print("Buff COIN didapat! Durasi: ", coin_buff_duration)

func process_end_of_stage():
	print("Memproses akhir stage, mengurangi durasi buff...")
	
	# Hanya jalankan jika bukan stage pertama di setiap world
	if not str(current_stage).ends_with("-1"):
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
				active_defense -= 3
				print("Buff DEF SEMENTARA telah habis.")
		# Proses Buff AGI
		if agi_buff_duration > 0:
			agi_buff_duration -= 1
			if agi_buff_duration == 0:
				active_speed = BASE_SPEED
				active_jump_cd = BASE_JUMP_CD
				active_dash_cd = BASE_DASH_CD
				print("Buff AGI SEMENTARA telah habis.")
		# Proses Buff POTION
		if potion_buff_duration > 0:
			potion_buff_duration -= 1
			if potion_buff_duration == 0:
				active_heal_amount = BASE_HEAL_AMOUNT
				print("Buff POTION SEMENTARA telah habis.")
		# ... (lanjutkan untuk buff lain jika perlu) ...
