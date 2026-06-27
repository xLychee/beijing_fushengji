extends Node

var failed := false

func _ready() -> void:
	_require_methods([
		"clear",
		"size",
		"enqueue_messages",
		"pop_next_message",
	])
	if failed:
		return
	_test_dialog_manager_preserves_queue_order()
	if failed:
		return
	_test_main_scene_has_retro_message_dialog()
	if failed:
		return
	print("Dialog queue test passed")
	get_tree().quit(0)

func _require_methods(methods: Array[String]) -> void:
	for method in methods:
		_require(DialogManager.has_method(method), "DialogManager.%s is missing" % method)

func _test_dialog_manager_preserves_queue_order() -> void:
	DialogManager.clear()
	DialogManager.enqueue_messages([
		{"type": "diary", "text": "第一条"},
		{"type": "news", "text": "第二条"},
	])
	_require(DialogManager.size() == 2, "queue should keep both messages")
	_require(String(DialogManager.pop_next_message()["text"]) == "第一条", "queue should pop first message first")
	_require(String(DialogManager.pop_next_message()["text"]) == "第二条", "queue should pop second message second")
	_require(DialogManager.size() == 0, "queue should be empty after popping")

func _test_main_scene_has_retro_message_dialog() -> void:
	DialogManager.clear()
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var dialog = main.get_node_or_null("MessageDialog")
	_require(dialog != null, "main scene should include a reusable message dialog")
	if failed:
		return
	_require(String(dialog.title) == "记事本", "message dialog should use original diary-style title")
	_require(String(dialog.dialog_text).contains("俺来到了北京"), "message dialog should show queued new-game text")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Dialog queue test failed: %s" % message)
	get_tree().quit(1)
