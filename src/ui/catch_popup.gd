extends Control

signal popup_closed
signal keep_fish(fish: FishResource)

@onready var fish_name_label = $Panel/FishNameLabel
@onready var fish_desc_label = $Panel/FishDescriptionLabel
@onready var stats_label = $Panel/StatsLabel
@onready var close_button = $Panel/CloseButton

var current_fish: FishResource

func _ready():
	visible = false

func show_fish(fish: FishResource):
	current_fish = fish
	fish_name_label.text = fish.name
	fish_desc_label.text = fish.description
	stats_label.text = "Weight: %.1f kg | Value: $%d" % [fish.base_weight, fish.value]
	visible = true
	# Block mouse input to main game potentially? Or just grab focus
	close_button.grab_focus()

func _on_close_button_pressed():
	visible = false
	if current_fish:
		emit_signal("keep_fish", current_fish)
	emit_signal("popup_closed")
