extends Control

signal draft_complete

@onready var container = $Panel/HBoxContainer

# Simple test relics
# Relics are now in RelicDatabase

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_draft():
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_generate_choices()

func show_draft_on_board():
	show()
	if get_tree().paused:
		get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_generate_choices()

func _generate_choices():
	for child in container.get_children():
		child.queue_free()
		
	var choices = RelicDatabase.get_random_relics(3)
		
	for choice in choices:
		var btn = Button.new()
		var text = choice["name"] + "\n\n" + choice["desc"]
		if choice.get("rarity") == "cursed":
			text = "[CURSED]\n" + text
			btn.modulate = Color(0.8, 0, 0.8) # Purple
			
		btn.text = text
		btn.custom_minimum_size = Vector2(150, 200)
		btn.pressed.connect(func(): _select_relic(choice))
		container.add_child(btn)

func _select_relic(relic):
	print("Selected Relic: ", relic["name"])
	
	if InventoryManager:
		var boat_id = InventoryManager.current_boat_id
		var loadout = InventoryManager.get_boat_loadout(boat_id)
		var placed = false
		for i in range(loadout["relics"].size()):
			if loadout["relics"][i] == "":
				InventoryManager.set_boat_relic_slot(boat_id, i, relic.get("id", ""))
				placed = true
				break
		if not placed:
			print("No free relic slots on boat loadout.")
	if QuotaManager:
		QuotaManager.clear_pending_draft()
	
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
