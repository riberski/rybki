extends Node

signal quota_updated(current: int, target: int)
signal day_passed(day_count: int)
signal run_ended(reason: String)
signal quota_met
signal quota_failed
signal draft_phase_started
signal hull_updated(current: float, max: float)
signal deadline_updated(days_left: int, cycle_days: int)

# Run State
var current_day: int = 1
var quota_target: int = 100 
var base_quota: int = 100
var difficulty_scaler: float = 1.3
const DAILY_BREAD_RATION = 15
const QUOTA_CYCLE_DAYS = 3
const QUOTA_FAIL_HULL_PENALTY = 22.0
const QUOTA_FAIL_CASH_PENALTY_RATIO = 0.20
const QUOTA_SUCCESS_BONUS_BREAD = 4

var days_left_in_cycle: int = QUOTA_CYCLE_DAYS

# Hull System
var hull_integrity: float = 100.0
var max_hull: float = 100.0
var hull_damage_reduction: float = 0.0
var repair_cost_multiplier: float = 1.0
var pending_draft: bool = false
var crate_cost: int = 200

func _ready():
	InventoryManager.money_updated.connect(_on_money_changed)
	if TimeManager:
		# We don't rely on TimeManager for day cycling in TURN BASED mode
		pass

func _on_money_changed(amount):
	quota_updated.emit(amount, quota_target)

func _start_draft_phase():
	print("Draft Phase Started")
	pending_draft = true
	draft_phase_started.emit()
	# The UI (DraftUI) should pause the tree and show itself via signal

func repair_hull(amount: float):
	hull_integrity = min(hull_integrity + amount, max_hull)
	hull_updated.emit(hull_integrity, max_hull)

func increase_max_hull(amount: float):
	max_hull += amount
	hull_integrity += amount # Also heal the new amount? Usually yes.
	hull_updated.emit(hull_integrity, max_hull)

func damage_hull(amount: float):
	var damage = amount * (1.0 - hull_damage_reduction)
	hull_integrity -= damage
	hull_updated.emit(hull_integrity, max_hull)
	
	if hull_integrity <= 0:
		_game_over("Hull Destroyed!")

func end_day_check():
	check_run_status()

func start_new_run():
	current_day = 1
	hull_integrity = 100.0
	max_hull = 100.0
	hull_damage_reduction = 0.0
	repair_cost_multiplier = 1.0
	pending_draft = false
	crate_cost = 200
	
	# Initial Quota
	quota_target = base_quota
	days_left_in_cycle = QUOTA_CYCLE_DAYS
	
	InventoryManager.start_new_game()
	# Give Bread Ration immediately
	InventoryManager.bait_inventory["bread"] = DAILY_BREAD_RATION
	InventoryManager.emit_signal("bait_quantity_changed", "bread", DAILY_BREAD_RATION)
	
	quota_updated.emit(InventoryManager.money, quota_target)
	hull_updated.emit(hull_integrity, max_hull)
	deadline_updated.emit(days_left_in_cycle, QUOTA_CYCLE_DAYS)
	if RunMetrics:
		RunMetrics.record_run_started()
		RunMetrics.record_day_advanced(current_day, quota_target)
	
	print("New Run Started. Day 1. Quota: ", quota_target, " Bread: ", DAILY_BREAD_RATION)

func check_run_status():
	# Called when Player runs out of bait (Bread = 0)
	# End expedition: advance day and return to base
	print("End of Expedition: Advancing Day")
	advance_to_next_day()

func clear_pending_draft():
	pending_draft = false

