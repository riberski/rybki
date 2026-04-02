extends Node

# ProgressionManager.gd
# Zarządza meta-progresją: ulepszenia bazy, sloty, trwałe bonusy

signal upgrade_unlocked(upgrade)

var upgrades = {
	"extra_relic_slot": {"cost": 1000, "owned": false},
	"bigger_stash": {"cost": 1500, "owned": false},
	"faster_boat": {"cost": 2000, "owned": false},
	"rare_bait_unlock": {"cost": 1200, "owned": false}
}

func unlock_upgrade(upgrade_id):
	if upgrades.has(upgrade_id) and not upgrades[upgrade_id]["owned"]:
		upgrades[upgrade_id]["owned"] = true
		save_state()
		emit_signal("upgrade_unlocked", upgrade_id)

func is_unlocked(upgrade_id):
	return upgrades.has(upgrade_id) and upgrades[upgrade_id]["owned"]

func save_state():
	var file = FileAccess.open("user://progression_manager.save", FileAccess.WRITE)
	file.store_var(upgrades)
	file.close()

func load_state():
	if FileAccess.file_exists("user://progression_manager.save"):
		var file = FileAccess.open("user://progression_manager.save", FileAccess.READ)
		upgrades = file.get_var()
		file.close()
