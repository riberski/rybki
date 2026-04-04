extends Control

@onready var time_label: Label = $Panel/Margin/VBox/TimeLabel
@onready var extraction_label: Label = $Panel/Margin/VBox/ExtractionLabel
@onready var risk_label: Label = $Panel/Margin/VBox/RiskLabel
@onready var durability_label: Label = $Panel/Margin/VBox/DurabilityLabel
@onready var early_return_button: Button = get_node_or_null("Panel/EarlyReturnButton")

var _latest_risk: float = 0.0
var _latest_durability_ratio: float = 1.0

func _ready():
	if TimeManager:
		TimeManager.time_tick.connect(update_time_display)
		TimeManager.extraction_time_changed.connect(_on_extraction_time_changed)
		TimeManager.extraction_finished.connect(_on_extraction_finished)
		if not TimeManager.extraction_started.is_connected(_on_extraction_started):
			TimeManager.extraction_started.connect(_on_extraction_started)
		# Initial update
		update_time_display(TimeManager.current_time)
		if TimeManager.extraction_active:
			_on_extraction_time_changed(int(ceil(TimeManager.extraction_remaining_seconds)), TimeManager.extraction_duration_seconds)
		else:
			if extraction_label:
				extraction_label.hide()
			if early_return_button:
				early_return_button.hide()

	if RiskManager and not RiskManager.risk_changed.is_connected(_on_risk_changed):
		RiskManager.risk_changed.connect(_on_risk_changed)

	if InventoryManager and not InventoryManager.boat_durability_changed.is_connected(_on_boat_durability_changed):
		InventoryManager.boat_durability_changed.connect(_on_boat_durability_changed)

	_update_risk_label(0.0)
	if InventoryManager:
		_on_boat_durability_changed(InventoryManager.boat_durability, InventoryManager.boat_durability_max)
	else:
		_update_durability_label(1.0)

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
	_update_risk_label(0.0)

func _on_extraction_started(_total_seconds: int) -> void:
	_update_risk_label(0.0)
	if InventoryManager:
		_on_boat_durability_changed(InventoryManager.boat_durability, InventoryManager.boat_durability_max)

func _on_risk_changed(risk_level: float, _components: Dictionary) -> void:
	_update_risk_label(risk_level)

func _on_boat_durability_changed(current: float, max_value: float) -> void:
	var ratio := 1.0
	if max_value > 0.0:
		ratio = clamp(current / max_value, 0.0, 1.0)
	_update_durability_label(ratio)

func _update_risk_label(risk_level: float) -> void:
	_latest_risk = clamp(risk_level, 0.0, 100.0)
	if not risk_label:
		return
	risk_label.text = "Ryzyko: %d%%" % int(round(_latest_risk))
	if _latest_risk < 35.0:
		risk_label.modulate = Color(0.55, 1.0, 0.55)
	elif _latest_risk < 70.0:
		risk_label.modulate = Color(1.0, 0.85, 0.35)
	else:
		risk_label.modulate = Color(1.0, 0.45, 0.45)

func _update_durability_label(ratio: float) -> void:
	_latest_durability_ratio = clamp(ratio, 0.0, 1.0)
	if not durability_label:
		return
	var percent := int(round(_latest_durability_ratio * 100.0))
	durability_label.text = "Kadlub: %d%%" % percent
	if _latest_durability_ratio >= 0.6:
		durability_label.modulate = Color(0.6, 1.0, 0.65)
	elif _latest_durability_ratio >= 0.3:
		durability_label.modulate = Color(1.0, 0.78, 0.32)
	else:
		durability_label.modulate = Color(1.0, 0.42, 0.42)
