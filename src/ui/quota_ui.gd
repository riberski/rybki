extends Control

@onready var money_label = $Panel/VBoxContainer/MoneyLabel
@onready var hull_label = $Panel/VBoxContainer/HullLabel
@onready var hull_bar = $Panel/VBoxContainer/HullBar
@onready var vbox = $Panel/VBoxContainer

var quota_label: Label
var quota_bar: ProgressBar
var _quota_target: int = 1

func _ready():
	_ensure_quota_widgets()
	if hull_label:
		hull_label.hide()
	if hull_bar:
		hull_bar.hide()

	if QuotaManager:
		if not QuotaManager.hull_updated.is_connected(_update_hull):
			QuotaManager.hull_updated.connect(_update_hull)
		if not QuotaManager.quota_updated.is_connected(_update_quota):
			QuotaManager.quota_updated.connect(_update_quota)
	
	if InventoryManager:
		if not InventoryManager.money_updated.is_connected(_update_money):
			InventoryManager.money_updated.connect(_update_money)
	
	# Initial
	if QuotaManager:
		_update_hull(QuotaManager.hull_integrity, QuotaManager.max_hull)
		_update_quota(InventoryManager.money if InventoryManager else 0, QuotaManager.quota_target)
	if InventoryManager:
		_update_money(InventoryManager.money)

func _ensure_quota_widgets():
	if not vbox:
		return

	quota_label = vbox.get_node_or_null("QuotaLabel")
	quota_bar = vbox.get_node_or_null("QuotaBar")

	if not quota_label:
		vbox.add_child(HSeparator.new())
		quota_label = Label.new()
		quota_label.name = "QuotaLabel"
		quota_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quota_label.text = "Quota: $0 / $0"
		vbox.add_child(quota_label)

	if not quota_bar:
		quota_bar = ProgressBar.new()
		quota_bar.name = "QuotaBar"
		quota_bar.step = 1.0
		quota_bar.show_percentage = false
		quota_bar.max_value = 1.0
		quota_bar.value = 0.0
		vbox.add_child(quota_bar)

func _update_hull(current, max_val):
	if hull_label:
		hull_label.hide()
	if hull_bar:
		hull_bar.hide()

func _update_money(amount: int):
	if money_label:
		money_label.text = "$%d" % amount
	_update_quota(amount, _quota_target)

func _update_quota(current: int, target: int):
	_quota_target = max(1, target)

	if quota_label:
		quota_label.text = "Quota: $%d / $%d" % [current, target]
		if current >= target:
			quota_label.modulate = Color(0.65, 1.0, 0.65)
		else:
			quota_label.modulate = Color(1.0, 0.85, 0.55)

	if quota_bar:
		quota_bar.max_value = float(_quota_target)
		quota_bar.value = float(clamp(current, 0, _quota_target))
		if current >= target:
			quota_bar.modulate = Color(0.45, 1.0, 0.45)
		else:
			quota_bar.modulate = Color(1.0, 0.75, 0.35)
