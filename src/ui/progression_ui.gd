extends Control

# ProgressionUI.gd
# UI do kupowania ulepszeń meta-progresji

@onready var upgrades_list = $Margin/UpgradesList

var progression_manager = null

func _ready():
	progression_manager = get_node("/root/ProgressionManager")
	refresh_upgrades()

func refresh_upgrades():
	for child in upgrades_list.get_children():
		child.queue_free()
	for upgrade_id in progression_manager.upgrades.keys():
		var upgrade = progression_manager.upgrades[upgrade_id]
		var btn = Button.new()
		btn.text = "%s (%d)" % [upgrade_id, upgrade["cost"]]
		btn.disabled = upgrade["owned"]
		btn.pressed.connect(Callable(self, "_on_upgrade_pressed").bind(upgrade_id))
		upgrades_list.add_child(btn)

func _on_upgrade_pressed(upgrade_id):
	# Tu można dodać sprawdzenie czy gracz ma wystarczająco pieniędzy
	progression_manager.unlock_upgrade(upgrade_id)
	refresh_upgrades()
