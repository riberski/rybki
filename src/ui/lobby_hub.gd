extends Control

@onready var money_value: Label = $Margin/Root/LeftPanel/Stats/MoneyRow/MoneyValue
@onready var board_background: ColorRect = $Background
@onready var board_margin: Control = $Margin
@onready var bottom_bar: Control = $BottomBar
@onready var left_panel: PanelContainer = $Margin/Root/LeftPanel
@onready var right_panel: PanelContainer = $Margin/Root/RightPanel
@onready var title_label: Label = $Margin/Root/LeftPanel/Stats/Title
@onready var subtitle_label: Label = $Margin/Root/LeftPanel/Stats/Subtitle
@onready var bread_value: Label = $Margin/Root/LeftPanel/Stats/BreadRow/BreadValue
@onready var hull_value: Label = $Margin/Root/LeftPanel/Stats/HullRow/HullValue
@onready var fish_value: Label = $Margin/Root/LeftPanel/Stats/FishRow/FishValue
@onready var extraction_time_label: Label = $Margin/Root/RightPanel/Actions/ExtractionTimeLabel
@onready var pending_fish_label: Label = $Margin/Root/RightPanel/Actions/PendingFishLabel
@onready var claim_fish_button: Button = $Margin/Root/RightPanel/Actions/ClaimFishButton
@onready var buy_crate_button: Button = $Margin/Root/RightPanel/Actions/BuyCrateButton
@onready var contract_description: Label = $Margin/Root/RightPanel/Actions/ContractBox/ContractDescription
@onready var contract_risk: Label = $Margin/Root/RightPanel/Actions/ContractBox/ContractRisk
@onready var contract_reward: Label = $Margin/Root/RightPanel/Actions/ContractBox/ContractReward
@onready var contract_accept_button: Button = $Margin/Root/RightPanel/Actions/ContractBox/ContractAcceptButton
@onready var expedition_positive: Label = $Margin/Root/RightPanel/Actions/ExpeditionModifiers/ExpeditionPositive
@onready var expedition_negative: Label = $Margin/Root/RightPanel/Actions/ExpeditionModifiers/ExpeditionNegative
@onready var start_run_button: Button = $Margin/Root/RightPanel/Actions/StartRunButton
@onready var sell_all_button: Button = $Margin/Root/RightPanel/Actions/SellAllButton
@onready var return_menu_button: Button = $Margin/Root/RightPanel/Actions/ReturnMenuButton
@onready var boat_name_label: Label = $Margin/Root/RightPanel/Actions/BoatBox/BoatName
@onready var boat_select: OptionButton = $Margin/Root/RightPanel/Actions/BoatBox/BoatSelect
@onready var boat_preview_label: Label = $Margin/Root/RightPanel/Actions/BoatBox/BoatPreview
@onready var boat_credit_label: Label = $Margin/Root/RightPanel/Actions/BoatBox/BoatCredit
@onready var boat_earnings_label: Label = $Margin/Root/RightPanel/Actions/BoatBox/BoatEarnings
@onready var boat_next_label: Label = $Margin/Root/RightPanel/Actions/BoatBox/BoatNext
@onready var boat_buy_button: Button = $Margin/Root/RightPanel/Actions/BoatBox/BoatBuyButton
@onready var relic_slot_buttons: Array = [
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/RelicSlots/RelicSlot1,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/RelicSlots/RelicSlot2,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/RelicSlots/RelicSlot3,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/RelicSlots/RelicSlot4
]
@onready var roll_charm_button: Button = $Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/CharmRollRow/RollCharmButton
@onready var charm_status_label: Label = $Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/CharmStatus
@onready var upgrade_stat_buttons: Array = [
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot1/UpgradeStat1,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot2/UpgradeStat2,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot3/UpgradeStat3,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot4/UpgradeStat4
]
@onready var upgrade_level_labels: Array = [
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot1/UpgradeLevel1,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot2/UpgradeLevel2,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot3/UpgradeLevel3,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot4/UpgradeLevel4
]
@onready var upgrade_buttons: Array = [
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot1/UpgradeButton1,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot2/UpgradeButton2,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot3/UpgradeButton3,
	$Margin/Root/LeftPanel/MetaWidgets/BoatLoadout/BoatLoadoutBox/UpgradeSlots/UpgradeSlot4/UpgradeButton4
]
@onready var draft_ui: Control = $DraftUI
@onready var contract_offer_ui: Control = $ContractOfferUI
@onready var challenge_ui = $ChallengeUI
@onready var progression_ui = get_node_or_null("Margin/Root/LeftPanel/Stats/ProgressionUI")
@onready var meta_widgets: Control = $Margin/Root/LeftPanel/MetaWidgets
@onready var actions_title: Label = $Margin/Root/RightPanel/Actions/ActionsTitle
@onready var actions_note: Label = $Margin/Root/RightPanel/Actions/ActionsNote
@onready var nav_start_run: Button = $BottomBar/BottomBarButtons/NavStartRun
@onready var nav_contract: Button = $BottomBar/BottomBarButtons/NavContract
@onready var nav_buy_crate: Button = $BottomBar/BottomBarButtons/NavBuyCrate
@onready var nav_sell_all: Button = $BottomBar/BottomBarButtons/NavSellAll
@onready var nav_claim_fish: Button = $BottomBar/BottomBarButtons/NavClaimFish
@onready var nav_loadout: Button = $BottomBar/BottomBarButtons/NavLoadout
@onready var nav_manage_boats: Button = $BottomBar/BottomBarButtons/NavManageBoats
@onready var nav_return_menu: Button = $BottomBar/BottomBarButtons/NavReturnMenu
@onready var nav_plan_expedition: Button = $BottomBar/BottomBarButtons/NavPlanExpedition

