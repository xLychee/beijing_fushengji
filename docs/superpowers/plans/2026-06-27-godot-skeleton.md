# Godot Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the first Godot 4 project skeleton for the Beijing Fushengji remake so it opens in Godot, runs a main scene, loads starter data, and exposes clean singleton boundaries for later gameplay work.

**Architecture:** The repository root is the Godot project. The original VC6/MFC project lives under `reference/original-vc6/`, with Godot autoload singletons for state, rules, dialogs, saves, and audio at the root. The first scene shows initial state and starter data so the project is immediately testable on macOS.

**Tech Stack:** Godot 4.7, GDScript, JSON data files, Godot Control UI.

---

## File Structure

- Create `project.godot`: Godot project config, app metadata, main scene, and autoload registrations.
- Create `icon.svg`: simple project icon referenced by `project.godot`.
- Create `scenes/Main.tscn`: minimal Control scene with status labels, location list, market list, inventory list, and action buttons.
- Create `scripts/autoload/GameState.gd`: mutable game state and reset/derived helpers.
- Create `scripts/autoload/GameRules.gd`: starter rule entrypoints; initial version only resets and generates starter market prices.
- Create `scripts/autoload/DialogManager.gd`: message queue stub for future modal dialogs.
- Create `scripts/autoload/SaveManager.gd`: local user-data paths and starter high-score/settings helpers.
- Create `scripts/autoload/AudioManager.gd`: sound toggle stub for future WAV playback.
- Create `scripts/ui/MainController.gd`: main-scene controller that reads autoloads and populates labels/lists.
- Create `data/goods.json`: migrated starter goods with original names and price ranges.
- Create `data/locations.json`: starter Beijing and alternate location data.
- Create `data/text.json`: starter UI strings.
- Create `tests/smoke_test.gd`: command-line smoke test that verifies autoload scripts can instantiate and starter data parses.

## Task 1: Create Godot Project Config

**Files:**
- Create: `project.godot`
- Create: `icon.svg`

- [ ] **Step 1: Write the project config**

Create `project.godot`:

```ini
; Engine configuration file.
; Generated manually for the Beijing Fushengji Godot remake.

config_version=5

[application]

config/name="北京浮生记"
config/description="Godot remake of Beijing Fushengji"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.7")
config/icon="res://icon.svg"

[autoload]

GameState="*res://scripts/autoload/GameState.gd"
GameRules="*res://scripts/autoload/GameRules.gd"
DialogManager="*res://scripts/autoload/DialogManager.gd"
SaveManager="*res://scripts/autoload/SaveManager.gd"
AudioManager="*res://scripts/autoload/AudioManager.gd"

[display]

window/size/viewport_width=1180
window/size/viewport_height=760
window/size/window_width_override=1180
window/size/window_height_override=760

[rendering]

renderer/rendering_method="mobile"
```

- [ ] **Step 2: Write the temporary project icon**

Create `icon.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="18" fill="#1d1b16"/>
  <rect x="18" y="20" width="92" height="88" rx="8" fill="#d8b25c"/>
  <path d="M33 42h62v9H33zm0 20h62v9H33zm0 20h38v9H33z" fill="#1d1b16"/>
  <circle cx="91" cy="86" r="10" fill="#8a2e2b"/>
</svg>
```

- [ ] **Step 3: Verify Godot recognizes the project**

Run:

```bash
godot --path . --headless --quit
```

Expected: Godot starts without a project parse error. It may warn that the main scene does not exist until Task 5 is complete.

## Task 2: Add Starter Data

**Files:**
- Create: `data/goods.json`
- Create: `data/locations.json`
- Create: `data/text.json`

- [ ] **Step 1: Write goods data**

Create `data/goods.json`:

```json
[
  {"id": "imported_cigarettes", "name": "进口香烟", "base_price": 100, "random_range": 350, "fame_penalty_on_sale": 0},
  {"id": "smuggled_cars", "name": "走私汽车", "base_price": 15000, "random_range": 15000, "fame_penalty_on_sale": 0},
  {"id": "pirated_vcd_games", "name": "盗版VCD、游戏", "base_price": 5, "random_range": 50, "fame_penalty_on_sale": 0},
  {"id": "fake_liquor", "name": "假白酒（剧毒！）", "base_price": 1000, "random_range": 2500, "fame_penalty_on_sale": 10},
  {"id": "shanghai_baby", "name": "《上海小宝贝》（禁书）", "base_price": 5000, "random_range": 9000, "fame_penalty_on_sale": 7},
  {"id": "imported_toys", "name": "进口玩具", "base_price": 250, "random_range": 600, "fame_penalty_on_sale": 0},
  {"id": "gray_market_phones", "name": "水货手机", "base_price": 750, "random_range": 750, "fame_penalty_on_sale": 0},
  {"id": "shoddy_cosmetics", "name": "伪劣化妆品", "base_price": 65, "random_range": 180, "fame_penalty_on_sale": 0}
]
```

