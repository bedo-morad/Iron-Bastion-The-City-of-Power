# CLAUDE.md

This file provides guidance to Claude (claude.ai/code) when working with code in this repository.

## Read First

- **`CLAUDE.md` is the single source of truth** for this repo.
  - Architecture, build/run, vision/roadmap, and working agreements all live here.
  - `AGENTS.md` (for Codex and other AGENTS.md-aware tools) and `project-context.md` are thin pointers back to this file.
  - **Make all documentation updates here**, not in those, so the docs never drift apart.


# CRITICAL RULES - MUST FOLLOW

## RESPONSES

- Keep responses concise and to the point — unless the user asks otherwise.

## Communication Preferences

- Ask for clarifications on ambiguous problems rather than guessing.
- Be direct and honest. Keep responses concise unless asked otherwise.

## PLANNING MODE

- Always ask clarifying questions.
- Never assume design, tech stack, or features.
- Use deep-dive sub-agents to assist with research.
- Use deep-dive sub-agents to review the different aspects of your plan before presenting to the user.

## CHANGE / EDIT MODE

- Never implement features yourself when possible — use sub-agents!
- Identify changes from the plan that can be implemented in parallel, and use sub-agents to implement the features efficiently.
- When using sub-agents to implement features, act as a coordinator only.
- Use the best model for the task — premium models for complex tasks (like coding) and mid-tier models for simpler tasks, like documentation.
- After completing features (large or small), always run commands like lint, type check, and build to check code quality.

## TESTING

- Use any testing tools, libraries, or scripts available to the project for testing your changes.
- Never assume your changes simply work — always test!
- If the project does not have any testing tools, scripts, MCP tools, skills, etc. available, ask the user whether testing should be skipped.

## Project Overview

**Iron Bastion: The City of Power** — a top-down 2D action-adventure RPG built in **Godot 4.6** with **GDScript**, inspired by classic 2D Zelda games.

The developer is a backend engineer (Java/Spring Boot, some Flutter; CS grad) who is a **beginner in Godot/GDScript** — prefer clear explanations over assumptions.

## Vision & Planned Features

