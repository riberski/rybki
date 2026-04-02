extends Control

@onready var quest_label: Label = $Panel/Label
@onready var progress_bar: ProgressBar = $Panel/ProgressBar

func _ready():
	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_accepted.connect(_on_quest_accepted)
	
	# Initial update
	if not QuestManager.active_quest.is_empty():
		_update_ui(QuestManager.active_quest)
	else:
		hide()

func _on_quest_updated(quest_data: Dictionary):
	_update_ui(quest_data)

func _on_quest_accepted(quest_data: Dictionary):
	show()
	_update_ui(quest_data)

func _on_quest_completed(quest_data: Dictionary):
	quest_label.text = "Quest Completed!\nReward: %d Gold" % quest_data["reward_money"]
	progress_bar.value = 100
	
	# Hide after a delay
	await get_tree().create_timer(3.0).timeout
	hide()

func _update_ui(quest_data: Dictionary):
	if quest_data.is_empty():
		hide()
		return
		
	show()
	var description = quest_data.get("description", "Unknown Quest")
	var current = quest_data.get("current_amount", 0)
	var target = quest_data.get("target_amount", 1)
	
	quest_label.text = "%s\n(%d/%d)" % [description, current, target]
	progress_bar.max_value = target
	progress_bar.value = current
