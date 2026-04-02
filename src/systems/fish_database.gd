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
	if available_fish.is_empty(): return null
	return available_fish.pick_random()
