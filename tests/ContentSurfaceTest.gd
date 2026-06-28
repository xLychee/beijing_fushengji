extends Node

var failed := false

func _ready() -> void:
	var main = preload("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	_require(main.get_node_or_null("TipButton") != null, "main scene should expose tip button")
	_require(main.get_node_or_null("StoryButton") != null, "main scene should expose story button")
	_require(main.get_node_or_null("HelpButton") != null, "main scene should expose help button")
	_require(main.get_node_or_null("AboutButton") != null, "main scene should expose about button")
	_require(main.get_node_or_null("DeclareButton") != null, "main scene should expose declaration button")
	_require(main.get_node_or_null("LocationPanel/BossButton") != null, "main scene should expose boss button")
	_require(main.get_node_or_null("ContentDialog") != null, "main scene should create content dialog")
	_require(main.get_node_or_null("BossDialog") != null, "main scene should create boss dialog")
	if failed:
		return

	_test_content_files()
	if failed:
		return
	_test_tip_dialog(main)
	if failed:
		return
	_test_help_and_about_dialogs(main)
	if failed:
		return
	_test_boss_dialog(main)
	if failed:
		return
	print("Content surface test passed")
	get_tree().quit(0)

func _test_content_files() -> void:
	var tips = JSON.parse_string(FileAccess.get_file_as_string("res://data/tips.json"))
	_require(typeof(tips) == TYPE_ARRAY, "tips file should be a JSON array")
	_require(Array(tips).size() >= 10, "tips file should preserve original tip density")
	var content = JSON.parse_string(FileAccess.get_file_as_string("res://data/content.json"))
	_require(typeof(content) == TYPE_DICTIONARY, "content file should be a JSON dictionary")
	for key in ["story", "help", "about", "declaration", "boss"]:
		_require(Dictionary(content).has(key), "content file should include %s" % key)

func _test_tip_dialog(main: Node) -> void:
	main.get_node("TipButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("ContentDialog")
	_require(dialog.visible == true, "tip button should open content dialog")
	_require(String(dialog.title).contains("提示"), "tip dialog should use tip title")
	_require(_dialog_body(dialog).contains("人生短暂"), "tip dialog should show original first tip")

func _test_help_and_about_dialogs(main: Node) -> void:
	main.get_node("HelpButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("ContentDialog")
	_require(_dialog_body(dialog).contains("村长"), "help dialog should describe debt rules")
	main.get_node("AboutButton").pressed.emit()
	await get_tree().process_frame
	_require(_dialog_body(dialog).contains("Guoly Computing"), "about dialog should credit original developer")

func _test_boss_dialog(main: Node) -> void:
	main.get_node("LocationPanel/BossButton").pressed.emit()
	await get_tree().process_frame
	var dialog = main.get_node("BossDialog")
	_require(dialog.visible == true, "boss button should open boss dialog")
	_require(_dialog_body(dialog).contains("本月工作计划"), "boss dialog should disguise the game")

func _dialog_body(dialog: Node) -> String:
	var label = dialog.find_child("BodyLabel", true, false)
	if label == null:
		return ""
	return String(label.text)

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Content surface test failed: %s" % message)
	get_tree().quit(1)
