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
  - Pause menu Save/Load works (`SaveManager` persists current level + player HP/position).
  - `items` / `persistence` / `quests` fields exist in the save dict but aren't wired up yet.
- ⬜ Inventory (Items - Enemy Drops - Treasure Chest)
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
| `PlayerManager` | `00-Globals/global_player_manager.gd` | Instantiates and owns the `Player`; reparents it across levels; `set_hp()` / `set_player_position()` used by `SaveManager` on load |
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
  - Plays `destroy_<dir>` then `queue_free()`.

**`Slime`** (`Enemies/Slime/Slime.tscn`) is the one concrete enemy.

- State children in order: `Idle → Wonder → Stun → Destroy`.
- Carries both a `HurtBox` (deals contact damage to the player) and a `HitBox` (receives the player's attacks).

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
  - Stub arrays: `items` / `persistence` / `quests` (declared but not yet written/read by anything).
- Signals: `game_saved`, `game_loaded`.
- Quick save/load: handles **`quick_save` (F5)** / **`quick_load` (F9)** in `_unhandled_input` — pauses the tree, runs save/load, unpauses.

**`save_game()`:**

1. Calls `update_player_data()` — reads `PlayerManager.player.hp` / `max_hp` / `global_position`.
2. Calls `update_scene_path()` — scans `get_tree().root` children for a `Level` and stores its `scene_file_path`.
3. `JSON.stringify`s the dict, writes one line.
4. Emits `game_saved`.
5. `ToastManager.push_message("Game Saved")`.

**`load_game()`:**

1. Parses the save file.
2. Calls `LevelManager.load_new_level(scene_path, "", Vector2.ZERO)` — empty `target_transition` → no `LevelTransition` repositions the player.
3. `await`s `level_load_started`.
4. Restores position via `PlayerManager.set_player_position()` and HP via `PlayerManager.set_hp()`.
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