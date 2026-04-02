extends Control

@onready var continue_button = $CenterContainer/VBoxContainer/ContinueButton

func _ready():
	# Check if save file exists
	if not FileAccess.file_exists("user://savegame.json"):
		continue_button.disabled = true
	else:
		continue_button.grab_focus()

func _on_new_game_button_pressed():
	if RunMetrics:
		RunMetrics.start_session("new_game")

	# Start a fresh extraction run and move to lobby hub.
	if QuotaManager:
		QuotaManager.start_new_run()
	else:
		InventoryManager.start_new_game()
	
	# Delete other save files if they exist (Journal, Quests, Achievements)
	var other_saves = [
		"user://journal.json",
		"user://quests.json",
		"user://achievements.json"
	]
	var dir = DirAccess.open("user://")
	for file in other_saves:
		if dir.file_exists(file):
			dir.remove(file)
	
	# Transition to extraction lobby
	var err = get_tree().change_scene_to_file("res://src/ui/lobby_world.tscn")
	if err != OK:
		push_error("Failed to load lobby_world.tscn: %s" % err)

func _on_continue_button_pressed():
	if FileAccess.file_exists("user://savegame.json"):
		if RunMetrics:
			RunMetrics.start_session("continue")
		var err = get_tree().change_scene_to_file("res://src/ui/lobby_world.tscn")
		if err != OK:
			push_error("Failed to load lobby_world.tscn: %s" % err)

func _on_quit_button_pressed():
	if RunMetrics:
		RunMetrics.end_session("quit_from_menu")
	get_tree().quit()
