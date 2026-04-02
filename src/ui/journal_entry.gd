extends Control

@onready var icon_texture: TextureRect = $Panel/Icon
@onready var name_label: Label = $Panel/Name
@onready var stats_label: Label = $Panel/Stats
@onready var new_badge: Control = $Panel/NewBadge

var current_fish_id: String = ""
var current_fish_res = null

func setup(fish_res, journal_data: Dictionary):
	current_fish_res = fish_res
	current_fish_id = fish_res.id
	
	name_label.text = "???"
	stats_label.text = "Caught: 0\nMax: 0.0 kg"
	icon_texture.modulate = Color(0, 0, 0, 0.5) # Silhouette
	new_badge.hide()
	
	if journal_data.get("is_discovered", false):
		name_label.text = fish_res.name
		icon_texture.texture = fish_res.icon
		icon_texture.modulate = Color(1, 1, 1, 1)
		
		var count = journal_data.get("caught_count", 0)
		var max_w = journal_data.get("max_weight", 0.0)
		stats_label.text = "Caught: %d\nMax: %.2f kg" % [count, max_w]
	else:
		# Undiscovered, maybe partial hint?
		if fish_res.icon:
			icon_texture.texture = fish_res.icon
			# Keep silhouette
