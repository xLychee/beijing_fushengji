extends Node

func set_sound_enabled(enabled: bool) -> void:
	GameState.sound_enabled = enabled

func play_sound(sound_name: String) -> void:
	if not GameState.sound_enabled:
		return
	print("sound:", sound_name)
