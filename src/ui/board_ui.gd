extends Control

signal action_selected(action_id: String)
signal close_requested

@onready var left_page_button: Button = $Panel/VBox/Header/LeftPageButton
@onready var right_page_button: Button = $Panel/VBox/Header/RightPageButton
@onready var subtitle_label: Label = $Panel/VBox/Header/HeaderInfo/Subtitle
@onready var page_label: Label = $Panel/VBox/Header/HeaderInfo/PageLabel
@onready var page_boat_dev: VBoxContainer = $Panel/VBox/Pages/PageBoatDev
@onready var page_finances: VBoxContainer = $Panel/VBox/Pages/PageFinances
@onready var page_expedition: VBoxContainer = $Panel/VBox/Pages/PageExpedition
@onready var boat_current_label: Label = $Panel/VBox/Pages/PageBoatDev/BoatCurrentLabel
@onready var boat_credit_label: Label = $Panel/VBox/Pages/PageBoatDev/BoatCreditLabel
@onready var boat_next_label: Label = $Panel/VBox/Pages/PageBoatDev/BoatNextLabel
@onready var money_label: Label = $Panel/VBox/Pages/PageFinances/MoneyLabel
@onready var pending_fish_label: Label = $Panel/VBox/Pages/PageFinances/PendingFishLabel
@onready var expedition_info_label: Label = $Panel/VBox/Pages/PageExpedition/ExpeditionInfo
@onready var expedition_positive_label: Label = $Panel/VBox/Pages/PageExpedition/ExpeditionPositiveLabel
@onready var expedition_negative_label: Label = $Panel/VBox/Pages/PageExpedition/ExpeditionNegativeLabel
@onready var start_run_button: Button = $Panel/VBox/Pages/PageExpedition/StartRunButton
@onready var contract_button: Button = $Panel/VBox/Pages/PageFinances/ContractButton
@onready var prev_boat_button: Button = $Panel/VBox/Pages/PageBoatDev/BoatButtons/PrevBoatButton
@onready var next_boat_button: Button = $Panel/VBox/Pages/PageBoatDev/BoatButtons/NextBoatButton
@onready var buy_boat_button: Button = $Panel/VBox/Pages/PageBoatDev/BoatButtons/BuyBoatButton
@onready var buy_crate_button: Button = $Panel/VBox/Pages/PageBoatDev/BuyCrateButton
@onready var sell_all_button: Button = $Panel/VBox/Pages/PageFinances/SellAllButton
@onready var claim_fish_button: Button = $Panel/VBox/Pages/PageFinances/ClaimFishButton
@onready var contract_value_label: Label = $Panel/VBox/Pages/PageFinances/ContractValueLabel
@onready var contract_status_label: Label = $Panel/VBox/Pages/PageFinances/ContractStatusLabel
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var return_menu_button: Button = $Panel/VBox/BottomRow/ReturnMenuButton

var _page_nodes: Array[Control] = []
var _page_names := ["Rozwoj lodki", "Finanse", "Planowanie wyprawy"]
var _page_hints := [
	"Strzalki lub A/D: zmiana strony, Esc: zamknij tablice",
	"Sprzedaj/odbierz ryby i obsluz kontrakt przed rejsem",
	"Sprawdz modyfikatory i gotowosc lodzi przed startem"
]
var _current_page := 0
var _start_run_block_reason := ""