func advance_to_next_day():
	current_day += 1
	days_left_in_cycle = max(0, days_left_in_cycle - 1)
	
	# Solar Panel / Daily Repair Logic
	if InventoryManager and InventoryManager.daily_hull_repair > 0:
		repair_hull(InventoryManager.daily_hull_repair)
		print("Daily Repair: healed ", InventoryManager.daily_hull_repair)

	if days_left_in_cycle <= 0:
		_resolve_quota_deadline()
		days_left_in_cycle = QUOTA_CYCLE_DAYS
	
	# Apply Interest
	if InventoryManager and InventoryManager.daily_interest_rate > 0:
		var interest = int(float(InventoryManager.money) * InventoryManager.daily_interest_rate)
		if interest > 0:
			InventoryManager.money += interest
			InventoryManager.money_updated.emit(InventoryManager.money)
			print("Interest Paid: +$%d" % interest)
	
	# Refill Bread Ration
	var daily_bread = DAILY_BREAD_RATION
	if InventoryManager:
		daily_bread += InventoryManager.bread_ration_bonus
		
	InventoryManager.bait_inventory["bread"] = daily_bread
	InventoryManager.emit_signal("bait_quantity_changed", "bread", daily_bread)
	
	day_passed.emit(current_day)
	quota_updated.emit(InventoryManager.money, quota_target)
	deadline_updated.emit(days_left_in_cycle, QUOTA_CYCLE_DAYS)
	if RunMetrics:
		RunMetrics.record_day_advanced(current_day, quota_target)
	
	print("Day Passed! Day: ", current_day, " New Quota: ", quota_target, " Bread Refilled.")
	
	# Heal hull slightly
	repair_hull(10.0)

func _resolve_quota_deadline() -> void:
	if InventoryManager == null:
		return

	if InventoryManager.money >= quota_target:
		quota_met.emit()
		InventoryManager.add_bait("bread", QUOTA_SUCCESS_BONUS_BREAD)
		# Grow next quota after successful cycle.
		var scaler: float = difficulty_scaler
		if InventoryManager.quota_reduction_percent > 0:
			scaler = max(1.1, scaler - InventoryManager.quota_reduction_percent)
		quota_target = int(float(quota_target) * scaler)
		print("Quota met. Next target: ", quota_target)
		return

	quota_failed.emit()
	var cash_penalty: int = int(round(float(quota_target) * QUOTA_FAIL_CASH_PENALTY_RATIO))
	InventoryManager.money = max(0, InventoryManager.money - cash_penalty)
	InventoryManager.money_updated.emit(InventoryManager.money)
	damage_hull(QUOTA_FAIL_HULL_PENALTY)
	print("Quota failed. Penalty cash: ", cash_penalty, " hull: ", QUOTA_FAIL_HULL_PENALTY)

func get_deadline_status() -> Dictionary:
	return {
		"day": current_day,
		"quota_target": quota_target,
		"days_left": days_left_in_cycle,
		"cycle_days": QUOTA_CYCLE_DAYS
	}

func _game_over(reason):
	# Calculate Meta Currency Reward
	var scales_earned = current_day * 10
	if AchievementManager:
		AchievementManager.add_meta_currency(scales_earned)
	
	var full_reason = reason + "\n\nSurvived %d Days\nEarned %d Scales" % [current_day, scales_earned]
	
	print("GAME OVER: ", reason)
	if RunMetrics:
		RunMetrics.record_run_ended(reason)
		RunMetrics.end_session("game_over")
	run_ended.emit(full_reason)
	# Trigger Game Over UI

func get_save_data() -> Dictionary:
	return {
		"day": current_day,
		"quota": quota_target,
		"days_left_in_cycle": days_left_in_cycle,
		"hull": hull_integrity,
		"max_hull": max_hull,
		"damage_reduction": hull_damage_reduction,
		"repair_cost_mult": repair_cost_multiplier,
		"crate_cost": crate_cost
	}

func load_save_data(data: Dictionary):
	current_day = data.get("day", 1)
	quota_target = data.get("quota", 150)
	days_left_in_cycle = int(data.get("days_left_in_cycle", QUOTA_CYCLE_DAYS))
	hull_integrity = data.get("hull", 100.0)
	max_hull = data.get("max_hull", 100.0)
	hull_damage_reduction = data.get("damage_reduction", 0.0)
	repair_cost_multiplier = data.get("repair_cost_mult", 1.0)
	crate_cost = data.get("crate_cost", 200)
	
	# Emit updates to sync UI
	quota_updated.emit(InventoryManager.money, quota_target)
	hull_updated.emit(hull_integrity, max_hull)
	deadline_updated.emit(days_left_in_cycle, QUOTA_CYCLE_DAYS)
	print("QuotaManager Loaded: Day %d Quota %d" % [current_day, quota_target])
