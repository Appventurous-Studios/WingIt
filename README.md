# WingIt

WingIt is a portrait-mode Godot 4 prototype for a one-finger falling game. The prototype uses only hand-authored greybox geometry; it contains no generated artwork.

## Run

Open this directory in Godot 4.2 or newer and run `scenes/main.tscn` (also configured as the project main scene). The project uses a 540 × 960 logical viewport and canvas-item stretching.

## Play loop

1. Open **Wing Forge** to tune the wing span, size, materials, craft level, color, and two equipped action slots.
2. Start the current level and steer through the barriers.
3. Clear the goal to receive coins and unlock the next material or action.
4. Return to the forge to equip rewards and improve the wing before the next flight.

Tap the left or right half of the play screen to steer. Swipe to activate action slot 1; press and hold to activate slot 2. A failed flight can be retried without losing the equipped build. Progress is saved locally in `user://wingit_progress.cfg`.

## Extending the prototype

- Create `WingMaterial` resources for skin or structure materials. Set a material ID, display name, graybox color, weight/thrust/score values, and optionally assign a human-made `Texture2D` in `display_texture`. Add the resource to `material_catalog` in `scripts/progress_store.gd`; rewards unlock catalog entries in order.
- Create `WingAbility` resources for thrust, glide, or feather-dash actions and add them to `ability_catalog`. Unlock order is catalog order.
- `WingBuild` contains the wing materials, editable geometry values, craft level, and a configurable action-slot count. The player gesture mappings currently invoke slots 1 and 2; `PlayerController.activate_action(slot_index)` is index-based so additional input mappings can be added with further slots.
- Movement, gesture thresholds, level width, gap layout, scoring inputs, and resource appearance/stat values are exported for Inspector tuning. GDScript follows Godot's `snake_case` variable and function naming convention.

There are no repository-specific automated tests or Android export presets yet. Android export requires the Android build template, SDK, and signing configuration in Godot.