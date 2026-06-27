# 北京浮生记 Godot Remake

This repository is a new Godot 4 remake project for 北京浮生记.

The original Visual C++ 6.0 / MFC source tree is kept only as reference material in `reference/original-vc6/`. New development should happen in the Godot project at the repository root.

## Run

```bash
godot --path .
```

## Smoke Test

```bash
godot --path . --headless --script tests/smoke_test.gd
godot --path . --headless --scene tests/EconomyTest.tscn
```

## Structure

- `project.godot`: Godot project file.
- `scenes/`: Godot scenes.
- `scripts/`: GDScript source.
- `data/`: UTF-8 game data migrated from the original game.
- `tests/`: command-line smoke tests.
- `reference/original-vc6/`: original Windows/VC6 project kept for research.
