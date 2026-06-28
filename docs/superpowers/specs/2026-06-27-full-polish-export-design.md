# Full Polish Export Design

## Goal

Finish the next remake PR as a single playable-polish pass: original-style operation dialogs, closer original formulas, missing content surfaces, better score/settings UI, full-run verification, export presets, and licensing/readme cleanup.

## Scope

This PR should keep the current Godot architecture and improve it rather than rewrite it. The main scene remains the first playable surface. Rule logic stays in `GameRules.gd`; reusable UI behavior goes into small scripts under `scripts/ui/`; user-facing text/data lives under `data/`.

The PR should include these seven deliverables:

1. Replace fixed shortcut side actions with original-style modal flows for buying, selling, bank deposit/withdraw, hospital treatment, debt repayment, and house rental.
2. Calibrate side-action formulas against the original VC6 source where the formula is clear.
3. Add missing original content surfaces: startup tips, story, Beijing intro/help, declaration/about, and boss-coming cover mode.
4. Improve settings and high-score UI beyond plain text.
5. Add automated full-run coverage and run a manual visual/play sanity check.
6. Add Godot export presets for macOS and Windows and verify what can be exported on this machine.
7. Update README/license notes for original GPLv2 source, migrated text, and migrated WAV assets.

## Original Formula Targets

Use these values from `reference/original-vc6/SelectionDlg.cpp` and helper dialogs:

- Hospital costs `3500` yuan per health point and can cure 1 to `100 - health` points.
- House rental is unavailable when capacity is `140`; unavailable when cash is under `30000`; accepted rental increases capacity by `10`; if cash is `<= 30000`, reduce cash by `25000`; otherwise reduce cash to `cash / 2 - 2000`.
- Internet cafe is unavailable after 3 visits, unavailable if cash is under `15`, and grants `1..10` yuan.
- Debt repayment can repay any chosen amount up to current cash and debt.
- Bank deposit/withdraw can move any chosen amount up to current cash or bank balance.
- High-score defaults should include the original ten entries where readable.
- Fame labels should use the original bands: `德高望重`, `杰出青年`, `一般般`, `不佳`, `争议人物`, `差`, `很差`, `江湖唾弃`.

## UI Direction

Keep the current 600x528 Win32-style screen. New dialogs should use the existing `RetroDialog` look: light gray panel, square controls, small title bar, black text, no modern dark modal styling. Dialog controls should feel like old MFC forms: labels, spin/input fields, radio/check buttons, and table-like score rows.

For buy/sell and money dialogs, the default amount should be the maximum useful amount or a small sensible amount, but the user can type/step values. Buttons should say `OK` and `取消` where cancellation is meaningful. Errors should route through the queued diary dialog.

## Data And Content

Create small UTF-8 JSON/text data files for:

- startup tips from `reference/original-vc6/Tips.txt` when readable;
- story/about/help snippets from original dialogs or decoded help text where practical;
- high-score default rows;
- optional export metadata.

If an original content file is encoded or transformed and cannot be cleanly decoded in this PR, include a concise readable fallback summary based on the visible source and document that it still needs fuller migration.

## Testing

Add focused tests before production changes:

- `OperationDialogTest`: verifies dialogs exist and emit intended rule calls.
- `FormulaCalibrationTest`: verifies hospital, house, internet cafe, fame labels, and high-score defaults.
- `ContentSurfaceTest`: verifies tips/story/help/about/boss surfaces exist and can open.
- `FullRunTest`: drives a deterministic 40-day run with random events disabled and confirms game over, liquidation, and high-score result.
- `ExportConfigTest`: verifies export presets include macOS and Windows names.

Existing tests must remain green.

## Export

Add `export_presets.cfg` for:

- macOS app bundle preset;
- Windows desktop executable preset.

Run a real export if export templates are installed. If templates are unavailable, keep the presets and record the exact Godot error in the PR, while still verifying project load and test suite.

## Acceptance

The PR is acceptable when:

- A player can operate core actions through dialogs rather than fixed shortcut amounts.
- Side-action numbers match the original where known.
- Original content surfaces are present and reachable from the main UI.
- High scores/settings are readable and persistent.
- A deterministic full 40-day automated run passes.
- README explains running, testing, exporting, and GPLv2/source attribution.
