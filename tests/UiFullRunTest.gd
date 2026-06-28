extends Node

var failed := false

func _ready() -> void:
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	GameState.random_events_enabled = false
	GameState.debt = 0
	GameState.cash = 10000
	DialogManager.clear()
	main.get_node("MessageDialog").hide()

	var location_labels := {
		"xizhimen": "西直门",
		"jishuitan": "积水潭",
		"dongzhimen": "东直门",
		"pingguoyuan": "苹果园",
		"gongzhufen": "公主坟",
		"fuxingmen": "复兴门",
		"jianguomen": "建国门",
		"changchunjie": "长椿街",
		"chongwenmen": "崇文门",
		"beijing_station": "北京站",
	}
	var route := [
		"xizhimen",
		"jishuitan",
		"dongzhimen",
		"jianguomen",
		"beijing_station",
		"fuxingmen",
		"gongzhufen",
		"pingguoyuan",
	]

	var steps := 0
	while not GameState.game_over and steps < GameState.MAX_DAYS:
		await _sell_first_visible_inventory(main)
		if failed:
			return
		await _buy_first_affordable_goods(main)
		if failed:
			return

		var location_id: String = route[steps % route.size()]
		if location_id == GameState.current_location_id:
			location_id = route[(steps + 1) % route.size()]
		_require(_press_location_button(main, String(location_labels[location_id])), "location button should be reachable in the UI")
		if failed:
			return
		await get_tree().process_frame
		if GameState.game_over:
			break
		await _drain_dialogs(main)
		if failed:
			return
		steps += 1

	_require(GameState.game_over == true, "UI full run should reach game over")
	_require(GameState.day == GameState.MAX_DAYS, "UI full run should end on day 40")
	_require(GameState.time_left == 0, "UI full run should consume all days")
	_require(await _advance_to_dialog_containing(main, "北京浮生结束了"), "UI full run should show final score dialog")
	if failed:
		return
	print("UI full run test passed")
	get_tree().quit(0)

func _sell_first_visible_inventory(main: Node) -> void:
	var inventory_list: Tree = main.get_node("InventoryList")
	var root := inventory_list.get_root()
	if root == null:
		return
	var row := root.get_first_child()
	while row != null:
		var goods_id := String(row.get_metadata(0))
		if GameState.market_prices.has(goods_id):
			row.select(0)
			inventory_list.item_selected.emit()
			main.get_node("SellButton").pressed.emit()
			await get_tree().process_frame
			var dialog = main.get_node("SellDialog")
			if dialog.visible:
				dialog.get_node("AmountSpinBox").value = dialog.get_node("AmountSpinBox").max_value
				dialog.get_node("OkButton").pressed.emit()
				await get_tree().process_frame
				await _drain_dialogs(main)
			return
		row = row.get_next()

func _buy_first_affordable_goods(main: Node) -> void:
	if GameState.inventory_total() >= GameState.capacity:
		return
	var market_list: Tree = main.get_node("MarketList")
	var root := market_list.get_root()
	if root == null:
		return
	var row := root.get_first_child()
	while row != null:
		var goods_id := String(row.get_metadata(0))
		var price := int(GameState.market_prices.get(goods_id, 0))
		if price > 0 and price <= GameState.cash:
			row.select(0)
			market_list.item_selected.emit()
			main.get_node("BuyButton").pressed.emit()
			await get_tree().process_frame
			var dialog = main.get_node("BuyDialog")
			if dialog.visible:
				dialog.get_node("AmountSpinBox").value = 1
				dialog.get_node("OkButton").pressed.emit()
				await get_tree().process_frame
				await _drain_dialogs(main)
			return
		row = row.get_next()

func _press_location_button(main: Node, label: String) -> bool:
	for child in main.get_node("LocationPanel/LocationGrid").get_children():
		if child is Button and String(child.text) == label:
			child.pressed.emit()
			return true
	return false

func _drain_dialogs(main: Node) -> void:
	for _attempt in range(8):
		var dialog = main.get_node("MessageDialog")
		if dialog.visible:
			dialog.get_node("OkButton").pressed.emit()
			await get_tree().process_frame
		elif DialogManager.has_messages():
			main.call("_render_next_message")
			await get_tree().process_frame
		else:
			return
	_fail("dialog queue should drain within a few clicks")

func _advance_to_dialog_containing(main: Node, text: String) -> bool:
	for _attempt in range(8):
		var dialog = main.get_node("MessageDialog")
		if dialog.visible and String(dialog.dialog_text).contains(text):
			return true
		if dialog.visible:
			dialog.get_node("OkButton").pressed.emit()
			await get_tree().process_frame
		elif DialogManager.has_messages():
			main.call("_render_next_message")
			await get_tree().process_frame
		else:
			return false
	return false

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("UI full run test failed: %s" % message)
	get_tree().quit(1)
