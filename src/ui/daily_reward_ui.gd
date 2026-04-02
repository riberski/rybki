extends Control

# DailyRewardUI.gd
# UI do odbierania codziennych nagród

@onready var reward_label = $Margin/VBox/RewardLabel
@onready var claim_button = $Margin/VBox/ClaimButton

var reward_manager = null

func _ready():
	reward_manager = DailyRewardManager # Use correct singleton
	reward_manager.connect("daily_reward_available", Callable(self, "on_daily_reward_available"))
	reward_manager.connect("daily_reward_claimed", Callable(self, "on_daily_reward_claimed"))
	claim_button.connect("pressed", Callable(self, "on_claim_pressed"))
	update_ui()

func on_daily_reward_available(reward):
	reward_label.text = "Nagroda dnia: %s" % str(reward)
	claim_button.disabled = false

func on_daily_reward_claimed(reward):
	reward_label.text = "Odebrano: %s" % str(reward)
	claim_button.disabled = true

func on_claim_pressed():
	reward_manager.claim_reward()

func update_ui():
	if reward_manager.is_new_day():
		claim_button.disabled = false
		reward_label.text = "Nagroda dnia: %s" % str(reward_manager.get_today_reward())
	else:
		claim_button.disabled = true
		reward_label.text = "Nagroda odebrana. Jutro kolejna!"
