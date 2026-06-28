extends Node

var failed := false

func _ready() -> void:
	_require(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 600, "internal viewport width should stay at original layout width")
	_require(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 528, "internal viewport height should stay at original layout height")
	_require(int(ProjectSettings.get_setting("display/window/size/window_width_override")) >= 900, "default window width should be readable on modern displays")
	_require(int(ProjectSettings.get_setting("display/window/size/window_height_override")) >= 780, "default window height should be readable on modern displays")
	_require(String(ProjectSettings.get_setting("display/window/stretch/mode")) != "disabled", "window should scale the original fixed layout")
	_require(String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "keep", "window scaling should preserve original aspect ratio")
	if failed:
		return
	print("Window scale test passed")
	get_tree().quit(0)

func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error("Window scale test failed: %s" % message)
	get_tree().quit(1)