func _enter_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_visual_polish()
	extraction_time_label.text = "Czas ekstrakcji: 20 min (wczesny powrot od 2:00)"
	_connect_signals()
	_refresh_stats()
	_update_lobby_widgets()
	_update_contract_ui()
	_update_expedition_modifiers()
	_update_boat_ui()
	_setup_loadout_ui()
	_show_pending_draft()
	_connect_nav_buttons()
	_show_page("start_run")
	_play_intro_motion()
	if buy_crate_button and not buy_crate_button.pressed.is_connected(_on_buy_crate_button_pressed):
		buy_crate_button.pressed.connect(_on_buy_crate_button_pressed)
	if roll_charm_button and not roll_charm_button.pressed.is_connected(_on_roll_charm_button_pressed):
		roll_charm_button.pressed.connect(_on_roll_charm_button_pressed)
	if contract_accept_button and not contract_accept_button.pressed.is_connected(_on_contract_accept_button_pressed):
		contract_accept_button.pressed.connect(_on_contract_accept_button_pressed)
	if boat_buy_button and not boat_buy_button.pressed.is_connected(_on_buy_boat_button_pressed):
		boat_buy_button.pressed.connect(_on_buy_boat_button_pressed)
	if boat_select and not boat_select.item_selected.is_connected(_on_boat_selected):
		boat_select.item_selected.connect(_on_boat_selected)

func _apply_visual_polish() -> void:
	if board_background:
		board_background.color = Color(0.055, 0.065, 0.082, 1.0)

	if title_label:
		title_label.add_theme_font_size_override("font_size", 44)
		title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	if subtitle_label:
		subtitle_label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90, 0.92))

	if left_panel:
		left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.09, 0.12, 0.16, 0.94), Color(0.25, 0.39, 0.55, 0.9), 14))
	if right_panel:
		right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.14, 0.19, 0.95), Color(0.29, 0.45, 0.62, 0.95), 14))
	if bottom_bar is PanelContainer:
		(bottom_bar as PanelContainer).add_theme_stylebox_override("panel", _make_panel_style(Color(0.07, 0.10, 0.14, 0.96), Color(0.33, 0.52, 0.72, 0.92), 16))

	for value_label in [money_value, bread_value, hull_value, fish_value]:
		if value_label:
			value_label.add_theme_color_override("font_color", Color(0.91, 0.95, 0.98, 1.0))
			value_label.add_theme_font_size_override("font_size", 20)

	if actions_title:
		actions_title.add_theme_font_size_override("font_size", 30)
		actions_title.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0, 1.0))
	if actions_note:
		actions_note.add_theme_color_override("font_color", Color(0.63, 0.77, 0.89, 0.92))

	if expedition_positive:
		expedition_positive.add_theme_color_override("font_color", Color(0.53, 0.90, 0.68, 1.0))
	if expedition_negative:
		expedition_negative.add_theme_color_override("font_color", Color(1.0, 0.52, 0.56, 1.0))

	var primary := _make_button_style(Color(0.17, 0.54, 0.86, 0.98), Color(0.24, 0.62, 0.96, 1.0), Color(0.12, 0.40, 0.67, 1.0), Color(0.42, 0.74, 1.0, 1.0))
	var success := _make_button_style(Color(0.19, 0.56, 0.42, 0.98), Color(0.27, 0.66, 0.50, 1.0), Color(0.15, 0.45, 0.33, 1.0), Color(0.51, 0.86, 0.68, 1.0))
	var warning := _make_button_style(Color(0.66, 0.44, 0.18, 0.98), Color(0.75, 0.53, 0.24, 1.0), Color(0.54, 0.35, 0.13, 1.0), Color(0.93, 0.69, 0.34, 1.0))
	var danger := _make_button_style(Color(0.58, 0.25, 0.30, 0.98), Color(0.70, 0.31, 0.38, 1.0), Color(0.47, 0.19, 0.24, 1.0), Color(0.92, 0.44, 0.50, 1.0))

	_apply_button_theme(start_run_button, primary)
	_apply_button_theme(contract_accept_button, primary)
	_apply_button_theme(boat_buy_button, warning)
	_apply_button_theme(buy_crate_button, warning)
	_apply_button_theme(claim_fish_button, success)
	_apply_button_theme(sell_all_button, success)
	_apply_button_theme(return_menu_button, danger)
	_apply_button_theme(roll_charm_button, warning)

	for nav_btn in [
		nav_start_run,
		nav_contract,
		nav_buy_crate,
		nav_sell_all,
		nav_claim_fish,
		nav_loadout,
		nav_manage_boats,
		nav_return_menu,
		nav_plan_expedition,
	]:
		_apply_button_theme(nav_btn, primary)

	for btn in upgrade_buttons:
		_apply_button_theme(btn, primary)

