# Iron Bastion: The City of Power

A top-down 2D action-adventure RPG built with **Godot 4.7** and **GDScript**, inspired by classic Zelda-style exploration and combat.

> **Current state:** Active in-development prototype with core combat, room transitions, inventory, pickups, and save/load already playable.

---

## Why this project exists

This repository tracks the development of **Iron Bastion** as a practical game-dev journey:
- Learning Godot architecture and gameplay systems in production-like structure
- Building reusable systems (state machines, combat, inventory, transitions)
- Shipping incrementally with clear roadmap milestones

---

## Current feature snapshot

✅ **Implemented**
- 4-direction player movement and facing
- Melee combat loop (attack, hit/hurt logic, enemy stun, enemy death)
- Room-to-room level transitions with fade effects
- Resource-driven inventory UI in pause menu
- World pickups, enemy item drops, and treasure chests
- Save/load for level, player state, and inventory

🚧 **In progress / partial**
- Player death flow (currently placeholder behavior)
- Expanded enemy behavior (chase/combat depth)
- Broader world content and progression

⬜ **Planned**
- NPCs, quests, puzzles, equipment, boomerang, boss battle, audio/music systems, title/splash flow

---

## Tech stack

- **Engine:** Godot 4.7
- **Language:** GDScript
- **Project type:** 2D top-down action-adventure RPG
- **Primary IDE:** JetBrains Rider (Godot editor also supported)

---

## Run locally

### Requirements
- Godot 4.7 installed

### Open and run
1. Open the repository root in **Godot 4.7**
2. Press **F5** to run

The current entry scene is `Levels/Area01/01.tscn`.

---

## Controls (default)

- **Move:** WASD / Arrow Keys / Gamepad left stick
- **Attack:** `Z` / Gamepad button 2
- **Interact:** `X` / Gamepad button 0
- **Pause:** `Esc` / Gamepad button 6
- **Quick Save:** `F5`
- **Quick Load:** `F9`

---

## Architecture highlights

The codebase uses modular gameplay systems with clear separation of responsibilities:
- **Autoload managers** for level flow, player ownership, HUD, save/load, transitions, and UI overlays
- **State machines** for both player and enemy behavior
- **HitBox/HurtBox combat pattern** for damage processing and stun/death transitions
- **Resource-driven inventory** (`ItemData`, `SlotData`, `InventoryData`) with in-world pickups and consumable effects

For full technical documentation and system details, see **`CLAUDE.md`**.

---

## Project status & roadmap

This is a living project under active development. The current focus is:
1. Complete combat/death polish
2. Expand enemy AI and encounter depth
3. Grow world content and progression systems
4. Add quest/NPC and equipment loops
