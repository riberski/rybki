# Contributing Guide

## Naming Conventions (GDScript)

We follow the official Godot Style Guide:

- **Classes/Nodes**: PascalCase (e.g., `FishingManager`, `Player3D`)
- **Variables/Functions**: snake_case (e.g., `current_speed`, `cast_rod`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_SPEED`, `FISHING_STATE`)
- **Signals**: snake_case, past tense (e.g., `fish_caught`, `rod_cast`)
- **File Names**: snake_case (e.g., `main_menu.tscn`, `player_controller.gd`)

## Directory Structure

- `src/`: Source code and scenes
  - `systems/`: Manager scripts (singletons or logic controllers)
  - `ui/`: User Interface scenes and scripts
  - `player/`: Player scenes and scripts
  - `fishing/`: Fishing-specific logic
  - `world/`: World objects and levels
- `assets/`: Raw assets (textures, audio, models)
- `docs/`: Documentation
- `tests/`: Unit tests (if applicable)

## Coding Style

- Use tabs for indentation.
- Type hints are encouraged (e.g., `var speed: float = 10.0`).
- Comments should explain *why*, not *what*.
- Avoid magic numbers; define constants.
  
## Version Control

- **Commit Messages**: Present tense, imperative style (e.g., "Add fishing minigame", "Fix player movement bug").
- **Branches**: `feature/feature-name` or `fix/bug-name`.
