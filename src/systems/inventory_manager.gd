extends Node

signal inventory_updated(item: FishResource)
signal money_updated(amount: int)
signal upgrade_purchased(upgrade_name: String, new_level: int)
signal bait_changed(bait_id: String)
signal bait_quantity_changed(bait_id: String, new_quantity: int)
signal level_up(new_sp: int)
signal pending_fish_changed(count: int)
signal boat_changed(boat_id: String)
signal expedition_credit_updated(credit_due: int, earnings: int)

var caught_fish: Array[FishResource] = []
var expedition_fish: Array[FishResource] = [] # Fish caught during current extraction (temporary)
var pending_fish: Array[FishResource] = [] # Fish awaiting claim in base
var money: int = 500 # Start with more money
var total_caught_count: int = 0
const SP_THRESHOLD = 5

# Ekwipunek przynęt: { "bait_id": quantity }
var bait_inventory: Dictionary = {
	"bread": 10
}
var current_bait_id: String = "bread"

# Boats and Loadouts
const DEFAULT_BOAT_ID = "starter"
const BOAT_CREDIT_UPGRADE_COST = 50
const BOAT_CREDIT_RELIC_COST = 100
const BOAT_STAT_UPGRADE_COST_BASE = 100
var boats_catalog: Dictionary = {
	"starter": {"name": "Dinghy", "cost": 0},
	"skiff": {"name": "Skiff", "cost": 600},
	"cutter": {"name": "Cutter", "cost": 1400}
}
var boat_order: Array = ["starter", "skiff", "cutter"]
var owned_boats: Array = []
var current_boat_id: String = DEFAULT_BOAT_ID
var boat_loadouts: Dictionary = {}
var boat_upgrade_types: Array = [
	"reel_speed",
	"line_strength",
	"attraction",
	"cast_range",
	"minigame_bar_size",
	"minigame_catch_speed",
	"minigame_lose_speed",
	"hook_window"
]

# Upgrade levels
var rod_level: int = 1
var boat_speed_level: int = 1

# Current Run Relics
var active_relics: Array = []

# Persistent Run Stats
var global_value_multiplier: float = 1.0
var reel_speed_multiplier: float = 1.0
var line_strength_multiplier: float = 1.0
var attraction_bonus: float = 1.0
var luck_bonus: float = 0.0

# Unique Mechanics Unlocked by Relics
var can_boat_jump: bool = false
var boat_jump_force: float = 5.0
var can_nitro_boost: bool = false
var nitro_speed_multiplier: float = 1.0

# New Physics/Mechanics
var can_anchor_brake: bool = false
var float_height_modifier: float = 0.0 # Alter water line
var physics_friction_multiplier: float = 1.0 # For drift/hover
var cast_range_multiplier: float = 1.0

# Minigame Bonuses (Fishing Bar)
var minigame_start_bonus: float = 0.0 # Add to initial progress
var minigame_drain_multiplier: float = 1.0 # Reduce penalty speed
var minigame_bar_glue: bool = false # Easier control
var auto_catch_chance: float = 0.0 # Chance to catch instantly
var minigame_gravity_multiplier: float = 1.0 # Lower = slower fall
var minigame_fish_speed_multiplier: float = 1.0 # Fish behavior speed in minigame
var minigame_fish_pause_chance: float = 0.0 # Chance to pause fish movement briefly
var minigame_fish_pause_duration: float = 0.0 # Pause duration in seconds
var minigame_bar_size_multiplier: float = 1.0 # Catch bar size multiplier
var minigame_bar_min_size: float = 30.0 # Minimum catch bar size
var minigame_catch_speed_multiplier: float = 1.0 # Catch progress gain multiplier
var minigame_lose_speed_multiplier: float = 1.0 # Progress drain multiplier
var minigame_reel_force_multiplier: float = 1.0 # Reel force multiplier
var minigame_bounce_multiplier: float = 1.0 # Bounce strength multiplier
var minigame_dart_speed_multiplier: float = 1.0 # Dart behavior speed multiplier
var minigame_fish_stability_multiplier: float = 1.0 # Longer target holds
var minigame_fail_grace: bool = false # One-time save from fail per minigame
var minigame_fail_grace_amount: float = 0.15 # Progress restored on grace
var minigame_start_floor: float = 0.0 # Minimum starting progress
var minigame_bar_damping: float = 0.0 # Extra velocity damping

