# 北京浮生记 Godot Remake

This repository is a new Godot 4 remake project for 北京浮生记.

The original Visual C++ 6.0 / MFC source tree is kept only as reference material in `reference/original-vc6/`. New development should happen in the Godot project at the repository root.

The remake currently includes the core trading loop, original-style random events, queued diary/news dialogs, local settings and high-score persistence, original-style content dialogs, side-action amount dialogs, and migrated WAV sound cues.

## Run

```bash
godot --path .
```

## Export

The project has Godot export presets for macOS and Windows Desktop.

```bash
godot --path . --headless --export-release "macOS" build/macos/beijing_fushengji_macos.zip
godot --path . --headless --export-release "Windows Desktop" build/windows/beijing_fushengji.exe
```

Godot export templates must be installed for Godot `4.7.stable`. The macOS export uses ad-hoc signing by default, so a downloaded build may still be blocked by Gatekeeper unless it is notarized with an Apple developer account.

## Smoke Test

```bash
godot --path . --headless --log-file /private/tmp/beijing_fushengji_smoke.log --script tests/smoke_test.gd
godot --path . --headless --log-file /private/tmp/beijing_fushengji_economy.log --scene tests/EconomyTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_progression.log --scene tests/ProgressionTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_events.log --scene tests/EventRulesTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_saves.log --scene tests/SavePersistenceTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_dialogs.log --scene tests/DialogQueueTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_audio.log --scene tests/AudioManagerTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_window_scale.log --scene tests/WindowScaleTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_ui.log --scene tests/UiActionTest.tscn
godot --path . --headless --log-file /private/tmp/beijing_fushengji_ui_full_run.log --scene tests/UiFullRunTest.tscn
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

## License

This remake is distributed under GPL-2.0 for compatibility with the original project. See `LICENSE` and `NOTICE.md`.
