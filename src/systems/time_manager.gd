extends Node

signal time_tick(current_hour: float)
signal day_started
signal night_started
signal extraction_time_changed(remaining_seconds: int, total_seconds: int)
signal extraction_started(total_seconds: int)
signal extraction_finished(reason: String)

var current_time: float = 8.0 # Start at 8 AM
var time_speed: float = 1.0 # Game hours per real second? Maybe slower.
# Real time: 1 second = 1 game minute -> 60 game minutes = 60 seconds.
# 24 hours = 24 minutes. That's reasonable.
# So speed = 60.0 (minutes per second) / 60 = 1.0 hours per second? No.
# If 1 sec = 1 min, then 60 sec = 1 hour.
# current_time is in HOURS (0-24).
# So per second, we add 1/60th of an hour?
# speed = 1.0 / 60.0 * time_scale.

@export var time_scale: float = 60.0 # 1 real sec = 1 game minute

var is_day_active = true

const EXTRACTION_MIN_MINUTES := 2
const EXTRACTION_MAX_MINUTES := 20
const EXTRACTION_EARLY_RETURN_MIN_SECONDS := 120

var extraction_duration_minutes: int = EXTRACTION_MAX_MINUTES
var extraction_duration_seconds: int = EXTRACTION_MAX_MINUTES * 60
var extraction_remaining_seconds: float = 0.0
var extraction_active: bool = false
var _last_extraction_second: int = -1
var _is_finishing_extraction: bool = false

func set_extraction_duration_minutes(minutes: int) -> void:
	extraction_duration_minutes = clamp(minutes, EXTRACTION_MIN_MINUTES, EXTRACTION_MAX_MINUTES)
	extraction_duration_seconds = extraction_duration_minutes * 60
	if not extraction_active:
		extraction_time_changed.emit(extraction_duration_seconds, extraction_duration_seconds)

func start_extraction() -> void:
	extraction_active = true
	extraction_remaining_seconds = float(extraction_duration_seconds)
	_last_extraction_second = -1
	# Reset time to sunrise at the start of each expedition.
	current_time = 6.0
	if InventoryManager:
		InventoryManager.apply_boat_loadout()
		InventoryManager.start_expedition_credit()
		InventoryManager.generate_expedition_modifiers()
	if RunMetrics:
		RunMetrics.record_expedition_started()
	extraction_started.emit(extraction_duration_seconds)
	extraction_time_changed.emit(extraction_duration_seconds, extraction_duration_seconds)

func can_early_extract() -> bool:
	if not extraction_active:
		return false
	var elapsed := extraction_duration_seconds - int(ceil(extraction_remaining_seconds))
	return elapsed >= EXTRACTION_EARLY_RETURN_MIN_SECONDS

func get_early_extract_wait_seconds() -> int:
	if not extraction_active:
		return 0
	var elapsed := extraction_duration_seconds - int(ceil(extraction_remaining_seconds))
	return max(0, EXTRACTION_EARLY_RETURN_MIN_SECONDS - elapsed)

func finish_extraction(reason: String = "early_return") -> void:
	if _is_finishing_extraction:
		return
	if reason == "early_return" and not can_early_extract():
		return
	_is_finishing_extraction = true
	extraction_active = false
	extraction_remaining_seconds = 0.0
	
	# Handle expedition fish based on extraction reason
	if reason == "zone_extract":
		# Successful extraction from designated extraction zone.
		if InventoryManager:
			InventoryManager.complete_expedition_to_pending()
	else:
		# Timeout, early return, or other reasons - fish are lost
		if InventoryManager:
			if reason == "timeout" and InventoryManager.has_method("apply_timeout_upgrade_penalty"):
				InventoryManager.apply_timeout_upgrade_penalty()
			InventoryManager.discard_expedition()
	if InventoryManager:
		if not InventoryManager.is_expedition_credit_paid():
			InventoryManager.handle_expedition_credit_failure()
		InventoryManager.clear_expedition_modifiers()
	if RunMetrics:
		RunMetrics.record_expedition_finished(reason)
	
	extraction_finished.emit(reason)
	if QuotaManager:
		QuotaManager.check_run_status()
	_is_finishing_extraction = false

func _process(delta):
	if extraction_active:
		extraction_remaining_seconds = max(0.0, extraction_remaining_seconds - delta)
		var sec_left = int(ceil(extraction_remaining_seconds))
		if sec_left != _last_extraction_second:
			_last_extraction_second = sec_left
			extraction_time_changed.emit(sec_left, extraction_duration_seconds)
		if extraction_remaining_seconds <= 0.0:
			finish_extraction("timeout")
			return

		# Advance time only during extraction so the sun moves over the expedition.
		# A full 12h cycle (sunrise to sunset) matches the extraction duration.
		var duration_sec = max(1.0, float(extraction_duration_seconds))
		var hours_per_second = 12.0 / duration_sec
		current_time += delta * hours_per_second

		if current_time >= 24.0:
			current_time -= 24.0
			# Notify QuotaManager BEFORE day resets, to check if we survived day
			if QuotaManager:
				QuotaManager.end_day_check()
			
			emit_signal("day_started") # New day loop
		
		# Check day/night transition
		# Day: 6 - 20, Night: 20 - 6
		var daylight = (current_time >= 6.0 and current_time < 20.0)
		if daylight != is_day_active:
			is_day_active = daylight
			if is_day_active:
				print("Day started!")
				emit_signal("day_started")
			else:
				print("Night started!")
				emit_signal("night_started")

		emit_signal("time_tick", current_time)

func get_time_string() -> String:
	var hour = int(current_time)
	var minute = int((current_time - hour) * 60)
	return "%02d:%02d" % [hour, minute]

func is_night() -> bool:
	return not is_day_active
