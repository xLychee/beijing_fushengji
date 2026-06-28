extends Node

var failed := false

func _ready() -> void:
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	_require(main.get_node_or_null("BuyDialog") != null, "main scene should create buy dialog")
	_require(main.get_node_or_null("SellDialog") != null, "main scene should create sell dialog")
	_require(main.get_node_or_null("BankDialog") != null, "main scene should create bank dialog")
	_require(main.get_node_or_null("HospitalDialog") != null, "main scene should create hospital dialog")
	_require(main.get_node_or_null("DebtDialog") != null, "main scene should create debt dialog")
	_require(main.get_node_or_null("HouseDialog") != null, "main scene should create house dialog")
	if failed:
		return

	_test_bank_dialog_submits_amount(main)
	if failed:
		return
	_test_hospital_dialog_submits_points(main)
	if failed:
		return
	_test_debt_dialog_submits_amount(main)
	if failed:
		return
	print("Operation dialog test passed")
	get_tree().quit(0)

func _test_bank_dialog_submits_amount(main: Node) -> void:
	GameRules.new_game()
	main.get_node("BankButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("BankDialog")
	_require(dialog.visible == true, "bank button should open bank dialog")
	dialog.get_node("AmountSpinBox").value = 123
	dialog.get_node("OkButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.cash == 1877, "bank dialog should deposit submitted amount")
	_require(GameState.bank == 123, "bank dialog should increase bank by submitted amount")

func _test_hospital_dialog_submits_points(main: Node) -> void:
	GameRules.new_game()
	GameState.health = 90
	GameState.cash = 40000
	main.get_node("HospitalButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("HospitalDialog")
	_require(dialog.visible == true, "hospital button should open hospital dialog")
	dialog.get_node("AmountSpinBox").value = 5
	dialog.get_node("OkButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.health == 95, "hospital dialog should heal submitted points")
	_require(GameState.cash == 22500, "hospital dialog should use original 3500 per point")

func _test_debt_dialog_submits_amount(main: Node) -> void:
	GameRules.new_game()
	main.get_node("PostButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("DebtDialog")
	_require(dialog.visible == true, "post button should open debt dialog")
	dialog.get_node("AmountSpinBox").value = 321
	dialog.get_node("OkButton").pressed.emit()
	await get_tree().process_frame
	_require(GameState.cash == 1679, "debt dialog should repay submitted amount")
	_require(GameState.debt == 4679, "debt dialog should reduce debt by submitted amount")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Operation dialog test failed: %s" % message)
	get_tree().quit(1)
