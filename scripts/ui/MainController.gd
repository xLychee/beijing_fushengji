extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var location_list: ItemList = %LocationList
@onready var location_grid: Control = $LocationPanel/LocationGrid
@onready var market_list: Tree = %MarketList
@onready var inventory_list: Tree = %InventoryList
@onready var message_label: Label = %MessageLabel
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton
@onready var settings_button: Button = $SettingsButton
@onready var high_scores_button: Button = $HighScoresButton
@onready var bank_button: Button = $BankButton
@onready var hospital_button: Button = $HospitalButton
@onready var post_button: Button = $PostButton
@onready var house_button: Button = $HouseButton
@onready var wangba_button: Button = $WangbaButton
@onready var city_toggle_button: Button = $LocationPanel/CityToggleButton
@onready var message_dialog: Control = $MessageDialog
@onready var settings_dialog: Control = $SettingsDialog
@onready var sound_check: CheckButton = $SettingsDialog/SettingsPanel/SoundCheck
@onready var hacker_check: CheckButton = $SettingsDialog/SettingsPanel/HackerCheck
@onready var high_scores_dialog: Control = $HighScoresDialog
@onready var cash_value: Control = %CashValue
@onready var bank_value: Control = %BankValue
@onready var debt_value: Control = %DebtValue
@onready var health_value: Control = %HealthValue
@onready var fame_value: Control = %FameValue

var locations := {}
var goods_by_id := {}
var ui_font := SystemFont.new()
var goods_icon: Texture2D = preload("res://assets/ui/goods.png")
var amount_dialog_script: Script = preload("res://scripts/ui/AmountDialog.gd")
var content_dialog_script: Script = preload("res://scripts/ui/ContentDialog.gd")
var score_table_script: Script = preload("res://scripts/ui/ScoreTable.gd")
var buy_dialog: Control
var sell_dialog: Control
var bank_dialog: Control
var hospital_dialog: Control
var debt_dialog: Control
var house_dialog: Control
var content_dialog: Control
var boss_dialog: Control
var score_table
var content_data := {}
var tips: Array = []
var tip_index := 0
var pending_buy_goods_id := ""
var pending_sell_goods_id := ""
const TREE_SELECTED_BG := Color(0.02, 0.16, 0.72)
var location_positions := {
	"xizhimen": Vector2(145, 21),
	"jishuitan": Vector2(215, 21),
	"dongzhimen": Vector2(270, 21),
	"pingguoyuan": Vector2(6, 97),
	"gongzhufen": Vector2(88, 97),
	"fuxingmen": Vector2(174, 97),
	"jianguomen": Vector2(270, 97),
	"changchunjie": Vector2(145, 173),
	"chongwenmen": Vector2(215, 173),
	"beijing_station": Vector2(270, 173),
}

func _ready() -> void:
	randomize()
	_configure_fonts()
	_apply_retro_theme(self)
	_configure_tree(market_list, [134, 70])
	_configure_tree(inventory_list, [112, 70, 52])
	locations = _load_json_dictionary("res://data/locations.json")
	content_data = _load_json_dictionary("res://data/content.json")
	tips = _load_json_array("res://data/tips.json")
	for item in GameRules.load_goods():
		goods_by_id[String(item["id"])] = item
	_create_operation_dialogs()
	_create_content_surfaces()
	_create_score_table()
	DialogManager.clear()
	var result := GameRules.new_game()
	DialogManager.enqueue_messages(result["messages"])
	if not tips.is_empty():
		DialogManager.enqueue_messages([{"type": "diary", "text": "每日提示: %s" % _tip_text(0)}])
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	high_scores_button.pressed.connect(_on_high_scores_pressed)
	bank_button.pressed.connect(_on_bank_pressed)
	hospital_button.pressed.connect(_on_hospital_pressed)
	post_button.pressed.connect(_on_post_pressed)
	house_button.pressed.connect(_on_house_pressed)
	wangba_button.pressed.connect(_on_wangba_pressed)
	city_toggle_button.pressed.connect(_on_city_toggle_pressed)
	message_dialog.confirmed.connect(_on_message_dialog_confirmed)
	message_dialog.close_requested.connect(_on_message_dialog_confirmed)
	market_list.item_selected.connect(func() -> void:
		_apply_tree_row_highlight(market_list)
	)
	inventory_list.item_selected.connect(func() -> void:
		_apply_tree_row_highlight(inventory_list)
	)
	sound_check.toggled.connect(_on_sound_check_toggled)
	hacker_check.toggled.connect(_on_hacker_check_toggled)
	_render_all()

