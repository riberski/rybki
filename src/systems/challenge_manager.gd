extends Node

# ChallengeManager.gd
# Zarządza rotującymi wyzwaniami (codzienne/tygodniowe)

signal challenge_available(challenge)
signal challenge_completed(challenge)

var daily_challenges = [
	{"type": "catch_fish", "amount": 5},
	{"type": "sell_fish", "amount": 10},
	{"type": "win_run", "amount": 1},
	{"type": "catch_rare_fish", "amount": 1},
	{"type": "no_damage_run", "amount": 1}
]

var weekly_challenges = [
	{"type": "catch_fish", "amount": 50},
	{"type": "sell_fish", "amount": 100},
	{"type": "catch_legendary_fish", "amount": 1},
	{"type": "win_run", "amount": 7}
]

var current_daily = null
var current_weekly = null
var daily_completed = false
var weekly_completed = false
var last_daily_date = null
var last_weekly_date = null

func _ready():
	load_state()
	if is_new_day():
		pick_new_daily()
	if is_new_week():
		pick_new_weekly()

func is_new_day() -> bool:
	var today = Time.get_date_dict_from_system()
	return last_daily_date == null or today != last_daily_date

func is_new_week() -> bool:
	if last_weekly_date == null:
		return true
	
	var current_timestamp = Time.get_unix_time_from_system()
	var seven_days_in_seconds = 7 * 24 * 60 * 60
	return (current_timestamp - last_weekly_date) >= seven_days_in_seconds

func pick_new_daily():
	current_daily = daily_challenges[randi() % daily_challenges.size()]
	daily_completed = false
	last_daily_date = Time.get_date_dict_from_system()
	save_state()
	emit_signal("challenge_available", current_daily)

func pick_new_weekly():
	current_weekly = weekly_challenges[randi() % weekly_challenges.size()]
	weekly_completed = false
	last_weekly_date = Time.get_unix_time_from_system()
	save_state()
	emit_signal("challenge_available", current_weekly)

func complete_daily():
	daily_completed = true
	save_state()
	emit_signal("challenge_completed", current_daily)

func complete_weekly():
	weekly_completed = true
	save_state()
	emit_signal("challenge_completed", current_weekly)

func save_state():
	var state = {
		"current_daily": current_daily,
		"current_weekly": current_weekly,
		"daily_completed": daily_completed,
		"weekly_completed": weekly_completed,
		"last_daily_date": last_daily_date,
		"last_weekly_date": last_weekly_date
	}
	var file = FileAccess.open("user://challenge_manager.save", FileAccess.WRITE)
	file.store_var(state)
	file.close()

func load_state():
	if FileAccess.file_exists("user://challenge_manager.save"):
		var file = FileAccess.open("user://challenge_manager.save", FileAccess.READ)
		var state = file.get_var()
		file.close()
		current_daily = state.get("current_daily", null)
		current_weekly = state.get("current_weekly", null)
		daily_completed = state.get("daily_completed", false)
		weekly_completed = state.get("weekly_completed", false)
		last_daily_date = state.get("last_daily_date", null)
		last_weekly_date = state.get("last_weekly_date", null)
	else:
		current_daily = null
		current_weekly = null
		daily_completed = false
		weekly_completed = false
		last_daily_date = null
		last_weekly_date = null