# Hooking / Cast
var hook_window_multiplier: float = 1.0 # Hook window duration
var bite_time_multiplier: float = 1.0 # Time to bite
var cast_force_multiplier: float = 1.0 # Cast impulse multiplier
var bite_retry_chance: float = 0.0 # Chance for a quick re-bite on miss

# Chase
var distance_modifier_multiplier: float = 1.0 # Chase distance modifier strength

# Fish Behavior (World)
var fish_run_force_multiplier: float = 1.0 # Lower = fish flee slower
var fish_run_wiggle_multiplier: float = 1.0 # Lower = less erratic flee

# Expedition Modifiers
var expedition_value_multiplier: float = 1.0 # Fish value this expedition
var expedition_fish_speed_multiplier: float = 1.0 # Minigame fish speed this expedition
var expedition_positive: Dictionary = {}
var expedition_negative: Dictionary = {}
var expedition_credit_due: int = 0
var expedition_earnings: int = 0

# Economy / Quota Bonuses
var daily_interest_rate: float = 0.0 # Percent of current money added next day
var quota_reduction_percent: float = 0.0 # Multiplier to reduce quota growth
var shop_discount: float = 0.0 # Price reduction
var bread_ration_bonus: int = 0 # Extra bread per day
var sell_streak_bonus: float = 0.0 # Extra value per consecutive sale (simplified logic)

# Unique Relic Mechanics - Batch 4
var daily_hull_repair: float = 0.0
var bait_save_chance: float = 0.0
var golden_fish_chance: float = 0.0
var golden_fish_multiplier: float = 2.0

# Hull stats are in QuotaManager

const ROD_UPGRADE_COST_BASE = 100
const BOAT_SPEED_UPGRADE_COST_BASE = 150
const SAVE_FILE_PATH = "user://savegame.json"

func _ready():
	load_game()
	_ensure_boat_data()

func start_new_game():
	# Reset local state
	money = 100
	rod_level = 1
	boat_speed_level = 1
	bait_inventory = {"bread": 10}
	current_bait_id = "bread"
	caught_fish.clear()
	expedition_fish.clear()
	pending_fish.clear()
	owned_boats = [DEFAULT_BOAT_ID]
	current_boat_id = DEFAULT_BOAT_ID
	boat_loadouts.clear()
	
	# Reset Run Stats
	active_relics = []
	reset_run_modifiers()
	total_caught_count = 0

	# Reset Economy
	daily_interest_rate = 0.0
	quota_reduction_percent = 0.0
	shop_discount = 0.0
	bread_ration_bonus = 0
	sell_streak_bonus = 0.0

	# Reset Batch 4
	daily_hull_repair = 0.0
	bait_save_chance = 0.0
	golden_fish_chance = 0.0
	golden_fish_multiplier = 2.0

	# Reset other systems
	if JournalManager: JournalManager.reset()
	if QuestManager: QuestManager.reset()
	if AchievementManager: AchievementManager.reset()
	if SkillManager: SkillManager.reset()
	
	# Delete save file if exists to be clean before saving
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		
	# Emit updates
	money_updated.emit(money)
	emit_signal("inventory_updated", null)
	bait_quantity_changed.emit("bread", 10)
	
	save_game()

