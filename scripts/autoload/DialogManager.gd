extends Node

var queued_messages: Array = []

func clear() -> void:
	queued_messages.clear()

func enqueue_messages(messages: Array) -> void:
	for message in messages:
		queued_messages.append(message)

func pop_next_message() -> Dictionary:
	if queued_messages.is_empty():
		return {}
	return queued_messages.pop_front()

func has_messages() -> bool:
	return not queued_messages.is_empty()

func size() -> int:
	return queued_messages.size()