func _ready() -> void:
	show()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_page_nodes = [page_boat_dev, page_finances, page_expedition]
	_set_page(0)
	_refresh_all()
	_connect_data_signals()
	if left_page_button and not left_page_button.pressed.is_connected(_on_left_page_pressed):
		left_page_button.pressed.connect(_on_left_page_pressed)
	if right_page_button and not right_page_button.pressed.is_connected(_on_right_page_pressed):
		right_page_button.pressed.connect(_on_right_page_pressed)
	if prev_boat_button and not prev_boat_button.pressed.is_connected(_on_prev_boat_pressed):
		prev_boat_button.pressed.connect(_on_prev_boat_pressed)
	if next_boat_button and not next_boat_button.pressed.is_connected(_on_next_boat_pressed):
		next_boat_button.pressed.connect(_on_next_boat_pressed)
	if buy_boat_button and not buy_boat_button.pressed.is_connected(_on_buy_boat_pressed):
		buy_boat_button.pressed.connect(_on_buy_boat_pressed)
	if buy_crate_button and not buy_crate_button.pressed.is_connected(_on_buy_crate_pressed):
		buy_crate_button.pressed.connect(_on_buy_crate_pressed)
	if sell_all_button and not sell_all_button.pressed.is_connected(_on_sell_all_pressed):
		sell_all_button.pressed.connect(_on_sell_all_pressed)
	if claim_fish_button and not claim_fish_button.pressed.is_connected(_on_claim_fish_pressed):
		claim_fish_button.pressed.connect(_on_claim_fish_pressed)
	if contract_button and not contract_button.pressed.is_connected(_on_contract_pressed):
		contract_button.pressed.connect(_on_contract_pressed)
	if start_run_button and not start_run_button.pressed.is_connected(_on_start_run_pressed):
		start_run_button.pressed.connect(_on_start_run_pressed)
	if return_menu_button and not return_menu_button.pressed.is_connected(_on_return_menu_pressed):
		return_menu_button.pressed.connect(_on_return_menu_pressed)
	if close_button and not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

func _connect_data_signals() -> void:
	if InventoryManager:
		if not InventoryManager.money_updated.is_connected(_on_data_changed):
			InventoryManager.money_updated.connect(_on_data_changed)
		if not InventoryManager.pending_fish_changed.is_connected(_on_data_changed):
			InventoryManager.pending_fish_changed.connect(_on_data_changed)
		if not InventoryManager.boat_changed.is_connected(_on_boat_changed):
			InventoryManager.boat_changed.connect(_on_boat_changed)
		if not InventoryManager.expedition_credit_updated.is_connected(_on_credit_changed):
			InventoryManager.expedition_credit_updated.connect(_on_credit_changed)
	if QuestManager:
		if not QuestManager.contract_offer_updated.is_connected(_on_contract_data_changed):
			QuestManager.contract_offer_updated.connect(_on_contract_data_changed)
		if not QuestManager.quest_accepted.is_connected(_on_contract_data_changed):
			QuestManager.quest_accepted.connect(_on_contract_data_changed)
		if not QuestManager.quest_completed.is_connected(_on_contract_data_changed):
			QuestManager.quest_completed.connect(_on_contract_data_changed)

func _on_data_changed(_value = null) -> void:
	_refresh_all()

func _on_boat_changed(_boat_id: String) -> void:
	_refresh_all()

func _on_credit_changed(_credit_due: int, _earnings: int) -> void:
	_refresh_all()

func _on_contract_data_changed(_payload = null) -> void:
	_refresh_all()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_prev_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_next_page()
		get_viewport().set_input_as_handled()

func _set_page(index: int) -> void:
	if _page_nodes.is_empty():
		return
	_current_page = wrapi(index, 0, _page_nodes.size())
	for i in range(_page_nodes.size()):
		if _page_nodes[i]:
			_page_nodes[i].visible = i == _current_page
	if page_label:
		page_label.text = "%s (%d/%d)" % [_page_names[_current_page], _current_page + 1, _page_nodes.size()]
	if subtitle_label and _current_page < _page_hints.size():
		subtitle_label.text = _page_hints[_current_page]
	_refresh_all()

func _prev_page() -> void:
	_set_page(_current_page - 1)

func _next_page() -> void:
	_set_page(_current_page + 1)

func _on_left_page_pressed() -> void:
	_prev_page()

func _on_right_page_pressed() -> void:
	_next_page()

func _refresh_all() -> void:
	_refresh_contract_info()
	_refresh_finance_info()
	_refresh_boat_info()
	_refresh_expedition_info()

