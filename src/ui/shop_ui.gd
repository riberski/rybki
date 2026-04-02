extends Control

@onready var panel = $Panel
@onready var money_label = $Panel/MoneyLabel
@onready var rod_btn = $Panel/VBoxContainer/RodUpgrade.get_node("BuyButton")
@onready var rod_label = $Panel/VBoxContainer/RodUpgrade.get_node("Label")
@onready var rod_cost_label = $Panel/VBoxContainer/RodUpgrade.get_node("CostLabel")

@onready var boat_btn = $Panel/VBoxContainer/BoatUpgrade.get_node("BuyButton")
@onready var boat_label = $Panel/VBoxContainer/BoatUpgrade.get_node("Label")
@onready var boat_cost_label = $Panel/VBoxContainer/BoatUpgrade.get_node("CostLabel")

@onready var close_btn = $Panel/CloseButton
@onready var baits_container = $Panel/VBoxContainer/BaitsContainer

var sell_all_btn: Button
var early_return_btn: Button
var early_return_wait_label: Label
var _early_return_connected = false
var _last_wait_update: int = -1

func _ready():
	var vbox = $Panel/VBoxContainer
	
	# Get early return button safely
	early_return_btn = get_node_or_null("Panel/VBoxContainer/EarlyReturnContainer/EarlyReturnButton")
	
	# Create Sell Button Dynamically
	sell_all_btn = Button.new()
	sell_all_btn.custom_minimum_size = Vector2(0, 40)
	sell_all_btn.pressed.connect(_on_sell_all_pressed)
	vbox.add_child(HSeparator.new())
	vbox.add_child(sell_all_btn)
	
	# Connect signals
	rod_btn.pressed.connect(_on_rod_upgrade_pressed)
	boat_btn.pressed.connect(_on_boat_upgrade_pressed)
	close_btn.pressed.connect(hide_shop)
	_try_connect_early_return()
	
	InventoryManager.money_updated.connect(_on_money_updated)
	InventoryManager.upgrade_purchased.connect(_on_upgrade_purchased)
	InventoryManager.bait_quantity_changed.connect(_on_bait_quantity_changed)
	InventoryManager.inventory_updated.connect(func(x): update_ui())
	
	populate_baits()
	update_ui()
	hide()

func _try_connect_early_return():
	if _early_return_connected:
		return
	
	# Try different methods to find button
	if not early_return_btn:
		early_return_btn = get_node_or_null("Panel/VBoxContainer/EarlyReturnContainer/EarlyReturnButton")
	
	if not early_return_btn:
		early_return_btn = find_child("EarlyReturnButton", true, false)
	
	# Find wait label
	if not early_return_wait_label:
		early_return_wait_label = get_node_or_null("Panel/VBoxContainer/EarlyReturnContainer/EarlyReturnWaitLabel")
	
	if not early_return_wait_label:
		early_return_wait_label = find_child("EarlyReturnWaitLabel", true, false)
	
	if early_return_btn and not _early_return_connected:
		early_return_btn.pressed.connect(_on_early_return_pressed)
		_early_return_connected = true

func _process(_delta):
	# Failsafe: try to connect button if not connected yet
	if not _early_return_connected:
		_try_connect_early_return()
	
	# Update early return timer if shop is visible
	if visible and early_return_btn:
		_update_early_return_ui()

func _format_seconds(total_seconds: int) -> String:
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	return "%d:%02d" % [minutes, seconds]

func _update_early_return_ui() -> void:
	early_return_btn.disabled = true
	if TimeManager and TimeManager.extraction_active:
		if early_return_wait_label:
			early_return_wait_label.text = "Wroc przez strefe ekstrakcji"
	else:
		if early_return_wait_label:
			early_return_wait_label.text = "Brak aktywnej wyprawy"

func _on_money_updated(amount):
	update_ui() # Refresh buttons state

func _on_upgrade_purchased(upgrade_name, level):
	update_ui()
	
