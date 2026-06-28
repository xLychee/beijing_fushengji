extends Tree
class_name ScoreTable

func _ready() -> void:
	_configure()

func render_scores(scores: Array) -> void:
	_configure()
	clear()
	var root := create_item()
	for index in scores.size():
		var score: Dictionary = scores[index]
		var row := create_item(root)
		row.set_text(0, str(index + 1))
		row.set_text(1, String(score.get("name", "")))
		row.set_text(2, str(int(score.get("score", 0))))
		row.set_text(3, str(int(score.get("health", 0))))
		row.set_text(4, String(score.get("fame", "")))
		row.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
		row.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)
		row.set_text_alignment(3, HORIZONTAL_ALIGNMENT_RIGHT)

func _configure() -> void:
	hide_root = true
	column_titles_visible = true
	columns = 5
	var titles := ["名次", "姓名", "金钱", "健康", "名声"]
	var widths := [38, 84, 90, 52, 72]
	for column in columns:
		set_column_title(column, titles[column])
		set_column_expand(column, false)
		set_column_custom_minimum_width(column, widths[column])
