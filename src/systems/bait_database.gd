extends Node
# removed class_name to avoid conflict with Singleton

# Dictionary of Bait ID (String) mapped to Bait Properties (Dictionary or Resource)
var baits = {
	"bread": {
		"name": "Chleb",
		"price": 5,
		"attraction": 1.0, # Normal bite time
		"quality": 1.0, # Normal fish rarity
		"description": "Najtańsza przynęta na drobnicę."
	},
	"worm": {
		"name": "Robak",
		"price": 20,
		"attraction": 1.5, # Faster bite time (divide by attraction)
		"quality": 1.2, # Better fish chance
		"description": "Klasyk wędkarstwa."
	},
	"shrimp": {
		"name": "Krewetka",
		"price": 50,
		"attraction": 2.0,
		"quality": 1.5,
		"description": "Przysmak dla rzadkich okazów."
	},
	"magnet": {
		"name": "Magnes",
		"price": 30,
		"attraction": 1.0,
		"quality": 1.0, # Normal fish rarity
		"description": "Zwiększa szansę na znalezienie skarbu.",
		"special": "treasure"
	},
	"glowworm": {
		"name": "Świetlik",
		"price": 40,
		"attraction": 2.5, # Very fast at night
		"quality": 1.3,
		"description": "Idealny na nocne połowy.",
		"special": "night"
	},
	"spinner": {
		"name": "Błystka",
		"price": 60,
		"attraction": 3.0, # Fast bites
		"quality": 0.8, # More common aggressive fish
		"description": "Szybki połów, ale odstrasza rzadkie ryby.",
		"special": "fast"
	}
}

func get_bait(id: String):
	return baits.get(id, null)

func get_next_bait_id(current_id: String) -> String:
	var keys = baits.keys()
	var index = keys.find(current_id)
	if index == -1 or index == keys.size() - 1:
		return keys[0]
	return keys[index + 1]
