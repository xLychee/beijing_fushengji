# Godot Remake Design

## Goal

Rewrite Beijing Fushengji as a Godot 4 desktop game for macOS and Windows, preserving the original game loop, text, humor, rules, sound cues, and local-only feel while using a cleaner modern UI.

The remake should feel like the original game has been rebuilt carefully, not like a different game wearing the same name. The first full version should be playable end to end and should include the major original systems rather than only a narrow prototype.

## Source Project Summary

The original project is a Visual C++ 6.0 MFC application for Windows XP. The main game is concentrated in `SelectionDlg.cpp` and `SelectionDlg.h`, with helper dialogs for buying, selling, banking, hospital visits, post office debt repayment, internet cafe, house rental, settings, story, tips, and high scores.

Important original runtime assets:

- `sound/`: WAV sound effects.
- `Tips.txt`: startup tips.
- `News.txt`: encoded or legacy-format news/ticker content.
- `helpinfo`: encoded help content.
- `score.txt`: local high score file.
- `res/`: BMP, JPG, ICO, and dialog resources.

The old executable is Windows-only. The remake will not try to compile or wrap the MFC application.

## Target Experience

The game is a 2D UI-driven management game:

- One main screen shows status, current city/area, market goods, inventory, and action buttons.
- The player travels between locations. Moving to a new location consumes one day and triggers the normal turn pipeline.
- The player buys and sells goods, manages cash, debt, bank savings, health, fame, and storage capacity.
- Events appear as modal news or diary messages.
- The game ends after 40 days, on death, or when the player exits and final score is calculated.

The UI should be modernized but still compact. It should avoid heavy custom art requirements in the first version.

## Scope

The first complete Godot version includes:

- 40-day core loop.
- Beijing and alternate city/location mode from the original "go Shanghai / wander city" button.
- Market price generation.
- Buying goods.
- Selling goods.
- Inventory quantities and average purchase price.
- Storage capacity and house rental expansion.
- Cash, debt, bank savings, debt interest, and bank interest.
- Commercial random events.
- Health random events.
- Money loss random events.
- Optional hacker bank event.
- Bank deposit and withdrawal.
- Hospital treatment.
- Post office debt repayment and village-chief flavor messages.
- Internet cafe visit limits and small cash reward.
- Fame penalties for selected goods.
- Death handling.
- End-of-game forced sale and score calculation.
- High score table.
- Settings for sound and hacker events.
- Original text content migrated to UTF-8 data.
- Original WAV effects reused where practical.

The first version does not need:

- Network features.
- Online leaderboard.
- Full recreation of the old MFC window chrome.
- Pixel-art map animations.
- New balancing unless an original bug blocks playability.

## Recommended Godot Version

Use Godot 4.x with GDScript.

Reasons:

- GDScript is fastest for learning Godot and iterating on UI/game rules.
- This game has simple state and event logic, so C# is unnecessary.
- Godot Control nodes are a good match for tables, buttons, panels, and modal dialogs.
- Exporting desktop builds for macOS and Windows is a normal Godot workflow.

## Project Layout

```text
godot/
  project.godot
  scenes/
    Main.tscn
    dialogs/
      MessageDialog.tscn
      TradeDialog.tscn
      BankDialog.tscn
      HospitalDialog.tscn
      DebtDialog.tscn
      HouseDialog.tscn
      HighScoresDialog.tscn
      SettingsDialog.tscn
  scripts/
    autoload/
      GameState.gd
      GameRules.gd
      DialogManager.gd
      SaveManager.gd
      AudioManager.gd
    ui/
      MainController.gd
      MarketTable.gd
      InventoryTable.gd
  data/
    goods.json
    locations.json
    commercial_events.json
    health_events.json
    money_events.json
    tips.json
    text.json
  assets/
    audio/
    images/
```

The original source and assets stay at the repository root. The Godot remake lives in `godot/` so the old code remains available for reference.

## Game State

`GameState.gd` owns the mutable state:

- `day`: starts at 0, ends at 40.
- `time_left`: starts at 40.
- `city`: `beijing` or `alternate`.
- `current_location_id`: empty before first travel.
- `cash`: starts at 2000.
- `debt`: starts at 5000.
- `bank`: starts at 0.
- `health`: starts at 100.
- `fame`: starts at 100.
- `capacity`: starts at 100.
- `inventory_total`: derived from inventory quantities.
- `inventory`: dictionary keyed by goods id with quantity and average buy price.
- `market_prices`: dictionary keyed by goods id.
- `wangba_visits`: starts at 0.
- `sound_enabled`: starts true.
- `hacker_events_enabled`: starts false.
- `game_over`: false until end state.

`GameState` should expose small methods for reset, serialization, and derived values. It should not directly update UI nodes.

## Game Rules

`GameRules.gd` owns deterministic game operations:

- `new_game()`
- `travel_to(location_id)`
- `generate_market_prices(leaveout)`
- `apply_cash_and_debt_interest()`
- `apply_commercial_events()`
- `apply_health_event()`
- `apply_money_event()`
- `buy(goods_id, count)`
- `sell(goods_id, count)`
- `deposit(amount)`
- `withdraw(amount)`
- `repay_debt(amount)`
- `heal(points)`
- `rent_larger_house()`
- `visit_internet_cafe()`
- `toggle_city_mode()`
- `finish_game()`

Rule methods return a structured result:

```gdscript
{
  "ok": true,
  "messages": [
    {"type": "diary", "text": "...", "sound": "kill.wav"}
  ],
  "state_changed": true,
  "game_over": false
}
```

The UI consumes these results and decides how to show dialogs.

## Data Migration

Original hardcoded data should be converted into UTF-8 JSON.

`goods.json`:

- id
- original name
- base price
- random price range
- fame penalty on sale, if any
- optional tags

`commercial_events.json`:

- frequency
- message
- affected goods id
- price multiplier
- price divisor
- goods granted
- debt change, if any

`health_events.json`:

- frequency
- message
- health damage
- sound

`money_events.json`:

- frequency
- message
- loss ratio
- target: cash or bank

`locations.json`:

- city id
- location id
- label
- display order

Migration should preserve original text first. Later copy-editing can be a separate pass.

## Main Scene

`Main.tscn` is a `Control` scene.

Suggested layout:

- Top status bar: day, cash, debt, bank, health, fame, capacity.
- Left area: location buttons grouped by current city mode.
- Center area: market goods table.
- Right area: player inventory table.
- Bottom action bar: buy, sell, bank, hospital, post office, internet cafe, house, settings, high scores.
- Event ticker or latest-message strip near the bottom.

Tables should use Godot UI nodes, not hand-drawn canvas, so the project teaches real Godot Control workflows.

## Dialogs

Dialogs are separate reusable scenes:

- `MessageDialog`: diary/news/story messages.
- `TradeDialog`: buy/sell quantity selection.
- `BankDialog`: deposit and withdraw.
- `HospitalDialog`: choose treatment points.
- `DebtDialog`: repay village-chief debt.
- `HouseDialog`: rent larger storage.
- `HighScoresDialog`: show and insert local scores.
- `SettingsDialog`: sound and hacker options.

Message dialogs should queue, so several events from one travel action appear one after another.

## Turn Pipeline

Traveling to a new location runs the core original pipeline:

1. If it is late game, generate all goods; otherwise generate a market with some goods left out.
2. Apply debt and bank interest.
3. Apply commercial events.
4. Display market goods.
5. Apply health event.
6. Apply money loss event.
7. If debt is too high, apply punishment.
8. Decrease time left.
9. Warn on final day.
10. On day 40, force-sell remaining goods and finish the game.
11. Refresh all UI.

This should match the original behavior before adding any improvements.

## Persistence

Use Godot `user://` storage:

- `user://settings.json`
- `user://high_scores.json`

The old `score.txt` format does not need to be reused internally. A one-time importer can be added later if useful.

## Audio And Assets

Copy original WAV files into `godot/assets/audio/`.

Image assets can be copied into `godot/assets/images/`. BMP files should be converted to PNG during migration so Godot imports them cleanly and the repo remains easier to work with.

The first full version should use audio cues for:

- buy
- sell
- travel/open door
- injury/death
- bank/airport-style actions where original sounds exist

## Testing Strategy

Add lightweight rule tests using Godot's command line where practical.

Important rule checks:

- New game initializes expected starting values.
- Price generation follows original ranges.
- Buying reduces cash and increases inventory/capacity usage.
- Selling increases cash and decreases inventory/capacity usage.
- Debt increases by 10% per travel turn.
- Bank savings increase by 1% per travel turn.
- The game ends after 40 days.
- Fame penalties apply for the original goods.
- High scores sort correctly.

Manual playtest checklist:

- Start new game.
- Travel several times.
- Buy and sell at least two goods.
- Deposit and withdraw.
- Repay debt.
- Trigger or simulate major event types.
- Rent house.
- Visit internet cafe more than the allowed count.
- Finish a 40-day run.
- Restart after game over.
- Verify sound toggle.

## Milestones

### Milestone 1: Godot Skeleton

- Create `godot/` project.
- Add main scene.
- Add autoload singletons.
- Add starter data files with migrated examples.
- Show initial state on screen.

### Milestone 2: Core Economy

- Implement goods data.
- Implement price generation.
- Implement location travel.
- Implement buy and sell.
- Implement cash, debt, bank, capacity, and day changes.

### Milestone 3: Original Event Systems

- Migrate commercial, health, and money events.
- Add queued message dialogs.
- Add sounds for major events.
- Add high debt punishment and death.

### Milestone 4: Side Actions

- Bank.
- Hospital.
- Post office debt repayment.
- Internet cafe.
- House rental.
- City/location toggle.
- Settings.

### Milestone 5: Endgame And Polish

- Forced sale on final day.
- Score calculation.
- High score persistence.
- Startup tips/story.
- Asset conversion.
- macOS and Windows export verification.

## Design Risks

- Original code mixes rules and UI heavily. Some behaviors may need careful interpretation rather than direct line-by-line translation.
- Original text encoding is legacy GBK/GB18030. Migration must be scripted and checked visually.
- Some original files, such as `News.txt` and `helpinfo`, are encoded or transformed and may need separate decoding work.
- Godot tables are less native than web tables, so inventory and market UI should stay simple.
- GPL v2 applies to derivative releases using the original code/assets/text.

## Acceptance Criteria

The remake is successful when:

- A player can complete a full 40-day run on macOS and Windows.
- The major original actions and random event categories are present.
- The game uses original goods, locations, core formulas, event frequencies, and text content.
- Local high scores and settings persist.
- Sound can be toggled.
- The code separates game rules from UI scenes clearly enough that balancing or UI changes do not require rewriting core logic.
