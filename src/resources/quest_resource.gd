extends Resource
class_name QuestResource

@export var title: String
@export var description: String
@export var target_fish_name: String # Name of the fish resource to catch
@export var target_amount: int
@export var current_amount: int
@export var reward_money: int
@export var is_completed: bool = false

func check_progress(fish_name: String):
	if is_completed: return
	
	if fish_name == target_fish_name:
		current_amount += 1
		if current_amount >= target_amount:
			complete_quest()

func complete_quest():
	is_completed = true
	# Signal completed? Handled by manager usually.
