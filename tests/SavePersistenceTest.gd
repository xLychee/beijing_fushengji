extends Node

const SETTINGS_TEST_PATH := "/private/tmp/beijing_fushengji_settings_test.json"
const SCORES_TEST_PATH := "/private/tmp/beijing_fushengji_scores_test.json"

var failed := false

func _ready() -> void:
	_require_methods([
		"load_settings",
		"save_settings",
		"load_high_scores",
		"save_high_scores",
	])
	if failed:
		return
	_test_settings_round_trip()
	if failed:
		return
	_test_high_scores_round_trip()
	if failed:
		return
	print("Save persistence test passed")
	get_tree().quit(0)

func _require_methods(methods: Array[String]) -> void:
	for method in methods:
		_require(SaveManager.has_method(method), "SaveManager.%s is missing" % method)

func _test_settings_round_trip() -> void:
	var settings := {
		"sound_enabled": false,
		"hacker_events_enabled": true,
	}
	_require(SaveManager.save_settings(settings, SETTINGS_TEST_PATH) == true, "save settings should succeed")
	var loaded = SaveManager.load_settings(SETTINGS_TEST_PATH)
	_require(loaded["sound_enabled"] == false, "loaded settings should preserve sound flag")
	_require(loaded["hacker_events_enabled"] == true, "loaded settings should preserve hacker flag")

func _test_high_scores_round_trip() -> void:
	var scores := [
		{"name": "甲", "score": 200, "health": 88, "fame": "杰出青年"},
		{"name": "乙", "score": 100, "health": 80, "fame": "普通群众"},
	]
	_require(SaveManager.save_high_scores(scores, SCORES_TEST_PATH) == true, "save high scores should succeed")
	var loaded = SaveManager.load_high_scores(SCORES_TEST_PATH)
	_require(loaded.size() == 2, "loaded high scores should preserve count")
	_require(String(loaded[0]["name"]) == "甲", "loaded high scores should preserve names")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Save persistence test failed: %s" % message)
	get_tree().quit(1)
