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
var random_events_enabled := true
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
	random_events_enabled = true
	game_over = false

func inventory_total() -> int:
	var total := 0
	for item in inventory.values():
		total += int(item.get("quantity", 0))
	return total

func score() -> int:
	return cash + bank - debt
