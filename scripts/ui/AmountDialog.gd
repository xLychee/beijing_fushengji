extends Panel
class_name AmountDialog

signal amount_submitted(amount: int)

var title := ""
var dialog_text := ""
var minimum_amount := 1
var maximum_amount := 1
var default_amount := 1
var show_mode_option := false

var title_label: Label
var body_label: Label
var amount_spin_box: SpinBox
var mode_option: OptionButton

func _ready() -> void:
	_build_nodes()
	_sync()

func configure(dialog_title: String, message: String, minimum: int, maximum: int, default_value: int, with_mode := false) -> void:
	title = dialog_title
	dialog_text = message
	minimum_amount = minimum
	maximum_amount = max(minimum, maximum)
	default_amount = clamp(default_value, minimum_amount, maximum_amount)
	show_mode_option = with_mode
	_sync()

func selected_mode() -> String:
	if mode_option == null or mode_option.selected < 0:
		return "deposit"
	return String(mode_option.get_item_metadata(mode_option.selected))

func popup_centered(dialog_size: Vector2i) -> void:
	size = Vector2(dialog_size)
	var viewport_size := get_viewport_rect().size
	position = (viewport_size - size) / 2.0
	visible = true
	move_to_front()
	_sync()

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
	title_bar.size = Vector2(280, 24)
	add_child(title_bar)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.position = Vector2(8, 3)
	title_label.size = Vector2(220, 18)
	title_bar.add_child(title_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.position = Vector2(251, 3)
	close_button.size = Vector2(22, 18)
	close_button.pressed.connect(func() -> void:
		hide()
	)
	title_bar.add_child(close_button)

	body_label = Label.new()
	body_label.name = "BodyLabel"
	body_label.position = Vector2(16, 36)
	body_label.size = Vector2(248, 40)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(body_label)

	mode_option = OptionButton.new()
	mode_option.name = "ModeOption"
	mode_option.position = Vector2(16, 79)
	mode_option.size = Vector2(86, 26)
	mode_option.add_item("存款")
	mode_option.set_item_metadata(0, "deposit")
	mode_option.add_item("取款")
	mode_option.set_item_metadata(1, "withdraw")
	add_child(mode_option)

	amount_spin_box = SpinBox.new()
	amount_spin_box.name = "AmountSpinBox"
	amount_spin_box.position = Vector2(112, 80)
	amount_spin_box.size = Vector2(96, 25)
	amount_spin_box.step = 1
	amount_spin_box.rounded = true
	add_child(amount_spin_box)

	var ok_button := Button.new()
	ok_button.name = "OkButton"
	ok_button.text = "OK"
	ok_button.position = Vector2(76, 118)
	ok_button.size = Vector2(58, 26)
	ok_button.pressed.connect(func() -> void:
		hide()
		amount_submitted.emit(int(amount_spin_box.value))
	)
	add_child(ok_button)

	var cancel_button := Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "取消"
	cancel_button.position = Vector2(146, 118)
	cancel_button.size = Vector2(58, 26)
	cancel_button.pressed.connect(func() -> void:
		hide()
	)
	add_child(cancel_button)

func _sync() -> void:
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = dialog_text
	if amount_spin_box != null:
		amount_spin_box.min_value = minimum_amount
		amount_spin_box.max_value = maximum_amount
		amount_spin_box.value = default_amount
	if mode_option != null:
		mode_option.visible = show_mode_option
		amount_spin_box.position.x = 112 if show_mode_option else 92