func reset_run_modifiers() -> void:
	global_value_multiplier = 1.0
	reel_speed_multiplier = 1.0
	line_strength_multiplier = 1.0
	attraction_bonus = 1.0
	luck_bonus = 0.0

	# Reset Unique Mechanics
	can_boat_jump = false
	boat_jump_force = 5.0
	can_nitro_boost = false
	nitro_speed_multiplier = 1.0

	# Reset New Physics
	can_anchor_brake = false
	float_height_modifier = 0.0
	physics_friction_multiplier = 1.0
	cast_range_multiplier = 1.0

	# Reset Minigame Bonuses
	minigame_start_bonus = 0.0
	minigame_drain_multiplier = 1.0
	minigame_bar_glue = false
	auto_catch_chance = 0.0
	minigame_gravity_multiplier = 1.0
	minigame_fish_speed_multiplier = 1.0
	minigame_fish_pause_chance = 0.0
	minigame_fish_pause_duration = 0.0
	minigame_bar_size_multiplier = 1.0
	minigame_bar_min_size = 30.0
	minigame_catch_speed_multiplier = 1.0
	minigame_lose_speed_multiplier = 1.0
	minigame_reel_force_multiplier = 1.0
	minigame_bounce_multiplier = 1.0
	minigame_dart_speed_multiplier = 1.0
	minigame_fish_stability_multiplier = 1.0
	minigame_fail_grace = false
	minigame_fail_grace_amount = 0.15
	minigame_start_floor = 0.0
	minigame_bar_damping = 0.0

	hook_window_multiplier = 1.0
	bite_time_multiplier = 1.0
	cast_force_multiplier = 1.0
	bite_retry_chance = 0.0

	distance_modifier_multiplier = 1.0

	# Reset Fish Behavior
	fish_run_force_multiplier = 1.0
	fish_run_wiggle_multiplier = 1.0

	# Reset Expedition Modifiers
	expedition_value_multiplier = 1.0
	expedition_fish_speed_multiplier = 1.0
	expedition_positive = {}
	expedition_negative = {}
	expedition_credit_due = 0
	expedition_earnings = 0

func _ensure_boat_data() -> void:
	if owned_boats.is_empty():
		owned_boats = [DEFAULT_BOAT_ID]
	if current_boat_id.is_empty() or not owned_boats.has(current_boat_id):
		current_boat_id = owned_boats[0]
	if not boat_loadouts.has(current_boat_id):
		boat_loadouts[current_boat_id] = _create_default_loadout()
	for boat_id in owned_boats:
		if not boat_loadouts.has(boat_id):
			boat_loadouts[boat_id] = _create_default_loadout()
	boat_changed.emit(current_boat_id)

func _create_default_loadout() -> Dictionary:
	return {
		"relics": ["", "", "", ""],
		"upgrades": [
			{"stat_id": "", "level": 0},
			{"stat_id": "", "level": 0},
			{"stat_id": "", "level": 0},
			{"stat_id": "", "level": 0}
		]
	}

func get_current_boat_data() -> Dictionary:
	return boats_catalog.get(current_boat_id, {"name": "Unknown", "cost": 0})

func get_next_unowned_boat_id() -> String:
	for boat_id in boat_order:
		if not owned_boats.has(boat_id):
			return boat_id
	return ""

func set_current_boat(boat_id: String) -> bool:
	if not owned_boats.has(boat_id):
		return false
	current_boat_id = boat_id
	boat_changed.emit(current_boat_id)
	return true

func buy_boat(boat_id: String) -> bool:
	if owned_boats.has(boat_id):
		return false
	if not boats_catalog.has(boat_id):
		return false
	var cost = int(boats_catalog[boat_id].get("cost", 0))
	if cost > 0 and not spend_money(cost):
		return false
	owned_boats.append(boat_id)
	boat_loadouts[boat_id] = _create_default_loadout()
	return true

func get_boat_loadout(boat_id: String) -> Dictionary:
	if not boat_loadouts.has(boat_id):
		boat_loadouts[boat_id] = _create_default_loadout()
	return boat_loadouts[boat_id]

