extends SceneTree

func _init() -> void:
	var goods_text := FileAccess.get_file_as_string("res://data/goods.json")
	var goods = JSON.parse_string(goods_text)
	assert(typeof(goods) == TYPE_ARRAY)
	assert(goods.size() == 8)
	assert(String(goods[0]["name"]) == "进口香烟")

	var state := preload("res://scripts/autoload/GameState.gd").new()
	state.reset()
	assert(state.cash == 2000)
	assert(state.debt == 5000)
	assert(state.time_left == 40)
	assert(state.inventory_total() == 0)
	state.free()

	print("Smoke test passed")
	quit(0)
