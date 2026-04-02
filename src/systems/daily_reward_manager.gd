extends Node

# DailyRewardManager.gd
# Zarządza codziennymi nagrodami za logowanie i streakami

signal daily_reward_available(reward)
signal daily_reward_claimed(reward)

var last_claimed_date = null
var streak = 0
var rewards = [
	{"type": "coins", "amount": 100},
	{"type": "bait", "amount": 1},
	{"type": "cosmetic", "id": "hat_1"},
	{"type": "coins", "amount": 200},
	{"type": "relic", "id": "random"},
	{"type": "coins", "amount": 300},
	{"type": "special", "id": "weekly_bonus"}
]

func _ready():
	load_state()
	if is_new_day():
		emit_signal("daily_reward_available", get_today_reward())

func is_new_day() -> bool:
	var today = Time.get_date_dict_from_system()
	return last_claimed_date == null or today != last_claimed_date

func get_today_reward():
	return rewards[streak % rewards.size()]

func claim_reward():
	if is_new_day():
		last_claimed_date = Time.get_date_dict_from_system()
		streak += 1
		save_state()
		emit_signal("daily_reward_claimed", get_today_reward())

func save_state():
	var state = {"last_claimed_date": last_claimed_date, "streak": streak}
	var file = FileAccess.open("user://daily_reward.save", FileAccess.WRITE)
	file.store_var(state)
	file.close()

func load_state():
	if FileAccess.file_exists("user://daily_reward.save"):
		var file = FileAccess.open("user://daily_reward.save", FileAccess.READ)
		var state = file.get_var()
		file.close()
		last_claimed_date = state.get("last_claimed_date", null)
		streak = state.get("streak", 0)
	else:
		last_claimed_date = null
		streak = 0
