extends Node

# RandomDropManager.gd
# Zarządza losowością i rzadkością dropów

var drop_table = [
	{"type": "relic", "id": "rare_relic_1", "chance": 0.01},
	{"type": "relic", "id": "common_relic_1", "chance": 0.2},
	{"type": "cosmetic", "id": "hat_rare", "chance": 0.05},
	{"type": "fish", "id": "legendary_fish", "chance": 0.005}
]

func get_random_drop():
	var roll = randf()
	var acc = 0.0
	for entry in drop_table:
		acc += entry["chance"]
		if roll < acc:
			return entry
	return null
