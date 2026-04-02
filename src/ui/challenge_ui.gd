extends Control

# ChallengeUI.gd
# UI do wyświetlania i odbierania wyzwań

@onready var daily_label = $Panel/Margin/VBox/DailyRow/DailyLabel
@onready var daily_status = $Panel/Margin/VBox/DailyRow/DailyStatus
@onready var weekly_label = $Panel/Margin/VBox/WeeklyRow/WeeklyLabel
@onready var weekly_status = $Panel/Margin/VBox/WeeklyRow/WeeklyStatus

var challenge_manager = null

func _ready():
	challenge_manager = get_node("/root/ChallengeManager")
	challenge_manager.challenge_available.connect(on_challenge_available)
	challenge_manager.challenge_completed.connect(on_challenge_completed)
	update_ui()

func on_challenge_available(challenge):
	update_ui()

func on_challenge_completed(challenge):
	update_ui()

func update_ui():
	if challenge_manager.current_daily:
		daily_label.text = "Codzienne: %s" % str(challenge_manager.current_daily)
		daily_status.text = "Ukończone" if challenge_manager.daily_completed else "W trakcie"
	else:
		daily_label.text = "Codzienne: brak"
		daily_status.text = "-"
	if challenge_manager.current_weekly:
		weekly_label.text = "Tygodniowe: %s" % str(challenge_manager.current_weekly)
		weekly_status.text = "Ukończone" if challenge_manager.weekly_completed else "W trakcie"
	else:
		weekly_label.text = "Tygodniowe: brak"
		weekly_status.text = "-"
