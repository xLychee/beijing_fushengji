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