func _play_intro_motion() -> void:
	if board_margin == null or bottom_bar == null:
		return
	board_margin.modulate.a = 0.0
	bottom_bar.modulate.a = 0.0
	board_margin.position.y += 18.0
	bottom_bar.position.y += 14.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(board_margin, "modulate:a", 1.0, 0.35)
	tween.tween_property(board_margin, "position:y", board_margin.position.y - 18.0, 0.42)
	tween.tween_property(bottom_bar, "modulate:a", 1.0, 0.40)
	tween.tween_property(bottom_bar, "position:y", bottom_bar.position.y - 14.0, 0.44)

func _make_panel_style(bg: Color, border: Color, corner: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	sb.corner_radius_bottom_right = corner
	sb.corner_radius_bottom_left = corner
	sb.content_margin_left = 16
	sb.content_margin_top = 14
	sb.content_margin_right = 16
	sb.content_margin_bottom = 14
	return sb

func _make_button_style(normal: Color, hover: Color, pressed: Color, border: Color) -> Dictionary:
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = normal
	normal_sb.border_width_left = 1
	normal_sb.border_width_top = 1
	normal_sb.border_width_right = 1
	normal_sb.border_width_bottom = 1
	normal_sb.border_color = border
	normal_sb.corner_radius_top_left = 10
	normal_sb.corner_radius_top_right = 10
	normal_sb.corner_radius_bottom_right = 10
	normal_sb.corner_radius_bottom_left = 10
	normal_sb.content_margin_left = 12
	normal_sb.content_margin_top = 8
	normal_sb.content_margin_right = 12
	normal_sb.content_margin_bottom = 8

	var hover_sb := normal_sb.duplicate()
	hover_sb.bg_color = hover

	var pressed_sb := normal_sb.duplicate()
	pressed_sb.bg_color = pressed

	var disabled_sb := normal_sb.duplicate()
	disabled_sb.bg_color = Color(normal.r * 0.55, normal.g * 0.55, normal.b * 0.55, 0.70)

	return {
		"normal": normal_sb,
		"hover": hover_sb,
		"pressed": pressed_sb,
		"disabled": disabled_sb
	}

func _apply_button_theme(button: BaseButton, styles: Dictionary) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", styles["normal"])
	button.add_theme_stylebox_override("hover", styles["hover"])
	button.add_theme_stylebox_override("pressed", styles["pressed"])
	button.add_theme_stylebox_override("disabled", styles["disabled"])
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.93, 0.96, 1.0, 1.0))