func _render_all() -> void:
	title_label.text = "北京浮生(%d/40天)" % GameState.day
	status_label.text = "您的状态"
	cash_value.set("value", str(GameState.cash))
	bank_value.set("value", str(GameState.bank))
	debt_value.set("value", str(GameState.debt))
	health_value.set("value", str(GameState.health))
	fame_value.set("value", str(GameState.fame))
	city_toggle_button.text = "我要逛京城" if GameState.city == "alternate" else "我要去外地"
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
		button.custom_minimum_size = Vector2(54, 28)
		button.size = Vector2(54, 28)
		button.position = location_positions.get(location_id, Vector2(10 + index % 5 * 78, 20 + index / 5 * 62))
		button.add_theme_font_override("font", ui_font)
		button.add_theme_font_size_override("font_size", 13)
		_style_retro_button(button)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			_on_location_pressed(location_id)
		)
		location_grid.add_child(button)

func _render_market() -> void:
	market_list.clear()
	var root := market_list.create_item()
	for goods_id in GameState.market_prices.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var price := int(GameState.market_prices[goods_id])
		var row := market_list.create_item(root)
		row.set_text(0, _truncate_goods_name(goods_name))
		row.set_text(1, str(price))
		row.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_icon(0, goods_icon)
		row.set_icon_max_width(0, 16)
		row.set_metadata(0, goods_id)
	_apply_tree_row_highlight(market_list)

func _render_inventory() -> void:
	inventory_list.clear()
	var root := inventory_list.create_item()
	if GameState.inventory.is_empty():
		return
	for goods_id in GameState.inventory.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var item = GameState.inventory[goods_id]
		var row := inventory_list.create_item(root)
		row.set_text(0, _truncate_goods_name(goods_name))
		row.set_text(1, str(int(item.get("average_price", 0))))
		row.set_text(2, str(int(item.get("quantity", 0))))
		row.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_icon(0, goods_icon)
		row.set_icon_max_width(0, 16)
		row.set_metadata(0, goods_id)
	_apply_tree_row_highlight(inventory_list)

func _render_next_message() -> void:
	if message_dialog.visible:
		return
	if DialogManager.has_messages():
		var message := DialogManager.pop_next_message()
		_set_ticker_message(String(message.get("text", "")))
		_show_message_dialog(message)
	else:
		_set_ticker_message("")

func _set_ticker_message(message: String) -> void:
	var prefix := ""
	if message != "":
		prefix = "%s    " % message
	message_label.text = "%s第%d/40天    现金:%d  存款:%d  欠债:%d  健康:%d  名声:%d  物品:%d/%d" % [
		prefix,
		GameState.day,
		GameState.cash,
		GameState.bank,
		GameState.debt,
		GameState.health,
		GameState.fame,
		GameState.inventory_total(),
		GameState.capacity,
	]

func _show_message_dialog(message: Dictionary) -> void:
	var message_type := String(message.get("type", "diary"))
	message_dialog.title = "新闻" if message_type == "news" else "记事本"
	message_dialog.dialog_text = String(message.get("text", ""))
	if message.has("sound"):
		AudioManager.play_sound(String(message["sound"]))
	message_dialog.popup_centered(Vector2i(360, 160))

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

