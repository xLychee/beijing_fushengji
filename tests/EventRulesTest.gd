extends Node

var failed := false

func _ready() -> void:
	_require_methods([
		"load_commercial_events",
		"load_health_events",
		"load_money_events",
		"apply_commercial_event",
		"apply_health_event",
		"apply_money_event",
		"apply_hacker_event",
		"apply_travel_events",
	])
	if failed:
		return
	_test_event_data_is_loaded()
	if failed:
		return
	_test_commercial_event_changes_price_and_grants_goods()
	if failed:
		return
	_test_health_event_reduces_health_and_reports_sound()
	if failed:
		return
	_test_money_events_reduce_cash_or_bank()
	if failed:
		return
	_test_hacker_event_respects_setting_and_bank_balance()
	if failed:
		return
	_test_travel_pipeline_can_apply_forced_events()
	if failed:
		return
	print("Event rules test passed")
	get_tree().quit(0)

func _require_methods(methods: Array[String]) -> void:
	for method in methods:
		_require(GameRules.has_method(method), "GameRules.%s is missing" % method)

func _test_event_data_is_loaded() -> void:
	_require(GameRules.load_commercial_events().size() == 18, "commercial event data should mirror original event count")
	_require(GameRules.load_health_events().size() == 12, "health event data should mirror original event count")
	_require(GameRules.load_money_events().size() == 7, "money event data should mirror original event count")

func _test_commercial_event_changes_price_and_grants_goods() -> void:
	GameRules.new_game()
	GameState.market_prices = {"pirated_vcd_games": 20}
	GameState.capacity = 1
	var result = GameRules.apply_commercial_event({
		"message": "测试：盗版碟突然紧俏。",
		"goods_id": "pirated_vcd_games",
		"price_multiplier": 4,
		"grant_count": 3,
		"debt_delta": 2500,
	})
	_require(result["ok"] == true, "commercial event should succeed")
	_require(GameState.market_prices["pirated_vcd_games"] == 80, "commercial event should multiply market price")
	_require(GameState.inventory_total() == 1, "commercial event should respect storage capacity")
	_require(GameState.inventory["pirated_vcd_games"]["average_price"] == 0, "granted goods should have zero average cost")
	_require(GameState.debt == 7500, "commercial event should apply configured debt delta")

func _test_health_event_reduces_health_and_reports_sound() -> void:
	GameRules.new_game()
	var result = GameRules.apply_health_event({
		"message": "测试：被人打了。",
		"damage": 130,
		"sound": "hit.wav",
	})
	_require(result["ok"] == true, "health event should succeed")
	_require(GameState.health == 0, "health event should clamp health at zero")
	_require(String(result["messages"][0].get("sound", "")) == "hit.wav", "health event should preserve sound cue")
	_require(result["game_over"] == true, "zero health should end the game")

func _test_money_events_reduce_cash_or_bank() -> void:
	GameRules.new_game()
	GameState.cash = 2000
	var cash_result = GameRules.apply_money_event({
		"message": "测试：被罚款。",
		"target": "cash",
		"loss_ratio": 40,
	})
	_require(cash_result["ok"] == true, "cash money event should succeed")
	_require(GameState.cash == 1200, "cash money event should reduce cash by ratio")

	GameState.bank = 1000
	var bank_result = GameRules.apply_money_event({
		"message": "测试：乱收费。",
		"target": "bank",
		"loss_ratio": 15,
	})
	_require(bank_result["ok"] == true, "bank money event should succeed")
	_require(GameState.bank == 850, "bank money event should reduce bank by ratio")

func _test_hacker_event_respects_setting_and_bank_balance() -> void:
	GameRules.new_game()
	GameState.hacker_events_enabled = false
	GameState.bank = 100000
	var disabled_result = GameRules.apply_hacker_event({"delta": -1000})
	_require(disabled_result["ok"] == false, "disabled hacker event should not apply")
	_require(GameState.bank == 100000, "disabled hacker event should preserve bank")

	GameState.hacker_events_enabled = true
	var enabled_result = GameRules.apply_hacker_event({"delta": -1000})
	_require(enabled_result["ok"] == true, "enabled hacker event should apply")
	_require(GameState.bank == 99000, "hacker event should apply deterministic bank delta")

func _test_travel_pipeline_can_apply_forced_events() -> void:
	GameRules.new_game()
	GameState.cash = 2000
	GameState.bank = 1000
	GameRules.apply_cash_and_debt_interest()
	var result = GameRules.apply_travel_events({
		"health": {"message": "测试：赶路摔了一跤。", "damage": 5, "sound": "hit.wav"},
		"money": {"message": "测试：钱包少了。", "target": "cash", "loss_ratio": 10},
	})
	_require(result["ok"] == true, "travel with forced events should succeed")
	_require(GameState.health == 95, "travel should apply forced health event")
	_require(GameState.cash == 1800, "travel should apply forced money event after interest")
	_require(GameState.bank == 1010, "travel should still apply bank interest")
	_require(Array(result["messages"]).size() >= 2, "travel event pipeline should return queued event messages")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Event rules test failed: %s" % message)
	get_tree().quit(1)