func _connect_signals() -> void:
	if InventoryManager:
		if not InventoryManager.money_updated.is_connected(_on_money_updated):
			InventoryManager.money_updated.connect(_on_money_updated)
		if not InventoryManager.bait_quantity_changed.is_connected(_on_bait_changed):
			InventoryManager.bait_quantity_changed.connect(_on_bait_changed)
		if not InventoryManager.inventory_updated.is_connected(_on_inventory_updated):
			InventoryManager.inventory_updated.connect(_on_inventory_updated)
		if not InventoryManager.pending_fish_changed.is_connected(_on_pending_fish_changed):
			InventoryManager.pending_fish_changed.connect(_on_pending_fish_changed)
		if not InventoryManager.boat_changed.is_connected(_on_boat_changed):
			InventoryManager.boat_changed.connect(_on_boat_changed)
		if not InventoryManager.expedition_credit_updated.is_connected(_on_expedition_credit_updated):
			InventoryManager.expedition_credit_updated.connect(_on_expedition_credit_updated)
		if not InventoryManager.charms_changed.is_connected(_on_charms_changed):
			InventoryManager.charms_changed.connect(_on_charms_changed)

	if QuotaManager:
		if not QuotaManager.hull_updated.is_connected(_on_hull_updated):
			QuotaManager.hull_updated.connect(_on_hull_updated)
		if not QuotaManager.quota_updated.is_connected(_on_quota_updated):
			QuotaManager.quota_updated.connect(_on_quota_updated)
		if not QuotaManager.day_passed.is_connected(_on_day_passed):
			QuotaManager.day_passed.connect(_on_day_passed)
		if not QuotaManager.deadline_updated.is_connected(_on_deadline_updated):
			QuotaManager.deadline_updated.connect(_on_deadline_updated)

	if QuestManager:
		if not QuestManager.contract_offer_updated.is_connected(_on_contract_offer_updated):
			QuestManager.contract_offer_updated.connect(_on_contract_offer_updated)
		if not QuestManager.quest_accepted.is_connected(_on_contract_accepted):
			QuestManager.quest_accepted.connect(_on_contract_accepted)
		if not QuestManager.quest_completed.is_connected(_on_contract_completed):
			QuestManager.quest_completed.connect(_on_contract_completed)

func _apply_responsive_layout() -> void:
	# No-op: UI is authored for the board viewport size.
	return

func _connect_nav_buttons() -> void:
	if nav_start_run and not nav_start_run.pressed.is_connected(_on_nav_start_run_pressed):
		nav_start_run.pressed.connect(_on_nav_start_run_pressed)
	if nav_contract and not nav_contract.pressed.is_connected(_on_nav_contract_pressed):
		nav_contract.pressed.connect(_on_nav_contract_pressed)
	if nav_buy_crate and not nav_buy_crate.pressed.is_connected(_on_nav_buy_crate_pressed):
		nav_buy_crate.pressed.connect(_on_nav_buy_crate_pressed)
	if nav_sell_all and not nav_sell_all.pressed.is_connected(_on_nav_sell_all_pressed):
		nav_sell_all.pressed.connect(_on_nav_sell_all_pressed)
	if nav_claim_fish and not nav_claim_fish.pressed.is_connected(_on_nav_claim_fish_pressed):
		nav_claim_fish.pressed.connect(_on_nav_claim_fish_pressed)
	if nav_loadout and not nav_loadout.pressed.is_connected(_on_nav_loadout_pressed):
		nav_loadout.pressed.connect(_on_nav_loadout_pressed)
	if nav_manage_boats and not nav_manage_boats.pressed.is_connected(_on_nav_manage_boats_pressed):
		nav_manage_boats.pressed.connect(_on_nav_manage_boats_pressed)
	if nav_return_menu and not nav_return_menu.pressed.is_connected(_on_nav_return_menu_pressed):
		nav_return_menu.pressed.connect(_on_nav_return_menu_pressed)
	if nav_plan_expedition and not nav_plan_expedition.pressed.is_connected(_on_nav_plan_expedition_pressed):
		nav_plan_expedition.pressed.connect(_on_nav_plan_expedition_pressed)

