# Playtest & Balance Guide

Run these checks in Roblox Studio after pasting all scripts from [SETUP.md](SETUP.md).

## Pre-flight (2 min)

- [ ] All 7 RemoteEvents exist under `ReplicatedStorage.Remotes`
- [ ] All 5 ModuleScripts exist under `ReplicatedStorage.Modules`
- [ ] `GameManager` is a **Script** (not LocalScript) in `ServerScriptService`
- [ ] NPC templates `Grunt`, `Runner`, `Tank` in `ServerStorage.NPCTemplates` each have `Humanoid`, `HumanoidRootPart`, and `NPCBrain` Script
- [ ] Tools in `StarterPack` named exactly `Rifle`, `Shotgun`, `SMG`
- [ ] At least one `SpawnLocation` in `Workspace.SpawnPoints`

## Phase 1 checklist

| # | Test | Expected |
|---|------|----------|
| 1 | Press Play (F5) | Wave 1 starts ~2s after spawn |
| 2 | Equip Rifle, click | First-person view, enemies take damage |
| 3 | Kill all grunts | Intermission message, 15s shop timer |
| 4 | Press **R** with partial mag | Reload blocks firing, mag refills |
| 5 | Let NPC hit you until death | Respawn after 3s with brief invulnerability |
| 6 | Empty mag, click | No shots until reload |

## Phase 2 checklist

| # | Test | Expected |
|---|------|----------|
| 7 | Equip Shotgun | Spread hits multiple pellets at close range |
| 8 | Equip SMG | Faster fire rate, higher ammo count |
| 9 | Kill NPC | Kill feed line appears top-right; +$15 currency |
| 10 | Clear wave | +$50 currency; shop opens |
| 11 | Buy Ammo Refill ($50) | All weapons refilled |
| 12 | Buy +25 HP ($75) | Max HP and current HP increase |
| 13 | Hold **Tab** | Scoreboard shows K/D/Wave/Currency |
| 14 | Wave 3+ | Runners and Tanks spawn |

## Two-client test (optional)

1. **Test → Start** with 2 players (Studio + local client).
2. Confirm both players see the same wave number and enemy count.
3. Confirm kills/currency are per-player on scoreboard.

## Default balance (tune in GunConfigs / WaveSystem)

| Weapon | Role | Feel |
|--------|------|------|
| Rifle | All-rounder | 25 dmg, 30 mag, tight spread |
| Shotgun | Close range | 8 pellets, 6 mag, wide spread |
| SMG | Spray | 14 dmg, 40 mag, fast fire |

| NPC | Speed | HP (wave 1 base) |
|-----|-------|------------------|
| Grunt | 14 | 80 (+12%/wave) |
| Runner | 22 | 50 |
| Tank | 8 | 200 |

**If too hard:** lower NPC damage in `NPCSpawner.luau` (`NPC_DAMAGE` table) or reduce wave counts in `WaveSystem.luau`.

**If too easy:** increase `NPC_BASE_HEALTH` scale in `WaveSystem.luau` or shorten intermission.

## Known Studio-only notes

- Output window warnings about missing templates mean that NPC model name doesn't match (`Grunt` / `Runner` / `Tank`).
- If HUD labels stay blank, verify ScreenGui child names match `HUDController` (`WaveLabel`, `EnemiesLabel`, etc.).
- If guns don't fire, confirm tool is in **Character** (equipped), not just Backpack.