func set_boat_relic_slot(boat_id: String, slot_index: int, relic_id: String) -> void:
	var loadout = get_boat_loadout(boat_id)
	if slot_index < 0 or slot_index >= loadout["relics"].size():
		return
	loadout["relics"][slot_index] = relic_id
	boat_loadouts[boat_id] = loadout
	save_game()

func set_boat_upgrade_slot(boat_id: String, slot_index: int, stat_id: String) -> void:
	var loadout = get_boat_loadout(boat_id)
	if slot_index < 0 or slot_index >= loadout["upgrades"].size():
		return
	if stat_id != "" and not boat_upgrade_types.has(stat_id):
		return
	loadout["upgrades"][slot_index]["stat_id"] = stat_id
	loadout["upgrades"][slot_index]["level"] = 0
	boat_loadouts[boat_id] = loadout
	save_game()

func get_boat_stat_upgrade_cost(level: int) -> int:
	return BOAT_STAT_UPGRADE_COST_BASE * (level + 1)

func upgrade_boat_stat(boat_id: String, slot_index: int) -> bool:
	var loadout = get_boat_loadout(boat_id)
	if slot_index < 0 or slot_index >= loadout["upgrades"].size():
		return false
	if loadout["upgrades"][slot_index]["stat_id"] == "":
		return false
	var current_level = int(loadout["upgrades"][slot_index]["level"])
	var cost = get_boat_stat_upgrade_cost(current_level)
	if not spend_money(cost):
		return false
	loadout["upgrades"][slot_index]["level"] = current_level + 1
	boat_loadouts[boat_id] = loadout
	save_game()
	return true

func apply_boat_loadout() -> void:
	reset_run_modifiers()
	active_relics = []
	var loadout = get_boat_loadout(current_boat_id)
	var relics = loadout.get("relics", [])
	for relic_id in relics:
		if relic_id == "":
			continue
		if RelicDatabase:
			var relic_data = RelicDatabase.get_relic_by_id(relic_id)
			if not relic_data.is_empty():
				active_relics.append(relic_data)
				RelicDatabase.apply_relic(relic_data)
	var upgrades = loadout.get("upgrades", [])
	for upgrade in upgrades:
		_apply_boat_upgrade(upgrade.get("stat_id", ""), int(upgrade.get("level", 0)))

func _apply_boat_upgrade(stat_id: String, level: int) -> void:
	if stat_id == "" or level <= 0:
		return
	match stat_id:
		"reel_speed":
			reel_speed_multiplier += 0.05 * level
		"line_strength":
			line_strength_multiplier += 0.05 * level
		"attraction":
			attraction_bonus += 0.05 * level
		"cast_range":
			cast_range_multiplier += 0.05 * level
		"minigame_bar_size":
			minigame_bar_size_multiplier += 0.05 * level
		"minigame_catch_speed":
			minigame_catch_speed_multiplier += 0.05 * level
		"minigame_lose_speed":
			minigame_lose_speed_multiplier *= pow(0.97, level)
		"hook_window":
			hook_window_multiplier += 0.05 * level

func calculate_expedition_credit() -> int:
	var boat_cost = int(get_current_boat_data().get("cost", 0))
	var loadout = get_boat_loadout(current_boat_id)
	var relics = loadout.get("relics", [])
	var relic_count = 0
	for relic_id in relics:
		if relic_id != "":
			relic_count += 1
	var upgrades = loadout.get("upgrades", [])
	var upgrade_levels = 0
	for upgrade in upgrades:
		upgrade_levels += int(upgrade.get("level", 0))
	return boat_cost + (upgrade_levels * BOAT_CREDIT_UPGRADE_COST) + (relic_count * BOAT_CREDIT_RELIC_COST)

func start_expedition_credit() -> void:
	expedition_credit_due = calculate_expedition_credit()
	expedition_earnings = 0
	expedition_credit_updated.emit(expedition_credit_due, expedition_earnings)

