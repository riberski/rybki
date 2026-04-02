extends Node

signal quest_updated(quest_data: Dictionary)
signal quest_completed(quest_data: Dictionary)
signal quest_accepted(quest_data: Dictionary)
signal contract_offer_updated(offer_data: Dictionary)

# Example Quest Structure:
# {
#   "id": "contract_123",
#   "type": "earn_money",
#   "target_amount": 300,
#   "current_amount": 0,
#   "reward_money": 120,
#   "description": "Kontrakt: zarob $300",
#   "completed": false
# }

var active_quest: Dictionary = {}
var contract_offer: Dictionary = {}
const SAVE_FILE_PATH = "user://quests.json"
const CONTRACT_REWARD_MULTIPLIER = 0.4
const CONTRACT_SPEED_BASE = 1.0
const CONTRACT_SPEED_PER_DIFFICULTY = 0.15
const CONTRACT_SPEED_MAX = 1.8
const CONTRACT_TARGET_BASE_MULT = 8.0
const CONTRACT_TARGET_VARIANCE = 6.0

func _ready():
	# Connect to InventoryManager to track progress
	InventoryManager.inventory_updated.connect(_on_fish_caught)
	load_quests()
	
	if active_quest.is_empty() and contract_offer.is_empty():
		generate_contract_offer()


func generate_contract_offer():
	# Use FishDatabase
	var all_fish = FishDatabase.get_all_fish()
	if all_fish.is_empty():
		print("No fish in database for quests!")
		return

	var avg_value = 0.0
	for fish in all_fish:
		avg_value += float(fish.value)
	avg_value = avg_value / float(max(all_fish.size(), 1))

	var difficulty = randf_range(1.5, 5.0)
	var speed_multiplier = CONTRACT_SPEED_BASE + ((difficulty - 1.0) * CONTRACT_SPEED_PER_DIFFICULTY)
	speed_multiplier = clamp(speed_multiplier, CONTRACT_SPEED_BASE, CONTRACT_SPEED_MAX)

	var target_money = int(avg_value * (CONTRACT_TARGET_BASE_MULT + randf_range(0.0, CONTRACT_TARGET_VARIANCE)) * (1.0 + (difficulty - 1.0) * 0.25))
	var reward = int(target_money * CONTRACT_REWARD_MULTIPLIER)

	contract_offer = {
		"id": "contract_" + str(Time.get_unix_time_from_system()),
		"type": "earn_money",
		"target_amount": target_money,
		"current_amount": 0,
		"reward_money": reward,
		"difficulty": difficulty,
		"fish_speed_multiplier": speed_multiplier,
		"description": "Kontrakt: zarob $%d" % target_money,
		"completed": false
	}

	contract_offer_updated.emit(contract_offer)
	save_quests()
	print("New Contract Offer: ", contract_offer["description"])


func accept_contract():
	if typeof(contract_offer) != TYPE_DICTIONARY:
		contract_offer = {}
	if typeof(active_quest) != TYPE_DICTIONARY:
		active_quest = {}
	if contract_offer.is_empty():
		return
	if not active_quest.is_empty() and not active_quest.get("completed", false):
		return
	active_quest = contract_offer.duplicate(true)
	contract_offer = {}
	quest_accepted.emit(active_quest)
	contract_offer_updated.emit(contract_offer)
	save_quests()

func _on_fish_caught(fish_resource):
	if active_quest.is_empty() or active_quest["completed"]: return
	if fish_resource == null: return # Handling selling/clearing

	var quest_type = active_quest.get("type", "earn_money")
	if quest_type == "catch_fish" and active_quest.has("target_fish_id"):
		if fish_resource.id == active_quest["target_fish_id"]:
			active_quest["current_amount"] += 1
			quest_updated.emit(active_quest)
			print("Quest Progress: %d/%d" % [active_quest["current_amount"], active_quest["target_amount"]])
			if active_quest["current_amount"] >= active_quest["target_amount"]:
				complete_quest()
	elif quest_type == "earn_money":
		var value = fish_resource.value
		if InventoryManager:
			value = int(value * InventoryManager.global_value_multiplier)
			value = int(value * InventoryManager.expedition_value_multiplier)
		active_quest["current_amount"] += value
		quest_updated.emit(active_quest)
		print("Contract Progress: $%d/$%d" % [active_quest["current_amount"], active_quest["target_amount"]])
		if active_quest["current_amount"] >= active_quest["target_amount"]:
			complete_quest()
	save_quests()

func reset():
	active_quest = {}
	contract_offer = {}
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	
	# Generate initial quest
	generate_contract_offer()
	print("Quests Reset!")

func complete_quest():
	if active_quest["completed"]: return
	
	active_quest["completed"] = true
	var payout = int(active_quest["reward_money"])
	if active_quest.get("type", "") == "earn_money":
		# Pay out the accumulated fish value plus the contract bonus.
		payout += int(active_quest.get("current_amount", 0))
	InventoryManager.money += payout
	InventoryManager.money_updated.emit(InventoryManager.money)
	if TimeManager and TimeManager.extraction_active:
		InventoryManager.register_expedition_earnings(payout)
	
	quest_completed.emit(active_quest)
	print("Quest Completed! Reward: $" + str(payout))
	active_quest = {}
	save_quests()
	
	# Auto-generate new quest after delay (or wait for player action)
	# For game loop flow, let's generate new one immediately or on next load
	# Or keep completed state until claimed?
	# Let's simple: Generate new one after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(generate_contract_offer)

func save_quests():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var payload = {
		"active_quest": active_quest,
		"contract_offer": contract_offer
	}
	file.store_string(JSON.stringify(payload))

func load_quests():
	if not FileAccess.file_exists(SAVE_FILE_PATH): return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			if data.has("active_quest") or data.has("contract_offer"):
				active_quest = data.get("active_quest", {})
				contract_offer = data.get("contract_offer", {})
				if typeof(active_quest) != TYPE_DICTIONARY:
					active_quest = {}
				if typeof(contract_offer) != TYPE_DICTIONARY:
					contract_offer = {}
			else:
				# Legacy format - data is active quest
				active_quest = data
				contract_offer = {}

			if not active_quest.is_empty() and not active_quest.has("fish_speed_multiplier"):
				active_quest["fish_speed_multiplier"] = CONTRACT_SPEED_BASE
			if not contract_offer.is_empty() and not contract_offer.has("fish_speed_multiplier"):
				contract_offer["fish_speed_multiplier"] = CONTRACT_SPEED_BASE

			# If loaded completed quest, clear it and offer a new one
			if not active_quest.is_empty() and active_quest.get("completed", false):
				active_quest = {}
				generate_contract_offer()
				return

			if not active_quest.is_empty():
				quest_accepted.emit(active_quest)
			if not contract_offer.is_empty():
				contract_offer_updated.emit(contract_offer)
			if active_quest.is_empty() and contract_offer.is_empty():
				generate_contract_offer()