func _show_page(page_id: String) -> void:
	if contract_offer_ui:
		contract_offer_ui.hide()
	if draft_ui:
		draft_ui.hide()
	var action_nodes = [
		actions_title,
		extraction_time_label,
		boat_name_label,
		boat_select,
		boat_preview_label,
		boat_credit_label,
		boat_earnings_label,
		boat_next_label,
		boat_buy_button,
		contract_description,
		contract_risk,
		contract_reward,
		contract_accept_button,
		expedition_positive,
		expedition_negative,
		start_run_button,
		sell_all_button,
		pending_fish_label,
		claim_fish_button,
		buy_crate_button,
		return_menu_button,
		actions_note,
	]
	for node in action_nodes:
		if node:
			node.visible = false
	if meta_widgets:
		meta_widgets.visible = page_id == "loadout" or page_id == "manage_boats"
	if actions_title:
		actions_title.visible = true
		actions_title.text = "Terminal Operacyjny"
	match page_id:
		"start_run":
			if extraction_time_label:
				extraction_time_label.visible = true
				extraction_time_label.text = "Kontrakt terenowy: 20 min | Wczesny powrot po 2:00"
			if start_run_button:
				start_run_button.visible = true
				start_run_button.text = "Start kontraktu"
		"contract":
			if contract_description:
				contract_description.visible = true
			if contract_risk:
				contract_risk.visible = true
			if contract_reward:
				contract_reward.visible = true
			if contract_accept_button:
				contract_accept_button.visible = true
		"buy_crate":
			if buy_crate_button:
				buy_crate_button.visible = true
		"sell_all":
			if sell_all_button:
				sell_all_button.visible = true
		"claim_fish":
			if pending_fish_label:
				pending_fish_label.visible = true
			if claim_fish_button:
				claim_fish_button.visible = true
		"loadout":
			if boat_name_label:
				boat_name_label.visible = true
			if boat_select:
				boat_select.visible = true
			if boat_preview_label:
				boat_preview_label.visible = true
			if boat_credit_label:
				boat_credit_label.visible = true
			if boat_earnings_label:
				boat_earnings_label.visible = true
			if boat_next_label:
				boat_next_label.visible = true
			if boat_buy_button:
				boat_buy_button.visible = true
		"manage_boats":
			if boat_name_label:
				boat_name_label.visible = true
			if boat_select:
				boat_select.visible = true
			if boat_preview_label:
				boat_preview_label.visible = true
			if boat_credit_label:
				boat_credit_label.visible = true
			if boat_earnings_label:
				boat_earnings_label.visible = true
			if boat_next_label:
				boat_next_label.visible = true
			if boat_buy_button:
				boat_buy_button.visible = true
		"return_menu":
			if return_menu_button:
				return_menu_button.visible = true
		"plan_expedition":
			if expedition_positive:
				expedition_positive.visible = true
			if expedition_negative:
				expedition_negative.visible = true
			if draft_ui and draft_ui.has_method("show_draft_on_board"):
				draft_ui.show_draft_on_board()

func _on_nav_start_run_pressed() -> void:
	_show_page("start_run")

func _on_nav_contract_pressed() -> void:
	_show_page("contract")

func _on_nav_buy_crate_pressed() -> void:
	_show_page("buy_crate")

func _on_nav_sell_all_pressed() -> void:
	_show_page("sell_all")

func _on_nav_claim_fish_pressed() -> void:
	_show_page("claim_fish")

func _on_nav_loadout_pressed() -> void:
	_show_page("loadout")

func _on_nav_manage_boats_pressed() -> void:
	_show_page("manage_boats")

func _on_nav_return_menu_pressed() -> void:
	_show_page("return_menu")

func _on_nav_plan_expedition_pressed() -> void:
	_show_page("plan_expedition")

func _refresh_stats() -> void:
	if QuotaManager:
		hull_value.text = "%d / %d" % [int(QuotaManager.hull_integrity), int(QuotaManager.max_hull)]

	if InventoryManager:
		money_value.text = str(InventoryManager.money)
		bread_value.text = str(InventoryManager.get_bait_count("bread"))
		fish_value.text = str(InventoryManager.caught_fish.size())
		var pending_count: int = int(InventoryManager.pending_fish.size())
		pending_fish_label.text = "Ryby do odebrania: %d" % pending_count
		claim_fish_button.disabled = pending_count == 0
		var crate_cost: int = 200
		if QuotaManager:
			crate_cost = int(QuotaManager.crate_cost)
		buy_crate_button.text = "Kup skrzynke perkow ($%d)" % crate_cost
		var can_buy: bool = bool(InventoryManager.can_afford(crate_cost))
		buy_crate_button.disabled = not can_buy
		if roll_charm_button:
			var charm_roll_cost: int = int(InventoryManager.get_charm_roll_cost())
			roll_charm_button.text = "Losuj charm ($%d)" % charm_roll_cost
			roll_charm_button.disabled = not InventoryManager.can_afford(charm_roll_cost) or InventoryManager.get_available_charm_roll_count() <= 0
		if charm_status_label and RelicDatabase:
			var owned_count: int = int(InventoryManager.get_owned_charms().size())
			var total_count: int = int(RelicDatabase.all_relics.size())
			charm_status_label.text = "Charmy: %d / %d" % [owned_count, total_count]

	if QuotaManager and actions_note:
		var quota_status: Dictionary = QuotaManager.get_deadline_status()
		var day_no: int = int(quota_status.get("day", 1))
		var target: int = int(quota_status.get("quota_target", 0))
		var days_left: int = int(quota_status.get("days_left", 0))
		actions_note.text = "Dzien %d | Cel firmy: $%d | Deadline za %d dni" % [day_no, target, days_left]

