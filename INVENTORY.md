# Inventory system

`InventoryManager` and `InventoryUI` are autoloads. Inventory data and definitions therefore survive room changes. The UI is parented under a full-viewport `Control` on its `CanvasLayer`, so the panel is centered in screen coordinates and recalculated on viewport resize. The screen button appears while a player is present. Open panels hold the player's `inventory` movement lock; dialogue and transitions use separate owner locks. Inventory can be toggled from the InputMap `inventory` action.

## Adding an item

1. Create a Resource using `scripts/inventory_item.gd` as its script. Set a unique `id`, display name, description, category flags, icon, stack limit, and use/consumable settings.
2. Register the Resource once, for example from a future item catalog or the level's setup script: `InventoryManager.register_item(load("res://items/example.tres"))`.
3. Add/remove items through `InventoryManager.add_item(&"id", amount)` and `remove_item(&"id", amount)`. These return the accepted/removed quantity. Use `has_item`, `get_item_count`, or `get_items` to query state. Inventory change signals notify UI and other systems.
4. For a usable item, attach a script extending `InventoryItem` and override `use(user) -> bool`. Return `true` only when use succeeds; consumable items are then reduced by one.

The `categories` export is a flags field, so an item can appear under Collectibles, Gameplay Items, or both. `teacher_note.tres` is the single registered item at this stage. Inventory slots can be selected to read their full description in the details area.

## Teacher note reward

The classroom NPC uses the `teacher_note_dialogue` ID and `teacher_note_reward` reward ID. `DialogueManager.dialogue_completed` fires only when the player advances past the final line; cancelling a conversation does not grant the reward. The manager clears its active state and releases the movement lock before emitting completion. NPC dialogue repeatability and one-time rewards are separate exported states. `InventoryManager.grant_reward_once` stores claimed reward IDs. Coins use a separate central balance through `add_coins`, `remove_coins`, and `get_coins`; they are not inventory stacks. `teacher_note.tres` defines the item and `assets/teacher_note.svg` is its icon.

## Pause, settings, and save foundation

`PauseMenu` is a persistent `CanvasLayer` autoload with `PROCESS_MODE_ALWAYS`; ESC toggles it while the `SceneTree` pause stops gameplay. Options use the existing `Music` and `SFX` buses and InputMap actions. `GameSettings` persists those values, keyboard binds, and mouse sensitivity to `user://settings.cfg`. Pause menu saves inventory stacks, coin balance, and claimed rewards to `user://savegame.json`. Save loading and broader world/player restoration remain future work.

## Display scaling

The game starts in regular fullscreen at a 1152×648 logical viewport. Canvas item stretching with the `keep` aspect setting preserves UI and artwork proportions; screens with a different aspect ratio can show letterbox bars. The Inventory panel uses center anchors and resizes to the viewport with edge margins.