func register_expedition_earnings(amount: int) -> void:
	if amount <= 0:
		return
	expedition_earnings += amount
	expedition_credit_updated.emit(expedition_credit_due, expedition_earnings)

func is_expedition_credit_paid() -> bool:
	return expedition_earnings >= expedition_credit_due

func handle_expedition_credit_failure() -> void:
	if current_boat_id == DEFAULT_BOAT_ID:
		return
	owned_boats.erase(current_boat_id)
	boat_loadouts.erase(current_boat_id)
	current_boat_id = DEFAULT_BOAT_ID
	_ensure_boat_data()

func apply_timeout_upgrade_penalty() -> void:
	var loadout: Dictionary = get_boat_loadout(current_boat_id)
	var upgrades: Array = loadout.get("upgrades", [])
	for i in range(upgrades.size()):
		upgrades[i]["level"] = 0
	loadout["upgrades"] = upgrades
	boat_loadouts[current_boat_id] = loadout

	boat_speed_level = 1
	upgrade_purchased.emit("boat_speed", boat_speed_level)
	boat_changed.emit(current_boat_id)
	save_game()

func add_fish(fish: FishResource):
	# Safety: during extraction, never add directly to inventory
	if TimeManager and TimeManager.extraction_active:
		add_expedition_fish(fish)
		return

	caught_fish.append(fish)
	emit_signal("inventory_updated", fish)
	print("Added " + fish.name + " to inventory.")
	
	total_caught_count += 1
	if total_caught_count % SP_THRESHOLD == 0:
		if SkillManager:
			SkillManager.add_skill_points(1)
			emit_signal("level_up", SkillManager.skill_points)
			print("Level Up! Gained 1 Skill Point.")
	
	# Lucky Catch Skill
	if SkillManager.get_skill_level("lucky_catch") > 0:
		var chance = SkillManager.get_bonus("lucky_catch")
		if randf() < chance:
			caught_fish.append(fish)
			total_caught_count += 1 # Counts as another catch
			emit_signal("inventory_updated", fish)
			print("Lucky Catch! Double fish!")
			if total_caught_count % SP_THRESHOLD == 0:
				if SkillManager:
					SkillManager.add_skill_points(1)
					emit_signal("level_up", SkillManager.skill_points)
					print("Level Up! Gained 1 Skill Point.")
	
	save_game()

func add_expedition_fish(fish: FishResource):
	# Add fish to temporary expedition list (not saved until extraction completes)
	expedition_fish.append(fish)
	var value = int(fish.value * global_value_multiplier * expedition_value_multiplier)
	register_expedition_earnings(value)
	# Emit to update contract progress and any listeners during a run
	emit_signal("inventory_updated", fish)
	save_game()

func generate_expedition_modifiers() -> void:
	var positives = [
		{
			"id": "value_bonus",
			"desc": "Ryby +20% wartosci",
			"value_mult": 1.20
		},
		{
			"id": "fast_bite",
			"desc": "Brania 20% szybciej",
			"bite_time_mult": 0.80
		},
		{
			"id": "steady_bar",
			"desc": "Mniej straty progresu",
			"lose_speed_mult": 0.85
		},
		{
			"id": "strong_reel",
			"desc": "Wedka +15% sily",
			"reel_force_mult": 1.15
		},
		{
			"id": "wide_bar",
			"desc": "Szerszy pasek minigry",
			"bar_size_mult": 1.15
		}
	]

	var negatives = [
		{
			"id": "fish_fast",
			"desc": "Ryby +10% szybciej",
			"fish_speed_mult": 1.10
		},
		{
			"id": "slippery_line",
			"desc": "Szybsza utrata progresu",
			"lose_speed_mult": 1.15
		},
		{
			"id": "late_bite",
			"desc": "Brania 20% wolniej",
			"bite_time_mult": 1.20
		},
		{
			"id": "short_hook",
			"desc": "Krotsze okno podciecia",
			"hook_window_mult": 0.80
		},
		{
			"id": "heavy_bar",
			"desc": "Ciezszy pasek (szybciej spada)",
			"gravity_mult": 1.20
		}
	]

	positives.shuffle()
	negatives.shuffle()
	expedition_positive = positives[0]
	expedition_negative = negatives[0]

	# Reset expedition-specific modifiers
	expedition_value_multiplier = 1.0
	expedition_fish_speed_multiplier = 1.0

	_apply_expedition_modifier(expedition_positive)
	_apply_expedition_modifier(expedition_negative)