func _update_lobby_widgets() -> void:
	if challenge_ui and challenge_ui.has_method("update_ui"):
		challenge_ui.update_ui()
	if progression_ui and progression_ui.has_method("refresh_upgrades"):
		progression_ui.refresh_upgrades()
	_update_contract_ui()
	_update_expedition_modifiers()
	_update_boat_ui()

func _on_start_run_button_pressed() -> void:
	if TimeManager:
		TimeManager.set_extraction_duration_minutes(TimeManager.EXTRACTION_MAX_MINUTES)
		TimeManager.start_extraction()
	get_tree().change_scene_to_file("res://src/Main3D.tscn")

func _on_sell_all_button_pressed() -> void:
	if InventoryManager:
		InventoryManager.sell_all_fish()
	_refresh_stats()

func _on_return_menu_button_pressed() -> void:
	if InventoryManager:
		InventoryManager.save_game()
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")

func _on_money_updated(_amount: int) -> void:
	_refresh_stats()

func _on_hull_updated(_current: float, _max: float) -> void:
	_refresh_stats()

func _on_quota_updated(_current: int, _target: int) -> void:
	_refresh_stats()

func _on_day_passed(_day_count: int) -> void:
	_refresh_stats()

func _on_deadline_updated(_days_left: int, _cycle_days: int) -> void:
	_refresh_stats()

func _on_bait_changed(_bait_id: String, _qty: int) -> void:
	_refresh_stats()

func _on_inventory_updated(_item) -> void:
	_refresh_stats()

func _on_pending_fish_changed(_count: int) -> void:
	_refresh_stats()

func _on_charms_changed() -> void:
	_setup_loadout_ui()
	_refresh_stats()

func _on_boat_changed(_boat_id: String) -> void:
	_update_boat_ui()

func _on_expedition_credit_updated(_credit_due: int, _earnings: int) -> void:
	_update_boat_ui()

func _on_contract_offer_updated(_offer_data: Dictionary) -> void:
	_update_contract_ui()

func _on_contract_accepted(_quest_data: Dictionary) -> void:
	_update_contract_ui()

func _on_contract_completed(_quest_data: Dictionary) -> void:
	_update_contract_ui()

func _on_claim_fish_button_pressed() -> void:
	if InventoryManager:
		InventoryManager.claim_pending_fish()
	_refresh_stats()

func _on_buy_crate_button_pressed() -> void:
	if not InventoryManager or not QuotaManager:
		return
	var crate_cost: int = int(QuotaManager.crate_cost)
	if InventoryManager.spend_money(crate_cost):
		QuotaManager.crate_cost += 50
		if draft_ui:
			draft_ui.show_draft()
	_refresh_stats()

func _on_buy_boat_button_pressed() -> void:
	if not InventoryManager:
		return
	var next_boat: String = str(InventoryManager.get_next_unowned_boat_id())
	if next_boat == "":
		return
	if InventoryManager.buy_boat(next_boat):
		InventoryManager.set_current_boat(next_boat)
	_update_boat_ui()

func _on_contract_accept_button_pressed() -> void:
	if contract_offer_ui and contract_offer_ui.has_method("show_offer"):
		contract_offer_ui.show_offer()
	else:
		if QuestManager:
			QuestManager.accept_contract()
		_update_contract_ui()

func _show_pending_draft() -> void:
	if QuotaManager and QuotaManager.pending_draft and draft_ui:
		draft_ui.show_draft()

func show_expedition_planning() -> void:
	if board_background:
		board_background.visible = false
	if board_margin:
		board_margin.visible = false
	if draft_ui:
		if draft_ui.has_method("show_draft_on_board"):
			draft_ui.show_draft_on_board()
		elif draft_ui.has_method("show_draft"):
			draft_ui.show_draft()

func _update_contract_ui() -> void:
	if not contract_description or not contract_accept_button:
		return
	if not QuestManager:
		contract_description.text = "Kontrakty sa niedostepne."
		contract_risk.text = ""
		contract_reward.text = ""
		contract_accept_button.disabled = true
		return

	if not QuestManager.active_quest.is_empty() and not QuestManager.active_quest.get("completed", false):
		var active: Dictionary = QuestManager.active_quest
		contract_description.text = "Aktywny: %s" % active.get("description", "Kontrakt")
		contract_risk.text = "Trudnosc: %.1f" % float(active.get("difficulty", 1.0))
		contract_reward.text = "Nagroda: $%d" % int(active.get("reward_money", 0))
		contract_accept_button.text = "Kontrakt aktywny"
		contract_accept_button.disabled = true
		return

	var offer: Dictionary = QuestManager.contract_offer
	if offer.is_empty():
		contract_description.text = "Brak ofert. Wroc pozniej."
		contract_risk.text = ""
		contract_reward.text = ""
		contract_accept_button.text = "Brak kontraktu"
		contract_accept_button.disabled = true
		return

	contract_description.text = offer.get("description", "Nowy kontrakt")
	contract_risk.text = "Trudnosc: %.1f" % float(offer.get("difficulty", 1.0))
	contract_reward.text = "Nagroda: $%d" % int(offer.get("reward_money", 0))
	contract_accept_button.text = "Przyjmij kontrakt"
	contract_accept_button.disabled = false

