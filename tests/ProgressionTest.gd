extends Node

var failed := false

func _ready() -> void:
	_require_methods([
		"deposit",
		"withdraw",
		"repay_debt",
		"heal",
		"rent_larger_house",
		"visit_internet_cafe",
		"toggle_city_mode",
		"finish_game",
		"toggle_sound",
		"toggle_hacker_events",
	])
	if failed:
		return
	_test_bank_and_debt_rules()
	if failed:
		return
	_test_hospital_house_and_internet_cafe_rules()
	if failed:
		return
	_test_settings_rules()
	if failed:
		return
	_test_city_toggle_and_finish_game()
	if failed:
		return
	_test_travel_on_last_day_finishes_game()
	if failed:
		return
	_test_high_score_recording()
	if failed:
		return
	print("Progression test passed")
	get_tree().quit(0)

func _require_methods(methods: Array[String]) -> void:
	for method in methods:
		_require(GameRules.has_method(method), "GameRules.%s is missing" % method)

func _test_bank_and_debt_rules() -> void:
	GameRules.new_game()
	var deposit_result = GameRules.deposit(500)
	_require(deposit_result["ok"] == true, "deposit should succeed")
	_require(GameState.cash == 1500, "deposit should reduce cash")
	_require(GameState.bank == 500, "deposit should increase bank")

	var withdraw_result = GameRules.withdraw(200)
	_require(withdraw_result["ok"] == true, "withdraw should succeed")
	_require(GameState.cash == 1700, "withdraw should increase cash")
	_require(GameState.bank == 300, "withdraw should reduce bank")

	var repay_result = GameRules.repay_debt(700)
	_require(repay_result["ok"] == true, "repay debt should succeed")
	_require(GameState.cash == 1000, "repay debt should reduce cash")
	_require(GameState.debt == 4300, "repay debt should reduce debt")

	var overpay_result = GameRules.repay_debt(999999)
	_require(overpay_result["ok"] == false, "repay debt should reject unaffordable amount")
	_require(GameState.cash == 1000, "failed repay should preserve cash")
	_require(GameState.debt == 4300, "failed repay should preserve debt")

func _test_hospital_house_and_internet_cafe_rules() -> void:
	GameRules.new_game()
	GameState.health = 40
	GameState.cash = 100000
	var heal_result = GameRules.heal(25)
	_require(heal_result["ok"] == true, "heal should succeed")
	_require(GameState.health == 65, "heal should increase health by points")
	_require(GameState.cash == 12500, "heal should cost 3500 per point")

	GameState.cash = 30000
	var house_result = GameRules.rent_larger_house()
	_require(house_result["ok"] == true, "rent larger house should succeed")
	_require(GameState.capacity == 110, "renting should add storage capacity")
	_require(GameState.cash == 5000, "renting should follow original cash threshold cost")

	GameState.cash = 15
	var wangba_result = GameRules.visit_internet_cafe(5)
	_require(wangba_result["ok"] == true, "internet cafe should succeed")
	_require(GameState.wangba_visits == 1, "internet cafe should count visits")
	_require(GameState.cash == 20, "internet cafe should add the original 1..10 reward")

func _test_city_toggle_and_finish_game() -> void:
	GameRules.new_game()
	var toggle_result = GameRules.toggle_city_mode()
	_require(toggle_result["ok"] == true, "city toggle should succeed")
	_require(GameState.city == "alternate", "city toggle should switch city")
	_require(GameState.current_location_id == "", "city toggle should clear location")
	_require(GameState.market_prices.size() == 5, "city toggle should refresh market")

	GameState.inventory = {
		"imported_cigarettes": {"quantity": 2, "average_price": 100},
		"pirated_vcd_games": {"quantity": 3, "average_price": 10},
	}
	GameState.market_prices = {
		"imported_cigarettes": 120,
		"pirated_vcd_games": 20,
	}
	var finish_result = GameRules.finish_game()
	_require(finish_result["ok"] == true, "finish game should succeed")
	_require(GameState.game_over == true, "finish game should mark game over")
	_require(GameState.inventory_total() == 0, "finish game should clear inventory")
	_require(GameState.cash == 2300, "finish game should liquidate inventory")
	_require(int(finish_result["score"]) == GameState.score(), "finish result should include score")
	_require(finish_result.has("high_scores"), "finish result should include high scores")
	if failed:
		return
	_require(Array(finish_result["high_scores"]).size() <= 10, "finish high scores should be capped")

func _test_settings_rules() -> void:
	GameRules.new_game()
	GameState.sound_enabled = true
	GameState.hacker_events_enabled = false
	var sound_result = GameRules.toggle_sound()
	_require(sound_result["ok"] == true, "sound toggle should succeed")
	_require(GameState.sound_enabled == false, "sound toggle should flip sound setting")

	var hacker_result = GameRules.toggle_hacker_events()
	_require(hacker_result["ok"] == true, "hacker event toggle should succeed")
	_require(GameState.hacker_events_enabled == true, "hacker event toggle should flip setting")

func _test_high_score_recording() -> void:
	_require(SaveManager.has_method("record_high_score"), "SaveManager.record_high_score is missing")
	if failed:
		return
	var scores := [
		{"name": "low", "score": 10, "health": 1, "fame": "低"},
		{"name": "mid", "score": 20, "health": 2, "fame": "中"},
	]
	var updated = SaveManager.record_high_score(scores, "top", 30, 100, "高")
	_require(updated.size() == 3, "record high score should append score")
	_require(String(updated[0]["name"]) == "top", "record high score should sort descending")

func _test_travel_on_last_day_finishes_game() -> void:
	GameRules.new_game()
	GameState.time_left = 1
	GameState.day = 39
	GameState.current_location_id = "xizhimen"
	GameState.inventory = {"imported_cigarettes": {"quantity": 2, "average_price": 100}}
	GameState.market_prices = {"imported_cigarettes": 120}
	var result = GameRules.travel_to("jianguomen")
	_require(result["ok"] == true, "last-day travel should succeed")
	_require(result["game_over"] == true, "last-day travel should end game")
	_require(GameState.inventory_total() == 0, "last-day travel should liquidate inventory")
	_require(GameState.cash == 2240, "last-day travel should add liquidation cash")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Progression test failed: %s" % message)
	get_tree().quit(1)