func clear_expedition_modifiers() -> void:
	expedition_value_multiplier = 1.0
	expedition_fish_speed_multiplier = 1.0
	expedition_positive = {}
	expedition_negative = {}
	expedition_credit_due = 0
	expedition_earnings = 0
	expedition_credit_updated.emit(expedition_credit_due, expedition_earnings)

func _apply_expedition_modifier(mod: Dictionary) -> void:
	if mod.has("value_mult"):
		expedition_value_multiplier *= float(mod["value_mult"])
	if mod.has("fish_speed_mult"):
		expedition_fish_speed_multiplier *= float(mod["fish_speed_mult"])
	if mod.has("bite_time_mult"):
		bite_time_multiplier *= float(mod["bite_time_mult"])
	if mod.has("lose_speed_mult"):
		minigame_lose_speed_multiplier *= float(mod["lose_speed_mult"])
	if mod.has("reel_force_mult"):
		minigame_reel_force_multiplier *= float(mod["reel_force_mult"])
	if mod.has("bar_size_mult"):
		minigame_bar_size_multiplier *= float(mod["bar_size_mult"])
	if mod.has("hook_window_mult"):
		hook_window_multiplier *= float(mod["hook_window_mult"])
	if mod.has("gravity_mult"):
		minigame_gravity_multiplier *= float(mod["gravity_mult"])

func complete_expedition_to_pending():
	# Move expedition fish to pending list (claimed later in base)
	if expedition_fish.is_empty():
		return
	for fish in expedition_fish:
		pending_fish.append(fish)
	expedition_fish.clear()
	pending_fish_changed.emit(pending_fish.size())
	save_game()

func claim_pending_fish():
	if pending_fish.is_empty():
		return
	for fish in pending_fish:
		add_fish(fish)
	pending_fish.clear()
	pending_fish_changed.emit(0)
	save_game()

func finalize_expedition():
	# Transfer all expedition fish to caught_fish when extraction succeeds
	for fish in expedition_fish:
		add_fish(fish)
	expedition_fish.clear()

func discard_expedition():
	# Clear all expedition fish when extraction fails
	expedition_fish.clear()

func sell_fish(fish_index: int):
	if fish_index >= 0 and fish_index < caught_fish.size():
		var fish = caught_fish[fish_index]
		var value = int(fish.value * global_value_multiplier)
		money += value
		caught_fish.remove_at(fish_index)
		money_updated.emit(money)
		# Ponowna emisja sygnału inventory_updated z null, by odświeżyć UI
		emit_signal("inventory_updated", null)
		save_game()

func sell_all_fish():
	var total_value = 0
	for fish in caught_fish:
		total_value += int(fish.value * global_value_multiplier)
	money += total_value
	caught_fish.clear()
	money_updated.emit(money)
	emit_signal("inventory_updated", null)
	save_game()

func can_afford(amount: int) -> bool:
	return money >= amount

func spend_money(amount: int) -> bool:
	if can_afford(amount):
		money -= amount
		money_updated.emit(money)
		save_game()
		return true
	return false

func get_rod_upgrade_cost() -> int:
	return ROD_UPGRADE_COST_BASE * (rod_level) 

