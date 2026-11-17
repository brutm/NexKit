# NexKit

> **The Ultimate All-in-One Leveling, Waypoints, Dungeon Tactics & Reagent Tracking Suite for World of Warcraft**

[![Version](https://img.shields.io/badge/Version-0.2-brightgreen.svg)](#)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-yellow.svg)](LICENSE)
[![Interface](https://img.shields.io/badge/WoW-Classic%20Era%201.15.5-blue.svg)](#)
[![Languages](https://img.shields.io/badge/Locales-EN%20%7C%20IT%20%7C%20DE%20%7C%20ES%20%7C%20FR%20%7C%20RU-orange.svg)](#)

---

## Overview

**NexKit** (also distributed as **NexusKit**) is an open-source, high-performance leveling and quality-of-life suite built for **World of Warcraft (Classic Era 1.15.x and custom clients)**. It combines speedrun leveling guides, smooth 3D waypoint navigation, dynamic quest sync, dungeon boss tactics, an interactive profession advisor, and a live reagent/materials tracker with in-bag buttons into one unified, lightweight, zero-taint addon.

---

## Key Features

### 1. Reagent & Materials Live Tracker (`/nk track`, `/nk trackbtn`)
* **Dedicated HUD Window**: A movable, resizable on-screen HUD tracking your selected reagents, herbs, ores, cloth, leather, meat, potions, and quest items in real time. Shows exact inventory count vs. target goal.
* **Interactive `[+]` Bag Slot Overlays**:
  * Every valid reagent or material slot in your bags displays a clean, solid green `[+]` button in the top-right corner.
  * Clicking `[+]` instantly toggles tracking, morphs the button into a red `[-]`, adds the item to your HUD tracker, and highlights the bag slot with a glowing cyan border.
  * Can be toggled on/off in Settings or via `/nk trackbtn` (enabled by default).
* **Alt + Left-Click Shortcut**: Simply hold `Alt` and left-click any item in your bags or loot frame to toggle tracking instantly without opening any menus.
* **Smart Highlight & Quest Protection**:
  * **Cyan Glow**: Currently tracked reagents.
  * **Golden Glow**: Valuable items to keep for future quests (never vendor important quest turn-in reagents).
  * **Orange/Yellow/Green Glow**: Materials relevant to leveling your currently learned professions.

### 2. Complete 1-60 Guided Speedrun Routes (Horde & Alliance)
* **Pre-calculated 1-60 Routes**: Full, step-by-step guidance covering all starting zones, mid-game contested regions, and end-game zones.
  * **Horde**: Durotar / Mulgore / Tirisfal (1-20) ➔ Southern Barrens / Stonetalon / Hillsbrad / Arathi / STV (20-40) ➔ Badlands / Tanaris / Feralas / Un'Goro / Felwood / Plaguelands (40-60).
  * **Alliance**: Elwynn / Dun Morogh / Teldrassil (1-20) ➔ Redridge / Duskwood / Wetlands / Hillsbrad / STV (20-40) ➔ Badlands / Tanaris / Feralas / Un'Goro / Felwood / Plaguelands (40-60).
* **Auto-Advancement**: Automatically advances across chapters and zones upon route completion.
* **Smart Auto-Sync**: Automatic step completion for quest accepts, turn-ins, flight paths, grinding milestones, and Hearthstone binds/uses.

### 3. Smooth 3D Waypoint Arrow & Map Pins
* Floating 3D/2D direction arrow with distance counter (yards) and arrival notifications.
* Optimized vector math and dimension caching for silky-smooth 60+ FPS even in crowded capital cities.
* World map and minimap POI pins: flight masters, innkeepers, class trainers, repair vendors, and mailboxes.

### 4. Dynamic Quest Log Sync (`/nk sync`)
* Instantly converts your current active quest log into an optimized leveling path for whatever zone you are currently exploring.
* Prioritizes tracked quests, suggests trainer visits at milestone levels, and groups nearby turn-ins.

### 5. Dungeon Guide & Boss Tactics (`/nk boss`)
* In-game tactic book with abilities, interrupt warnings, and phase strategies for Classic dungeons and raids.
* Auto-detection: automatically switches to the corresponding dungeon guide upon entering an instance.

### 6. Profession Skill Advisor (`/nk prof`)
* Step-by-step guide from 1 to 300 for all primary and secondary professions (Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring, Mining, Herbalism, Skinning, Cooking, First Aid, Fishing).
* Includes a **"Track All"** button to monitor all materials required for any recipe in your HUD with one click.

### 7. Buff & Weapon Reminder (`/nk buffs`)
* Smart monitor reminding you of missing class buffs (Intellect, Fortitude, Mark of the Wild, Blessings), weapon enhancements (oils/stones), and gathering tracking.

### 8. Zero-Taint Architecture
* Clean execution designed specifically for modern Classic Era engine requirements (1.15.5+).
* Isolated frames running in safe execution context without blocking default Blizzard UI action bars or protected combat routines.

---

## Installation

1. Download the latest release: **[NexKit-v0.2.zip](https://github.com/brutm/NexKit/releases/latest)**.
2. Extract the archive into your World of Warcraft AddOns directory:
   ```text
   World of Warcraft/_forever_/Interface/AddOns/
   ```
   *(Ensure the folder is named `NexKit` or `NexusKit`, e.g. `Interface/AddOns/NexKit/NexKit.toc`)*.
3. Launch World of Warcraft, verify that **NexKit** is enabled in the character selection **AddOns** menu, and enter the game.

---

## Slash Commands (`/nk`)

| Command | Action |
| :--- | :--- |
| `/nk` or `/nk help` | Opens the Welcome & Commands guide window |
| `/nk config` | Opens the multi-tab Settings configuration frame |
| `/nk track [item]` | Adds an item to the Reagent Tracker by name or link |
| `/nk trackbtn` | Toggles the `[+]` button overlays on bag items on/off |
| `/nk prof` | Opens the Profession Skill Advisor |
| `/nk buffs` | Opens the Buff & Tracking Advisor |
| `/nk boss [name]` | Opens the Dungeon Guide and boss tactics |
| `/nk sync` | Toggles dynamic Quest Log Sync mode |
| `/nk poi` | Toggles map/minimap Points of Interest pins |
| `/nk way <x> <y>` | Sets a custom TomTom-compatible waypoint |
| `/nk clear` | Clears the active custom waypoint |
| `/nk toggle` | Shows or hides the floating tracker HUD frame |
| `/nk reset` | Resets route progress for the current character |
| `/nk lang <code>` | Switches addon language (`enUS`, `itIT`, `deDE`, `esES`, `frFR`, `ruRU`) |
| `/nk donate` | Displays support and donation links (Ko-fi / PayPal) |

---

## Support & Donations

NexKit is **100% free and open-source software** developed for the community. If you enjoy using the addon and want to support ongoing development, new dungeon tactics, and continuous speedrun updates:

* **Ko-fi**: [https://ko-fi.com/kh4dgar](https://ko-fi.com/kh4dgar)
* **Discord Community**: [https://discord.gg/wowforever](https://discord.gg/wowforever)
* **GitHub Repository**: [https://github.com/brutm/NexKit](https://github.com/brutm/NexKit)

---

## Legal & License

Copyright (C) 2026 **NexKit Team**.

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. You are free to run, study, modify, and redistribute this software under the terms of the GPLv3 license.

See the [LICENSE](LICENSE) file for complete legal details.
