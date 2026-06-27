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
