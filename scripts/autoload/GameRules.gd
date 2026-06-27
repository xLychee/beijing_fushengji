extends Node

const GOODS_PATH := "res://data/goods.json"
const COMMERCIAL_EVENTS_PATH := "res://data/commercial_events.json"
const HEALTH_EVENTS_PATH := "res://data/health_events.json"
const MONEY_EVENTS_PATH := "res://data/money_events.json"
const HEAL_COST_PER_POINT := 35
const HOUSE_RENT_COST := 500
const HOUSE_CAPACITY_GAIN := 10
const INTERNET_CAFE_REWARD := 50
const INTERNET_CAFE_MAX_VISITS := 3

func new_game() -> Dictionary:
	GameState.reset()
	var settings := SaveManager.load_settings()
	GameState.sound_enabled = bool(settings.get("sound_enabled", true))
	GameState.hacker_events_enabled = bool(settings.get("hacker_events_enabled", false))
	GameState.market_prices = generate_market_prices(3)
	return _result([{"type": "diary", "text": "俺来到了北京。发财是唯一的目标。"}])

func load_goods() -> Array:
	return _load_json_array(GOODS_PATH)

func load_commercial_events() -> Array:
	return _load_json_array(COMMERCIAL_EVENTS_PATH)

func load_health_events() -> Array:
	return _load_json_array(HEALTH_EVENTS_PATH)

func load_money_events() -> Array:
	return _load_json_array(MONEY_EVENTS_PATH)

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
	var messages: Array = [{"type": "diary", "text": "俺换了个地方，黑市行情又变了。"}]
	var event_result := apply_travel_events()
	messages.append_array(event_result.get("messages", []))
	if GameState.game_over:
		return {
			"ok": true,
			"messages": messages,
			"state_changed": true,
			"game_over": true,
		}
	GameState.time_left = max(GameState.time_left - 1, 0)
	GameState.day = GameState.MAX_DAYS - GameState.time_left
	if GameState.time_left == 0:
		GameState.game_over = true
	return _result(messages)

func apply_cash_and_debt_interest() -> void:
	GameState.debt += int(GameState.debt * 0.10)
	GameState.bank += int(GameState.bank * 0.01)

func apply_travel_events(event_plan: Dictionary = {}) -> Dictionary:
	var messages: Array = []
	if event_plan.has("commercial"):
		for event in _normalize_event_list(event_plan["commercial"]):
			messages.append_array(apply_commercial_event(event).get("messages", []))
	elif GameState.random_events_enabled:
		for event in load_commercial_events():
			if _event_triggers(event, 950):
				messages.append_array(apply_commercial_event(event).get("messages", []))

	if event_plan.has("health"):
		messages.append_array(apply_health_event(event_plan["health"]).get("messages", []))
	elif GameState.random_events_enabled:
		for event in load_health_events():
			if _event_triggers(event, 1000):
				messages.append_array(apply_health_event(event).get("messages", []))
				break

	if event_plan.has("money"):
		messages.append_array(apply_money_event(event_plan["money"]).get("messages", []))
	elif GameState.random_events_enabled:
		for event in load_money_events():
			if _event_triggers(event, 1000):
				messages.append_array(apply_money_event(event).get("messages", []))
				break
		if randi_range(0, 999) % 25 == 0:
			messages.append_array(apply_hacker_event().get("messages", []))

	if GameState.debt > 100000:
		GameState.health = max(GameState.health - 30, 0)
		messages.append({"type": "diary", "text": "俺欠钱太多，村长带一群人打了俺一顿!", "sound": "kill.wav"})
		if GameState.health <= 0:
			GameState.game_over = true
	return _result(messages)

func apply_commercial_event(event: Dictionary) -> Dictionary:
	var messages: Array = []
	var goods_id := String(event.get("goods_id", ""))
	if goods_id != "" and not GameState.market_prices.has(goods_id):
		return _empty_result()
	if String(event.get("message", "")) != "":
		messages.append({"type": "news", "text": String(event["message"])})
	if goods_id != "":
		var price := int(GameState.market_prices[goods_id])
		var multiplier := int(event.get("price_multiplier", 0))
		var divisor := int(event.get("price_divisor", 0))
		if multiplier > 0:
			price *= multiplier
		if divisor > 0:
			price = max(int(price / divisor), 1)
		GameState.market_prices[goods_id] = price
		var grant_count := int(event.get("grant_count", 0))
		if grant_count > 0:
			var added_count := _grant_goods(goods_id, grant_count)
			if added_count < grant_count:
				messages.append({"type": "diary", "text": "可惜!俺的房子太小，只能放%d个物品。" % GameState.capacity})
	var debt_delta := int(event.get("debt_delta", 0))
	if debt_delta != 0:
		GameState.debt = max(GameState.debt + debt_delta, 0)
	return _result(messages)

