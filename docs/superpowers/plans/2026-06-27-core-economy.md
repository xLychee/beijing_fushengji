# Core Economy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first playable economy loop: travel, day progression, interest, market refresh, buying, and selling.

**Architecture:** `GameRules.gd` owns rule mutations and returns structured results. `GameState.gd` remains the state container. `MainController.gd` wires UI selections to rule calls and refreshes the existing lists.

**Tech Stack:** Godot 4.7, GDScript, command-line SceneTree tests.

---

## Tasks

### Task 1: Rule Tests

**Files:**
- Create: `tests/economy_test.gd`

- [ ] Write a failing command-line test covering travel, interest, buy, sell, and blocked invalid trades.
- [ ] Run `godot --path . --headless --script tests/economy_test.gd`.
- [ ] Expected failure: missing `travel_to`, `buy`, or `sell` methods.

### Task 2: Economy Rules

**Files:**
- Modify: `scripts/autoload/GameRules.gd`

- [ ] Implement `travel_to(location_id)`.
- [ ] Implement `apply_cash_and_debt_interest()`.
- [ ] Implement `buy(goods_id, count)`.
- [ ] Implement `sell(goods_id, count)`.
- [ ] Add small private helpers for inventory and messages.
- [ ] Run `godot --path . --headless --script tests/economy_test.gd`.
- [ ] Expected: `Smoke test passed` equivalent for economy test.

### Task 3: UI Wiring

**Files:**
- Modify: `scripts/ui/MainController.gd`
- Modify: `scenes/Main.tscn`

- [ ] Track goods ids and location ids in `ItemList` metadata.
- [ ] Connect location, buy, and sell buttons.
- [ ] Use one-click demo trade counts for now: buy/sell 1 selected item.
- [ ] Refresh the message label after each rule result.
- [ ] Run `godot --path . --headless --quit`.

### Task 4: Final Verification

**Files:**
- No extra changes.

- [ ] Run JSON validation.
- [ ] Run `tests/smoke_test.gd`.
- [ ] Run `tests/economy_test.gd`.
- [ ] Commit the result.
