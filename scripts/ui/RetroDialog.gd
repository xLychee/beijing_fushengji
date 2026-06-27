extends Panel

signal confirmed
signal close_requested

@export var title := "记事本"
@export_multiline var dialog_text := ""

@onready var title_label: Label = get_node_or_null("TitleBar/TitleLabel")
@onready var body_label: Label = get_node_or_null("BodyLabel")
@onready var ok_button: Button = get_node_or_null("OkButton")
@onready var close_button: Button = get_node_or_null("TitleBar/CloseButton")

func _ready() -> void:
	if ok_button != null:
		ok_button.pressed.connect(_confirm)
	if close_button != null:
		close_button.pressed.connect(_close)
	_sync_text()

func popup_centered(dialog_size: Vector2i) -> void:
	_sync_text()
	size = Vector2(dialog_size)
	var viewport_size := get_viewport_rect().size
	position = (viewport_size - size) / 2.0
	visible = true
	move_to_front()

func _sync_text() -> void:
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = dialog_text

func _confirm() -> void:
	visible = false
	confirmed.emit()

func _close() -> void:
	visible = false
	close_requested.emit()
