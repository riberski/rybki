extends Control

@onready var label = $Panel/Label

func _ready():
	InventoryManager.bait_changed.connect(_on_bait_changed)
	InventoryManager.bait_quantity_changed.connect(_on_bait_quantity_changed)
	
	# Initial update
	update_label()

func _on_bait_changed(_bait_id):
	update_label()
	
func _on_bait_quantity_changed(bait_id, _count):
	if bait_id == InventoryManager.current_bait_id:
		update_label()

func update_label():
	var bait_id = InventoryManager.current_bait_id
	var count = InventoryManager.bait_inventory.get(bait_id, 0)
	var bait_name = "Unknown"
	
	var info = BaitDatabase.get_bait(bait_id)
	if info:
		bait_name = info.name
	
	label.text = "%s: %d" % [bait_name, count]
