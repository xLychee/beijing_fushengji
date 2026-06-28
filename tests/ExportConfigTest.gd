extends Node

var failed := false

func _ready() -> void:
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	_require(err == OK, "export_presets.cfg should load")
	if failed:
		return
	_test_macos_preset(config)
	if failed:
		return
	_test_windows_preset(config)
	if failed:
		return
	print("Export config test passed")
	get_tree().quit(0)

func _test_macos_preset(config: ConfigFile) -> void:
	_require(config.get_value("preset.0", "name", "") == "macOS", "first preset should be macOS")
	_require(config.get_value("preset.0", "platform", "") == "macOS", "macOS preset should use macOS platform")
	_require(config.get_value("preset.0", "runnable", false) == true, "macOS preset should be runnable")
	_require(String(config.get_value("preset.0", "export_path", "")).ends_with(".zip"), "macOS preset should export a zip")
	_require(String(config.get_value("preset.0.options", "application/bundle_identifier", "")).contains("beijingfushengji"), "macOS preset should have a bundle id")

func _test_windows_preset(config: ConfigFile) -> void:
	_require(config.get_value("preset.1", "name", "") == "Windows Desktop", "second preset should be Windows Desktop")
	_require(config.get_value("preset.1", "platform", "") == "Windows Desktop", "Windows preset should use Windows Desktop platform")
	_require(config.get_value("preset.1", "runnable", false) == true, "Windows preset should be runnable")
	_require(String(config.get_value("preset.1", "export_path", "")).ends_with(".exe"), "Windows preset should export an exe")
	_require(config.get_value("preset.1.options", "binary_format/embed_pck", false) == true, "Windows preset should embed pck")

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Export config test failed: %s" % message)
	get_tree().quit(1)
