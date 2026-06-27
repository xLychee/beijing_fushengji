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
