extends Node

# Relic Database
# Centralizes all relic definitions and their application logic.

var all_relics = [
	{
		"id": "turbo_reel",
		"name": "Turbo Reel", 
		"desc": "+12% Reel Speed", 
		"effect": "reel_speed",
		"value": 0.12
	},
	{
		"id": "titanium_line",
		"name": "Titanium Line", 
		"desc": "+18% Line Strength (Less Tension Gain)", 
		"effect": "line_strength",
		"value": 0.18
	},
	{
		"id": "scented_lure",
		"name": "Scented Lure", 
		"desc": "+20% Attraction (Faster Bites)", 
		"effect": "attraction",
		"value": 0.20
	},
	{
		"id": "carbon_fiber_rod",
		"name": "Carbon Fiber Rod", 
		"desc": "+25% Cast Range", 
		"effect": "cast_range",
		"value": 0.25
	},
	{
		"id": "ghost_net",
		"name": "Ghost Net", 
		"desc": "Start Minigame at +20% Progress", 
		"effect": "minigame_start",
		"value": 0.20
	},
	{
		"id": "barbed_hook",
		"name": "Barbed Hook", 
		"desc": "-50% Progress Drain Speed", 
		"effect": "minigame_drain",
		"value": 0.5
	},
	{
		"id": "sticky_gears",
		"name": "Sticky Gears", 
		"desc": "Bar Stops Faster (Precision Control)", 
		"effect": "minigame_glue"
	},
	{
		"id": "quantum_lure",
		"name": "Quantum Lure", 
		"desc": "7% Chance to Catch Instantly", 
		"effect": "auto_catch",
		"value": 0.07
	},
	{
		"id": "ballast_core",
		"name": "Ballast Core",
		"desc": "Heavier Bar (Slower Fall)",
		"effect": "minigame_gravity",
		"value": 0.80
	},
	{
		"id": "calm_current",
		"name": "Calm Current",
		"desc": "Fish Move Slower, Sometimes Pause",
		"effect": "fish_behavior_speed",
		"value": 0.80,
		"pause_chance": 0.18,
		"pause_duration": 0.6
	},
	{
		"id": "anchor_charm",
		"name": "Anchor Charm",
		"desc": "Fish Flee Slower and Wiggle Less",
		"effect": "fish_run_force",
		"value": 0.80,
		"wiggle_mult": 0.7
	},
	{
		"id": "wide_float",
		"name": "Wide Float",
		"desc": "Catch Bar +20%", 
		"effect": "minigame_bar_size",
		"value": 0.20
	},
	{
		"id": "focus_reel",
		"name": "Focus Reel",
		"desc": "Catch Progress +15%", 
		"effect": "minigame_catch_speed",
		"value": 0.15
	},
	{
		"id": "anti_slip",
		"name": "Anti-Slip",
		"desc": "Progress Loss -20%", 
		"effect": "minigame_lose_speed",
		"value": 0.80
	},
	{
		"id": "power_crank",
		"name": "Power Crank",
		"desc": "Reel Force +20%", 
		"effect": "minigame_reel_force",
		"value": 0.20
	},
	{
		"id": "soft_spring",
		"name": "Soft Spring",
		"desc": "Softer Bounce at Bounds", 
		"effect": "minigame_bounce",
		"value": 0.60
	},
	{
		"id": "dart_damper",
		"name": "Dart Damper",
		"desc": "Dart Bursts Slower", 
		"effect": "minigame_dart_speed",
		"value": 0.75
	},
	{
		"id": "long_hook",
		"name": "Long Hook",
		"desc": "Hook Window +40%", 
		"effect": "hook_window",
		"value": 1.40
	},
	{
		"id": "quick_bite",
		"name": "Quick Bite",
		"desc": "Bites 20% Faster", 
		"effect": "bite_time",
		"value": 0.80
	},
	{
		"id": "heavy_cast",
		"name": "Heavy Cast",
		"desc": "Cast Force +20%", 
		"effect": "cast_force",
		"value": 0.20
	},
	{
		"id": "dead_stick",
		"name": "Dead Stick",
		"desc": "Fish Pause More Often", 
		"effect": "fish_pause",
		"pause_chance": 0.25,
		"pause_duration": 0.8
	},
	{
		"id": "drift_limiter",
		"name": "Drift Limiter",
		"desc": "Fish Wiggle Less When Fleeing", 
		"effect": "fish_run_wiggle",
		"value": 0.70
	},
	{
		"id": "thick_cork",
		"name": "Thick Cork",
		"desc": "Catch Bar Minimum Size 60", 
		"effect": "minigame_bar_min",
		"value": 60.0
	},
	{
		"id": "steady_targets",
		"name": "Steady Targets",
		"desc": "Fish Hold Target Longer", 
		"effect": "minigame_fish_stability",
		"value": 1.40
	},
	{
		"id": "safety_net",
		"name": "Safety Net",
		"desc": "One-Time Fail Grace in Minigame", 
		"effect": "minigame_fail_grace"
	},
	{
		"id": "rescue_line",
		"name": "Rescue Line",
		"desc": "Fail Grace Restores 25%", 
		"effect": "minigame_fail_grace_amount",
		"value": 0.25
	},
	{
		"id": "headstart",
		"name": "Headstart",
		"desc": "Start Minigame at 35%", 
		"effect": "minigame_start_floor",
		"value": 0.35
	},
	{
		"id": "gyro_grip",
		"name": "Gyro Grip",
		"desc": "Extra Bar Damping", 
		"effect": "minigame_bar_damping",
		"value": 6.0
	},
	{
		"id": "second_chance",
		"name": "Second Chance",
		"desc": "25% Chance for Quick Re-Bite", 
		"effect": "bite_retry",
		"value": 0.25
	},
	{
		"id": "tether_line",
		"name": "Tether Line",
		"desc": "Distance Penalty Weaker", 
		"effect": "distance_modifier",
		"value": 1.15
	}
]