- [ ] **Step 2: Write location data**

Create `data/locations.json`:

```json
{
  "beijing": [
    {"id": "jianguomen", "label": "建国门"},
    {"id": "beijing_station", "label": "北京站"},
    {"id": "xizhimen", "label": "西直门"},
    {"id": "chongwenmen", "label": "崇文门"},
    {"id": "dongzhimen", "label": "东直门"},
    {"id": "fuxingmen", "label": "复兴门"},
    {"id": "jishuitan", "label": "积水潭"},
    {"id": "changchunjie", "label": "长椿街"},
    {"id": "gongzhufen", "label": "公主坟"},
    {"id": "pingguoyuan", "label": "苹果园"}
  ],
  "alternate": [
    {"id": "yonganli", "label": "永安里"},
    {"id": "fangzhuang", "label": "方 庄"},
    {"id": "haidian_street", "label": "海淀大街"},
    {"id": "yongdingmen", "label": "永定门"},
    {"id": "sanyuan_west_bridge", "label": "三元西桥"},
    {"id": "fuyou_street", "label": "府右街"},
    {"id": "asian_games_village", "label": "亚运村"},
    {"id": "yuquanying", "label": "玉泉营"},
    {"id": "cuiwei_road", "label": "翠微路"},
    {"id": "bajiao_west_road", "label": "八角西路"}
  ]
}
```

- [ ] **Step 3: Write UI text data**

Create `data/text.json`:

```json
{
  "title": "北京浮生记",
  "new_game": "新游戏",
  "market": "黑市行情",
  "inventory": "我的货物",
  "locations": "地点",
  "actions": "行动"
}
```

- [ ] **Step 4: Validate JSON syntax**

Run:

```bash
python3 -m json.tool data/goods.json >/dev/null
python3 -m json.tool data/locations.json >/dev/null
python3 -m json.tool data/text.json >/dev/null
```

Expected: all commands exit with status 0 and no output.

## Task 3: Create Autoload Singletons

**Files:**
- Create: `scripts/autoload/GameState.gd`
- Create: `scripts/autoload/GameRules.gd`
- Create: `scripts/autoload/DialogManager.gd`
- Create: `scripts/autoload/SaveManager.gd`
- Create: `scripts/autoload/AudioManager.gd`

- [ ] **Step 1: Write `GameState.gd`**

```gdscript
extends Node

const MAX_DAYS := 40

var day := 0
var time_left := MAX_DAYS
var city := "beijing"
var current_location_id := ""
var cash := 2000
var debt := 5000
var bank := 0
var health := 100
var fame := 100
var capacity := 100
var inventory := {}
var market_prices := {}
var wangba_visits := 0
var sound_enabled := true
var hacker_events_enabled := false
var game_over := false

func reset() -> void:
	day = 0
	time_left = MAX_DAYS
	city = "beijing"
	current_location_id = ""
	cash = 2000
	debt = 5000
	bank = 0
	health = 100
	fame = 100
	capacity = 100
	inventory = {}
	market_prices = {}
	wangba_visits = 0
	sound_enabled = true
	hacker_events_enabled = false
	game_over = false

func inventory_total() -> int:
	var total := 0
	for item in inventory.values():
		total += int(item.get("quantity", 0))
	return total

func score() -> int:
	return cash + bank - debt
```

- [ ] **Step 2: Write `GameRules.gd`**

```gdscript
extends Node

const GOODS_PATH := "res://data/goods.json"

func new_game() -> Dictionary:
	GameState.reset()
	GameState.market_prices = generate_market_prices(3)
	return _result([{"type": "diary", "text": "俺来到了北京。发财是唯一的目标。"}])

func load_goods() -> Array:
	return _load_json_array(GOODS_PATH)

func generate_market_prices(leaveout: int) -> Dictionary:
	var goods := load_goods()
	var prices := {}
	for item in goods:
		var id := String(item["id"])
		var base_price := int(item["base_price"])
		var random_range := int(item["random_range"])
		prices[id] = base_price + randi_range(0, max(random_range - 1, 0))
	for index in range(leaveout):
		if prices.is_empty():
			break
		var keys := prices.keys()
		var removed_id := keys[randi_range(0, keys.size() - 1)]
		prices.erase(removed_id)
	return prices

func _load_json_array(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read JSON file: %s" % path)
		return []
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected JSON array in %s" % path)
		return []
	return parsed

func _result(messages: Array) -> Dictionary:
	return {
		"ok": true,
		"messages": messages,
		"state_changed": true,
		"game_over": GameState.game_over
	}
```

