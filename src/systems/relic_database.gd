extends Node

# Relic Database
# Centralizes all relic definitions and their application logic.

var all_relics = [
	{
		"id": "mapa_hotspotow",
		"name": "Mapa",
		"desc": "Pokazuje hotspoty ryb (+attraction)",
		"effect": "attraction",
		"value": 0.12
	},
	{
		"id": "noz",
		"name": "Noz",
		"desc": "Szybkie ponowne zarzucenie (retry +35%)",
		"effect": "bite_retry",
		"value": 0.35
	},
	{
		"id": "kompas",
		"name": "Kompas",
		"desc": "Latwiejsza droga ucieczki",
		"effect": "distance_modifier",
		"value": 1.12
	},
	{
		"id": "krotkofalowka",
		"name": "Krotkofalowka",
		"desc": "Lepsza koordynacja (okno podciecia +20%)",
		"effect": "hook_window",
		"value": 1.20
	},
	{
		"id": "sprezyna",
		"name": "Sprezyna",
		"desc": "Pozwala skakac lodka",
		"effect": "boat_jump",
		"value": 5.8
	},
	{
		"id": "zlota_przyneta",
		"name": "Zlota przyneta",
		"desc": "Zwiesza szanse na rzadkie ryby",
		"effect": "luck_bonus",
		"value": 0.16
	},
	{
		"id": "magnes",
		"name": "Magnes",
		"desc": "Wiecej skarbowej wartosci",
		"effect": "value_mult",
		"value": 1.10
	},
	{
		"id": "zamrazajaca_wedka",
		"name": "Zamrazajaca wedka",
		"desc": "Spowalnia ryby po trafieniu",
		"effect": "fish_behavior_speed",
		"value": 0.82,
		"pause_chance": 0.12,
		"pause_duration": 0.45
	},
	{
		"id": "elektryczna_przyneta",
		"name": "Elektryczna przyneta",
		"desc": "Oglusza ryby lokalnie",
		"effect": "fish_pause",
		"pause_chance": 0.28,
		"pause_duration": 0.85
	},
	{
		"id": "boja_sonarowa",
		"name": "Boja sonarowa",
		"desc": "Pokazuje miejsca z duza iloscia ryb",
		"effect": "attraction",
		"value": 0.14
	},
	{
		"id": "klon_ryby",
		"name": "Klon ryby",
		"desc": "Szansa sklonowania ostatniej ryby",
		"effect": "fish_clone",
		"value": 0.22
	},
	{
		"id": "dopalacz",
		"name": "Dopalacz",
		"desc": "Chwilowe przyspieszenie lodzi",
		"effect": "nitro",
		"value": 1.32
	},
	{
		"id": "beczka_paliwa",
		"name": "Beczka z paliwem",
		"desc": "Natychmiastowa poprawa kondycji lodzi",
		"effect": "hull_bonus",
		"value": 1.12
	},
	{
		"id": "tarcza_lodzi",
		"name": "Tarcza lodzi",
		"desc": "Wzmacnia kadlub i linie",
		"effect": "line_strength",
		"value": 0.20
	},
	{
		"id": "wirnik_wodny",
		"name": "Wirnik wodny",
		"desc": "Tworzy wir spowalniajacy uciekajace ryby",
		"effect": "fish_run_force",
		"value": 0.76,
		"wiggle_mult": 0.82
	},
	{
		"id": "mini_lodka_ratunkowa",
		"name": "Mini lodka ratunkowa",
		"desc": "Latwiejszy powrot po porazce",
		"effect": "rescue_boost",
		"keep_bonus": 0.22,
		"value_penalty": 0.12
	},
	{
		"id": "kotwica_bojowa",
		"name": "Kotwica bojowa",
		"desc": "Hamowanie awaryjne lodzi",
		"effect": "anchor_brake"
	},
	{
		"id": "lornetka",
		"name": "Lornetka",
		"desc": "Wiekszy zasieg obserwacji/rzutu",
		"effect": "cast_range",
		"value": 0.20
	},
	{
		"id": "mapa_skarbow",
		"name": "Mapa skarbow",
		"desc": "Losowe miejsce z lootem (wieksza wartosc)",
		"effect": "value_mult",
		"value": 1.12
	},
	{
		"id": "latarka_uv",
		"name": "Latarka UV",
		"desc": "Ujawnia ukryte obiekty i ryby",
		"effect": "luck_bonus",
		"value": 0.10
	},
	{
		"id": "mikstura_niewidzialnosci",
		"name": "Mikstura niewidzialnosci",
		"desc": "Latwiej uniknac zagrozenia",
		"effect": "fish_behavior_speed",
		"value": 0.90,
		"pause_chance": 0.10,
		"pause_duration": 0.30
	},
	{
		"id": "spowalniacz_czasu",
		"name": "Spowalniacz czasu",
		"desc": "Na chwile spowalnia wszystko wokol",
		"effect": "minigame_dart_speed",
		"value": 0.68
	},
	{
		"id": "falszywy_kompas",
		"name": "Falszywy kompas",
		"desc": "Mylace wskazania dla innych (u Ciebie pewniejsza trasa)",
		"effect": "distance_modifier",
		"value": 1.08
	},
	{
		"id": "megafon",
		"name": "Megafon",
		"desc": "Glos slychac dalej (szybsze brania)",
		"effect": "bite_time",
		"value": 0.86
	},
	{
		"id": "pulapka_sieciowa",
		"name": "Pulapka sieciowa",
		"desc": "Unieruchamia cele na chwile (stun ryb)",
		"effect": "fish_pause",
		"pause_chance": 0.20,
		"pause_duration": 1.00
	},
	{
		"id": "przywolanie_osmiornicy",
		"name": "Przywolanie osmiornicy",
		"desc": "Agresywny efekt obszarowy",
		"effect": "auto_catch",
		"value": 0.12
	},
	{
		"id": "kradnaca_wedka",
		"name": "Kradnaca wedka",
		"desc": "Przechwytuje dodatkowa zdobycz",
		"effect": "fish_clone",
		"value": 0.16
	},
	{
		"id": "bomba_wodna",
		"name": "Bomba wodna",
		"desc": "Silny impuls na wodzie",
		"effect": "minigame_reel_force",
		"value": 0.25
	},
	{
		"id": "sliska_plama",
		"name": "Sliska plama",
		"desc": "Trudniejsza kontrola, ale wiekszy zysk",
		"effect": "slippery_tradeoff",
		"value": 1.15,
		"friction_mult": 0.88
	},
	{
		"id": "ropucha_szczescia",
		"name": "Ropucha szczescia",
		"desc": "Losowy bonus lub kara",
		"effect": "random_luck"
	},
	{
		"id": "kosc_losu",
		"name": "Kosc losu",
		"desc": "Silny losowy efekt",
		"effect": "random_chaos"
	},
	{
		"id": "czapka_rybaka",
		"name": "Czapka rybaka",
		"desc": "Lekki bonus do lowienia",
		"effect": "attraction",
		"value": 0.06
	},
	{
		"id": "lustro_klonujace",
		"name": "Lustro klonujace",
		"desc": "Tworzy kopie zdobyczy",
		"effect": "fish_clone",
		"value": 0.30
	},
	{
		"id": "teczowa_fala",
		"name": "Teczowa fala",
		"desc": "Bonusy w obszarze fali",
		"effect": "rainbow_wave",
		"value": 1.10
	},
	{
		"id": "duch_rybaka",
		"name": "Duch rybaka",
		"desc": "Pomaga automatycznie lowic przez chwile",
		"effect": "ghost_fisher",
		"auto_catch": 0.10,
		"bite_time": 0.88
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
		"boat_jump":
			if InventoryManager:
				InventoryManager.can_boat_jump = true
				InventoryManager.boat_jump_force = max(InventoryManager.boat_jump_force, relic_data.get("value", 5.5))
		"luck_bonus":
			if InventoryManager:
				InventoryManager.luck_bonus += relic_data.get("value", 0.1)
		"value_mult":
			if InventoryManager:
				InventoryManager.global_value_multiplier *= relic_data.get("value", 1.1)
		"fish_clone":
			if InventoryManager:
				InventoryManager.fish_clone_chance += relic_data.get("value", 0.15)
		"nitro":
			if InventoryManager:
				InventoryManager.can_nitro_boost = true
				InventoryManager.nitro_speed_multiplier = max(InventoryManager.nitro_speed_multiplier, relic_data.get("value", 1.25))
		"hull_bonus":
			if InventoryManager:
				InventoryManager.boat_durability_max *= relic_data.get("value", 1.1)
		"rescue_boost":
			if InventoryManager:
				InventoryManager.soft_loss_keep_bonus += relic_data.get("keep_bonus", 0.18)
				InventoryManager.soft_loss_value_penalty += relic_data.get("value_penalty", 0.10)
		"anchor_brake":
			if InventoryManager:
				InventoryManager.can_anchor_brake = true
		"slippery_tradeoff":
			if InventoryManager:
				InventoryManager.global_value_multiplier *= relic_data.get("value", 1.12)
				InventoryManager.physics_friction_multiplier *= relic_data.get("friction_mult", 0.9)
		"random_luck":
			if InventoryManager:
				var roll: float = randf()
				if roll < 0.5:
					InventoryManager.global_value_multiplier *= 1.20
				else:
					InventoryManager.global_value_multiplier *= 0.92
		"random_chaos":
			if InventoryManager:
				var chaos_roll: int = randi() % 4
				match chaos_roll:
					0:
						InventoryManager.auto_catch_chance += 0.12
					1:
						InventoryManager.minigame_lose_speed_multiplier *= 0.75
					2:
						InventoryManager.global_value_multiplier *= 1.25
					_:
						InventoryManager.fish_run_force_multiplier *= 0.75
		"rainbow_wave":
			if InventoryManager:
				InventoryManager.global_value_multiplier *= relic_data.get("value", 1.10)
				InventoryManager.attraction_bonus += 0.10
		"ghost_fisher":
			if InventoryManager:
				InventoryManager.auto_catch_chance += relic_data.get("auto_catch", 0.08)
				InventoryManager.bite_time_multiplier *= relic_data.get("bite_time", 0.9)