func _load_json_array(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read JSON file: %s" % path)
		return []
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected JSON array in %s" % path)
		return []
	return parsed

func _on_location_pressed(location_id: String) -> void:
	var result := GameRules.travel_to(location_id)
	if result.get("ok", false):
		AudioManager.play_sound("shutdoor.wav")
	_apply_rule_result(result)

func _on_buy_pressed() -> void:
	var selected := market_list.get_selected()
	if selected == null:
		_show_message("先选一个想买的货。")
		return
	pending_buy_goods_id = String(selected.get_metadata(0))
	var price := int(GameState.market_prices.get(pending_buy_goods_id, 0))
	var capacity_left: int = max(GameState.capacity - GameState.inventory_total(), 0)
	var max_count: int = min(int(GameState.cash / max(price, 1)), capacity_left)
	if max_count <= 0:
		_show_message("俺的现金或者房子都撑不住这笔买卖。")
		return
	var goods_name := _goods_name(pending_buy_goods_id)
	buy_dialog.configure("买进", "买进%s，每个%d元。" % [goods_name, price], 1, max_count, 1)
	buy_dialog.popup_centered(Vector2i(280, 160))

func _on_buy_amount_submitted(amount: int) -> void:
	var result := GameRules.buy(pending_buy_goods_id, amount)
	if result.get("ok", false):
		AudioManager.play_sound("buy.wav")
	_apply_rule_result(result)

func _on_sell_pressed() -> void:
	var selected := inventory_list.get_selected()
	if selected == null:
		_show_message("先选一个想卖的货。")
		return
	pending_sell_goods_id = String(selected.get_metadata(0))
	var item = GameState.inventory.get(pending_sell_goods_id, {})
	var owned := int(item.get("quantity", 0))
	if owned <= 0:
		_show_message("俺没有这个货。")
		return
	var price := int(GameState.market_prices.get(pending_sell_goods_id, 0))
	var goods_name := _goods_name(pending_sell_goods_id)
	sell_dialog.configure("卖出", "卖出%s，每个%d元。" % [goods_name, price], 1, owned, 1)
	sell_dialog.popup_centered(Vector2i(280, 160))

func _on_sell_amount_submitted(amount: int) -> void:
	var result := GameRules.sell(pending_sell_goods_id, amount)
	if result.get("ok", false):
		AudioManager.play_sound("money.wav")
	_apply_rule_result(result)

func _on_bank_pressed() -> void:
	AudioManager.play_sound("opendoor.wav")
	if GameState.cash <= 0 and GameState.bank <= 0:
		_show_message("银行里没有钱，身上也没什么可存的。")
		return
	var default_amount: int = min(500, max(GameState.cash, GameState.bank))
	bank_dialog.configure("银行", "要办理多少钱？", 1, max(GameState.cash, GameState.bank), default_amount, true)
	bank_dialog.popup_centered(Vector2i(280, 160))

func _on_bank_amount_submitted(amount: int) -> void:
	var result := {}
	if bank_dialog.selected_mode() == "withdraw":
		result = GameRules.withdraw(amount)
	else:
		result = GameRules.deposit(amount)
	if result.get("ok", false):
		AudioManager.play_sound("money.wav")
	_apply_rule_result(result)

func _on_hospital_pressed() -> void:
	AudioManager.play_sound("opendoor.wav")
	if GameState.health >= 100:
		_show_message("俺身体好着呢。")
		return
	var max_points: int = min(100 - GameState.health, int(GameState.cash / GameRules.HEAL_COST_PER_POINT))
	if max_points <= 0:
		_apply_rule_result(GameRules.heal(1))
		return
	hospital_dialog.configure("医院", "每恢复1点健康要%d元。" % GameRules.HEAL_COST_PER_POINT, 1, max_points, 1)
	hospital_dialog.popup_centered(Vector2i(280, 160))

func _on_hospital_amount_submitted(points: int) -> void:
	_apply_rule_result(GameRules.heal(points))

func _on_post_pressed() -> void:
	AudioManager.play_sound("opendoor.wav")
	if GameState.debt <= 0:
		_show_message("俺已经不欠村长钱了。")
		return
	var max_amount: int = min(GameState.cash, GameState.debt)
	if max_amount <= 0:
		_show_message("俺身上没有现金还债。")
		return
	debt_dialog.configure("邮局", "给村长汇多少钱还债？", 1, max_amount, min(500, max_amount))
	debt_dialog.popup_centered(Vector2i(280, 160))

func _on_debt_amount_submitted(amount: int) -> void:
	_apply_rule_result(GameRules.repay_debt(amount))

func _on_house_pressed() -> void:
	if GameState.capacity >= GameRules.HOUSE_MAX_CAPACITY or GameState.cash < GameRules.HOUSE_MIN_CASH:
		_apply_rule_result(GameRules.rent_larger_house())
		return
	var cost_text := "现金三万时收25000，超过三万时收一半再扣2000。"
	house_dialog.configure("租房中心", "%s\n确定换大房子？" % cost_text, 1, 1, 1)
	house_dialog.popup_centered(Vector2i(300, 170))

func _on_house_amount_submitted(_amount: int) -> void:
	_apply_rule_result(GameRules.rent_larger_house())

func _on_wangba_pressed() -> void:
	AudioManager.play_sound("Airport.wav")
	_apply_rule_result(GameRules.visit_internet_cafe())

func _on_city_toggle_pressed() -> void:
	_apply_rule_result(GameRules.toggle_city_mode())

func _on_settings_pressed() -> void:
	sound_check.button_pressed = GameState.sound_enabled
	hacker_check.button_pressed = GameState.hacker_events_enabled
	settings_dialog.popup_centered(Vector2i(280, 150))

func _on_high_scores_pressed() -> void:
	high_scores_dialog.dialog_text = ""
	score_table.render_scores(SaveManager.load_high_scores())
	high_scores_dialog.popup_centered(Vector2i(360, 260))

func _on_tip_pressed() -> void:
	if tips.is_empty():
		_show_message("今天没有提示。")
		return
	content_dialog.configure("每日提示", _tip_text(tip_index))
	tip_index = (tip_index + 1) % tips.size()
	content_dialog.popup_centered(Vector2i(420, 230))

func _on_story_pressed() -> void:
	_show_content_entry("story", Vector2i(440, 260))

func _on_help_pressed() -> void:
	_show_content_entry("help", Vector2i(460, 330))

func _on_about_pressed() -> void:
	_show_content_entry("about", Vector2i(440, 270))

func _on_declare_pressed() -> void:
	_show_content_entry("declaration", Vector2i(460, 300))

func _on_boss_pressed() -> void:
	var entry: Dictionary = content_data.get("boss", {})
	boss_dialog.configure(String(entry.get("title", "本月工作计划")), String(entry.get("body", "")))
	boss_dialog.popup_centered(Vector2i(560, 450))

func _apply_rule_result(result: Dictionary) -> void:
	DialogManager.enqueue_messages(result.get("messages", []))
	_render_all()

func _show_message(message: String) -> void:
	DialogManager.enqueue_messages([{"type": "diary", "text": message}])
	_render_next_message()

func _on_message_dialog_confirmed() -> void:
	message_dialog.hide()
	_render_next_message()

func _on_sound_check_toggled(pressed: bool) -> void:
	GameState.sound_enabled = pressed
	SaveManager.save_settings({
		"sound_enabled": GameState.sound_enabled,
		"hacker_events_enabled": GameState.hacker_events_enabled,
	})

func _on_hacker_check_toggled(pressed: bool) -> void:
	GameState.hacker_events_enabled = pressed
	SaveManager.save_settings({
		"sound_enabled": GameState.sound_enabled,
		"hacker_events_enabled": GameState.hacker_events_enabled,
	})

func _format_high_scores(scores: Array) -> String:
	var lines: Array[String] = ["名次    姓名          金钱        健康    名声"]
	for index in scores.size():
		var score = scores[index]
		lines.append("%2d      %-8s  %10d    %3d     %s" % [
			index + 1,
			String(score.get("name", "")),
			int(score.get("score", 0)),
			int(score.get("health", 0)),
			String(score.get("fame", "")),
		])
	return "\n".join(lines)

func _create_operation_dialogs() -> void:
	buy_dialog = _create_amount_dialog("BuyDialog")
	sell_dialog = _create_amount_dialog("SellDialog")
	bank_dialog = _create_amount_dialog("BankDialog")
	hospital_dialog = _create_amount_dialog("HospitalDialog")
	debt_dialog = _create_amount_dialog("DebtDialog")
	house_dialog = _create_amount_dialog("HouseDialog")
	buy_dialog.amount_submitted.connect(_on_buy_amount_submitted)
	sell_dialog.amount_submitted.connect(_on_sell_amount_submitted)
	bank_dialog.amount_submitted.connect(_on_bank_amount_submitted)
	hospital_dialog.amount_submitted.connect(_on_hospital_amount_submitted)
	debt_dialog.amount_submitted.connect(_on_debt_amount_submitted)
	house_dialog.amount_submitted.connect(_on_house_amount_submitted)

func _create_amount_dialog(dialog_name: String) -> Control:
	var dialog = amount_dialog_script.new()
	dialog.name = dialog_name
	dialog.visible = false
	add_child(dialog)
	_apply_retro_theme(dialog)
	return dialog

func _create_content_surfaces() -> void:
	content_dialog = _create_content_dialog("ContentDialog")
	boss_dialog = _create_content_dialog("BossDialog")
	_create_top_content_button("TipButton", "提示", 298, _on_tip_pressed)
	_create_top_content_button("StoryButton", "故事", 352, _on_story_pressed)
	_create_top_content_button("HelpButton", "帮助", 406, _on_help_pressed)
	_create_top_content_button("AboutButton", "关于", 460, _on_about_pressed)
	_create_top_content_button("DeclareButton", "声明", 514, _on_declare_pressed)
	var old_boss_label := get_node_or_null("LocationPanel/BossLabel") as Label
	if old_boss_label != null:
		old_boss_label.visible = false
	var boss_button := Button.new()
	boss_button.name = "BossButton"
	boss_button.text = "老板来了"
	boss_button.position = Vector2(36, 158)
	boss_button.size = Vector2(92, 25)
	boss_button.focus_mode = Control.FOCUS_NONE
	boss_button.pressed.connect(_on_boss_pressed)
	location_grid.get_parent().add_child(boss_button)
	_style_retro_button(boss_button)

func _create_score_table() -> void:
	var body_label := high_scores_dialog.get_node_or_null("BodyLabel") as Label
	if body_label != null:
		body_label.visible = false
	score_table = score_table_script.new()
	score_table.name = "ScoreTable"
	score_table.position = Vector2(12, 40)
	score_table.size = Vector2(336, 170)
	high_scores_dialog.add_child(score_table)
	score_table.add_theme_font_override("font", ui_font)
	score_table.add_theme_font_size_override("font_size", 12)
	score_table.add_theme_color_override("font_color", Color.BLACK)
	score_table.add_theme_color_override("font_selected_color", Color.WHITE)
	score_table.add_theme_color_override("title_button_color", Color(0.91, 0.91, 0.91))
	score_table.add_theme_color_override("guide_color", Color(0.78, 0.78, 0.78))
	score_table.add_theme_constant_override("v_separation", 0)

func _create_content_dialog(dialog_name: String) -> Control:
	var dialog = content_dialog_script.new()
	dialog.name = dialog_name
	dialog.visible = false
	add_child(dialog)
	_apply_retro_theme(dialog)
	return dialog

func _create_top_content_button(button_name: String, button_text: String, x_position: int, handler: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	button.position = Vector2(x_position, 27)
	button.size = Vector2(48, 19)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	add_child(button)
	_style_retro_button(button)
	return button

func _show_content_entry(key: String, dialog_size: Vector2i) -> void:
	var entry: Dictionary = content_data.get(key, {})
	content_dialog.configure(String(entry.get("title", key)), String(entry.get("body", "")))
	content_dialog.popup_centered(dialog_size)

func _tip_text(index: int) -> String:
	if tips.is_empty():
		return ""
	var tip = tips[index % tips.size()]
	if typeof(tip) == TYPE_DICTIONARY:
		return String(tip.get("text", ""))
	return String(tip)

func _goods_name(goods_id: String) -> String:
	return String(goods_by_id.get(goods_id, {}).get("name", goods_id))

func _truncate_goods_name(goods_name: String) -> String:
	if goods_name.length() <= 10:
		return goods_name
	return goods_name.substr(0, 9) + "..."

func _configure_fonts() -> void:
	ui_font.font_names = PackedStringArray(["SimSun", "宋体", "Songti SC", "Microsoft YaHei", "PingFang SC", "Arial Unicode MS"])

func _configure_tree(tree: Tree, column_widths: Array) -> void:
	tree.columns = column_widths.size()
	tree.hide_root = true
	tree.column_titles_visible = false
	for column in column_widths.size():
		tree.set_column_expand(column, false)
		tree.set_column_custom_minimum_width(column, int(column_widths[column]))
	tree.add_theme_font_override("font", ui_font)
	tree.add_theme_font_size_override("font_size", 14)
	tree.add_theme_color_override("font_color", Color.BLACK)
	tree.add_theme_color_override("font_selected_color", Color.WHITE)
	tree.add_theme_color_override("guide_color", Color(0.84, 0.84, 0.84))
	tree.add_theme_stylebox_override("selected", _make_tree_selection_style(false))
	tree.add_theme_stylebox_override("selected_focus", _make_tree_selection_style(true))
	tree.add_theme_constant_override("v_separation", 0)

func _apply_retro_theme(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_font_override("font", ui_font)
		if label != message_label:
			label.add_theme_color_override("font_color", Color.BLACK)
	if node is Button:
		_style_retro_button(node as Button)
	for child in node.get_children():
		_apply_retro_theme(child)

func _style_retro_button(button: Button) -> void:
	button.add_theme_font_override("font", ui_font)
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

func _make_tree_selection_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TREE_SELECTED_BG if focused else Color(0.08, 0.22, 0.62)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style

func _apply_tree_row_highlight(tree: Tree) -> void:
	var selected := tree.get_selected()
	var root := tree.get_root()
	if root == null:
		return
	var row := root.get_first_child()
	while row != null:
		for column in tree.columns:
			if row == selected:
				row.set_custom_bg_color(column, TREE_SELECTED_BG)
				row.set_custom_color(column, Color.WHITE)
			else:
				row.clear_custom_bg_color(column)
				row.clear_custom_color(column)
		row = row.get_next()