func apply_health_event(event: Dictionary) -> Dictionary:
	var damage := int(event.get("damage", 0))
	if damage <= 0:
		return _empty_result()
	GameState.health = max(GameState.health - damage, 0)
	var message := "%s俺的健康减少了%d点。" % [String(event.get("message", "")), damage]
	var result_message := {"type": "diary", "text": message}
	if event.has("sound"):
		result_message["sound"] = String(event["sound"])
	var messages: Array = [result_message]
	if GameState.health <= 0:
		GameState.game_over = true
		messages.append({"type": "diary", "text": "俺倒在街头，日记本上写着：“北京需要俺健康地活着!”", "sound": "death.wav"})
	return _result(messages)

func apply_money_event(event: Dictionary) -> Dictionary:
	var ratio := int(event.get("loss_ratio", 0))
	if ratio <= 0:
		return _empty_result()
	var target := String(event.get("target", "cash"))
	var messages: Array = []
	if target == "bank":
		if GameState.bank <= 0:
			return _empty_result()
		GameState.bank = max(int(GameState.bank / 100) * (100 - ratio), 0)
		messages.append({"type": "diary", "text": "%s俺的存款减少了%d%%，哎呀!" % [String(event.get("message", "")), ratio]})
	else:
		GameState.cash = max(int(GameState.cash / 100) * (100 - ratio), 0)
		messages.append({"type": "diary", "text": "%s俺的银子减少了%d%%。" % [String(event.get("message", "")), ratio]})
	return _result(messages)

func apply_hacker_event(event: Dictionary = {}) -> Dictionary:
	if not GameState.hacker_events_enabled or GameState.bank < 1000:
		return _empty_result(false)
	var delta := int(event.get("delta", 0))
	if delta == 0:
		if GameState.bank > 100000:
			var amount := int(GameState.bank / (2 + randi_range(0, 19)))
			delta = -amount if randi_range(0, 19) % 3 != 0 else amount
		else:
			delta = int(GameState.bank / (1 + randi_range(0, 14)))
	if delta == 0:
		return _empty_result(false)
	GameState.bank = max(GameState.bank + delta, 0)
	var verb := "增加" if delta > 0 else "减少"
	return _result([{
		"type": "diary",
		"text": "黑客入侵银行网络，疯狂修改数据库，俺的存款%s了%d。" % [verb, abs(delta)]
	}])

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
	_save_current_settings()
	var label := "打开" if GameState.sound_enabled else "关闭"
	return _result([{"type": "diary", "text": "声音已经%s。" % label}])

func toggle_hacker_events() -> Dictionary:
	GameState.hacker_events_enabled = not GameState.hacker_events_enabled
	_save_current_settings()
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
		SaveManager.load_high_scores(),
		"玩家",
		GameState.score(),
		GameState.health,
		_fame_label()
	)
	SaveManager.save_high_scores(high_scores)
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

func _empty_result(ok := true) -> Dictionary:
	return {
		"ok": ok,
		"messages": [],
		"state_changed": false,
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

func _grant_goods(goods_id: String, count: int) -> int:
	var available_space: int = max(GameState.capacity - GameState.inventory_total(), 0)
	var add_count: int = min(count, available_space)
	if add_count <= 0:
		return 0
	var item = GameState.inventory.get(goods_id, {"quantity": 0, "average_price": 0})
	var old_quantity := int(item.get("quantity", 0))
	var average_price := int(item.get("average_price", 0))
	GameState.inventory[goods_id] = {
		"quantity": old_quantity + add_count,
		"average_price": average_price,
	}
	return add_count

func _event_triggers(event: Dictionary, upper: int) -> bool:
	var frequency := int(event.get("frequency", 0))
	if frequency <= 0:
		return false
	return randi_range(0, upper - 1) % frequency == 0

func _normalize_event_list(value) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		return [value]
	return []

func _save_current_settings() -> void:
	SaveManager.save_settings({
		"sound_enabled": GameState.sound_enabled,
		"hacker_events_enabled": GameState.hacker_events_enabled,
	})

func _fame_label() -> String:
	if GameState.fame >= 90:
		return "杰出青年"
	if GameState.fame >= 70:
		return "普通群众"
	if GameState.fame >= 40:
		return "争议人物"
	return "臭名昭著"
