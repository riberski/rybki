extends Control

@onready var reason_label = $Panel/VBoxContainer/ReasonLabel
@onready var restart_button = $Panel/VBoxContainer/RestartButton

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Show even if game paused
	
	if QuotaManager:
		QuotaManager.run_ended.connect(_on_run_ended)
	
	restart_button.pressed.connect(_on_restart_pressed)

func _on_run_ended(reason):
	reason_label.text = "RUN ENDED\n" + reason
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if QuotaManager:
		QuotaManager.start_new_run()
		# Reload scene to reset everything properly?
		# Or just partial reset? Reload is safer for roguelikes.
		get_tree().reload_current_scene()
