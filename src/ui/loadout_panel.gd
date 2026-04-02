extends Control

@onready var relic_slot_buttons: Array = [
	$Panel/Margin/Root/RelicSlots/RelicSlot1,
	$Panel/Margin/Root/RelicSlots/RelicSlot2,
	$Panel/Margin/Root/RelicSlots/RelicSlot3,
	$Panel/Margin/Root/RelicSlots/RelicSlot4
]
@onready var upgrade_stat_buttons: Array = [
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot1/UpgradeStat1,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot2/UpgradeStat2,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot3/UpgradeStat3,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot4/UpgradeStat4
]
@onready var upgrade_level_labels: Array = [
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot1/UpgradeLevel1,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot2/UpgradeLevel2,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot3/UpgradeLevel3,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot4/UpgradeLevel4
]
@onready var upgrade_buttons: Array = [
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot1/UpgradeButton1,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot2/UpgradeButton2,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot3/UpgradeButton3,
	$Panel/Margin/Root/UpgradeSlots/UpgradeSlot4/UpgradeButton4
]
@onready var close_button: Button = $Panel/Margin/Root/CloseButton

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_loadout_ui()
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if InventoryManager:
		if not InventoryManager.boat_changed.is_connected(_on_boat_changed):
			InventoryManager.boat_changed.connect(_on_boat_changed)
		if not InventoryManager.money_updated.is_connected(_on_money_updated):
			InventoryManager.money_updated.connect(_on_money_updated)

func show_panel() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_loadout_ui()

func _on_close_pressed() -> void:
	hide()

func _on_boat_changed(_boat_id: String) -> void:
	_refresh_loadout_ui()

func _on_money_updated(_amount: int) -> void:
	_refresh_loadout_ui()

func _setup_loadout_ui() -> void:
	if not InventoryManager:
		return
	for i in range(relic_slot_buttons.size()):
		var btn = relic_slot_buttons[i]
		btn.clear()
		btn.add_item("(pusto)", 0)
		var index = 1
		for relic in RelicDatabase.all_relics:
			btn.add_item(relic.get("name", "Relic"), index)
			btn.set_item_metadata(index, relic.get("id", ""))
			index += 1
		if not btn.item_selected.is_connected(_on_relic_slot_selected):
			btn.item_selected.connect(_on_relic_slot_selected.bind(i))
	for i in range(upgrade_stat_buttons.size()):
		var stat_btn = upgrade_stat_buttons[i]
		stat_btn.clear()
		stat_btn.add_item("(pusto)", 0)
		var stat_index = 1
		for stat_id in InventoryManager.boat_upgrade_types:
			stat_btn.add_item(stat_id, stat_index)
			stat_btn.set_item_metadata(stat_index, stat_id)
			stat_index += 1
		if not stat_btn.item_selected.is_connected(_on_upgrade_stat_selected):
			stat_btn.item_selected.connect(_on_upgrade_stat_selected.bind(i))
		var upgrade_btn = upgrade_buttons[i]
		if not upgrade_btn.pressed.is_connected(_on_upgrade_stat_pressed):
			upgrade_btn.pressed.connect(_on_upgrade_stat_pressed.bind(i))
	_refresh_loadout_ui()

func _refresh_loadout_ui() -> void:
	if not InventoryManager:
		return
	var loadout = InventoryManager.get_boat_loadout(InventoryManager.current_boat_id)
	var relics = loadout.get("relics", [])
	for i in range(relic_slot_buttons.size()):
		var relic_id = relics[i] if i < relics.size() else ""
		var btn = relic_slot_buttons[i]
		var selected_index = 0
		for idx in range(1, btn.get_item_count()):
			if btn.get_item_metadata(idx) == relic_id:
				selected_index = idx
				break
		btn.select(selected_index)
		btn.tooltip_text = relic_id
	var upgrades = loadout.get("upgrades", [])
	for i in range(upgrade_stat_buttons.size()):
		var upgrade = upgrades[i] if i < upgrades.size() else {"stat_id": "", "level": 0}
		var stat_id = upgrade.get("stat_id", "")
		var level = int(upgrade.get("level", 0))
		var stat_btn = upgrade_stat_buttons[i]
		var selected = 0
		for idx in range(1, stat_btn.get_item_count()):
			if stat_btn.get_item_metadata(idx) == stat_id:
				selected = idx
				break
		stat_btn.select(selected)
		upgrade_level_labels[i].text = "Lv %d" % level
		var cost = InventoryManager.get_boat_stat_upgrade_cost(level)
		upgrade_buttons[i].text = "+ ($%d)" % cost
		upgrade_buttons[i].disabled = stat_id == "" or not InventoryManager.can_afford(cost)

func _on_relic_slot_selected(index: int, slot_index: int) -> void:
	if not InventoryManager:
		return
	var btn = relic_slot_buttons[slot_index]
	var relic_id = ""
	if index > 0:
		relic_id = str(btn.get_item_metadata(index))
	InventoryManager.set_boat_relic_slot(InventoryManager.current_boat_id, slot_index, relic_id)
	_refresh_loadout_ui()

func _on_upgrade_stat_selected(index: int, slot_index: int) -> void:
	if not InventoryManager:
		return
	var btn = upgrade_stat_buttons[slot_index]
	var stat_id = ""
	if index > 0:
		stat_id = str(btn.get_item_metadata(index))
	InventoryManager.set_boat_upgrade_slot(InventoryManager.current_boat_id, slot_index, stat_id)
	_refresh_loadout_ui()

func _on_upgrade_stat_pressed(slot_index: int) -> void:
	if not InventoryManager:
		return
	if InventoryManager.upgrade_boat_stat(InventoryManager.current_boat_id, slot_index):
		_refresh_loadout_ui()
