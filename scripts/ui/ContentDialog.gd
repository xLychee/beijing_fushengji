extends Panel
class_name ContentDialog

signal confirmed
signal close_requested

var title := ""
var dialog_text := ""

var title_label: Label
var body_label: Label
var scroll_container: ScrollContainer

func _ready() -> void:
	_build_nodes()
	_sync_text()

func configure(dialog_title: String, body: String) -> void:
	title = dialog_title
	dialog_text = body
	_sync_text()

func popup_centered(dialog_size: Vector2i) -> void:
	_build_nodes()
	size = Vector2(dialog_size)
	_layout_nodes()
	var viewport_size := get_viewport_rect().size
	position = (viewport_size - size) / 2.0
	visible = true
	move_to_front()
	_sync_text()

func _build_nodes() -> void:
	if get_node_or_null("TitleBar") != null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.925, 0.925, 0.925)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.55, 0.55, 0.55)
	add_theme_stylebox_override("panel", panel_style)

	var title_bar := Panel.new()
	title_bar.name = "TitleBar"
	title_bar.position = Vector2.ZERO
	add_child(title_bar)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.position = Vector2(8, 3)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_bar.add_child(title_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.pressed.connect(func() -> void:
		hide()
		close_requested.emit()
	)
	title_bar.add_child(close_button)

	scroll_container = ScrollContainer.new()
	scroll_container.name = "BodyScroll"
	add_child(scroll_container)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(body_label)

	var ok_button := Button.new()
	ok_button.name = "OkButton"
	ok_button.text = "OK"
	ok_button.pressed.connect(func() -> void:
		hide()
		confirmed.emit()
	)
	add_child(ok_button)
	_layout_nodes()

func _layout_nodes() -> void:
	var width: float = max(size.x, 320.0)
	var height: float = max(size.y, 180.0)
	var title_bar := get_node_or_null("TitleBar") as Control
	if title_bar != null:
		title_bar.size = Vector2(width, 24)
	if title_label != null:
		title_label.size = Vector2(width - 42, 18)
	var close_button := get_node_or_null("TitleBar/CloseButton") as Button
	if close_button != null:
		close_button.position = Vector2(width - 29, 3)
		close_button.size = Vector2(22, 18)
	if scroll_container != null:
		scroll_container.position = Vector2(16, 38)
		scroll_container.size = Vector2(width - 32, height - 86)
	if body_label != null:
		body_label.custom_minimum_size = Vector2(width - 52, 0)
	var ok_button := get_node_or_null("OkButton") as Button
	if ok_button != null:
		ok_button.position = Vector2((width - 58) / 2.0, height - 36)
		ok_button.size = Vector2(58, 26)

func _sync_text() -> void:
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = dialog_text
