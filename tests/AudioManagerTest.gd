extends Node

var failed := false

func _ready() -> void:
	_require_methods([
		"has_sound",
		"play_sound",
		"last_played_sound",
	])
	if failed:
		return
	_test_audio_assets_are_available()
	if failed:
		return
	_test_sound_toggle_controls_playback()
	if failed:
		return
	print("Audio manager test passed")
	get_tree().quit(0)

func _require_methods(methods: Array[String]) -> void:
	for method in methods:
		_require(AudioManager.has_method(method), "AudioManager.%s is missing" % method)

func _test_audio_assets_are_available() -> void:
	_require(AudioManager.has_sound("hit.wav") == true, "hit.wav should be available")
	_require(AudioManager.has_sound("buy.wav") == true, "buy.wav should be available")
	_require(AudioManager.has_sound("shutdoor.wav") == true, "shutdoor.wav should be available")

func _test_sound_toggle_controls_playback() -> void:
	GameState.sound_enabled = true
	AudioManager.play_sound("hit.wav")
	_require(AudioManager.last_played_sound() == "hit.wav", "audio manager should remember last played sound")
	GameState.sound_enabled = false
	AudioManager.play_sound("buy.wav")
	_require(AudioManager.last_played_sound() == "hit.wav", "disabled sound should not replace last played sound")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Audio manager test failed: %s" % message)
	get_tree().quit(1)
