# DeepSleep

Roblox wave-survival FPS — Luau scripts for copy-paste into Roblox Studio.

## Quick start

1. Open [studio/SETUP.md](studio/SETUP.md) and create the Studio hierarchy (folders, RemoteEvents, GUIs, Tools, NPCs).
2. Paste each `.luau` file into the matching Studio instance (paths are in file headers).
3. Build a simple arena floor + cover in `Workspace.Arena` and add `SpawnPoints`.
4. Press **Play** in Studio and follow [studio/PLAYTEST.md](studio/PLAYTEST.md).

## What's included

| Phase | Features |
|-------|----------|
| **Core** | Raycast shooting, 3 escalating waves, NPC AI, health/respawn, spawn protection, HUD |
| **Medium** | Rifle + Shotgun + SMG, kill feed, Tab scoreboard, reload/ammo UI, 3 NPC types, intermission shop |

## Script layout

```
studio/
  SETUP.md              — Studio hierarchy & paste map
  PLAYTEST.md           — Test checklist & balance tuning
  ReplicatedStorage/Modules/
  ServerScriptService/
  ServerStorage/NPCTemplates/
  StarterPlayer/StarterPlayerScripts/
  StarterGui/
  StarterPack/
```

## Controls

- **Left click** — Fire (hold for auto weapons)
- **R** — Reload
- **Tab** — Scoreboard
