class_name DigitalNumber
extends Control

@export var value := "0":
	set(next_value):
		value = next_value
		queue_redraw()

@export var segment_color := Color(0.0, 1.0, 0.05, 1.0):
	set(next_color):
		segment_color = next_color
		queue_redraw()

@export var off_color := Color(0.0, 0.18, 0.02, 1.0):
	set(next_color):
		off_color = next_color
		queue_redraw()

const DIGITS := {
	"0": [true, true, true, true, true, true, false],
	"1": [false, true, true, false, false, false, false],
	"2": [true, true, false, true, true, false, true],
	"3": [true, true, true, true, false, false, true],
	"4": [false, true, true, false, false, true, true],
	"5": [true, false, true, true, false, true, true],
	"6": [true, false, true, true, true, true, true],
	"7": [true, true, true, false, false, false, false],
	"8": [true, true, true, true, true, true, true],
	"9": [true, true, true, true, false, true, true],
}

func _draw() -> void:
	var text := value
	if text.is_empty():
		return
	var gap: float = max(3.0, size.y * 0.08)
	var digit_width: float = min(size.y * 0.62, (size.x - gap * float(text.length() - 1)) / float(text.length()))
	var total_width: float = digit_width * float(text.length()) + gap * float(text.length() - 1)
	var start_x: float = max(0.0, (size.x - total_width) * 0.5)
	for index in text.length():
		var digit_rect := Rect2(Vector2(start_x + index * (digit_width + gap), 0), Vector2(digit_width, size.y))
		_draw_digit(digit_rect, text[index])

func _draw_digit(rect: Rect2, digit: String) -> void:
	var active: Array = DIGITS.get(digit, [false, false, false, false, false, false, false])
	var thickness: float = clamp(min(rect.size.x, rect.size.y) * 0.16, 4.0, 9.0)
	var inset: float = thickness * 0.7
	var x: float = rect.position.x + inset
	var y: float = rect.position.y + inset
	var w: float = rect.size.x - inset * 2.0
	var h: float = rect.size.y - inset * 2.0
	var mid_y: float = y + h * 0.5
	var bottom_y: float = y + h - thickness
	var right_x: float = x + w - thickness
	var segments: Array[Rect2] = [
		Rect2(x + thickness * 0.55, y, w - thickness * 1.1, thickness),
		Rect2(right_x, y + thickness * 0.55, thickness, h * 0.5 - thickness * 0.95),
		Rect2(right_x, mid_y + thickness * 0.45, thickness, h * 0.5 - thickness),
		Rect2(x + thickness * 0.55, bottom_y, w - thickness * 1.1, thickness),
		Rect2(x, mid_y + thickness * 0.45, thickness, h * 0.5 - thickness),
		Rect2(x, y + thickness * 0.55, thickness, h * 0.5 - thickness * 0.95),
		Rect2(x + thickness * 0.55, mid_y - thickness * 0.5, w - thickness * 1.1, thickness),
	]
	for index in segments.size():
		draw_rect(segments[index], segment_color if active[index] else off_color)
