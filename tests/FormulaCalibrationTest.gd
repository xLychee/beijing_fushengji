extends Node

var failed := false

func _ready() -> void:
	_test_hospital_uses_original_cost()
	if failed:
		return
	_test_house_uses_original_costs_and_capacity_limit()
	if failed:
		return
	_test_internet_cafe_uses_original_gate_and_reward_range()
	if failed:
		return
	_test_high_scores_and_fame_labels_match_original()
	if failed:
		return
	print("Formula calibration test passed")
	get_tree().quit(0)

func _test_hospital_uses_original_cost() -> void:
	GameRules.new_game()
	GameState.health = 80
	GameState.cash = 100000
	var result = GameRules.heal(3)
	_require(result["ok"] == true, "hospital should accept affordable treatment")
	_require(GameState.health == 83, "hospital should heal requested points")
	_require(GameState.cash == 89500, "hospital should cost 3500 per point")

func _test_house_uses_original_costs_and_capacity_limit() -> void:
	GameRules.new_game()
	GameState.cash = 30000
	var first = GameRules.rent_larger_house()
	_require(first["ok"] == true, "house rental should accept 30000 cash")
	_require(GameState.cash == 5000, "house rental should cost 25000 when cash is <= 30000")
	_require(GameState.capacity == 110, "house rental should add 10 capacity")

	GameState.cash = 100000
	var second = GameRules.rent_larger_house()
	_require(second["ok"] == true, "house rental should accept rich player")
	_require(GameState.cash == 48000, "house rental should leave cash / 2 - 2000 when cash is above 30000")
	_require(GameState.capacity == 120, "second house rental should add 10 capacity")

	GameState.capacity = 140
	var too_large = GameRules.rent_larger_house()
	_require(too_large["ok"] == false, "house rental should reject capacity 140")

func _test_internet_cafe_uses_original_gate_and_reward_range() -> void:
	GameRules.new_game()
	GameState.cash = 14
	var too_poor = GameRules.callv("visit_internet_cafe", [5])
	_require(too_poor["ok"] == false, "internet cafe should require at least 15 cash")

	GameState.cash = 15
	var result = GameRules.callv("visit_internet_cafe", [7])
	_require(result["ok"] == true, "internet cafe should accept enough cash")
	_require(GameState.cash == 22, "internet cafe should add deterministic 1..10 reward")

	GameRules.callv("visit_internet_cafe", [1])
	GameRules.callv("visit_internet_cafe", [1])
	var fourth = GameRules.callv("visit_internet_cafe", [1])
	_require(fourth["ok"] == false, "internet cafe should allow only three visits")

func _test_high_scores_and_fame_labels_match_original() -> void:
	var scores = SaveManager.default_high_scores()
	_require(scores.size() == 10, "default high scores should include original top ten")
	_require(String(scores[2]["name"]) == "二黑", "default high scores should include original third row")
	_require(GameRules.fame_label_for_score(100) == "德高望重", "fame 100 should be original top label")
	_require(GameRules.fame_label_for_score(85) == "一般般", "fame 85 should be original middle label")
	_require(GameRules.fame_label_for_score(5) == "江湖唾弃", "fame 5 should be original bottom label")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Formula calibration test failed: %s" % message)
	get_tree().quit(1)
