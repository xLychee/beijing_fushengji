extends Node

var failed := false

func _ready() -> void:
	GameRules.new_game()
	GameState.random_events_enabled = false
	GameState.debt = 0
	GameState.cash = 10000
	var locations := [
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
	while not GameState.game_over and steps < 60:
		_trade_safely()
		var location_id: String = locations[steps % locations.size()]
		if location_id == GameState.current_location_id:
			location_id = locations[(steps + 1) % locations.size()]
		var result = GameRules.travel_to(location_id)
		_require(result["ok"] == true, "travel should succeed during full run")
		if failed:
			return
		steps += 1

	_require(GameState.game_over == true, "full run should reach game over")
	_require(GameState.day == GameState.MAX_DAYS, "full run should end on day 40")
	_require(GameState.inventory_total() == 0, "full run should liquidate inventory")
	_require(GameState.time_left == 0, "full run should consume all time")
	_require(steps <= 40, "full run should not need extra travel after day 40")
	if failed:
		return
	print("Full run test passed")
	get_tree().quit(0)

func _trade_safely() -> void:
	for goods_id in GameState.inventory.keys():
		if GameState.market_prices.has(goods_id):
			var quantity := int(GameState.inventory[goods_id].get("quantity", 0))
			if quantity > 0:
				GameRules.sell(goods_id, quantity)
	if GameState.inventory_total() >= GameState.capacity:
		return
	for goods_id in GameState.market_prices.keys():
		var price := int(GameState.market_prices[goods_id])
		if price > 0 and price <= GameState.cash:
			GameRules.buy(goods_id, 1)
			return

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Full run test failed: %s" % message)
	get_tree().quit(1)
