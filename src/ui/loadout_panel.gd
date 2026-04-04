extends Control

@onready var relic_slot_buttons: Array = [
	$Panel/Margin/Root/RelicSlots/RelicSlot1,
	$Panel/Margin/Root/RelicSlots/RelicSlot2,
	$Panel/Margin/Root/RelicSlots/RelicSlot3,
	$Panel/Margin/Root/RelicSlots/RelicSlot4
]
@onready var module_slot_labels: Array = [
	$Panel/Margin/Root/ModuleSlots/ModuleSlot1/ModuleLabel1,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot2/ModuleLabel2,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot3/ModuleLabel3,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot4/ModuleLabel4,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot5/ModuleLabel5
]
@onready var module_slot_buttons: Array = [
	$Panel/Margin/Root/ModuleSlots/ModuleSlot1/ModuleOption1,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot2/ModuleOption2,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot3/ModuleOption3,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot4/ModuleOption4,
	$Panel/Margin/Root/ModuleSlots/ModuleSlot5/ModuleOption5
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

const MODULE_SLOT_IDS: Array[String] = ["engine_slot", "sonar_slot", "utility_slot_1", "utility_slot_2", "special_slot"]

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
	var owned_charms: Array[String] = InventoryManager.get_owned_charms()
	for i in range(relic_slot_buttons.size()):
		var btn = relic_slot_buttons[i]
		btn.clear()
		btn.add_item("(pusto)", 0)
		var index: int = 1
		for charm_id in owned_charms:
			var relic: Dictionary = RelicDatabase.get_relic_by_id(charm_id)
			btn.add_item(str(relic.get("name", charm_id)), index)
			btn.set_item_metadata(index, charm_id)
			index += 1
		if not btn.item_selected.is_connected(_on_relic_slot_selected):
			btn.item_selected.connect(_on_relic_slot_selected.bind(i))

	for i in range(module_slot_buttons.size()):
		var slot_id: String = MODULE_SLOT_IDS[i]
		if i < module_slot_labels.size():
			var slot_label: Label = module_slot_labels[i]
			slot_label.text = InventoryManager.get_boat_module_slot_label(slot_id)
		var module_btn: OptionButton = module_slot_buttons[i]
		module_btn.clear()
		module_btn.add_item("(pusto)", 0)
		module_btn.set_item_metadata(0, "")
		var module_options: Array = InventoryManager.get_boat_module_options(slot_id)
		var module_index := 1
		for module_id in module_options:
			module_btn.add_item(InventoryManager.get_boat_module_display_name(module_id), module_index)
			module_btn.set_item_metadata(module_index, module_id)
			module_index += 1
		if not module_btn.item_selected.is_connected(_on_module_slot_selected):
			module_btn.item_selected.connect(_on_module_slot_selected.bind(i))

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

	for i in range(module_slot_buttons.size()):
		var slot_id: String = MODULE_SLOT_IDS[i]
		var module_id: String = InventoryManager.get_boat_module_slot(InventoryManager.current_boat_id, slot_id)
		var module_btn: OptionButton = module_slot_buttons[i]
		var selected_module_index := 0
		for idx in range(module_btn.get_item_count()):
			if str(module_btn.get_item_metadata(idx)) == module_id:
				selected_module_index = idx
				break
		module_btn.select(selected_module_index)
		module_btn.tooltip_text = InventoryManager.get_boat_module_description(module_id)

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

func _on_module_slot_selected(index: int, slot_index: int) -> void:
	if not InventoryManager:
		return
	var slot_id: String = MODULE_SLOT_IDS[slot_index]
	var module_btn: OptionButton = module_slot_buttons[slot_index]
	var module_id := ""
	if index > 0:
		module_id = str(module_btn.get_item_metadata(index))
	InventoryManager.set_boat_module_slot(InventoryManager.current_boat_id, slot_id, module_id)
	_setup_loadout_ui()
