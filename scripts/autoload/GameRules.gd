extends Node

const GOODS_PATH := "res://data/goods.json"
const HEAL_COST_PER_POINT := 35
const HOUSE_RENT_COST := 500
const HOUSE_CAPACITY_GAIN := 10
const INTERNET_CAFE_REWARD := 50
const INTERNET_CAFE_MAX_VISITS := 3

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
	if GameState.time_left <= 1:
		apply_cash_and_debt_interest()
		GameState.time_left = 0
		GameState.day = GameState.MAX_DAYS
		var finish_result := finish_game()
		var messages: Array = [{"type": "diary", "text": "最后一天到了。"}]
		messages.append_array(finish_result["messages"])
		finish_result["messages"] = messages
		return finish_result
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
	var fame_penalty := _goods_fame_penalty(goods_id) * count
	if fame_penalty > 0:
		GameState.fame = max(GameState.fame - fame_penalty, 0)
	var remaining := owned - count
	if remaining == 0:
		GameState.inventory.erase(goods_id)
	else:
		item["quantity"] = remaining
		GameState.inventory[goods_id] = item
	return _result([{"type": "diary", "text": "卖出了%d个%s。" % [count, _goods_name(goods_id)]}])

func toggle_sound() -> Dictionary:
	GameState.sound_enabled = not GameState.sound_enabled
	var label := "打开" if GameState.sound_enabled else "关闭"
	return _result([{"type": "diary", "text": "声音已经%s。" % label}])

func toggle_hacker_events() -> Dictionary:
	GameState.hacker_events_enabled = not GameState.hacker_events_enabled
	var label := "打开" if GameState.hacker_events_enabled else "关闭"
	return _result([{"type": "diary", "text": "黑客事件已经%s。" % label}])

func deposit(amount: int) -> Dictionary:
	if amount <= 0:
		return _failure("存款数目不对。")
	if amount > GameState.cash:
		return _failure("俺没有这么多现金。")
	GameState.cash -= amount
	GameState.bank += amount
	return _result([{"type": "diary", "text": "往银行存了%d元。" % amount}])

func withdraw(amount: int) -> Dictionary:
	if amount <= 0:
		return _failure("取款数目不对。")
	if amount > GameState.bank:
		return _failure("银行里没有这么多钱。")
	GameState.bank -= amount
	GameState.cash += amount
	return _result([{"type": "diary", "text": "从银行取了%d元。" % amount}])

func repay_debt(amount: int) -> Dictionary:
	if amount <= 0:
		return _failure("还债数目不对。")
	if amount > GameState.cash:
		return _failure("俺的现金不够还债。")
	if GameState.debt <= 0:
		return _failure("俺已经不欠钱了。")
	var actual_amount: int = min(amount, GameState.debt)
	GameState.cash -= actual_amount
	GameState.debt -= actual_amount
	return _result([{"type": "diary", "text": "还给村长%d元。" % actual_amount}])

func heal(points: int) -> Dictionary:
	if points <= 0:
		return _failure("治疗数量不对。")
	if GameState.health >= 100:
		return _failure("俺身体好着呢。")
	var actual_points: int = min(points, 100 - GameState.health)
	var cost: int = actual_points * HEAL_COST_PER_POINT
	if cost > GameState.cash:
		return _failure("俺没钱看病。")
	GameState.cash -= cost
	GameState.health += actual_points
	return _result([{"type": "diary", "text": "花了%d元，健康恢复到%d。" % [cost, GameState.health]}])

func rent_larger_house() -> Dictionary:
	if GameState.cash < HOUSE_RENT_COST:
		return _failure("俺的现金不够租更大的房子。")
	GameState.cash -= HOUSE_RENT_COST
	GameState.capacity += HOUSE_CAPACITY_GAIN
	return _result([{"type": "diary", "text": "租到了更大的房子，能放%d个物品了。" % GameState.capacity}])

func visit_internet_cafe() -> Dictionary:
	if GameState.wangba_visits >= INTERNET_CAFE_MAX_VISITS:
		return _failure("网吧老板说俺今天来得太勤了。")
	GameState.wangba_visits += 1
	GameState.cash += INTERNET_CAFE_REWARD
	return _result([{"type": "diary", "text": "在网吧接了点小活，赚了%d元。" % INTERNET_CAFE_REWARD}])

func toggle_city_mode() -> Dictionary:
	GameState.city = "alternate" if GameState.city == "beijing" else "beijing"
	GameState.current_location_id = ""
	var leaveout := 0 if GameState.time_left <= 2 else 3
	GameState.market_prices = generate_market_prices(leaveout)
	var label := "俺要逛京城。" if GameState.city == "beijing" else "俺换个地方转转。"
	return _result([{"type": "diary", "text": label}])

func finish_game() -> Dictionary:
	var liquidation := 0
	for goods_id in GameState.inventory.keys():
		var item = GameState.inventory[goods_id]
		var quantity := int(item.get("quantity", 0))
		var price := int(GameState.market_prices.get(goods_id, item.get("average_price", 0)))
		liquidation += quantity * price
	GameState.cash += liquidation
	GameState.inventory = {}
	GameState.game_over = true
	var high_scores := SaveManager.record_high_score(
		SaveManager.default_high_scores(),
		"玩家",
		GameState.score(),
		GameState.health,
		_fame_label()
	)
	return {
		"ok": true,
		"messages": [{"type": "diary", "text": "北京浮生结束了，最后得分%d。" % GameState.score()}],
		"state_changed": true,
		"game_over": true,
		"score": GameState.score(),
		"high_scores": high_scores,
	}

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

func _goods_fame_penalty(goods_id: String) -> int:
	for item in load_goods():
		if String(item["id"]) == goods_id:
			return int(item.get("fame_penalty_on_sale", 0))
	return 0

func _fame_label() -> String:
	if GameState.fame >= 90:
		return "杰出青年"
	if GameState.fame >= 70:
		return "普通群众"
	if GameState.fame >= 40:
		return "争议人物"
	return "臭名昭著"
