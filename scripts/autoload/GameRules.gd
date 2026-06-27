extends Node

const GOODS_PATH := "res://data/goods.json"

func new_game() -> Dictionary:
	GameState.reset()
	GameState.market_prices = generate_market_prices(3)
	return _result([{"type": "diary", "text": "俺来到了北京。发财是唯一的目标。"}])

func load_goods() -> Array:
	return _load_json_array(GOODS_PATH)

func generate_market_prices(leaveout: int) -> Dictionary:
	var goods := load_goods()
	var prices := {}
	for item in goods:
		var id := String(item["id"])
		var base_price := int(item["base_price"])
		var random_range := int(item["random_range"])
		prices[id] = base_price + randi_range(0, max(random_range - 1, 0))
	for _index in range(leaveout):
		if prices.is_empty():
			break
		var keys := prices.keys()
		var removed_id = keys[randi_range(0, keys.size() - 1)]
		prices.erase(removed_id)
	return prices

func travel_to(location_id: String) -> Dictionary:
	if GameState.game_over:
		return _failure("游戏已经结束。")
	if location_id == "":
		return _failure("还没有选定地点。")
	if GameState.current_location_id == location_id:
		return _failure("俺已经在这里了。")
	GameState.current_location_id = location_id
	var leaveout := 0 if GameState.time_left <= 2 else 3
	GameState.market_prices = generate_market_prices(leaveout)
	apply_cash_and_debt_interest()
	GameState.time_left = max(GameState.time_left - 1, 0)
	GameState.day = GameState.MAX_DAYS - GameState.time_left
	if GameState.time_left == 0:
		GameState.game_over = true
	return _result([{"type": "diary", "text": "俺换了个地方，黑市行情又变了。"}])

func apply_cash_and_debt_interest() -> void:
	GameState.debt += int(GameState.debt * 0.10)
	GameState.bank += int(GameState.bank * 0.01)

func buy(goods_id: String, count: int) -> Dictionary:
	if count <= 0:
		return _failure("数量不对。")
	if not GameState.market_prices.has(goods_id):
		return _failure("黑市上没有这个货。")
	var price := int(GameState.market_prices[goods_id])
	var total_cost := price * count
	if total_cost > GameState.cash:
		return _failure("俺的现金不够。")
	if GameState.inventory_total() + count > GameState.capacity:
		return _failure("俺租的房子放不下。")
	var item = GameState.inventory.get(goods_id, {"quantity": 0, "average_price": 0})
	var old_quantity := int(item["quantity"])
	var old_average := int(item["average_price"])
	var new_quantity := old_quantity + count
	var new_average := int(((old_average * old_quantity) + total_cost) / new_quantity)
	GameState.inventory[goods_id] = {
		"quantity": new_quantity,
		"average_price": new_average
	}
	GameState.cash -= total_cost
	return _result([{"type": "diary", "text": "买进了%d个%s。" % [count, _goods_name(goods_id)]}])

func sell(goods_id: String, count: int) -> Dictionary:
	if count <= 0:
		return _failure("数量不对。")
	if not GameState.market_prices.has(goods_id):
		return _failure("黑市上没有这个货。")
	if not GameState.inventory.has(goods_id):
		return _failure("俺没有这个货。")
	var item = GameState.inventory[goods_id]
	var owned := int(item["quantity"])
	if count > owned:
		return _failure("俺没这么多货。")
	var price := int(GameState.market_prices[goods_id])
	GameState.cash += price * count
	var remaining := owned - count
	if remaining == 0:
		GameState.inventory.erase(goods_id)
	else:
		item["quantity"] = remaining
		GameState.inventory[goods_id] = item
	return _result([{"type": "diary", "text": "卖出了%d个%s。" % [count, _goods_name(goods_id)]}])

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

func _result(messages: Array) -> Dictionary:
	return {
		"ok": true,
		"messages": messages,
		"state_changed": true,
		"game_over": GameState.game_over
	}

func _failure(message: String) -> Dictionary:
	return {
		"ok": false,
		"messages": [{"type": "diary", "text": message}],
		"state_changed": false,
		"game_over": GameState.game_over
	}

func _goods_name(goods_id: String) -> String:
	for item in load_goods():
		if String(item["id"]) == goods_id:
			return String(item["name"])
	return goods_id