func _update_expedition_modifiers() -> void:
	if not expedition_positive or not expedition_negative:
		return
	if not InventoryManager:
		expedition_positive.text = "+ --"
		expedition_negative.text = "- --"
		return
	var pos_desc: String = str(InventoryManager.expedition_positive.get("desc", "Brak"))
	var neg_desc: String = str(InventoryManager.expedition_negative.get("desc", "Brak"))
	expedition_positive.text = "+ %s" % pos_desc
	expedition_negative.text = "- %s" % neg_desc

func _update_boat_ui() -> void:
	if not boat_name_label or not boat_credit_label or not boat_earnings_label:
		return
	if not InventoryManager:
		boat_name_label.text = "Aktualna: --"
		if boat_select:
			boat_select.clear()
		if boat_preview_label:
			boat_preview_label.text = "Podglad: --"
		boat_credit_label.text = "Kredyt: $0"
		boat_earnings_label.text = "Zarobek: $0"
		if boat_next_label:
			boat_next_label.text = "Nastepna: --"
		if boat_buy_button:
			boat_buy_button.disabled = true
		return
	var boat_data: Dictionary = InventoryManager.get_current_boat_data()
	boat_name_label.text = "Aktualna: %s" % boat_data.get("name", "--")
	_update_boat_select()
	_update_boat_preview()
	boat_credit_label.text = "Kredyt: $%d" % InventoryManager.calculate_expedition_credit()
	boat_earnings_label.text = "Zarobek: $%d" % InventoryManager.expedition_earnings
	if boat_next_label and boat_buy_button:
		var next_boat_id: String = str(InventoryManager.get_next_unowned_boat_id())
		if next_boat_id == "":
			boat_next_label.text = "Nastepna: brak"
			boat_buy_button.disabled = true
		else:
			var next_data: Dictionary = InventoryManager.boats_catalog.get(next_boat_id, {"name": "--", "cost": 0})
			boat_next_label.text = "Nastepna: %s ($%d)" % [next_data.get("name", "--"), int(next_data.get("cost", 0))]
			boat_buy_button.disabled = not InventoryManager.can_afford(int(next_data.get("cost", 0)))

func _update_boat_select() -> void:
	if not boat_select or not InventoryManager:
		return
	boat_select.clear()
	var selected_index: int = 0
	var idx: int = 0
	for boat_id in InventoryManager.owned_boats:
		var data: Dictionary = InventoryManager.boats_catalog.get(boat_id, {"name": boat_id, "cost": 0})
		boat_select.add_item(data.get("name", boat_id), idx)
		boat_select.set_item_metadata(idx, boat_id)
		if boat_id == InventoryManager.current_boat_id:
			selected_index = idx
		idx += 1
	boat_select.select(selected_index)

func _update_boat_preview() -> void:
	if not boat_preview_label or not InventoryManager:
		return
	var data: Dictionary = InventoryManager.get_current_boat_data()
	var cost: int = int(data.get("cost", 0))
	boat_preview_label.text = "Podglad: koszt $%d | reliki %d/4 | ulepszenia %d/4" % [
		cost,
		_count_relics(),
		_count_upgrades()
	]

func _count_relics() -> int:
	var loadout: Dictionary = InventoryManager.get_boat_loadout(InventoryManager.current_boat_id)
	var relics: Array = loadout.get("relics", [])
	var count: int = 0
	for relic_id in relics:
		if relic_id != "":
			count += 1
	return count

func _count_upgrades() -> int:
	var loadout: Dictionary = InventoryManager.get_boat_loadout(InventoryManager.current_boat_id)
	var upgrades: Array = loadout.get("upgrades", [])
	var count: int = 0
	for upgrade in upgrades:
		if upgrade.get("stat_id", "") != "":
			count += 1
	return count

func _on_boat_selected(index: int) -> void:
	if not InventoryManager or not boat_select:
		return
	var boat_id: String = str(boat_select.get_item_metadata(index))
	if InventoryManager.set_current_boat(boat_id):
		_refresh_loadout_ui()
		_update_boat_ui()