func _refresh_finance_info() -> void:
	if money_label:
		money_label.text = "Gotowka: $%d" % int(InventoryManager.money if InventoryManager else 0)
	var pending_count := 0
	if pending_fish_label:
		if InventoryManager:
			pending_count = InventoryManager.pending_fish.size()
		pending_fish_label.text = "Ryby do odebrania: %d" % pending_count
	if claim_fish_button:
		claim_fish_button.disabled = pending_count == 0
		claim_fish_button.tooltip_text = "Brak ryb do odbioru." if pending_count == 0 else "Przenies ryby do ladowni."

	var fish_count := 0
	if InventoryManager:
		fish_count = InventoryManager.caught_fish.size()
	if sell_all_button:
		sell_all_button.disabled = fish_count == 0
		sell_all_button.tooltip_text = "Brak ryb do sprzedazy." if fish_count == 0 else "Sprzedaj cala ladownie."

	if buy_crate_button:
		var crate_cost := 0
		var can_buy_crate := false
		if QuotaManager:
			crate_cost = int(QuotaManager.crate_cost)
			buy_crate_button.text = "Kup skrzynke perkow ($%d)" % crate_cost
			if InventoryManager:
				can_buy_crate = InventoryManager.can_afford(crate_cost)
		buy_crate_button.disabled = not can_buy_crate
		if not QuotaManager:
			buy_crate_button.tooltip_text = "Skrzynki chwilowo niedostepne."
		elif not can_buy_crate:
			buy_crate_button.tooltip_text = "Za malo gotowki."
		else:
			buy_crate_button.tooltip_text = "Kup losowy zestaw perkow."

func _refresh_boat_info() -> void:
	if not InventoryManager:
		if boat_current_label:
			boat_current_label.text = "Aktualna lodz: --"
		if boat_credit_label:
			boat_credit_label.text = "Kredyt wyprawy: --"
		if boat_next_label:
			boat_next_label.text = "Nastepna lodz: --"
		if prev_boat_button:
			prev_boat_button.disabled = true
		if next_boat_button:
			next_boat_button.disabled = true
		if buy_boat_button:
			buy_boat_button.disabled = true
		return
	var current = InventoryManager.get_current_boat_data()
	if boat_current_label:
		boat_current_label.text = "Aktualna lodz: %s" % str(current.get("name", "--"))
	if boat_credit_label:
		boat_credit_label.text = "Kredyt wyprawy: $%d" % int(InventoryManager.calculate_expedition_credit())
	var next_id := InventoryManager.get_next_unowned_boat_id()
	if next_id == "":
		if boat_next_label:
			boat_next_label.text = "Nastepna lodz: brak"
		if buy_boat_button:
			buy_boat_button.disabled = true
	else:
		var next_data = InventoryManager.boats_catalog.get(next_id, {"name": "--", "cost": 0})
		var price = int(next_data.get("cost", 0))
		if boat_next_label:
			boat_next_label.text = "Nastepna lodz: %s ($%d)" % [str(next_data.get("name", "--")), price]
		if buy_boat_button:
			buy_boat_button.disabled = not InventoryManager.can_afford(price)
	var can_switch_boat := InventoryManager.owned_boats.size() > 1
	if prev_boat_button:
		prev_boat_button.disabled = not can_switch_boat
	if next_boat_button:
		next_boat_button.disabled = not can_switch_boat

func _refresh_expedition_info() -> void:
	var context := _build_start_run_context()
	if expedition_info_label:
		expedition_info_label.text = "Plan wyprawy (start z lodzi)\nPrzyneta: %s x%d" % [
			str(context.get("bait_id", "bread")),
			int(context.get("bait_count", 0))
		]
	if not InventoryManager:
		if expedition_positive_label:
			expedition_positive_label.text = "+ --"
		if expedition_negative_label:
			expedition_negative_label.text = "- --"
		if start_run_button:
			start_run_button.disabled = true
			start_run_button.tooltip_text = "Brak systemu ekwipunku."
		return
	if expedition_positive_label:
		expedition_positive_label.text = "+ %s" % str(InventoryManager.expedition_positive.get("desc", "Brak"))
	if expedition_negative_label:
		expedition_negative_label.text = "- %s" % str(InventoryManager.expedition_negative.get("desc", "Brak"))
	var can_start := false
	_start_run_block_reason = "Start wyprawy tylko z poziomu lodzi (E: 1/4 READY)."
	if start_run_button:
		start_run_button.disabled = not can_start
		start_run_button.text = "Start z lodzi"
		if can_start:
			start_run_button.tooltip_text = "Rozpocznij wyprawe."
		else:
			start_run_button.tooltip_text = _start_run_block_reason

