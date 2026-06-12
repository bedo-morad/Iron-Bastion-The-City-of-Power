# CLAUDE.md

This file provides guidance to Claude (claude.ai/code) when working with code in this repository.

## Read First
- **`CLAUDE.md` is the single source of truth** for this repo — architecture, build/run, vision/roadmap, and working agreements all live here. `AGENTS.md` (for Codex and other AGENTS.md-aware tools) and `project-context.md` are thin pointers back to this file. **Make all documentation updates here**, not in those, so the docs never drift apart.

## Project Overview

**Iron Bastion: The City of Power** — a top-down 2D action-adventure RPG built in **Godot 4.6** with **GDScript**, inspired by classic 2D Zelda games. The developer is a backend engineer (Java/Spring Boot, some Flutter; CS grad) who is a **beginner in Godot/GDScript**; prefer clear explanations over assumptions.

## Vision & Planned Features

Built by following the YouTube series [*Make a 2D Action & Adventure RPG in Godot 4*](https://www.youtube.com/playlist?list=PLfcCiyd_V9GH8M9xd_QKlyU8jryGcy3Xa) — much of the architecture (state machines, hit/hurt boxes, manager autoloads) mirrors that series, so it's a useful reference when a pattern looks unfamiliar.

Intended scope (✅ built · 🚧 partial · ⬜ not started):
- ✅ Player movement & 4-direction facing
- 🚧 Combat — melee attack, player/enemy stun, and enemy death all work; **player death is still a placeholder** (HP resets instead of dying) (TODO: Enemy with Chase State)
- 🚧 World exploration — multi-room level transitions exist (`Levels/Area01/01–03`); the world is still small
- ⬜ Inventory (Items - Enemy Drops - Treasure Chest)
- ⬜ Puzzles 
- ⬜ Persistent Data
- ⬜ Boomerang
- ⬜ Music & Audio Manager
- ⬜ NPCs
- ⬜ Splash & Title Screen
- ⬜ Boss Battle
- ⬜ Quest System 
- ⬜ Equipment  System 

## Build & Run

- **Godot executable:** `d:\Game Dev\Godot\Godot.exe`
- **Open project:** Open the root folder in Godot 4.6 or JetBrains Rider (primary IDE).
- **Run game:** F5 in Godot editor, or `"d:\Game Dev\Godot\Godot.exe" --path .` from the project root (runs the main scene).
- **No test framework is currently configured.** There is no build step, linter, or CI. If testing is needed, ask the user whether to skip or set one up.

## Architecture

### Entry Point

Main scene: `Levels/Area01/01.tscn` (set via UID `uid://bbytmlooyyxjw` in `project.godot`). `Levels/PlayGround/playground.tscn` still exists as a standalone dev sandbox (no level transitions) but is no longer the entry point.

### Autoload Singletons (`project.godot` → `[autoload]`, in load order)

| Singleton | Script / Scene | Purpose |
|---|---|---|
| `LevelManager` | `00-Globals/global_level_manager.gd` | Tilemap bounds (`tile_map_bounds_changed`) **and** level-load orchestration: `load_new_level()`, `level_load_started` / `level_loaded` signals |
| `PlayerHud` | `GUI/HUD/player_hud.tscn` | On-screen heart HUD; redrawn via `update_hp(hp, max_hp)` |
| `PlayerManager` | `00-Globals/global_player_manager.gd` | **Instantiates and owns** the `Player`; reparents it across levels |
| `SceneTransition` | `GUI/scene_transition/scene_transition.tscn` | Full-screen fade overlay; `fade_out()` / `fade_in()` |

> The former `MCPRuntime` autoload (and the `godot_mcp_*` / `auto_reload` editor plugins) are **no longer enabled** — only `rider-plugin` remains. The addon folders are still on disk but disabled in `project.godot`.

### Player System

1. `Player` (`Player/Scripts/player.gd`) — `CharacterBody2D` (`class_name Player`). Reads input each frame, delegates movement to `move_and_slide()`, manages 4-directional facing via `cardinal_direction` (+ the `DIR_4` table). Sets `PlayerManager.player = self` in `_ready()` (though `PlayerManager` also pre-instantiates it — see Gotchas).
   - **Health:** `hp` / `max_hp` (both `10`) plus an `invulnerable` flag. The player owns a `$HitBox` (on the *PlayerHurt* layer) whose `damaged` signal is wired to `take_damage(hurt_box)`. `take_damage` early-returns while invulnerable, else `update_hp(-hurt_box.damage)` and emits `player_damaged(hurt_box)`. `update_hp()` clamps `hp` and pushes it straight to `PlayerHud.update_hp(hp, max_hp)`. `make_invulnerable(duration = 1.0)` toggles i-frames and disables the HitBox.
   - ⚠️ **Death is not implemented yet:** the `hp <= 0` branch just calls `update_hp(99)`, resetting to full — the player currently cannot die.
   - `$EffectAnimationPlayer` plays the `"damaged"` flicker; the weapon is `%AttackHurtBox` (a `HurtBox` masking the *Enemy* layer, `monitoring` off until an attack swings).
2. `PlayerStateMachine` (`Player/Scripts/player_state_machine.gd`) — discovers child `State` nodes, sets the shared static `player`/`state_machine`, calls `init()` on every state, then drives `process` / `physics` / `handle_input` on the current state. First child is the initial state.
3. `State` base class (`Player/Scripts/state.gd`) — **both `player` and `state_machine` are static vars**, shared by all state instances.
4. Concrete states (scene order): `StateIdle`, `StateWalk`, `StateAttack`, `StateStun`.
   - **`StateStun` (new):** entered by *signal*, not the usual return-value transition. Its `init()` connects `player.player_damaged`; on damage it calls `state_machine.change_state(self)` directly, so it can interrupt any current state. On enter it applies knockback away from the `hurt_box`, calls `make_invulnerable`, plays `stun_<dir>` + the `"damaged"` effect, blocks input, and decelerates — returning to `Idle` when the stun animation finishes.
5. `PlayerInteractionsHost` — rotates to match player facing; child of the Player node.

### Enemy System

Mirrors the player pattern, with these specifics:
- `Enemy` (`Enemies/Scripts/enemy.gd`) — `CharacterBody2D` (`class_name Enemy`). Grabs `PlayerManager.player` in `_ready()` (now safe — the player exists from autoload init). Has exported `hp` (default `3`) and an `invulnerable` flag, and owns a `$HitBox` whose `damaged` signal is wired to `_take_damage(hurt_box)`: subtract `hurt_box.damage`, then emit **`enemy_damaged(hurt_box)`** if `hp > 0` or **`enemy_destroyed(hurt_box)`** if `hp <= 0`. Also emits `direction_changed`.
- `EnemyStateMachine` — `initialize(enemy)` sets `enemy` + `state_machine` on each child `EnemyState`, calls `init()` on all, then enters the first child.
- `EnemyState` base class — stores `enemy` and `state_machine` as **instance** vars (not static like player states).
- Concrete states (Slime scene order): `EnemyStateIdle` (timer-based → configurable `after_idle_state`), `EnemyStateWonder` (random cardinal movement, cycles — note the spelling **"Wonder"**, not "Wander"), `EnemyStateStun`, `EnemyStateDestroy`.
   - **`EnemyStateStun` (new):** `init()` connects `enemy.enemy_damaged`; on trigger it sets `invulnerable`, knocks back away from the hit, plays `stun_<dir>`, and returns to `next_state` (Idle) when the animation ends. No timer — duration = animation length.
   - **`EnemyStateDestroy` (new):** `init()` connects `enemy.enemy_destroyed`; plays `destroy_<dir>` then `queue_free()`. Terminal death state.
- **`Slime`** (`Enemies/Slime/Slime.tscn`) is the one concrete enemy. State children in order: `Idle → Wonder → Stun → Destroy`. It carries both a `HurtBox` (deals contact damage to the player) and a `HitBox` (receives the player's attacks).

### Combat: HitBox / HurtBox Pattern

- `HurtBox` (`Scenes/HurtBox/hurt_box.gd`) — `Area2D` with an exported `damage: int`. On `area_entered`, if the other area `is HitBox`, it calls `hit_box.take_damage(self)` (passes **itself**).
- `HitBox` (`Scenes/HitBox/hit_box.gd`) — `Area2D` whose `take_damage(hurt_box)` re-emits `damaged(hurt_box)`. ⚠️ The signal is *declared* `damaged(damage: int)` but actually emits the **`HurtBox`** object — receivers read `hurt_box.damage` (and `hurt_box.global_position` for knockback).
- Flow: **HurtBox overlaps a HitBox → `HitBox.take_damage()` → HitBox emits `damaged(hurt_box)` → the HitBox owner's handler runs.** Owners respond differently:
  - **Player** → `take_damage` → `StateStun` (or the HP-reset placeholder).
  - **Enemy** → `_take_damage` → `EnemyStateStun` (`hp > 0`) or `EnemyStateDestroy` (`hp <= 0`).
  - **`Plant`** (`Scenes/Props/Plants/plant.gd`) → `queue_free()`.

### Camera & Tilemap Bounds

`LevelTileMaps` (`Tile Maps/level_tile_maps.gd`) computes bounds from `get_used_rect()` and pushes them to `LevelManager`. `PlayerCamera` subscribes to `LevelManager.tile_map_bounds_changed` and sets camera limits.

### Levels & Scene Transitions

Levels live under `Levels/` (`Area01/01.tscn`, `02.tscn`, `03.tscn`, plus the `PlayGround` sandbox). Three scripts in `Levels/Scripts/` drive room-to-room flow:

- `Level` (`level.gd`, `class_name Level`, `Node2D`) — root of each level scene. On `_ready()` it enables `y_sort_enabled`, calls `PlayerManager.set_as_parent(self)` to pull the persistent player into the level, and connects `LevelManager.level_load_started` → `_free_level` (which unparents the player and frees the old level).
- `PlayerSpawn` (`player_spawn.gd`, `Node2D`) — an editor marker (hidden at runtime). On the **first game load only** (`PlayerManager.player_spawned == false`) it moves the player to its position; afterward, positioning is handled by level transitions instead.
- `LevelTransition` (`level_transition.gd`, `class_name LevelTransition`, `Area2D`, `@tool`) — a door zone at a room edge. Exports `level` (target `.tscn`), `target_transition_area` (the **node name** to land at in the target scene, default `"LevelTransition"`), plus editor sizing exports (`size`, `side`, `snap_to_grid`). On `body_entered` it calls `LevelManager.load_new_level(level, target_transition_area, get_offset())`; on load it `_place_player()`s the player if its own `name` matches `LevelManager.target_transition`.

**Transition flow:** player enters a `LevelTransition` → `LevelManager.load_new_level()` pauses the tree, `await SceneTransition.fade_out()`, emits `level_load_started` (old level frees), `change_scene_to_file()`, `await SceneTransition.fade_in()`, unpauses, emits `level_loaded`. The new `Level` reparents the player; the `LevelTransition` whose name matches `target_transition` repositions it.

### HUD (`PlayerHud`)

- `PlayerHud` (`GUI/HUD/player_hud.gd`, `CanvasLayer`, autoload) shows player HP as hearts. `Player.update_hp()` calls `PlayerHud.update_hp(hp, max_hp)` **directly** (no signal).
- A single heart is `HeartGui` (`GUI/HUD/heart_gui.gd`, `Control`) whose `value` (`0`/`1`/`2` = empty/half/full) sets a sprite frame. **Each heart = 2 HP**, so `max_hp` 10 → 5 visible hearts; the scene pre-places 10 hearts (20 HP capacity). There is a single `hp` stat — no separate "life" vs "health".

### Scene Transition (`SceneTransition`)

`SceneTransition` (`GUI/scene_transition/scene_transition.gd`, `CanvasLayer`, autoload) is a full-screen black `ColorRect` with `fade_out()` / `fade_in()` (0.2 s each, `await`-able). Its `process_mode = ALWAYS` so fades animate while `LevelManager` holds the tree paused. Triggered only by `LevelManager.load_new_level()`.

### Physics Layers (`project.godot`)

| Layer | Name |
|---|---|
| 1 | Player |
| 2 | PlayerHurt |
| 5 | Walls |
| 9 | Enemy |

### Input Actions

`up`, `down`, `left`, `right`, `attack` — WASD + arrow keys + gamepad.

### Display

Viewport: 480×270, window: 960×540 (2× integer scale), stretch mode: `viewport`, texture filter: nearest-neighbor (pixel art).

## Key Patterns & Gotchas

- **State machines require scene tree wiring:** States must be child nodes of the state machine node in the scene. Adding a `.gd` file alone is not enough.
- **PlayerManager owns the Player now:** `PlayerManager._ready()` instantiates the player (`add_player_instance()`) at autoload time and reparents it between levels (`set_as_parent` / `unparent_player`). Because this happens before any level loads, nodes that read `PlayerManager.player` in `_ready()` (like enemies) are now safe — the old spawn-order fragility is gone. (`Player._ready()` still also assigns `PlayerManager.player = self`.)
- **`player_spawned` is first-load-only:** set `true` 0.5 s after launch and never reset, so `PlayerSpawn` only positions the player on the very first load; later rooms position via `LevelTransition`.
- **Stun is entered by signal:** both `StateStun` and `EnemyStateStun` transition via a `*_damaged` signal calling `change_state()` directly, not via a state's return value — so they can interrupt any current state.
- **Player can't die yet:** the `hp <= 0` path resets HP to full (placeholder, not a death/game-over flow).
- **`damaged` carries a HurtBox:** despite being declared `damaged(damage: int)`, `HitBox` emits the **`HurtBox`**; handlers read `hurt_box.damage`.
- **Player State's static vars:** `State.player` *and* `State.state_machine` are `static` — shared across all player state instances. Intentional but unusual; don't add per-instance refs.
- **`Wonder` spelling:** the wander state is spelled `Wonder` (class, node, file) throughout — match it.
- **Animation naming convention:** `{state}_{direction}` (e.g. `walk_down`, `attack_side`, `stun_up`). Directions: `down`, `up`, `side`.
- **Sprite mirroring:** Left-facing is handled by `sprite.scale.x = -1`, not a separate animation.

## Editor Plugins

- `rider-plugin` — JetBrains Rider integration (the only plugin currently **enabled** in `project.godot`).
- `auto_reload`, `godot_mcp_editor`, `godot_mcp_runtime` — still present in `addons/` but **disabled**; the `MCPRuntime` autoload was removed.


# CRITICAL RULES - MUST FOLLOW

## RESPONSES

- Keep responses concise and to the point - unless the user asks otherwise

## Communication Preferences

- Ask for clarifications on ambiguous problems rather than guessing.
- Be direct and honest. Keep responses concise unless asked otherwise.

## PLANNING MODE

- Always ask clarifying questions
- Never assume design, tech stack or features
- Use deep-dive sub-agents to assist with research
- Use deep-dive sub-agents to review the different aspects of your plan before presenting to the user

## CHANGE / EDIT MODE

- Never implement features yourself when possible - use sub-agents!
- Identify changes from the plan that can be implemented in parallel, and use sub-agents to implement the features efficiently
- When using sub-agents to implement features, act as a coordinator only
- Use the best model for the task - premium models for complex tasks (like coding) and mid-tier models for simpler tasks, like documentation
- After completing features (large or small), always run commands like lint, type check and next build to check code quality

## TESTING

- Use any testing tools, libraries available to the project for testing your changes
- Never assume your changes simply work, always test!
- If the project does not have any testing tools, scripts, MCP tools, skills, etc. available for testing, ask the user whether testing should be skipped.
