extends Node

var failed := false

func _ready() -> void:
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var initial_cash := GameState.cash
	main.get_node("BankButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.bank == 500, "bank button should deposit 500")
	_require(GameState.cash == initial_cash - 500, "bank button should reduce cash")

	main.get_node("PostButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.debt == 4500, "post button should repay 500 debt")

	main.get_node("LocationPanel/CityToggleButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.city == "alternate", "city toggle button should switch city")

	main.get_node("SettingsButton").pressed.emit()
	await get_tree().process_frame
	var settings_dialog = main.get_node("SettingsDialog")
	_require(settings_dialog.visible == true, "settings button should open settings dialog")
	_require(main.get_node("SettingsDialog/SettingsPanel/SoundCheck").button_pressed == GameState.sound_enabled, "settings dialog should reflect sound setting")

	main.get_node("HighScoresButton").pressed.emit()
	await get_tree().process_frame
	var high_scores_dialog = main.get_node("HighScoresDialog")
	_require(high_scores_dialog.visible == true, "high scores button should open high scores dialog")
	_require(String(high_scores_dialog.dialog_text).contains("赖皮张"), "high scores dialog should show default scores")

	if failed:
		return
	print("UI action test passed")
	get_tree().quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("UI action test failed: %s" % message)
	get_tree().quit(1)
