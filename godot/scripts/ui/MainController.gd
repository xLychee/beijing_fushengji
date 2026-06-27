extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var location_list: ItemList = %LocationList
@onready var market_list: ItemList = %MarketList
@onready var inventory_list: ItemList = %InventoryList
@onready var message_label: Label = %MessageLabel

var locations := {}
var goods_by_id := {}

func _ready() -> void:
	randomize()
	locations = _load_json_dictionary("res://data/locations.json")
	for item in GameRules.load_goods():
		goods_by_id[String(item["id"])] = item
	var result := GameRules.new_game()
	DialogManager.enqueue_messages(result["messages"])
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
		location_list.add_item(String(location["label"]))

func _render_market() -> void:
	market_list.clear()
	for goods_id in GameState.market_prices.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var price := int(GameState.market_prices[goods_id])
		market_list.add_item("%s    %d元" % [goods_name, price])

func _render_inventory() -> void:
	inventory_list.clear()
	if GameState.inventory.is_empty():
		inventory_list.add_item("还没有货物")
		return
	for goods_id in GameState.inventory.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var item = GameState.inventory[goods_id]
		inventory_list.add_item("%s    %d个" % [goods_name, int(item.get("quantity", 0))])

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
