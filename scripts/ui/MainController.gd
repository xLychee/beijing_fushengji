extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var location_list: ItemList = %LocationList
@onready var market_list: ItemList = %MarketList
@onready var inventory_list: ItemList = %InventoryList
@onready var message_label: Label = %MessageLabel
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton

var locations := {}
var goods_by_id := {}

func _ready() -> void:
	randomize()
	locations = _load_json_dictionary("res://data/locations.json")
	for item in GameRules.load_goods():
		goods_by_id[String(item["id"])] = item
	var result := GameRules.new_game()
	DialogManager.enqueue_messages(result["messages"])
	location_list.item_selected.connect(_on_location_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	_render_all()

func _render_all() -> void:
	title_label.text = "北京浮生记"
	status_label.text = "第%d/40天  现金:%d  债务:%d  存款:%d  健康:%d  名声:%d  容量:%d/%d" % [
		GameState.day,
		GameState.cash,
		GameState.debt,
		GameState.bank,
		GameState.health,
		GameState.fame,
		GameState.inventory_total(),
		GameState.capacity
	]
	_render_locations()
	_render_market()
	_render_inventory()
	_render_next_message()

func _render_locations() -> void:
	location_list.clear()
	for location in locations.get(GameState.city, []):
		var index := location_list.add_item(String(location["label"]))
		location_list.set_item_metadata(index, String(location["id"]))

func _render_market() -> void:
	market_list.clear()
	for goods_id in GameState.market_prices.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var price := int(GameState.market_prices[goods_id])
		var index := market_list.add_item("%s    %d元" % [goods_name, price])
		market_list.set_item_metadata(index, goods_id)

func _render_inventory() -> void:
	inventory_list.clear()
	if GameState.inventory.is_empty():
		inventory_list.add_item("还没有货物")
		return
	for goods_id in GameState.inventory.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var item = GameState.inventory[goods_id]
		var index := inventory_list.add_item("%s    %d个" % [goods_name, int(item.get("quantity", 0))])
		inventory_list.set_item_metadata(index, goods_id)

func _render_next_message() -> void:
	if DialogManager.has_messages():
		var message := DialogManager.pop_next_message()
		message_label.text = String(message.get("text", ""))
	else:
		message_label.text = ""

func _load_json_dictionary(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Expected JSON dictionary in %s" % path)
		return {}
	return parsed

func _on_location_selected(index: int) -> void:
	var location_id := String(location_list.get_item_metadata(index))
	_apply_rule_result(GameRules.travel_to(location_id))

func _on_buy_pressed() -> void:
	var selected := market_list.get_selected_items()
	if selected.is_empty():
		_show_message("先选一个想买的货。")
		return
	var goods_id := String(market_list.get_item_metadata(selected[0]))
	_apply_rule_result(GameRules.buy(goods_id, 1))

func _on_sell_pressed() -> void:
	var selected := inventory_list.get_selected_items()
	if selected.is_empty():
		_show_message("先选一个想卖的货。")
		return
	var goods_id := String(inventory_list.get_item_metadata(selected[0]))
	_apply_rule_result(GameRules.sell(goods_id, 1))

func _apply_rule_result(result: Dictionary) -> void:
	DialogManager.enqueue_messages(result.get("messages", []))
	_render_all()

func _show_message(message: String) -> void:
	DialogManager.enqueue_messages([{"type": "diary", "text": message}])
	_render_next_message()