func get_random_relics(count: int = 3) -> Array:
	var pool = all_relics.duplicate()
	pool.shuffle()
	var result = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	return result

func get_relic_by_id(relic_id: String) -> Dictionary:
	for relic in all_relics:
		if relic.get("id", "") == relic_id:
			return relic
	return {}

func apply_relic(relic_data: Dictionary):
	print("RelicDatabase: Applying ", relic_data["name"])
	
	# Add to inventory tracking if needed (usually handled by InventoryManager calling this)
	# But here we just apply the immediate or passive stats.
	
	match relic_data["effect"]:
		"reel_speed":
			if InventoryManager: 
				InventoryManager.reel_speed_multiplier += relic_data.get("value", 0.15)
		"line_strength":
			if InventoryManager: 
				InventoryManager.line_strength_multiplier += relic_data.get("value", 0.20)
		"attraction":
			if InventoryManager: 
				InventoryManager.attraction_bonus += relic_data.get("value", 0.25)
		"cast_range":
			if InventoryManager:
				InventoryManager.cast_range_multiplier += relic_data.get("value", 0.30)
		"minigame_start":
			if InventoryManager:
				InventoryManager.minigame_start_bonus += relic_data.get("value", 0.25)
		"minigame_drain":
			if InventoryManager:
				InventoryManager.minigame_drain_multiplier *= relic_data.get("value", 0.5)
		"minigame_glue":
			if InventoryManager:
				InventoryManager.minigame_bar_glue = true
		"auto_catch":
			if InventoryManager:
				InventoryManager.auto_catch_chance += relic_data.get("value", 0.05)
		"minigame_gravity":
			if InventoryManager:
				InventoryManager.minigame_gravity_multiplier *= relic_data.get("value", 0.85)
		"fish_behavior_speed":
			if InventoryManager:
				InventoryManager.minigame_fish_speed_multiplier *= relic_data.get("value", 0.85)
				InventoryManager.minigame_fish_pause_chance = max(InventoryManager.minigame_fish_pause_chance, relic_data.get("pause_chance", 0.0))
				InventoryManager.minigame_fish_pause_duration = max(InventoryManager.minigame_fish_pause_duration, relic_data.get("pause_duration", 0.0))
		"fish_run_force":
			if InventoryManager:
				InventoryManager.fish_run_force_multiplier *= relic_data.get("value", 0.85)
				InventoryManager.fish_run_wiggle_multiplier *= relic_data.get("wiggle_mult", 1.0)
		"minigame_bar_size":
			if InventoryManager:
				InventoryManager.minigame_bar_size_multiplier += relic_data.get("value", 0.20)
		"minigame_catch_speed":
			if InventoryManager:
				InventoryManager.minigame_catch_speed_multiplier += relic_data.get("value", 0.15)
		"minigame_lose_speed":
			if InventoryManager:
				InventoryManager.minigame_lose_speed_multiplier *= relic_data.get("value", 0.80)
		"minigame_reel_force":
			if InventoryManager:
				InventoryManager.minigame_reel_force_multiplier += relic_data.get("value", 0.20)
		"minigame_bounce":
			if InventoryManager:
				InventoryManager.minigame_bounce_multiplier *= relic_data.get("value", 0.60)
		"minigame_dart_speed":
			if InventoryManager:
				InventoryManager.minigame_dart_speed_multiplier *= relic_data.get("value", 0.75)
		"hook_window":
			if InventoryManager:
				InventoryManager.hook_window_multiplier *= relic_data.get("value", 1.40)
		"bite_time":
			if InventoryManager:
				InventoryManager.bite_time_multiplier *= relic_data.get("value", 0.80)
		"cast_force":
			if InventoryManager:
				InventoryManager.cast_force_multiplier += relic_data.get("value", 0.20)
		"fish_pause":
			if InventoryManager:
				InventoryManager.minigame_fish_pause_chance = max(InventoryManager.minigame_fish_pause_chance, relic_data.get("pause_chance", 0.0))
				InventoryManager.minigame_fish_pause_duration = max(InventoryManager.minigame_fish_pause_duration, relic_data.get("pause_duration", 0.0))
		"fish_run_wiggle":
			if InventoryManager:
				InventoryManager.fish_run_wiggle_multiplier *= relic_data.get("value", 0.70)
		"minigame_bar_min":
			if InventoryManager:
				InventoryManager.minigame_bar_min_size = max(InventoryManager.minigame_bar_min_size, relic_data.get("value", 60.0))
		"minigame_fish_stability":
			if InventoryManager:
				InventoryManager.minigame_fish_stability_multiplier *= relic_data.get("value", 1.40)
		"minigame_fail_grace":
			if InventoryManager:
				InventoryManager.minigame_fail_grace = true
		"minigame_fail_grace_amount":
			if InventoryManager:
				InventoryManager.minigame_fail_grace_amount = max(InventoryManager.minigame_fail_grace_amount, relic_data.get("value", 0.25))
		"minigame_start_floor":
			if InventoryManager:
				InventoryManager.minigame_start_floor = max(InventoryManager.minigame_start_floor, relic_data.get("value", 0.35))
		"minigame_bar_damping":
			if InventoryManager:
				InventoryManager.minigame_bar_damping += relic_data.get("value", 6.0)
		"bite_retry":
			if InventoryManager:
				InventoryManager.bite_retry_chance += relic_data.get("value", 0.25)
		"distance_modifier":
			if InventoryManager:
				InventoryManager.distance_modifier_multiplier *= relic_data.get("value", 1.15)
