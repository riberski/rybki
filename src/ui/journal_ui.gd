extends Control

@onready var grid_container: GridContainer = $ColorRect/ScrollContainer/GridContainer
@onready var entry_scene: PackedScene = preload("res://src/ui/journal_entry.tscn")

func _ready():
	_refresh_journal()
	JournalManager.journal_updated.connect(_on_entry_updated)
	JournalManager.new_species_caught.connect(_on_entry_updated)

func _refresh_journal():
	# Clear existing
	for child in grid_container.get_children():
		child.queue_free()
		
	# Get all possible fish
	var all_fish = FishDatabase.get_all_fish()
	
	for fish in all_fish:
		var entry = entry_scene.instantiate()
		grid_container.add_child(entry)
		
		# Get saved data
		var data = JournalManager.get_entry(fish.id) # Assuming fish resource has 'id'
		entry.setup(fish, data)

func _on_entry_updated(fish_id, _data):
	# Ideally update just the one, but for simplicity call refresh or update methods on children
	# Let's iterate children and find the matching one
	for child in grid_container.get_children():
		if child.current_fish_id == fish_id:
			child.setup(child.current_fish_res, JournalManager.get_entry(fish_id))
			return

func show_journal():
	_refresh_journal()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_journal():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