Built by following the YouTube series [*Make a 2D Action & Adventure RPG in Godot 4*](https://www.youtube.com/playlist?list=PLfcCiyd_V9GH8M9xd_QKlyU8jryGcy3Xa). Much of the architecture (state machines, hit/hurt boxes, manager autoloads) mirrors that series, so it's a useful reference when a pattern looks unfamiliar.

Intended scope (✅ built · 🚧 partial · ⬜ not started):

- ✅ Player movement & 4-direction facing
- 🚧 Combat
  - Melee attack, player/enemy stun, and enemy death all work.
  - **Player death is still a placeholder** (HP resets instead of dying).
  - TODO: Enemy with Chase State.
- 🚧 World exploration — multi-room level transitions exist (`Levels/Area01/01–03`); the world is still small.
- 🚧 Persistent Data
  - Pause menu Save/Load works (`SaveManager` persists current level + player HP/position + inventory).
  - The `items` field is now wired up (serialized inventory); `persistence` / `quests` fields exist in the save dict but aren't wired up yet.
- 🚧 Inventory (Items - Enemy Drops - Treasure Chest)
  - Resource-driven inventory renders in the pause menu (`ItemData` / `SlotData` / `InventoryData` + `InventoryUi`).
  - **Pickup → store → use loop works:** `ItemPickup` props in the world add items to the player inventory (`InventoryData.add_item()` stacks or fills the first empty slot), and consumable items run their `ItemEffect`s when a slot is pressed.
  - **Inventory now saves/loads:** `SaveManager` serializes the inventory into the save's `items` field (`InventoryData.get_save_data()` / `parse_save_data()`).
  - **Enemy drops work:** dying enemies spawn `ItemPickup`s via `EnemyStateDestroy` + per-enemy `DropData` (probability + amount range); the pickups are physics bodies that scatter, bounce off walls, and bob (see Enemy System / Inventory System).
  - TODO: treasure chests.
- ⬜ Puzzles
- ⬜ Boomerang
- ⬜ Music & Audio Manager
- ⬜ NPCs
- ⬜ Splash & Title Screen
- ⬜ Boss Battle
- ⬜ Quest System
- ⬜ Equipment System

## Build & Run

- **Godot executable:** `d:\Game Dev\Godot\Godot.exe`
- **Open project:** Open the root folder in Godot 4.6 or JetBrains Rider (primary IDE).
- **Run game:** F5 in Godot editor, or `"d:\Game Dev\Godot\Godot.exe" --path .` from the project root.
- **No test framework is currently configured.** There is no build step, linter, or CI. If testing is needed, ask the user whether to skip or set one up.

## Architecture

### Entry Point

- Main scene: `Levels/Area01/01.tscn` (set via UID `uid://bbytmlooyyxjw` in `project.godot`).
- `Levels/PlayGround/playground.tscn` still exists as a standalone dev sandbox (no level transitions) but is no longer the entry point.

### Autoload Singletons

Listed in `project.godot` → `[autoload]`, in load order:

| Singleton | Script / Scene | Purpose |
|---|---|---|
| `LevelManager` | `00-Globals/global_level_manager.gd` | Tilemap bounds (`tile_map_bounds_changed`) and level-load orchestration: `load_new_level()`, `level_load_started` / `level_loaded` signals |
| `PlayerHud` | `GUI/HUD/player_hud.tscn` | On-screen heart HUD; redrawn via `update_hp(hp, max_hp)` |
| `PlayerManager` | `00-Globals/global_player_manager.gd` | Instantiates and owns the `Player`; reparents it across levels; `set_hp()` / `set_player_position()` used by `SaveManager` on load; also holds the shared `INVENTORY_DATA` const (preloads `player_inventory.tres`) that world pickups write to |
| `SceneTransition` | `GUI/scene_transition/scene_transition.tscn` | Full-screen fade overlay; `fade_out()` / `fade_in()` |
| `SaveManager` | `00-Globals/global_save_manager.gd` | Save/load to `user://save.sav` (JSON); F5/F9 quick save/load |
| `PauseMenu` | `GUI/pause_menu/pause_menu.tscn` | Pause overlay (`process_mode = ALWAYS`, `layer = 3`); Resume/Save/Load/Quit buttons |
| `ToastManager` | `GUI/toast/toast.tscn` | Transient toasts (auto-dismiss after 3 s); `push_message(text)` |

> The former `MCPRuntime` autoload (and the `godot_mcp_*` / `auto_reload` editor plugins) are **no longer enabled** — only `rider-plugin` remains. The addon folders are still on disk but disabled in `project.godot`.

### Player System

**`Player`** (`Player/Scripts/player.gd`) — `CharacterBody2D` (`class_name Player`).

- Reads input each frame, delegates movement to `move_and_slide()`.
- Manages 4-directional facing via `cardinal_direction` (+ the `DIR_4` table).
- Sets `PlayerManager.player = self` in `_ready()` (though `PlayerManager` also pre-instantiates it — see Gotchas).

**Health:**

- `hp` / `max_hp` (both `10`) plus an `invulnerable` flag.
- The player owns a `$HitBox` (on the *PlayerHurt* layer) whose `damaged` signal is wired to `take_damage(hurt_box)`.
- `take_damage` early-returns while invulnerable, else calls `update_hp(-hurt_box.damage)` and emits `player_damaged(hurt_box)`.
- `update_hp()` clamps `hp` and pushes it straight to `PlayerHud.update_hp(hp, max_hp)`.
- `make_invulnerable(duration = 1.0)` toggles i-frames and disables the HitBox.
- ⚠️ **Death is not implemented yet:** the `hp <= 0` branch just calls `update_hp(99)`, resetting to full — the player currently cannot die.

**Effects & weapon:**

- `$EffectAnimationPlayer` plays the `"damaged"` flicker.
- The weapon is `%AttackHurtBox` (a `HurtBox` masking the *Enemy* layer, `monitoring` off until an attack swings).

**State machine:**

- `PlayerStateMachine` (`Player/Scripts/player_state_machine.gd`) discovers child `State` nodes, sets the shared static `player` / `state_machine`, calls `init()` on every state, then drives `process` / `physics` / `handle_input` on the current state. First child is the initial state.
- `State` base class (`Player/Scripts/state.gd`) — both `player` and `state_machine` are **static vars**, shared by all state instances.
- Concrete states (scene order): `StateIdle`, `StateWalk`, `StateAttack`, `StateStun`.

**`StateStun`** is entered by *signal*, not the usual return-value transition:

- `init()` connects `player.player_damaged`; on damage it calls `state_machine.change_state(self)` directly, so it can interrupt any current state.
- On enter: applies knockback away from the `hurt_box`, calls `make_invulnerable`, plays `stun_<dir>` + the `"damaged"` effect, blocks input, and decelerates.
- Returns to `Idle` when the stun animation finishes.

**`PlayerInteractionsHost`** — rotates to match player facing; child of the Player node.

### Enemy System

Mirrors the player pattern, with these specifics:

**`Enemy`** (`Enemies/Scripts/enemy.gd`) — `CharacterBody2D` (`class_name Enemy`).

- Grabs `PlayerManager.player` in `_ready()` (now safe — the player exists from autoload init).
- Has exported `hp` (default `3`) and an `invulnerable` flag.
- Owns a `$HitBox` whose `damaged` signal is wired to `_take_damage(hurt_box)`:
  - Subtract `hurt_box.damage`.
  - Emit **`enemy_damaged(hurt_box)`** if `hp > 0`, or **`enemy_destroyed(hurt_box)`** if `hp <= 0`.
- Also emits `direction_changed`.

**State machine:**

- `EnemyStateMachine.initialize(enemy)` sets `enemy` + `state_machine` on each child `EnemyState`, calls `init()` on all, then enters the first child.
- `EnemyState` base class — stores `enemy` and `state_machine` as **instance** vars (not static like player states).

**Concrete states (Slime scene order):**

- `EnemyStateIdle` — timer-based; configurable `after_idle_state`.
- `EnemyStateWonder` — random cardinal movement, cycles. Note the spelling **"Wonder"**, not "Wander".
- `EnemyStateStun`:
  - `init()` connects `enemy.enemy_damaged`.
  - On trigger: sets `invulnerable`, knocks back away from the hit, plays `stun_<dir>`.
  - Returns to `next_state` (Idle) when the animation ends. No timer — duration = animation length.
- `EnemyStateDestroy` — terminal death state:
  - `init()` connects `enemy.enemy_destroyed`.
  - On enter: knocks back, plays `destroy_<dir>`, disables the `HurtBox`, **drops items** (`drop_items()`), then `queue_free()`s when the animation finishes.
  - Exports `drops: Array[DropData]` (under the `"Item Drops"` `@export_category`) and `preload`s the `ItemPickup` scene.
  - `drop_items()` walks each `DropData`, rolls `get_drop_count()`, and for each rolled item instantiates an `ItemPickup`, sets its `item_data`, `call_deferred("add_child", ...)`s it onto the enemy's parent (so it survives the enemy freeing), positions it at the enemy, and gives it a randomly-rotated `velocity` based on the enemy's so drops scatter outward.

**`DropData`** (`Enemies/Scripts/drop_data.gd`, `class_name DropData`, `Resource`) — one drop-table entry:

- `item_data: ItemData`, `probability` (0–100 %), `min_amount` / `max_amount` (1–10).
- `get_drop_count()` returns `0` if a `randf_range(0, 100)` roll fails the `probability`, otherwise a `randi_range(min_amount, max_amount)`.

**`Slime`** (`Enemies/Slime/Slime.tscn`) is the one concrete enemy.

- State children in order: `Idle → Wonder → Stun → Destroy`.
- Carries both a `HurtBox` (deals contact damage to the player) and a `HitBox` (receives the player's attacks).
- Its `Destroy` state's `drops` array holds two `DropData` entries: a **gem** (100 %, up to 2) and an **apple** (25 %, 1).

### Combat: HitBox / HurtBox Pattern

**`HurtBox`** (`Scenes/HurtBox/hurt_box.gd`) — `Area2D` with an exported `damage: int`.

- On `area_entered`, if the other area `is HitBox`, calls `hit_box.take_damage(self)` — passing **itself**.

**`HitBox`** (`Scenes/HitBox/hit_box.gd`) — `Area2D`.

- `take_damage(hurt_box)` re-emits `damaged(hurt_box)`.
- ⚠️ The signal is *declared* `damaged(damage: int)` but actually emits the **`HurtBox`** object — receivers read `hurt_box.damage` (and `hurt_box.global_position` for knockback).

**Flow:**

```
HurtBox overlaps HitBox → HitBox.take_damage() → HitBox emits damaged(hurt_box) → owner's handler runs
```

Owners respond differently:

- **Player** → `take_damage` → `StateStun` (or the HP-reset placeholder).
- **Enemy** → `_take_damage` → `EnemyStateStun` (`hp > 0`) or `EnemyStateDestroy` (`hp <= 0`).
- **`Plant`** (`Scenes/Props/Plants/plant.gd`) → `queue_free()`.

### Camera & Tilemap Bounds

- `LevelTileMaps` (`Tile Maps/level_tile_maps.gd`) computes bounds from `get_used_rect()` and pushes them to `LevelManager`.
- `PlayerCamera` subscribes to `LevelManager.tile_map_bounds_changed` and sets camera limits.

### Levels & Scene Transitions

Levels live under `Levels/` (`Area01/01.tscn`, `02.tscn`, `03.tscn`, plus the `PlayGround` sandbox). Three scripts in `Levels/Scripts/` drive room-to-room flow:

**`Level`** (`level.gd`, `class_name Level`, `Node2D`) — root of each level scene.

- On `_ready()`:
  - Enables `y_sort_enabled`.
  - Calls `PlayerManager.set_as_parent(self)` to pull the persistent player into the level.
  - Connects `LevelManager.level_load_started` → `_free_level` (which unparents the player and frees the old level).

**`PlayerSpawn`** (`player_spawn.gd`, `Node2D`) — an editor marker (hidden at runtime).

- On the **first game load only** (`PlayerManager.player_spawned == false`) it moves the player to its position.
- Afterward, positioning is handled by level transitions instead.

**`LevelTransition`** (`level_transition.gd`, `class_name LevelTransition`, `Area2D`, `@tool`) — a door zone at a room edge.

- Exports:
  - `level` — target `.tscn`.
  - `target_transition_area` — the **node name** to land at in the target scene (default `"LevelTransition"`).
  - Editor sizing exports: `size`, `side`, `snap_to_grid`.
- On `body_entered`: calls `LevelManager.load_new_level(level, target_transition_area, get_offset())`.
- On load: `_place_player()`s the player if its own `name` matches `LevelManager.target_transition`.

**Transition flow:**

1. Player enters a `LevelTransition`.
2. `LevelManager.load_new_level()` pauses the tree.
3. `await SceneTransition.fade_out()`.
4. Emits `level_load_started` (old level frees).
5. `change_scene_to_file()`.
6. `await SceneTransition.fade_in()`.
7. Unpauses, emits `level_loaded`.
8. The new `Level` reparents the player; the `LevelTransition` whose name matches `target_transition` repositions it.

### HUD (`PlayerHud`)

- `PlayerHud` (`GUI/HUD/player_hud.gd`, `CanvasLayer`, autoload) shows player HP as hearts.
- `Player.update_hp()` calls `PlayerHud.update_hp(hp, max_hp)` **directly** (no signal).
- A single heart is `HeartGui` (`GUI/HUD/heart_gui.gd`, `Control`):
  - `value` (`0` / `1` / `2` = empty / half / full) sets a sprite frame.
  - **Each heart = 2 HP**, so `max_hp` 10 → 5 visible hearts.
  - The scene pre-places 10 hearts (20 HP capacity).
- There is a single `hp` stat — no separate "life" vs "health".

### Scene Transition (`SceneTransition`)

- `SceneTransition` (`GUI/scene_transition/scene_transition.gd`, `CanvasLayer`, autoload) is a full-screen black `ColorRect`.
- `fade_out()` / `fade_in()` (0.2 s each, `await`-able).
- `process_mode = ALWAYS` so fades animate while `LevelManager` holds the tree paused.
- Triggered only by `LevelManager.load_new_level()`.

### Pause Menu & Save/Load

**`PauseMenu`** (`GUI/pause_menu/pause_menu.gd`, `CanvasLayer`, autoload).

- `process_mode = ALWAYS`, `layer = 3`.
- Emits **`shown`** / **`hidden`** signals from `show_pause_menu()` / `hide_pause_menu()` — the inventory UI listens to these to build/clear itself (see Inventory System).
- Exposes `update_item_description(text)` which writes to the `$Control/ItemDescription` label (driven by inventory slot focus).
- Exposes `play_audio(audio)` which plays an item's use-sound through its `$Control/ItemEffectAudio` player (used by `HealItemEffect`; see Inventory System).
- `_unhandled_input` toggles on the `pause` action:
  - `show_pause_menu()` sets `get_tree().paused = true` and grabs focus on the **Resume** button.
  - `hide_pause_menu()` unpauses.
- Buttons (in scene order):
  - **Resume** — just hides the menu.
  - **Save** — calls `SaveManager.save_game()`.
  - **Load** — calls `SaveManager.load_game()`, `await`s `LevelManager.level_load_started` before hiding so the menu doesn't close before the scene swap begins.
  - **Quit** — calls `get_tree().quit()`.

**`SaveManager`** (`00-Globals/global_save_manager.gd`, autoload).

- Single-slot JSON save at `user://save.sav`.
- Holds an in-memory `current_save: Dictionary`:
  - `scene_path`
  - `player {hp, max_hp, pos_x, pos_y}`
  - `items` — written/read as the serialized inventory (see below).
  - `persistence` / `quests` remain declared-but-unused stub arrays.
- Signals: `game_saved`, `game_loaded`.
- Quick save/load: handles **`quick_save` (F5)** / **`quick_load` (F9)** in `_unhandled_input` — pauses the tree, runs save/load, unpauses.

**`save_game()`:**

1. Calls `update_player_data()` — reads `PlayerManager.player.hp` / `max_hp` / `global_position`.
2. Calls `update_scene_path()` — scans `get_tree().root` children for a `Level` and stores its `scene_file_path`.
3. Calls `update_item_data()` — stores `PlayerManager.INVENTORY_DATA.get_save_data()` into `current_save.items`.
4. `JSON.stringify`s the dict, writes one line.
5. Emits `game_saved`.
6. `ToastManager.push_message("Game Saved")`.

**`load_game()`:**

1. Parses the save file.
2. Calls `LevelManager.load_new_level(scene_path, "", Vector2.ZERO)` — empty `target_transition` → no `LevelTransition` repositions the player.
3. `await`s `level_load_started`.
4. Restores position via `PlayerManager.set_player_position()`, HP via `PlayerManager.set_hp()`, and the inventory via `PlayerManager.INVENTORY_DATA.parse_save_data(current_save.items)`.
5. `await`s `level_loaded`.
6. Emits `game_loaded`.
7. `ToastManager.push_message("Game Loaded")`.

**`PlayerManager.set_hp(hp, max_hp)`** — sets `player.max_hp` / `player.hp` then calls `player.update_hp(0)` to refresh the HUD without changing HP again.

### Toast Notifications (`ToastManager`)

- `ToastManager` (`GUI/toast/toast.gd`, `CanvasLayer`, autoload, `layer = 2`) is a stack of transient text toasts in the top-left of the screen.
- `ToastManager.push_message(text)` instantiates a `ToastItem` (`GUI/toast/toast_item.tscn`, `PanelContainer`) into a `VBoxContainer` and plays the `show_notification` animation.
- Animation: 3 s total — fade-in → hold → fade-out. When it finishes, the item `queue_free()`s itself.
- Used by `SaveManager` to surface "Game Saved" / "Game Loaded" feedback.
- Intended as the general-purpose channel for short, non-interactive messages. Reserve "notification" for richer popups later (quests, achievements).

### Inventory System

A resource-driven inventory that renders inside the pause menu. There is **no inventory autoload** — the data lives in a `.tres` and the UI is a node inside the pause menu scene. Items are now picked up from the world, stacked, and consumed for effects (no longer read-only).

**Data resources:**

- **`ItemData`** (`Items/scripts/item_data.gd`, `class_name ItemData`, `Resource`) — one item definition: `name`, `description` (`@export_multiline`), `texture`, and `effects: Array[ItemEffect]` (under the `"Item Use Effects"` `@export_category`). Concrete items are `.tres` files in `Items/` (`gem.tres`, `potion.tres`, `stone.tres`, `apple.tres`), all drawing regions from the shared `Items/sprites/items.png` atlas.
  - `use() -> bool` returns `false` when `effects` is empty (so the item isn't consumable), otherwise runs every non-`null` effect's `use()` and returns `true`.
  - `potion` and `apple` carry a `HealItemEffect`; `gem` and `stone` have **no effects** (their `.tres` references the effect script but assigns no effects array), so they're collectible-only.
- **`ItemEffect`** (`Items/item_effect/item_effect.gd`, `class_name ItemEffect`, `Resource`) — base class for a usable effect: a `use_description: String` and a `use()` that does nothing by default. Subclass it to add behavior.
- **`HealItemEffect`** (`Items/item_effect/heal_item_effect.gd`, `class_name HealItemEffect extends ItemEffect`) — `heal_amount: int = 1` + `audio: AudioStream`. `use()` calls `PlayerManager.player.update_hp(heal_amount)` and `PauseMenu.play_audio(audio)`. Potion sets `heal_amount = 2` (one heart); apple keeps the default `1` (half a heart, since each heart = 2 HP).
- **`SlotData`** (`GUI/Inventory/scripts/slot_data.gd`, `class_name SlotData`, `Resource`) — one stack: `item_data: ItemData` + `quantity: int`. `quantity` has a setter that calls `emit_changed()` once it drops below `1` (this drives slot removal — see below).
- **`InventoryData`** (`GUI/Inventory/scripts/inventory_data.gd`, `class_name InventoryData`, `Resource`) — `slots: Array[SlotData]` (fixed-size 10; empty slots are `null`). The player's instance is `GUI/Inventory/player_inventory.tres`, which now **starts empty** (all 10 slots `null`; the old seeded gem/potion/stone were removed).
  - `_init()` calls `connect_slots()`, wiring each existing slot's `changed` signal to `slot_changed`.
  - `add_item(item_data, count = 1) -> bool` — stacks onto the first slot already holding that `item_data`, else fills the first `null` slot with a new `SlotData` (connecting its `changed`), else pushes a `"Inventory is full"` toast and returns `false`.
  - `slot_changed()` nulls out any slot whose `quantity < 1` (disconnects its `changed`, sets the entry to `null`) and calls `emit_changed()` so the UI rebuilds.
  - **Save/load serialization** (used by `SaveManager`):
    - `get_save_data() -> Array` maps every slot through `item_to_save()`, producing a fixed-length array (one entry per slot).
    - `item_to_save(slot) -> Dictionary` returns `{item_resource_path, quantity}`; an empty slot encodes as `{"", 0}`, otherwise it stores the `ItemData`'s `resource_path` and the stack `quantity`.
    - `parse_save_data(save_data)` clears + re-sizes `slots`, rebuilds each entry via `item_from_save()`, then calls `connect_slots()` to re-wire the `changed` signals.
    - `item_from_save(save_object) -> SlotData` returns `null` for an empty `item_resource_path`, else `load()`s the `ItemData` by path into a new `SlotData` and sets its `quantity`.

**World pickups:**

- **`ItemPickup`** (`Items/item_pickup/item_pickup.gd`, `class_name ItemPickup`, `@tool`, `CharacterBody2D`; scene `Items/item_pickup/item_pickup.tscn`) — a collectible placed in a level *or* spawned by an enemy drop.
  - Exports `item_data: ItemData`; its setter updates the child `Sprite2D` so the correct icon previews in the editor (`@tool`).
  - At runtime `_ready()` connects `$Area2D.body_entered`. On a `Player` body it calls `PlayerManager.INVENTORY_DATA.add_item(item_data)`; if that returns `true` it disconnects the signal, plays `$AudioStreamPlayer2D`, hides itself, `await`s the sound, then `queue_free()`s. (If the inventory is full, `add_item` returns `false` and the pickup stays.)
  - **It's now a physics body** (`CharacterBody2D`, `collision_mask` = Walls): `_physics_process` `move_and_collide`s its `velocity`, bounces off whatever it hits, and applies linear drag (`velocity -= velocity * delta * 4`) so dropped items scatter from the enemy, ricochet off walls, and coast to a stop. Placed (non-dropped) pickups just sit still (zero velocity).
  - The scene also carries a `ShadowSprite2D` and an `AnimationPlayer` autoplaying a `"default"` bob animation on the `Sprite2D`.
  - `Levels/Area01/01.tscn` places four of these directly: **Potion**, **Rock** (`stone`), **Gem**, **Apple**; enemies spawn more at runtime (see Enemy System → `EnemyStateDestroy` / `DropData`).

**UI:**

- **`InventoryUi`** (`GUI/Inventory/scripts/inventory_Ui.gd`, `class_name InventoryUi`, `Control`) — script on the `GridContainer` inside the pause menu. Holds an `@export var data: InventoryData` (the same `player_inventory.tres` that `PlayerManager.INVENTORY_DATA` points at).
  - On `_ready()`: connects `PauseMenu.shown → update_inventory`, `PauseMenu.hidden → clear_inventory`, and `data.changed → on_inventory_changed`, then calls `clear_inventory()`.
  - `update_inventory()` instantiates one `inventory_slot.tscn` per entry in `data.slots` (**including `null` ones**, so the child count is always 10), assigns `new_slot.slot_data = slot`, and connects each slot's `focus_entered → item_focused` (which records the focused index in `focus_index`).
  - `on_inventory_changed()` rebuilds the grid (`clear_inventory()` + `update_inventory()`), `await`s one process frame, then re-grabs focus on the previously focused index — so focus survives a slot emptying.
  - `clear_inventory()` `queue_free()`s all children. Slot nodes are **rebuilt every time the menu opens and on every `data.changed`**, and destroyed on close.
- **`InventorySlotUI`** (`GUI/Inventory/scripts/inventory_slot_ui.gd`, `class_name InventorySlotUI`, `Button`) — one slot (`GUI/Inventory/inventory_slot.tscn`).
  - `slot_data` has a setter (`set_slot_data`) that fills `$TextureRect`/`$Label` from `item_data.texture` and `quantity`; early-returns if the slot is `null`.
  - On focus (`focus_entered`) it pushes `item_data.description` to `PauseMenu.update_item_description()`; on `focus_exited` it clears it.
  - On `pressed` (`item_pressed`) it calls `slot_data.item_data.use()`; if that's `false` (non-consumable) it does nothing, otherwise it decrements `quantity` and refreshes the label.
- **`PauseMenu.play_audio(audio)`** plays an item's use-sound through `$Control/ItemEffectAudio` (an `AudioStreamPlayer`, `volume_db = -10`, `max_polyphony = 4`).

**Gotchas:**

- The pause menu scene **pre-places 10 empty `InventorySlot` instances** in the grid, but `InventoryUi._ready()` calls `clear_inventory()` immediately (freeing them), and slots are then rebuilt from `data.slots` each time the menu opens. The editor-placed instances are effectively just design-time scaffolding.
- The slot's item field is **`item_data`** (renamed from the old `itemData`) — it must match exactly across `slot_data.gd`, `inventory_slot_ui.gd`, and every `.tres` (a misnamed export caused an early bug).
- Focus handlers must null-check (`slot_data` / `item_data` can be `null`) because every slot — including empty ones — is a focusable button.
- `use()` returning `false` is what protects non-consumables: pressing a `gem` or `stone` (no effects) does nothing and doesn't decrement the stack.
- **`changed` only fires on a slot emptying.** `SlotData` emits `changed` solely when `quantity` drops below 1, which bubbles to `InventoryData.slot_changed` (nulls the slot) → `emit_changed()` → `InventoryUi.on_inventory_changed` (rebuild + restore focus). `add_item` (stack or new slot) does **not** emit `changed`, so an already-open inventory only auto-refreshes when a slot empties — world pickups happen while unpaused and just show up next time the menu opens.
- **Pickups, the UI, and saves share one resource.** `ItemPickup` writes to `PlayerManager.INVENTORY_DATA` while `InventoryUi.data` points at the same `player_inventory.tres`; because Godot caches a loaded resource, both see the same `slots`. `SaveManager` persists that same instance through `get_save_data()` / `parse_save_data()`, so a load mutates the shared resource in place.
- **Saved items are referenced by `resource_path`.** `item_from_save()` `load()`s each item's `.tres` by path, so renaming or moving an item resource breaks existing saves (the path won't resolve).

### Physics Layers

Defined in `project.godot`:

| Layer | Name |
|---|---|
| 1 | Player |
| 2 | PlayerHurt |
| 5 | Walls |
| 9 | Enemy |

### Input Actions

**Gameplay actions:** `up`, `down`, `left`, `right`, `attack`, `pause`, `quick_save` (F5), `quick_load` (F9).

- WASD + arrow keys + gamepad.
- `pause` = Esc / gamepad button 6.

**UI actions:** Godot's built-in `ui_accept`, `ui_cancel`, `ui_up` / `ui_down` / `ui_left` / `ui_right` are re-bound in `project.godot` so the pause menu navigates with both keyboard and gamepad.

### Display

- Viewport: 480×270.
- Window: 960×540 (2× integer scale).
- Stretch mode: `viewport`.
- Texture filter: nearest-neighbor (pixel art).

## Key Patterns & Gotchas

**State machines require scene tree wiring.**

- States must be child nodes of the state machine node in the scene.
- Adding a `.gd` file alone is not enough.

**PlayerManager owns the Player now.**

- `PlayerManager._ready()` instantiates the player (`add_player_instance()`) at autoload time and reparents it between levels (`set_as_parent` / `unparent_player`).
- Because this happens before any level loads, nodes that read `PlayerManager.player` in `_ready()` (like enemies) are now safe — the old spawn-order fragility is gone.
- `Player._ready()` still also assigns `PlayerManager.player = self`.

**`player_spawned` is first-load-only.**

- Set `true` 0.5 s after launch and never reset.
- So `PlayerSpawn` only positions the player on the very first load; later rooms position via `LevelTransition`.

**Stun is entered by signal.**

- Both `StateStun` and `EnemyStateStun` transition via a `*_damaged` signal calling `change_state()` directly, not via a state's return value.
- This is so they can interrupt any current state.

**Player can't die yet.** The `hp <= 0` path resets HP to full (placeholder, not a death/game-over flow).

**`damaged` carries a HurtBox.** Despite being declared `damaged(damage: int)`, `HitBox` emits the **`HurtBox`** object; handlers read `hurt_box.damage`.

**Player state's static vars.** `State.player` and `State.state_machine` are `static` — shared across all player state instances. Intentional but unusual; don't add per-instance refs.

**`Wonder` spelling.** The wander state is spelled `Wonder` (class, node, file) throughout — match it.

**Animation naming convention.** `{state}_{direction}` (e.g. `walk_down`, `attack_side`, `stun_up`). Directions: `down`, `up`, `side`.

**Sprite mirroring.** Left-facing is handled by `sprite.scale.x = -1`, not a separate animation.

**Save/Load skips `LevelTransition` placement.**

- `SaveManager.load_game()` calls `LevelManager.load_new_level(path, "", Vector2.ZERO)` with an empty `target_transition`.
- So no `LevelTransition` matches and *no* node repositions the player on load.
- `SaveManager` then sets the player's position itself (between `level_load_started` and `level_loaded`).
- Don't add logic that assumes a `LevelTransition` will run on every load.

## Editor Plugins

- `rider-plugin` — JetBrains Rider integration (the only plugin currently **enabled** in `project.godot`).
- `auto_reload`, `godot_mcp_editor`, `godot_mcp_runtime` — still present in `addons/` but **disabled**; the `MCPRuntime` autoload was removed.