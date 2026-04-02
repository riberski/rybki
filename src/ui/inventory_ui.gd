extends Control

@onready var container = $Panel/ScrollContainer/VBoxContainer
@onready var money_label = $Panel/MoneyLabel
@onready var close_button = $Panel/CloseButton

# Use global InventoryManager directly

func _ready():
	visible = false
	if close_button and not close_button.pressed.is_connected(hide_inventory):
		close_button.pressed.connect(hide_inventory)
	
	# Connect signals
	if InventoryManager:
		InventoryManager.inventory_updated.connect(update_ui)
		InventoryManager.money_updated.connect(update_money)
		update_money(InventoryManager.money)

func hide_inventory():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func show_inventory():
	visible = true
	if InventoryManager:
		update_money(InventoryManager.money)
		update_ui(null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_money(amount: int):
	money_label.text = "Money: $%d" % amount

func update_ui(fish: FishResource = null):
	if not InventoryManager: return
	
	# Clear list
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	# Header for Fish
	var fish_header = Label.new()
	fish_header.text = "--- Caught Fish ---"
	fish_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(fish_header)
	
	if InventoryManager.caught_fish.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "(Empty)"
		empty_lbl.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(empty_lbl)
	else:
		for i in range(InventoryManager.caught_fish.size()):
			var item = InventoryManager.caught_fish[i]
			var hbox = HBoxContainer.new()
			
			var label = Label.new()
			label.text = "%s ($%d)" % [item.name, int(item.value * InventoryManager.global_value_multiplier)]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(label)
			
			var sell_btn = Button.new()
			sell_btn.text = "Sell"
			sell_btn.pressed.connect(InventoryManager.sell_fish.bind(i))
			hbox.add_child(sell_btn)
			
			container.add_child(hbox)
			
	# Separator
	container.add_child(HSeparator.new())
	
	# Relics Section
	var relic_header = Label.new()
	relic_header.text = "--- Active Relics ---"
	relic_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(relic_header)
	
	if InventoryManager.active_relics.is_empty():
		var no_relics = Label.new()
		no_relics.text = "(None)"
		no_relics.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(no_relics)
	else:
		for relic in InventoryManager.active_relics:
			var r_lbl = Label.new()
			var r_name = relic.get("name", "Unknown Relic")
			var r_desc = relic.get("desc", "")
			r_lbl.text = "• %s" % r_name
			r_lbl.tooltip_text = r_desc
			if relic.get("rarity") == "cursed":
				r_lbl.modulate = Color(0.8, 0.2, 0.8)
			container.add_child(r_lbl)


