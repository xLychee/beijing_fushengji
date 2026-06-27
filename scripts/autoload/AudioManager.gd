extends Node

const AUDIO_ROOT := "res://assets/audio/"

var player: AudioStreamPlayer
var played_sound := ""

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)

func set_sound_enabled(enabled: bool) -> void:
	GameState.sound_enabled = enabled

func play_sound(sound_name: String) -> void:
	if not GameState.sound_enabled:
		return
	if not has_sound(sound_name):
		return
	if DisplayServer.get_name() == "headless":
		played_sound = sound_name
		return
	var stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(_sound_path(sound_name)))
	if stream == null:
		return
	player.stream = stream
	player.play()
	played_sound = sound_name

func has_sound(sound_name: String) -> bool:
	return FileAccess.file_exists(_sound_path(sound_name))

func last_played_sound() -> String:
	return played_sound

func _sound_path(sound_name: String) -> String:
	return AUDIO_ROOT + sound_name
