extends Control

@onready var time_label: Label = $Panel/TimeLabel
@onready var extraction_label: Label = $Panel/ExtractionLabel
@onready var early_return_button: Button = get_node_or_null("Panel/EarlyReturnButton")

func _ready():
	if TimeManager:
		TimeManager.time_tick.connect(update_time_display)
		TimeManager.extraction_time_changed.connect(_on_extraction_time_changed)
		TimeManager.extraction_finished.connect(_on_extraction_finished)
		# Initial update
		update_time_display(TimeManager.current_time)
		if TimeManager.extraction_active:
			_on_extraction_time_changed(int(ceil(TimeManager.extraction_remaining_seconds)), TimeManager.extraction_duration_seconds)
		else:
			if extraction_label:
				extraction_label.hide()
			if early_return_button:
				early_return_button.hide()

func update_time_display(current_time: float):
	if time_label:
		time_label.text = TimeManager.get_time_string()
		
		# Optional: Change color for night?
		if TimeManager.is_night():
			time_label.modulate = Color(0.5, 0.5, 1.0) # Blue-ish for night
		else:
			time_label.modulate = Color.WHITE

func _on_extraction_time_changed(remaining_seconds: int, _total_seconds: int) -> void:
	var minutes = remaining_seconds / 60
	var seconds = remaining_seconds % 60
	extraction_label.text = "Ekstrakcja: %02d:%02d" % [minutes, seconds]
	if extraction_label:
		extraction_label.show()
	if early_return_button:
		early_return_button.hide()

func _on_extraction_finished(_reason: String) -> void:
	if extraction_label:
		extraction_label.hide()
	if early_return_button:
		early_return_button.hide()
		early_return_button.disabled = false
		early_return_button.text = "Wroc wczesnie"