func _setup_loadout_ui() -> void:
	if not InventoryManager:
		return
	var owned_charms: Array[String] = InventoryManager.get_owned_charms()
	for i in range(relic_slot_buttons.size()):
		var btn: OptionButton = relic_slot_buttons[i] as OptionButton
		btn.clear()
		btn.add_item("(pusto)", 0)
		var index: int = 1
		for charm_id in owned_charms:
			var relic: Dictionary = RelicDatabase.get_relic_by_id(charm_id)
			var relic_name: String = str(relic.get("name", charm_id))
			btn.add_item(relic_name, index)
			btn.set_item_metadata(index, charm_id)
			index += 1
		if not btn.item_selected.is_connected(_on_relic_slot_selected):
			btn.item_selected.connect(_on_relic_slot_selected.bind(i))
	for i in range(upgrade_stat_buttons.size()):
		var stat_btn: OptionButton = upgrade_stat_buttons[i] as OptionButton
		stat_btn.clear()
		stat_btn.add_item("(pusto)", 0)
		var stat_index = 1
		for stat_id in InventoryManager.boat_upgrade_types:
			stat_btn.add_item(stat_id, stat_index)
			stat_btn.set_item_metadata(stat_index, stat_id)
			stat_index += 1
		if not stat_btn.item_selected.is_connected(_on_upgrade_stat_selected):
			stat_btn.item_selected.connect(_on_upgrade_stat_selected.bind(i))
		var upgrade_btn: Button = upgrade_buttons[i] as Button
		if not upgrade_btn.pressed.is_connected(_on_upgrade_stat_pressed):
			upgrade_btn.pressed.connect(_on_upgrade_stat_pressed.bind(i))
	_refresh_loadout_ui()

func _refresh_loadout_ui() -> void:
	if not InventoryManager:
		return
	var loadout: Dictionary = InventoryManager.get_boat_loadout(InventoryManager.current_boat_id)
	var relics: Array = loadout.get("relics", [])
	for i in range(relic_slot_buttons.size()):
		var relic_id: String = str(relics[i] if i < relics.size() else "")
		var btn: OptionButton = relic_slot_buttons[i] as OptionButton
		var selected_index: int = 0
		for idx in range(1, btn.get_item_count()):
			if btn.get_item_metadata(idx) == relic_id:
				selected_index = idx
				break
		btn.select(selected_index)
		btn.tooltip_text = relic_id
	var upgrades: Array = loadout.get("upgrades", [])
	for i in range(upgrade_stat_buttons.size()):
		var upgrade: Dictionary = upgrades[i] if i < upgrades.size() else {"stat_id": "", "level": 0}
		var stat_id: String = str(upgrade.get("stat_id", ""))
		var level: int = int(upgrade.get("level", 0))
		var stat_btn: OptionButton = upgrade_stat_buttons[i] as OptionButton
		var selected: int = 0
		for idx in range(1, stat_btn.get_item_count()):
			if stat_btn.get_item_metadata(idx) == stat_id:
				selected = idx
				break
		stat_btn.select(selected)
		upgrade_level_labels[i].text = "Lv %d" % level
		var cost: int = int(InventoryManager.get_boat_stat_upgrade_cost(level))
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

func _on_roll_charm_button_pressed() -> void:
	if not InventoryManager:
		return
	var roll_result: Dictionary = InventoryManager.roll_random_charm()
	if bool(roll_result.get("ok", false)):
		if charm_status_label:
			charm_status_label.text = "Wylosowano: %s" % str(roll_result.get("charm_name", "Charm"))
		_setup_loadout_ui()
		_refresh_loadout_ui()
		_refresh_stats()
	else:
		if charm_status_label:
			charm_status_label.text = str(roll_result.get("reason", "Nie udalo sie wylosowac"))

func _on_upgrade_stat_selected(index: int, slot_index: int) -> void:
	if not InventoryManager:
		return
	var btn = upgrade_stat_buttons[slot_index]
	var stat_id = ""
	if index > 0:
		stat_id = str(btn.get_item_metadata(index))
	InventoryManager.set_boat_upgrade_slot(InventoryManager.current_boat_id, slot_index, stat_id)
	_refresh_loadout_ui()
	_update_boat_ui()

func _on_upgrade_stat_pressed(slot_index: int) -> void:
	if not InventoryManager:
		return
	if InventoryManager.upgrade_boat_stat(InventoryManager.current_boat_id, slot_index):
		_refresh_loadout_ui()
		_update_boat_ui()
