extends Node

var failed := false

func _ready() -> void:
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	var initial_cash := GameState.cash
	main.get_node("BankButton").pressed.emit()
	await get_tree().process_frame
	var bank_dialog = main.get_node("BankDialog")
	_require(bank_dialog.visible == true, "bank button should open bank dialog")
	bank_dialog.get_node("AmountSpinBox").value = 500
	bank_dialog.get_node("OkButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.bank == 500, "bank button should deposit 500")
	_require(GameState.cash == initial_cash - 500, "bank button should reduce cash")

	main.get_node("PostButton").pressed.emit()
	await get_tree().process_frame
	var debt_dialog = main.get_node("DebtDialog")
	_require(debt_dialog.visible == true, "post button should open debt dialog")
	debt_dialog.get_node("AmountSpinBox").value = 500
	debt_dialog.get_node("OkButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.debt == 4500, "post button should repay 500 debt")

	main.get_node("LocationPanel/CityToggleButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.city == "alternate", "city toggle button should switch city")

	main.get_node("SettingsButton").pressed.emit()
	await get_tree().process_frame
	var settings_dialog = main.get_node("SettingsDialog")
	_require(settings_dialog.visible == true, "settings button should open settings dialog")
	var sound_check = main.get_node("SettingsDialog/SettingsPanel/SoundCheck")
	_require(sound_check.button_pressed == GameState.sound_enabled, "settings dialog should reflect sound setting")
	var original_sound_state := GameState.sound_enabled
	sound_check.button_pressed = not original_sound_state
	await get_tree().process_frame
	settings_dialog.hide()
	main.get_node("SettingsButton").pressed.emit()
	await get_tree().process_frame
	_require(sound_check.button_pressed == (not original_sound_state), "settings dialog should reflect saved toggle on reopen")
	sound_check.button_pressed = original_sound_state
	await get_tree().process_frame

	main.get_node("HighScoresButton").pressed.emit()
	await get_tree().process_frame
	var high_scores_dialog = main.get_node("HighScoresDialog")
	_require(high_scores_dialog.visible == true, "high scores button should open high scores dialog")
	var score_table = high_scores_dialog.get_node_or_null("ScoreTable")
	_require(score_table != null, "high scores dialog should render a score table")
	if score_table != null:
		_require(score_table.columns == 5, "score table should render rank, name, money, health, fame columns")
		var first_row = score_table.get_root().get_first_child()
		_require(first_row != null, "score table should render score rows")
		if first_row != null:
			_require(first_row.get_text(1) == "赖皮张", "score table should show default top player")
			_require(first_row.get_text(4) == "争议人物", "score table should show original fame label")

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
