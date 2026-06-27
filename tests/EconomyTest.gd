extends Node

var failed := false

func _ready() -> void:
	if not GameRules.has_method("travel_to"):
		_fail("GameRules.travel_to is missing")
		return
	if not GameRules.has_method("buy"):
		_fail("GameRules.buy is missing")
		return
	if not GameRules.has_method("sell"):
		_fail("GameRules.sell is missing")
		return
	_test_travel_advances_day_and_applies_interest()
	if failed:
		return
	_test_buy_and_sell_update_cash_and_inventory()
	if failed:
		return
	_test_selling_flagged_goods_reduces_fame()
	if failed:
		return
	_test_invalid_trades_are_rejected()
	if failed:
		return
	print("Economy test passed")
	get_tree().quit(0)

func _test_travel_advances_day_and_applies_interest() -> void:
	GameRules.new_game()
	var old_prices := GameState.market_prices.duplicate()
	var result = GameRules.travel_to("jianguomen")
	_require(result["ok"] == true, "travel should succeed")
	_require(GameState.current_location_id == "jianguomen", "travel should set current location")
	_require(GameState.day == 1, "travel should advance day")
	_require(GameState.time_left == 39, "travel should reduce time left")
	_require(GameState.debt == 5500, "travel should apply 10 percent debt interest")
	_require(GameState.bank == 0, "empty bank should stay zero")
	_require(GameState.market_prices.size() == 5, "normal market should show 5 goods")
	_require(GameState.market_prices != old_prices, "travel should refresh market prices")

func _test_buy_and_sell_update_cash_and_inventory() -> void:
	GameRules.new_game()
	GameState.market_prices = {"imported_cigarettes": 100}
	var buy_result = GameRules.buy("imported_cigarettes", 3)
	_require(buy_result["ok"] == true, "buy should succeed")
	_require(GameState.cash == 1700, "buy should reduce cash")
	_require(GameState.inventory_total() == 3, "buy should increase inventory total")
	_require(GameState.inventory["imported_cigarettes"]["quantity"] == 3, "buy should store quantity")
	_require(GameState.inventory["imported_cigarettes"]["average_price"] == 100, "buy should store average price")

	GameState.market_prices = {"imported_cigarettes": 150}
	var sell_result = GameRules.sell("imported_cigarettes", 2)
	_require(sell_result["ok"] == true, "sell should succeed")
	_require(GameState.cash == 2000, "sell should increase cash at market price")
	_require(GameState.inventory_total() == 1, "sell should decrease inventory total")
	_require(GameState.inventory["imported_cigarettes"]["quantity"] == 1, "sell should leave remaining quantity")

func _test_selling_flagged_goods_reduces_fame() -> void:
	GameRules.new_game()
	GameState.market_prices = {"fake_liquor": 1000}
	GameState.inventory = {"fake_liquor": {"quantity": 2, "average_price": 900}}
	var sell_result = GameRules.sell("fake_liquor", 1)
	_require(sell_result["ok"] == true, "selling flagged goods should succeed")
	_require(GameState.fame == 90, "selling fake liquor should reduce fame by configured penalty")

func _test_invalid_trades_are_rejected() -> void:
	GameRules.new_game()
	GameState.market_prices = {"imported_cigarettes": 100}
	var too_expensive = GameRules.buy("imported_cigarettes", 1000)
	_require(too_expensive["ok"] == false, "buy should reject unaffordable trade")
	_require(GameState.cash == 2000, "failed buy should preserve cash")
	_require(GameState.inventory_total() == 0, "failed buy should preserve inventory")

	var not_owned = GameRules.sell("imported_cigarettes", 1)
	_require(not_owned["ok"] == false, "sell should reject unowned goods")
	_require(GameState.cash == 2000, "failed sell should preserve cash")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Economy test failed: %s" % message)
	get_tree().quit(1)
