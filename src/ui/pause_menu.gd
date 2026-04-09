extends Control

@onready var resume_btn = $Panel/MarginContainer/HBoxContainer/LeftColumn/Buttons/ResumeButton
@onready var quit_btn = $Panel/MarginContainer/HBoxContainer/LeftColumn/Buttons/QuitButton
@onready var resolution_option: OptionButton = $Panel/MarginContainer/HBoxContainer/LeftColumn/Buttons/ResolutionRow/ResolutionOption
@onready var run_info_label = $Panel/MarginContainer/HBoxContainer/LeftColumn/RunInfoLabel
@onready var relic_list = $Panel/MarginContainer/HBoxContainer/RightColumn/ScrollContainer/RelicList

const RESOLUTION_OPTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Essential for pause menu!
	hide()
	resume_btn.pressed.connect(hide_menu)
	quit_btn.pressed.connect(_on_quit_pressed)
	_setup_resolution_options()

func _unhandled_input(event):
	if event.is_action_pressed("pause"): # Escape
		if visible:
			hide_menu()
		else:
			show_menu()
			get_viewport().set_input_as_handled()

func show_menu():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_update_run_info()
	_update_relic_list()
	_sync_resolution_selection()

func hide_menu():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _on_quit_pressed():
	get_tree().paused = false # Unpause before changing scene!
	# Optionally save game here?
	if InventoryManager: InventoryManager.save_game()
	if TimeManager and TimeManager.extraction_active:
		TimeManager.finish_extraction("abandon")
	
	get_tree().change_scene_to_file("res://src/ui/lobby_world.tscn")

func _update_run_info():
	var text = "[b]RUN STATUS:[/b]\n"
	text += "\n"
	
	# Global Stats
	if InventoryManager:
		text += "[b]Stats:[/b]\n"
		text += "Value Multiplier: x%.2f\n" % InventoryManager.global_value_multiplier
		
	run_info_label.text = text

func _update_relic_list():
	# Clear existing
	for child in relic_list.get_children():
		child.queue_free()
		
	if InventoryManager and InventoryManager.active_relics.size() > 0:
		for relic in InventoryManager.active_relics:
			var item = VBoxContainer.new()
			var name_label = Label.new()
			var desc_label = Label.new()
			
			name_label.text = relic["name"]
			if relic.get("rarity") == "cursed":
				name_label.add_theme_color_override("font_color", Color(0.8, 0, 0.8)) # Purple
			else:
				name_label.add_theme_color_override("font_color", Color.GOLD) # Gold
				
			desc_label.text = relic["desc"]
			desc_label.add_theme_font_size_override("font_size", 12)
			
			item.add_child(name_label)
			item.add_child(desc_label)
			item.add_theme_constant_override("separation", 2)
			
			relic_list.add_child(item)
			relic_list.add_child(HSeparator.new())
	else:
		var empty_label = Label.new()
		empty_label.text = "No Relics yet."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color(1, 1, 1, 0.5)
		relic_list.add_child(empty_label)

func _setup_resolution_options() -> void:
	if not resolution_option:
		return
	resolution_option.clear()
	for res in RESOLUTION_OPTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])
	resolution_option.item_selected.connect(_on_resolution_selected)
	_sync_resolution_selection()

func _sync_resolution_selection() -> void:
	if not resolution_option:
		return
	var current = DisplayServer.window_get_size()
	var best_index = 0
	var best_delta = INF
	for i in range(RESOLUTION_OPTIONS.size()):
		var res = RESOLUTION_OPTIONS[i]
		var delta = abs(res.x - current.x) + abs(res.y - current.y)
		if delta < best_delta:
			best_delta = delta
			best_index = i
	resolution_option.select(best_index)

func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTION_OPTIONS.size():
		return
	var size = RESOLUTION_OPTIONS[index]
	DisplayServer.window_set_size(size)

# Duplicate function removed