- [ ] **Step 3: Write `DialogManager.gd`**

```gdscript
extends Node

var queued_messages: Array = []

func enqueue_messages(messages: Array) -> void:
	for message in messages:
		queued_messages.append(message)

func pop_next_message() -> Dictionary:
	if queued_messages.is_empty():
		return {}
	return queued_messages.pop_front()

func has_messages() -> bool:
	return not queued_messages.is_empty()
```

- [ ] **Step 4: Write `SaveManager.gd`**

```gdscript
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
```

- [ ] **Step 5: Write `AudioManager.gd`**

```gdscript
extends Node

func set_sound_enabled(enabled: bool) -> void:
	GameState.sound_enabled = enabled

func play_sound(sound_name: String) -> void:
	if not GameState.sound_enabled:
		return
	print("sound:", sound_name)
```

- [ ] **Step 6: Validate scripts parse**

Run:

```bash
godot --path . --headless --check-only --script scripts/autoload/GameState.gd
godot --path . --headless --check-only --script scripts/autoload/GameRules.gd
godot --path . --headless --check-only --script scripts/autoload/DialogManager.gd
godot --path . --headless --check-only --script scripts/autoload/SaveManager.gd
godot --path . --headless --check-only --script scripts/autoload/AudioManager.gd
```

Expected: each command exits with status 0.

## Task 4: Create Main Controller

**Files:**
- Create: `scripts/ui/MainController.gd`

- [ ] **Step 1: Write `MainController.gd`**

```gdscript
extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var location_list: ItemList = %LocationList
@onready var market_list: ItemList = %MarketList
@onready var inventory_list: ItemList = %InventoryList
@onready var message_label: Label = %MessageLabel

var locations := {}
var goods_by_id := {}

func _ready() -> void:
	randomize()
	locations = _load_json_dictionary("res://data/locations.json")
	for item in GameRules.load_goods():
		goods_by_id[String(item["id"])] = item
	var result := GameRules.new_game()
	DialogManager.enqueue_messages(result["messages"])
	_render_all()

func _render_all() -> void:
	title_label.text = "北京浮生记"
	status_label.text = "第%d/40天  现金:%d  债务:%d  存款:%d  健康:%d  名声:%d  容量:%d/%d" % [
		GameState.day,
		GameState.cash,
		GameState.debt,
		GameState.bank,
		GameState.health,
		GameState.fame,
		GameState.inventory_total(),
		GameState.capacity
	]
	_render_locations()
	_render_market()
	_render_inventory()
	_render_next_message()

func _render_locations() -> void:
	location_list.clear()
	for location in locations.get(GameState.city, []):
		location_list.add_item(String(location["label"]))

func _render_market() -> void:
	market_list.clear()
	for goods_id in GameState.market_prices.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var price := int(GameState.market_prices[goods_id])
		market_list.add_item("%s    %d元" % [goods_name, price])

func _render_inventory() -> void:
	inventory_list.clear()
	if GameState.inventory.is_empty():
		inventory_list.add_item("还没有货物")
		return
	for goods_id in GameState.inventory.keys():
		var goods = goods_by_id.get(goods_id, {})
		var goods_name := String(goods.get("name", goods_id))
		var item := GameState.inventory[goods_id]
		inventory_list.add_item("%s    %d个" % [goods_name, int(item.get("quantity", 0))])

func _render_next_message() -> void:
	if DialogManager.has_messages():
		var message := DialogManager.pop_next_message()
		message_label.text = String(message.get("text", ""))
	else:
		message_label.text = ""

func _load_json_dictionary(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Could not read JSON file: %s" % path)
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Expected JSON dictionary in %s" % path)
		return {}
	return parsed
```

- [ ] **Step 2: Validate script parses**

Run:

```bash
godot --path . --headless --check-only --script scripts/ui/MainController.gd
```

Expected: exits with status 0.

## Task 5: Create Main Scene

**Files:**
- Create: `scenes/Main.tscn`

- [ ] **Step 1: Write `Main.tscn`**