func _refresh_contract_info() -> void:
	if not contract_value_label or not contract_status_label:
		return
	if not QuestManager:
		contract_value_label.text = "Wartosc kontraktu: --"
		contract_status_label.text = "Status: menedzer kontraktow niedostepny"
		if contract_button:
			contract_button.text = "Kontrakty niedostepne"
			contract_button.disabled = true
		return
	if not QuestManager.active_quest.is_empty() and not QuestManager.active_quest.get("completed", false):
		var active = QuestManager.active_quest
		var reward_active := int(active.get("reward_money", 0))
		contract_value_label.text = "Wartosc kontraktu: $%d" % reward_active
		contract_status_label.text = "Status: aktywny"
		if contract_button:
			contract_button.text = "Kontrakt aktywny"
			contract_button.disabled = true
		return
	var offer = QuestManager.contract_offer
	if offer.is_empty():
		contract_value_label.text = "Wartosc kontraktu: --"
		contract_status_label.text = "Status: brak oferty"
		if contract_button:
			contract_button.text = "Brak kontraktu"
			contract_button.disabled = true
		return
	var reward_offer := int(offer.get("reward_money", 0))
	contract_value_label.text = "Wartosc kontraktu: $%d" % reward_offer
	contract_status_label.text = "Status: oferta gotowa"
	if contract_button:
		contract_button.text = "Przyjmij kontrakt"
		contract_button.disabled = false

func _build_start_run_context() -> Dictionary:
	var bait_id := "bread"
	var bait_count := 0
	if InventoryManager:
		bait_id = str(InventoryManager.current_bait_id)
		bait_count = int(InventoryManager.get_bait_count(bait_id))
	return {
		"bait_id": bait_id,
		"bait_count": bait_count
	}

func _can_start_run(context: Dictionary = {}) -> bool:
	var resolved := context
	if resolved.is_empty():
		resolved = _build_start_run_context()

	_start_run_block_reason = ""
	if not InventoryManager:
		_start_run_block_reason = "Brak systemu ekwipunku."
		return false
	if int(resolved.get("bait_count", 0)) <= 0:
		_start_run_block_reason = "Brak przynety: %s." % str(resolved.get("bait_id", "bread"))
		return false
	return true

func _on_start_run_pressed() -> void:
	_refresh_expedition_info()

func _on_contract_pressed() -> void:
	if not QuestManager:
		return
	if not QuestManager.active_quest.is_empty() and not QuestManager.active_quest.get("completed", false):
		return
	if QuestManager.contract_offer.is_empty():
		return
	QuestManager.accept_contract()
	_refresh_all()

func _on_buy_crate_pressed() -> void:
	if not InventoryManager or not QuotaManager:
		return
	var crate_cost = int(QuotaManager.crate_cost)
	if InventoryManager.spend_money(crate_cost):
		QuotaManager.crate_cost += 50
	_refresh_all()

func _on_sell_all_pressed() -> void:
	if InventoryManager:
		InventoryManager.sell_all_fish()
	_refresh_all()

func _on_claim_fish_pressed() -> void:
	if InventoryManager:
		InventoryManager.claim_pending_fish()
	_refresh_all()

func _on_prev_boat_pressed() -> void:
	if not InventoryManager:
		return
	var owned = InventoryManager.owned_boats
	if owned.is_empty():
		return
	var idx = owned.find(InventoryManager.current_boat_id)
	if idx < 0:
		idx = 0
	idx = wrapi(idx - 1, 0, owned.size())
	InventoryManager.set_current_boat(str(owned[idx]))
	_refresh_all()

func _on_next_boat_pressed() -> void:
	if not InventoryManager:
		return
	var owned = InventoryManager.owned_boats
	if owned.is_empty():
		return
	var idx = owned.find(InventoryManager.current_boat_id)
	if idx < 0:
		idx = 0
	idx = wrapi(idx + 1, 0, owned.size())
	InventoryManager.set_current_boat(str(owned[idx]))
	_refresh_all()

func _on_buy_boat_pressed() -> void:
	if not InventoryManager:
		return
	var next_id = InventoryManager.get_next_unowned_boat_id()
	if next_id == "":
		return
	if InventoryManager.buy_boat(next_id):
		InventoryManager.set_current_boat(next_id)
	_refresh_all()

func _on_return_menu_pressed() -> void:
	action_selected.emit("return_menu")

func _on_close_pressed() -> void:
	close_requested.emit()
