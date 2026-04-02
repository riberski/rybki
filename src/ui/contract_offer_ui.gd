extends Control

@export var pause_tree := true

@onready var title_label: Label = $Panel/VBox/Title
@onready var description_label: Label = $Panel/VBox/Description
@onready var target_label: Label = $Panel/VBox/Target
@onready var difficulty_label: Label = $Panel/VBox/Difficulty
@onready var reward_label: Label = $Panel/VBox/Reward
@onready var speed_label: Label = $Panel/VBox/Speed
@onready var accept_button: Button = $Panel/VBox/Buttons/AcceptButton
@onready var decline_button: Button = $Panel/VBox/Buttons/DeclineButton

var _was_paused := false

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if accept_button and not accept_button.pressed.is_connected(_on_accept_pressed):
		accept_button.pressed.connect(_on_accept_pressed)
	if decline_button and not decline_button.pressed.is_connected(_on_decline_pressed):
		decline_button.pressed.connect(_on_decline_pressed)
	if QuestManager and not QuestManager.contract_offer_updated.is_connected(_on_offer_updated):
		QuestManager.contract_offer_updated.connect(_on_offer_updated)
	_update_ui(QuestManager.contract_offer if QuestManager else {})

func show_offer(offer: Dictionary = {}) -> void:
	var data = offer
	if data.is_empty() and QuestManager:
		data = QuestManager.contract_offer
	_update_ui(data)
	_show_modal()

func _show_modal() -> void:
	_was_paused = get_tree().paused
	if pause_tree:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func _hide_modal() -> void:
	hide()
	if pause_tree:
		get_tree().paused = _was_paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_accept_pressed() -> void:
	if QuestManager:
		QuestManager.accept_contract()
	_hide_modal()

func _on_decline_pressed() -> void:
	_hide_modal()

func _on_offer_updated(offer: Dictionary) -> void:
	if visible:
		_update_ui(offer)

func _update_ui(offer: Dictionary) -> void:
	if offer.is_empty():
		title_label.text = "Brak kontraktu"
		description_label.text = "Brak ofert. Wroc pozniej."
		target_label.text = "Cel: --"
		difficulty_label.text = "Trudnosc: --"
		reward_label.text = "Nagroda: --"
		speed_label.text = "Tempo ryb: --"
		accept_button.disabled = true
		return

	title_label.text = "Oferta kontraktu"
	description_label.text = offer.get("description", "Kontrakt")
	var target = int(offer.get("target_amount", 0))
	var difficulty = float(offer.get("difficulty", 1.0))
	var reward = int(offer.get("reward_money", 0))
	var speed = float(offer.get("fish_speed_multiplier", 1.0))
	target_label.text = "Cel: $%d" % target
	difficulty_label.text = "Trudnosc: %.1f" % difficulty
	reward_label.text = "Nagroda: $%d" % reward
	speed_label.text = "Tempo ryb: x%.2f" % speed
	accept_button.disabled = false