func _on_bait_quantity_changed(bait_id, count):
	# Find row and update "Own" label
	var row = baits_container.get_node_or_null(bait_id)
	if row:
		var lbl = row.get_node("OwnLabel")
		if lbl: lbl.text = "Own: " + str(count)
	update_ui() # To update buttons disabled state

func update_ui():
	money_label.text = "Money: $" + str(InventoryManager.money)
	
	var rod_cost = InventoryManager.get_rod_upgrade_cost()
	rod_label.text = "Better Rod (Lvl " + str(InventoryManager.rod_level) + ")"
	rod_cost_label.text = "$" + str(rod_cost)
	rod_btn.disabled = not InventoryManager.can_afford(rod_cost)
	
	var boat_cost = InventoryManager.get_boat_upgrade_cost()
	boat_label.text = "Faster Boat (Lvl " + str(InventoryManager.boat_speed_level) + ")"
	boat_cost_label.text = "$" + str(boat_cost)
	boat_btn.disabled = not InventoryManager.can_afford(boat_cost)
	
	# Update Sell Button
	if sell_all_btn:
		var fish_count = InventoryManager.caught_fish.size()
		var total_val = 0
		for f in InventoryManager.caught_fish:
			total_val += int(f.value * InventoryManager.global_value_multiplier)
		
		if fish_count > 0:
			sell_all_btn.text = "SELL ALL FISH (%d) - $%d" % [fish_count, total_val]
			sell_all_btn.disabled = false
			sell_all_btn.modulate = Color(0.5, 1.0, 0.5) # Greenish
		else:
			sell_all_btn.text = "No Fish to Sell"
			sell_all_btn.disabled = true
			sell_all_btn.modulate = Color(0.7, 0.7, 0.7) # Grey

	# Update bait buttons
	for bait_id in BaitDatabase.baits.keys():
		var row = baits_container.get_node_or_null(bait_id)
		if row:
			var info = BaitDatabase.get_bait(bait_id)
			var total_cost = info.price * 5
			var btn = row.get_child(2) # Button is 3rd child
			if btn:
				btn.disabled = not InventoryManager.can_afford(total_cost)

func populate_baits():
	# Clear existing
	for child in baits_container.get_children():
		child.queue_free()

	for bait_id in BaitDatabase.baits.keys():
		# SKIP BREAD - It is a limited daily resource, cannot be bought!
		if bait_id == "bread": continue
		
		var bait_info = BaitDatabase.get_bait(bait_id)
		if not bait_info: continue
		
		var current_price = bait_info.price
		if InventoryManager.shop_discount > 0:
			current_price = int(float(current_price) * (1.0 - InventoryManager.shop_discount))
			current_price = max(1, current_price)
		
		var row = HBoxContainer.new()
		row.name = bait_id # Useful for updates
		
		var label = Label.new()
		label.text = "%s ($%d)" % [bait_info.name, current_price]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		
		var own_label = Label.new()
		own_label.name = "OwnLabel"
		own_label.text = "Own: " + str(InventoryManager.get_bait_count(bait_id))
		row.add_child(own_label)
		
		var buy_btn = Button.new()
		buy_btn.text = "Buy (x5)"
		buy_btn.pressed.connect(func(): InventoryManager.buy_bait(bait_id, 5, current_price))
		row.add_child(buy_btn)
		
		baits_container.add_child(row)

func show_shop():
	_try_connect_early_return()
	update_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_shop():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _return_to_lobby() -> void:
	if InventoryManager:
		InventoryManager.save_game()
	if TimeManager and TimeManager.extraction_active:
		TimeManager.finish_extraction("abandon")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().call_deferred("change_scene_to_file", "res://src/ui/lobby_world.tscn")

func _on_sell_all_pressed():
	if not InventoryManager.caught_fish.is_empty():
		InventoryManager.sell_all_fish()
		update_ui()

func _on_rod_upgrade_pressed():
	InventoryManager.upgrade_rod()

func _on_boat_upgrade_pressed():
	InventoryManager.upgrade_boat_speed()

func _on_early_return_pressed():
	if early_return_wait_label:
		early_return_wait_label.text = "Uzyj strefy ekstrakcji na mapie"
