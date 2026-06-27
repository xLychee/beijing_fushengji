extends Node

const SETTINGS_PATH := "user://settings.json"
const HIGH_SCORES_PATH := "user://high_scores.json"

func default_settings() -> Dictionary:
	return {
		"sound_enabled": true,
		"hacker_events_enabled": false
	}

func default_high_scores() -> Array:
	return [
		{"name": "赖皮张", "score": 12500720, "health": 98, "fame": "争议人物"},
		{"name": "萧峰", "score": 830050, "health": 100, "fame": "杰出青年"}
	]

func load_settings(path: String = SETTINGS_PATH) -> Dictionary:
	var loaded := _load_dictionary(path)
	var settings := default_settings()
	for key in settings.keys():
		if loaded.has(key):
			settings[key] = loaded[key]
	return settings

func save_settings(settings: Dictionary, path: String = SETTINGS_PATH) -> bool:
	return _save_json(settings, path)

func load_high_scores(path: String = HIGH_SCORES_PATH) -> Array:
	var loaded := _load_array(path)
	if loaded.is_empty():
		return default_high_scores()
	return loaded

func save_high_scores(scores: Array, path: String = HIGH_SCORES_PATH) -> bool:
	return _save_json(scores, path)

func record_high_score(existing_scores: Array, player_name: String, score: int, health: int, fame: String) -> Array:
	var scores := existing_scores.duplicate(true)
	scores.append({
		"name": player_name,
		"score": score,
		"health": health,
		"fame": fame,
	})
	scores.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("score", 0)) > int(right.get("score", 0))
	)
	if scores.size() > 10:
		scores.resize(10)
	return scores

func _load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _load_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed

func _save_json(value, path: String) -> bool:
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	if directory != "":
		DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null and absolute_path != path:
		file = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value, "\t"))
	return true
