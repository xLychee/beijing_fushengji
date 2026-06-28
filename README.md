# 北京浮生记 Godot Remake

This repository is a new Godot 4 remake project for 北京浮生记.

The original Visual C++ 6.0 / MFC source tree is kept only as reference material in `reference/original-vc6/`. New development should happen in the Godot project at the repository root.

The remake currently includes the core trading loop, original-style random events, queued diary/news dialogs, local settings and high-score persistence, original-style content dialogs, side-action amount dialogs, and migrated WAV sound cues.

## Run

```bash
godot --path .
```

## Smoke Test

```bash
godot --path . --headless --log-file /private/tmp/beijing_fushengji_smoke.log --script tests/smoke_test.gd
godot --path . --headless --log-file /private/tmp/beijing_fushengji_economy.log --scene tests/EconomyTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_progression.log --scene tests/ProgressionTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_events.log --scene tests/EventRulesTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_saves.log --scene tests/SavePersistenceTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_dialogs.log --scene tests/DialogQueueTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_audio.log --scene tests/AudioManagerTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_ui.log --scene tests/UiActionTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_formula.log --scene tests/FormulaCalibrationTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_operation.log --scene tests/OperationDialogTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_content.log --scene tests/ContentSurfaceTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_full_run.log --scene tests/FullRunTest.tscn
```

## Structure

- `project.godot`: Godot project file.
- `scenes/`: Godot scenes.
- `scripts/`: GDScript source.
- `data/`: UTF-8 game data migrated from the original game.
- `assets/audio/`: WAV sound effects migrated from the original game.
- `tests/`: command-line smoke tests.
- `reference/original-vc6/`: original Windows/VC6 project kept for research.
