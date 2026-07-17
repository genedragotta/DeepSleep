# DeepSleep Wave-Survival FPS — Studio Setup

Copy each `.luau` file into Roblox Studio at the path shown in its header comment.
Create empty instances (Folder, RemoteEvent, ScreenGui, Tool, etc.) where noted below.

## 1. Workspace

```
Workspace
  Arena          (Part floor + cover — build your map here)
  SpawnPoints    (Folder)
    Spawn1       (SpawnLocation, Neutral = true)
    Spawn2       (SpawnLocation)
    Spawn3       (SpawnLocation)
    Spawn4       (SpawnLocation)
```

## 2. ReplicatedStorage

```
ReplicatedStorage
  Remotes (Folder)
    FireWeapon      (RemoteEvent)
    ReloadWeapon    (RemoteEvent)
    WaveUpdate      (RemoteEvent)
    HitConfirm      (RemoteEvent)
    KillFeed        (RemoteEvent)
    ShopPurchase    (RemoteEvent)
    MatchStateUpdate (RemoteEvent)
  Modules (Folder)
    GunConfigs        ← studio/ReplicatedStorage/Modules/GunConfigs.luau
    DamageService     ← DamageService.luau
    WaveSystem        ← WaveSystem.luau
    NPCSpawner        ← NPCSpawner.luau
    SharedUtils       ← SharedUtils.luau
```

## 3. ServerScriptService

```
ServerScriptService
  GameManager  ← studio/ServerScriptService/GameManager.luau  (paste as Script)
```

## 4. ServerStorage

```
ServerStorage
  NPCTemplates (Folder)
    Grunt  (Model)
      HumanoidRootPart  (Part, Anchored=false)
      Head              (Part, optional — headshot target)
      Torso             (Part)
      Humanoid
      NPCBrain          ← studio/ServerStorage/NPCTemplates/NPCBrain.luau (Script)
    Runner (Model — duplicate Grunt, set Humanoid.WalkSpeed = 22 in Studio)
    Tank   (Model — duplicate Grunt, Humanoid.WalkSpeed = 8, larger parts)
```

**Quick NPC dummy:** Insert a Part, rename to `HumanoidRootPart`, add Humanoid, weld a Head part on top, paste NPCBrain.

## 5. StarterPlayer

```
StarterPlayer
  StarterPlayerScripts
    GunController     ← GunController.luau (LocalScript)
    CameraController  ← CameraController.luau (LocalScript)
```

## 6. StarterGui

Create these ScreenGuis (ResetOnSpawn = false):

### GameHUD
```
GameHUD (ScreenGui)
  WaveLabel       (TextLabel, top center)
  EnemiesLabel    (TextLabel, below wave)
  HealthBar       (Frame background + Frame fill, bottom left)
  HealthText      (TextLabel)
  AmmoLabel       (TextLabel, bottom right)
  Crosshair       (TextLabel "+" center, or ImageLabel)
  HitMarker       (TextLabel, center, Visible=false)
  KillFeed        (Frame, top right, UIListLayout)
  HUDController   ← HUDController.luau (LocalScript)
```

### ScoreboardGui
```
ScoreboardGui (ScreenGui, Enabled=false)
  Panel (Frame, centered)
    PlayerList (ScrollingFrame + UIListLayout)
  ScoreboardController ← ScoreboardController.luau (LocalScript)
```

### ShopGui
```
ShopGui (ScreenGui, Enabled=false)
  Panel (Frame, center)
    TimerLabel (TextLabel)
    AmmoButton   (TextButton) — Text: "Ammo Refill (50)"
    HealthButton (TextButton) — Text: "+25 HP (75)"
  ShopController ← ShopController.luau (LocalScript)
```

## 7. StarterPack — Weapons

For each weapon, create a **Tool**:

```
StarterPack
  Rifle   (Tool)
    Handle (Part, size 0.4×0.4×2)
    WeaponScript ← WeaponToolScript.luau (LocalScript) — set WeaponName value or rename Tool
  Shotgun (Tool) — same script, rename Tool to "Shotgun"
  SMG     (Tool) — same script, rename Tool to "SMG"
```

Each Tool needs:
- `Grip` adjusted so it looks reasonable in hand
- Tool name must match a key in `GunConfigs` (Rifle, Shotgun, SMG)

## 8. Playtest

1. Press **Play** (F5) in Studio.
2. Waves auto-start when you spawn.
3. Equip a gun from Backpack, left-click to shoot, **R** to reload.
4. **Tab** toggles scoreboard during intermission or gameplay.
5. Shop opens automatically between waves.

## Tuning

Edit `GunConfigs.luau` for weapon feel, `WaveSystem.luau` for enemy counts.