```ini
[gd_scene load_steps=2 format=3 uid="uid://beijing_fushengji_main"]

[ext_resource type="Script" path="res://scripts/ui/MainController.gd" id="1_main_controller"]

[node name="Main" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_main_controller")

[node name="RootMargin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 18
theme_override_constants/margin_top = 18
theme_override_constants/margin_right = 18
theme_override_constants/margin_bottom = 18

[node name="RootVBox" type="VBoxContainer" parent="RootMargin"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="TitleLabel" type="Label" parent="RootMargin/RootVBox"]
unique_name_in_owner = true
layout_mode = 2
text = "北京浮生记"
horizontal_alignment = 1

[node name="StatusLabel" type="Label" parent="RootMargin/RootVBox"]
unique_name_in_owner = true
layout_mode = 2
text = "状态"

[node name="ContentHBox" type="HBoxContainer" parent="RootMargin/RootVBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="LocationPanel" type="VBoxContainer" parent="RootMargin/RootVBox/ContentHBox"]
layout_mode = 2
size_flags_horizontal = 3

[node name="LocationTitle" type="Label" parent="RootMargin/RootVBox/ContentHBox/LocationPanel"]
layout_mode = 2
text = "地点"

[node name="LocationList" type="ItemList" parent="RootMargin/RootVBox/ContentHBox/LocationPanel"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3

[node name="MarketPanel" type="VBoxContainer" parent="RootMargin/RootVBox/ContentHBox"]
layout_mode = 2
size_flags_horizontal = 4

[node name="MarketTitle" type="Label" parent="RootMargin/RootVBox/ContentHBox/MarketPanel"]
layout_mode = 2
text = "黑市行情"

[node name="MarketList" type="ItemList" parent="RootMargin/RootVBox/ContentHBox/MarketPanel"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3

[node name="InventoryPanel" type="VBoxContainer" parent="RootMargin/RootVBox/ContentHBox"]
layout_mode = 2
size_flags_horizontal = 4

[node name="InventoryTitle" type="Label" parent="RootMargin/RootVBox/ContentHBox/InventoryPanel"]
layout_mode = 2
text = "我的货物"

[node name="InventoryList" type="ItemList" parent="RootMargin/RootVBox/ContentHBox/InventoryPanel"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3

[node name="ActionHBox" type="HBoxContainer" parent="RootMargin/RootVBox"]
layout_mode = 2
theme_override_constants/separation = 8

[node name="BuyButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "买入"

[node name="SellButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "卖出"

[node name="BankButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "银行"

[node name="HospitalButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "医院"

[node name="PostButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "邮局"

[node name="HouseButton" type="Button" parent="RootMargin/RootVBox/ActionHBox"]
layout_mode = 2
text = "租房中介"

[node name="MessageLabel" type="Label" parent="RootMargin/RootVBox"]
unique_name_in_owner = true
layout_mode = 2
text = ""
autowrap_mode = 3
```

- [ ] **Step 2: Verify project can open headlessly**

Run:

```bash
godot --path . --headless --quit
```

Expected: exits with status 0 and no missing main scene errors.

## Task 6: Add Smoke Test

**Files:**
- Create: `tests/smoke_test.gd`

- [ ] **Step 1: Write `smoke_test.gd`**

```gdscript
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

	print("Smoke test passed")
	quit(0)
```

- [ ] **Step 2: Run the smoke test**

Run:

```bash
godot --path . --headless --script tests/smoke_test.gd
```

Expected output contains:

```text
Smoke test passed
```

Expected exit status: 0.

## Task 7: Final Verification And Commit

**Files:**
- Modify: no source changes beyond previous tasks.

- [ ] **Step 1: Check working tree**

Run:

```bash
git status --short
```

Expected: only the root Godot project files, `reference/original-vc6/`, and `docs/superpowers/plans/2026-06-27-godot-skeleton.md` are new or modified.

- [ ] **Step 2: Run final verification**

Run:

```bash
python3 -m json.tool data/goods.json >/dev/null
python3 -m json.tool data/locations.json >/dev/null
python3 -m json.tool data/text.json >/dev/null
godot --path . --headless --quit
godot --path . --headless --script tests/smoke_test.gd
```

Expected: JSON commands produce no output, Godot exits successfully, smoke test prints `Smoke test passed`.

- [ ] **Step 3: Commit**

Run:

```bash
git add docs/superpowers/plans/2026-06-27-godot-skeleton.md godot
git commit -m "Add Godot remake skeleton"
```

Expected: commit succeeds.