func get_boat_upgrade_cost() -> int:
	return BOAT_SPEED_UPGRADE_COST_BASE * (boat_speed_level)

func upgrade_rod() -> bool:
	var cost = get_rod_upgrade_cost()
	if spend_money(cost):
		rod_level += 1
		upgrade_purchased.emit("rod", rod_level)
		print("Rod upgraded to level " + str(rod_level))
		return true
	print("Not enough money for rod upgrade.")
	return false

func upgrade_boat_speed() -> bool:
	var cost = get_boat_upgrade_cost()
	if spend_money(cost):
		boat_speed_level += 1
		upgrade_purchased.emit("boat_speed", boat_speed_level)
		print("Boat speed upgraded to level " + str(boat_speed_level))
		return true
	print("Not enough money for boat upgrade.")
	return false

# --- Bait System ---

func add_bait(bait_id: String, quantity: int = 1):
	if quantity <= 0: return
	if not bait_inventory.has(bait_id):
		bait_inventory[bait_id] = 0
	
	bait_inventory[bait_id] += quantity
	bait_quantity_changed.emit(bait_id, bait_inventory[bait_id])
	save_game()
	print("Added %d of %s" % [quantity, bait_id])

func use_current_bait() -> Dictionary:
	# Returns the consumed bait info or empty Dictionary if failed
	if not bait_inventory.has(current_bait_id) or bait_inventory[current_bait_id] <= 0:
		print("No bait!")
		return {}

	var bait_info = BaitDatabase.get_bait(current_bait_id)
	if not bait_info: return {}

	# Recycler Logic
	if bait_save_chance > 0.0 and randf() < bait_save_chance:
		print("Recycler triggered! Bait saved.")
		return bait_info
		
	# Consume
	bait_inventory[current_bait_id] -= 1
	if RunMetrics:
		RunMetrics.record_bait_spent(1)
	bait_quantity_changed.emit(current_bait_id, bait_inventory[current_bait_id])
	save_game()
	
	return bait_info

func change_bait(bait_id: String) -> bool:
	if not BaitDatabase.get_bait(bait_id): return false
	current_bait_id = bait_id
	bait_changed.emit(current_bait_id)
	save_game()
	return true

func get_bait_count(bait_id: String) -> int:
	return bait_inventory.get(bait_id, 0)
	
func buy_bait(bait_id: String, quantity: int, override_price: int = -1) -> bool:
	var info = BaitDatabase.get_bait(bait_id)
	if not info: return false
	
	var price_per_unit = info.price
	var total_cost = 0
	
	if override_price != -1:
		total_cost = override_price * quantity
	else:
		total_cost = price_per_unit * quantity
		
	if spend_money(total_cost):
		add_bait(bait_id, quantity)
		return true
	print("Not enough money for bait")
	return false

# --- Saving / Loading ---

