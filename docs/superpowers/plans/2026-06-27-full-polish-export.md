# Full Polish Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a single PR that turns the current playable Godot remake into a more complete original-style desktop game pass.

**Architecture:** Keep `GameRules.gd` as the rule authority, keep `MainController.gd` as scene wiring, and add focused UI helper scripts for reusable retro dialogs. Data migrated from original files goes under `data/`. Tests stay as headless Godot scene/script tests.

**Tech Stack:** Godot 4.7, GDScript, JSON data files, GitHub PR workflow.

---

### Task 1: Dialog-Driven Operations

**Files:**
- Modify: `scenes/Main.tscn`
- Modify: `scripts/ui/MainController.gd`
- Create: `scripts/ui/AmountDialog.gd`
- Create: `tests/OperationDialogTest.gd`
- Create: `tests/OperationDialogTest.tscn`

- [ ] Write `OperationDialogTest` to instantiate `Main.tscn`, verify `TradeDialog`, `BankDialog`, `HospitalDialog`, `DebtDialog`, and `HouseDialog` nodes exist, open from the expected buttons, and can confirm an amount.
- [ ] Run `godot --path . --headless --log-file /private/tmp/beijing_fushengji_operation_red.log --scene tests/OperationDialogTest.tscn` and verify it fails because dialogs are missing.
- [ ] Add `AmountDialog.gd`, a `RetroDialog` subclass with `amount_submitted(amount: int)`, `configure(...)`, a `SpinBox`, message label, and `OK`/`取消`.
- [ ] Add dialog nodes to `Main.tscn` for buy, sell, bank, hospital, debt, and house flows.
- [ ] Update `MainController.gd` so buy/sell/bank/hospital/post/house buttons open dialogs and only call `GameRules` when confirmed.
- [ ] Run `OperationDialogTest` and existing `UiActionTest`.
- [ ] Commit with message `Add original-style operation dialogs`.

### Task 2: Formula Calibration

**Files:**
- Modify: `scripts/autoload/GameRules.gd`
- Modify: `scripts/autoload/SaveManager.gd`
- Modify: `tests/ProgressionTest.gd`
- Create: `tests/FormulaCalibrationTest.gd`
- Create: `tests/FormulaCalibrationTest.tscn`

- [ ] Write tests for hospital cost `3500`, house rental capacity/cost rules, internet cafe cash gate/reward range, original fame labels, and ten default high-score rows.
- [ ] Run the formula test and verify it fails on current simplified values.
- [ ] Update `GameRules` constants and methods to match original formulas.
- [ ] Expand default high scores and fame labels in `SaveManager`/`GameRules`.
- [ ] Run formula, progression, economy, and event tests.
- [ ] Commit with message `Calibrate side action formulas`.

### Task 3: Original Content Surfaces

**Files:**
- Create: `data/tips.json`
- Create: `data/content.json`
- Modify: `scenes/Main.tscn`
- Modify: `scripts/ui/MainController.gd`
- Create: `tests/ContentSurfaceTest.gd`
- Create: `tests/ContentSurfaceTest.tscn`

- [ ] Write tests that verify the main scene exposes buttons for tips/story/intro/help/about/declaration/boss and that each button opens a visible dialog or cover.
- [ ] Run the content test and verify it fails.
- [ ] Decode and migrate readable tips/story/help/about/declaration snippets from original files; use short readable fallback text where files are transformed.
- [ ] Add top/menu buttons and a boss-cover panel using the retro visual style.
- [ ] Wire controller methods to show content dialogs and close boss cover.
- [ ] Run content, dialog, and UI tests.
- [ ] Commit with message `Add original content surfaces`.

### Task 4: High Score And Settings UI Polish

**Files:**
- Modify: `scenes/Main.tscn`
- Modify: `scripts/ui/MainController.gd`
- Create: `scripts/ui/ScoreTable.gd`
- Modify: `tests/UiActionTest.gd`

- [ ] Extend UI tests to verify high-score rows are table-like and settings toggles persist after reopening.
- [ ] Run the UI test and verify the table-specific assertions fail.
- [ ] Add `ScoreTable.gd` or equivalent node wiring to render rank/name/score/health/fame columns.
- [ ] Keep settings in the current dialog but ensure toggle changes are immediately saved and reflected on reopen.
- [ ] Run UI, save, and dialog tests.
- [ ] Commit with message `Polish score and settings dialogs`.

### Task 5: Full-Run Verification

**Files:**
- Create: `tests/FullRunTest.gd`
- Create: `tests/FullRunTest.tscn`
- Modify: `README.md`

- [ ] Write a deterministic full-run test: start new game, disable random events, iterate through locations until day 40, buy/sell safely when possible, and assert game over with inventory liquidated and score present.
- [ ] Run the test and verify any current endgame gap.
- [ ] Adjust test setup or rule edge cases only if needed to make a real 40-day run pass.
- [ ] Add the full-run command to README.
- [ ] Commit with message `Add deterministic full-run test`.

### Task 6: Export Presets

**Files:**
- Create: `export_presets.cfg`
- Create: `tests/ExportConfigTest.gd`
- Create: `tests/ExportConfigTest.tscn`
- Modify: `README.md`

- [ ] Write a test that reads `export_presets.cfg` and verifies macOS and Windows desktop preset names.
- [ ] Run the test and verify it fails before the preset file exists.
- [ ] Add Godot export presets for `macOS` and `Windows Desktop` with output paths under `builds/`.
- [ ] Try `godot --path . --export-debug "macOS" builds/beijing-fushengji-macos.zip` and `godot --path . --export-debug "Windows Desktop" builds/beijing-fushengji.exe`; record whether templates are available.
- [ ] Document export commands and any local template limitation in README.
- [ ] Commit with message `Add desktop export presets`.

### Task 7: License And Final Verification

**Files:**
- Modify: `README.md`
- Create: `COPYING.original`
- Modify: `.gitignore`

- [ ] Add attribution and GPLv2 source notes to README.
- [ ] Copy or reference the original GPLv2 text into `COPYING.original`.
- [ ] Ensure `builds/` is ignored.
- [ ] Run the full verification suite: `git diff --check`, JSON parse, Godot load, all test scenes/scripts.
- [ ] Run visual screenshot/movie check for the main scene.
- [ ] Commit with message `Document licensing and verification`.
- [ ] Push branch and create PR.
