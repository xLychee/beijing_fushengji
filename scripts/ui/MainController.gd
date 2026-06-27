extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var location_list: ItemList = %LocationList
@onready var location_grid: Control = $LocationPanel/LocationGrid
@onready var market_list: ItemList = %MarketList
@onready var inventory_list: ItemList = %InventoryList
@onready var message_label: Label = %MessageLabel
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton
@onready var cash_value: Label = %CashValue
@onready var bank_value: Label = %BankValue
@onready var debt_value: Label = %DebtValue
@onready var health_value: Label = %HealthValue
@onready var fame_value: Label = %FameValue

var locations := {}
var goods_by_id := {}
var location_positions := {
	"xizhimen": Vector2(204, 24),
	"jishuitan": Vector2(310, 24),
	"dongzhimen": Vector2(418, 24),
	"pingguoyuan": Vector2(6, 123),
	"gongzhufen": Vector2(105, 123),
	"fuxingmen": Vector2(204, 123),
	"jianguomen": Vector2(416, 123),
	"changchunjie": Vector2(204, 216),
	"chongwenmen": Vector2(312, 216),
	"beijing_station": Vector2(418, 216),
}

func _ready() -> void:
	randomize()
	_apply_retro_theme(self)
	locations = _load_json_dictionary("res://data/locations.json")
	for item in GameRules.load_goods():
		goods_by_id[String(item["id"])] = item
	var result := GameRules.new_game()
	DialogManager.enqueue_messages(result["messages"])
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	_render_all()

func _render_all() -> void:
	title_label.text = "北京浮生(%d/40天)" % GameState.day
	status_label.text = "您的状态"
	cash_value.text = str(GameState.cash)
	bank_value.text = str(GameState.bank)
	debt_value.text = str(GameState.debt)
	health_value.text = str(GameState.health)
	fame_value.text = str(GameState.fame)
	_render_locations()
	_render_market()
	_render_inventory()
	_render_next_message()

func _render_locations() -> void:
	location_list.clear()
	for child in location_grid.get_children():
		child.queue_free()
	for location in locations.get(GameState.city, []):
		var location_id := String(location["id"])
		var label := String(location["label"])
		var index := location_list.add_item(label)
		location_list.set_item_metadata(index, location_id)
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(86, 46)
		button.size = Vector2(86, 46)
		button.position = location_positions.get(location_id, Vector2(12 + index % 5 * 100, 24 + index / 5 * 92))
		button.add_theme_font_size_override("font_size", 18)
		_style_retro_button(button)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			_on_location_pressed(location_id)
		)
		location_grid.add_child(button)

func _render_market() -> void:
	market_list.clear()
	for goods_id in GameState.market_prices.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var price := int(GameState.market_prices[goods_id])
		var index := market_list.add_item("%-18s %7d" % [_truncate_goods_name(goods_name), price])
		market_list.set_item_metadata(index, goods_id)

func _render_inventory() -> void:
	inventory_list.clear()
	if GameState.inventory.is_empty():
		inventory_list.add_item("")
		return
	for goods_id in GameState.inventory.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var item = GameState.inventory[goods_id]
		var index := inventory_list.add_item("%-18s %7d" % [_truncate_goods_name(goods_name), int(item.get("quantity", 0))])
		inventory_list.set_item_metadata(index, goods_id)

func _render_next_message() -> void:
	if DialogManager.has_messages():
		var message := DialogManager.pop_next_message()
		message_label.text = "%s    第%d/40天    现金:%d  存款:%d  欠债:%d  健康:%d  名声:%d  物品:%d/%d" % [
			String(message.get("text", "")),
			GameState.day,
			GameState.cash,
			GameState.bank,
			GameState.debt,
			GameState.health,
			GameState.fame,
			GameState.inventory_total(),
			GameState.capacity,
		]
	else:
		message_label.text = "第%d/40天    现金:%d  存款:%d  欠债:%d  健康:%d  名声:%d  物品:%d/%d" % [
			GameState.day,
			GameState.cash,
			GameState.bank,
			GameState.debt,
			GameState.health,
			GameState.fame,
			GameState.inventory_total(),
			GameState.capacity,
		]

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

func _on_location_pressed(location_id: String) -> void:
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

func _truncate_goods_name(goods_name: String) -> String:
	if goods_name.length() <= 12:
		return goods_name
	return goods_name.substr(0, 11) + "..."

func _apply_retro_theme(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if not _is_status_number(label) and label != message_label:
			label.add_theme_color_override("font_color", Color.BLACK)
	if node is Button:
		_style_retro_button(node as Button)
	for child in node.get_children():
		_apply_retro_theme(child)

func _style_retro_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_focus_color", Color.BLACK)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.88, 0.88, 0.88), Color(0.66, 0.66, 0.66)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.94, 0.94, 0.94), Color(0.55, 0.55, 0.55)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.76, 0.76, 0.76), Color(0.45, 0.45, 0.45)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style

func _is_status_number(label: Label) -> bool:
	return label == cash_value or label == bank_value or label == debt_value or label == health_value or label == fame_value
