extends Node

# Stores all available fish resources in one place
var available_fish: Array[FishResource] = []

func _ready():
	_load_all_fish()

func _load_all_fish():
	# For now, manually add the known fish resources
	available_fish.append(load("res://data/fish/carp.tres"))
	available_fish.append(load("res://data/fish/bass.tres"))
	available_fish.append(load("res://data/fish/golden_trout.tres"))
	available_fish.append(load("res://data/fish/catfish.tres"))
	available_fish.append(load("res://data/fish/pike.tres"))
	available_fish.append(load("res://data/fish/electric_eel.tres"))
	available_fish.append(load("res://data/fish/giant_catfish.tres"))
	
	# New behavior fish
	available_fish.append(load("res://data/fish/neon_tetra.tres")) # Smooth / Circles
	available_fish.append(load("res://data/fish/stonefish.tres"))  # Sinker / Bottom
	available_fish.append(load("res://data/fish/marlin.tres"))     # Dart / Fast

func get_all_fish() -> Array[FishResource]:
	return available_fish

func get_fish_by_name(name: String) -> FishResource:
	for fish in available_fish:
		if fish.name == name:
			return fish
	return null

func get_random_fish() -> FishResource:
	return get_random_fish_for_context("", false, 0.0)

func get_random_fish_for_context(current_bait_id: String, is_night: bool, risk_level: float = 0.0) -> FishResource:
	if available_fish.is_empty():
		return null

	var weighted_pool: Array = []
	var total_weight: float = 0.0
	var risk_t: float = float(clamp(risk_level / 100.0, 0.0, 1.0))

	for fish in available_fish:
		if fish == null:
			continue
		var weight := 1.0

		if fish.preferred_bait_id != "":
			if fish.preferred_bait_id == current_bait_id:
				weight *= 1.8
			else:
				weight *= 0.7

		if fish.active_time == "Day" and is_night:
			weight *= 0.55
		elif fish.active_time == "Night" and not is_night:
			weight *= 0.55

		# Higher risk means better chance for rare fish.
		weight *= lerp(1.0, 1.8, risk_t * clamp(float(fish.rarity), 0.0, 1.0))

		weighted_pool.append({"fish": fish, "weight": weight})
		total_weight += weight

	if total_weight <= 0.0:
		return available_fish.pick_random()

	var roll := randf() * total_weight
	var cursor := 0.0
	for item in weighted_pool:
		cursor += float(item["weight"])
		if roll <= cursor:
			return item["fish"]

	return weighted_pool.back()["fish"]