func save_game():
	var valid_bait_id = current_bait_id
	if not valid_bait_id: valid_bait_id = "bread"
	
	var data = {
		"money": money,
		"rod_level": rod_level,
		"boat_speed_level": boat_speed_level,
		"owned_boats": owned_boats,
		"current_boat_id": current_boat_id,
		"boat_loadouts": boat_loadouts,
		"bait_inventory": bait_inventory,
		"current_bait_id": valid_bait_id,
		"active_relics": active_relics,
		"stats": {
			"value_mult": global_value_multiplier,
			"reel_mult": reel_speed_multiplier,
			"line_mult": line_strength_multiplier,
			"attraction": attraction_bonus,
			"luck": luck_bonus
		},
		"mechanics": {
			"can_jump": can_boat_jump,
			"jump_force": boat_jump_force,
			"can_nitro": can_nitro_boost,
			
			"daily_hull_repair": daily_hull_repair,
			"bait_save": bait_save_chance,
			"golden_fish": golden_fish_chance,
			"golden_mult": golden_fish_multiplier,
			"nitro_mult": nitro_speed_multiplier,
			"anchor_brake": can_anchor_brake,
			"float_mod": float_height_modifier,
			"friction_mult": physics_friction_multiplier,
			"cast_mult": cast_range_multiplier,
			"minigame_start": minigame_start_bonus,
			"minigame_drain": minigame_drain_multiplier,
			"minigame_glue": minigame_bar_glue,
			"auto_catch": auto_catch_chance,
			"interest_rate": daily_interest_rate,
			"quota_reducer": quota_reduction_percent,
			"shop_discount": shop_discount,
			"bread_bonus": bread_ration_bonus,
			"sell_streak": sell_streak_bonus
		}
	}
	
	# Include QuotaManager Data
	if QuotaManager:
		data["quota_data"] = QuotaManager.get_save_data()
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("Game Saved.")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return # No save file

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		money = data.get("money", 100)
		rod_level = data.get("rod_level", 1)
		boat_speed_level = data.get("boat_speed_level", 1)
		owned_boats = data.get("owned_boats", [DEFAULT_BOAT_ID])
		current_boat_id = data.get("current_boat_id", DEFAULT_BOAT_ID)
		boat_loadouts = data.get("boat_loadouts", {})
		bait_inventory = data.get("bait_inventory", {"bread": 10})
		current_bait_id = data.get("current_bait_id", "bread")
		
		# Progresja
		if data.has("active_relics"): active_relics = data["active_relics"]
		else: active_relics = []
		
		if data.has("stats"):
			var stats = data["stats"]
			global_value_multiplier = stats.get("value_mult", 1.0)
			reel_speed_multiplier = stats.get("reel_mult", 1.0)
			line_strength_multiplier = stats.get("line_mult", 1.0)
			attraction_bonus = stats.get("attraction", 1.0)
			luck_bonus = stats.get("luck", 0.0)

		# Load Mechanics
		if data.has("mechanics"):
			var mechs = data["mechanics"]
			can_boat_jump = mechs.get("can_jump", false)
			
			daily_hull_repair = mechs.get("daily_hull_repair", 0.0)
			bait_save_chance = mechs.get("bait_save", 0.0)
			golden_fish_chance = mechs.get("golden_fish", 0.0)
			golden_fish_multiplier = mechs.get("golden_mult", 2.0)
			boat_jump_force = mechs.get("jump_force", 5.0)
			can_nitro_boost = mechs.get("can_nitro", false)
			nitro_speed_multiplier = mechs.get("nitro_mult", 1.0)
			
			can_anchor_brake = mechs.get("anchor_brake", false)
			float_height_modifier = mechs.get("float_mod", 0.0)
			physics_friction_multiplier = mechs.get("friction_mult", 1.0)
			cast_range_multiplier = mechs.get("cast_mult", 1.0)

			minigame_start_bonus = mechs.get("minigame_start", 0.0)
			minigame_drain_multiplier = mechs.get("minigame_drain", 1.0)
			minigame_bar_glue = mechs.get("minigame_glue", false)
			auto_catch_chance = mechs.get("auto_catch", 0.0)

			daily_interest_rate = mechs.get("interest_rate", 0.0)
			quota_reduction_percent = mechs.get("quota_reducer", 0.0)
			shop_discount = mechs.get("shop_discount", 0.0)
			bread_ration_bonus = mechs.get("bread_bonus", 0)
			sell_streak_bonus = mechs.get("sell_streak", 0.0)
		
		# Load QuotaManager Data
		if data.has("quota_data") and QuotaManager:
			QuotaManager.load_save_data(data["quota_data"])
		
		# Upgrade migration for new field names if any
		if typeof(bait_inventory) != TYPE_DICTIONARY:
			bait_inventory = {"bread": 10}
			
		_ensure_boat_data()
		money_updated.emit(money)
		bait_changed.emit(current_bait_id)
		print("Game Loaded.")
	else:
		print("JSON Parse Error: ", json.get_error_message())
