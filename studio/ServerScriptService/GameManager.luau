-- PASTE INTO: ServerScriptService > GameManager (Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfigs = require(ReplicatedStorage.Modules.GunConfigs)
local DamageService = require(ReplicatedStorage.Modules.DamageService)
local WaveSystem = require(ReplicatedStorage.Modules.WaveSystem)
local NPCSpawner = require(ReplicatedStorage.Modules.NPCSpawner)
local SharedUtils = require(ReplicatedStorage.Modules.SharedUtils)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireWeapon = Remotes:WaitForChild("FireWeapon") :: RemoteEvent
local ReloadWeapon = Remotes:WaitForChild("ReloadWeapon") :: RemoteEvent
local WaveUpdate = Remotes:WaitForChild("WaveUpdate") :: RemoteEvent
local HitConfirm = Remotes:WaitForChild("HitConfirm") :: RemoteEvent
local KillFeed = Remotes:WaitForChild("KillFeed") :: RemoteEvent
local ShopPurchase = Remotes:WaitForChild("ShopPurchase") :: RemoteEvent
local MatchStateUpdate = Remotes:WaitForChild("MatchStateUpdate") :: RemoteEvent

local MatchState = {
	Waiting = "Waiting",
	Wave = "Wave",
	Intermission = "Intermission",
	GameOver = "GameOver",
}

local RESPAWN_DELAY = 3
local SPAWN_PROTECTION = 2
local CURRENCY_PER_KILL = 15
local CURRENCY_PER_WAVE = 50

local SHOP_ITEMS = {
	AmmoRefill = { cost = 50 },
	HealthBoost = { cost = 75, healthBonus = 25 },
}

local currentWave = 0
local matchState = MatchState.Waiting
local intermissionEndTime = 0

-- [Player] = { [weaponName] = { ammo, reloading, reloadEnd } }
local playerWeaponState: { [Player]: { [string]: { ammo: number, reloading: boolean, reloadEnd: number } } } = {}
local lastFireTime: { [Player]: number } = {}

local function broadcastWaveUpdate(extra: { [string]: any }?)
	local payload = {
		wave = currentWave,
		enemiesRemaining = NPCSpawner.countAlive(),
		matchState = matchState,
		intermissionEndTime = intermissionEndTime,
	}
	if extra then
		for k, v in extra do
			payload[k] = v
		end
	end
	WaveUpdate:FireAllClients(payload)
end

local function broadcastMatchState()
	MatchStateUpdate:FireAllClients({
		matchState = matchState,
		wave = currentWave,
		intermissionEndTime = intermissionEndTime,
	})
end

local function ensureLeaderstats(player: Player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end

	local function ensureInt(name: string, default: number): IntValue
		local val = stats:FindFirstChild(name)
		if not val then
			val = Instance.new("IntValue")
			val.Name = name
			val.Value = default
			val.Parent = stats
		end
		return val :: IntValue
	end

	ensureInt("Kills", 0)
	ensureInt("Deaths", 0)
	ensureInt("WaveReached", 0)
	ensureInt("Currency", 0)
end

local function getWeaponState(player: Player, weaponName: string)
	if not playerWeaponState[player] then
		playerWeaponState[player] = {}
	end
	if not playerWeaponState[player][weaponName] then
		local config = GunConfigs[weaponName]
		playerWeaponState[player][weaponName] = {
			ammo = config and config.magSize or 30,
			reloading = false,
			reloadEnd = 0,
		}
	end
	return playerWeaponState[player][weaponName]
end

local function syncToolAttributes(player: Player, weaponName: string)
	local config = GunConfigs[weaponName]
	if not config then
		return
	end
	local state = getWeaponState(player, weaponName)
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChild(weaponName)
	if not tool or not tool:IsA("Tool") then
		tool = player.Backpack:FindFirstChild(weaponName)
	end
	if tool and tool:IsA("Tool") then
		tool:SetAttribute("Ammo", state.ammo)
		tool:SetAttribute("MagSize", config.magSize)
		tool:SetAttribute("Reloading", state.reloading)
		tool:SetAttribute("WeaponName", weaponName)
	end
end

local function syncAllTools(player: Player)
	for weaponName in GunConfigs do
		syncToolAttributes(player, weaponName)
	end
end

local function getEquippedWeapon(player: Player): string?
	local character = player.Character
	if not character then
		return nil
	end
	for weaponName in GunConfigs do
		if character:FindFirstChild(weaponName) then
			return weaponName
		end
	end
	return nil
end

local function addCurrency(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local currency = stats:FindFirstChild("Currency")
		if currency then
			currency.Value += amount
		end
	end
end

local function addKill(player: Player)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local kills = stats:FindFirstChild("Kills")
		if kills then
			kills.Value += 1
		end
	end
	addCurrency(player, CURRENCY_PER_KILL)
end

local function updateWaveReached()
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local waveStat = stats:FindFirstChild("WaveReached")
			if waveStat and waveStat.Value < currentWave then
				waveStat.Value = currentWave
			end
		end
	end
end

local function anyPlayerAlive(): boolean
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local function getRandomSpawnCFrame(): CFrame?
	local spawnFolder = workspace:FindFirstChild("SpawnPoints")
	if spawnFolder then
		local points = {}
		for _, child in spawnFolder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child)
			end
		end
		if #points > 0 then
			local part = points[math.random(1, #points)]
			return part.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 5, 0)
end

local function giveSpawnProtection(character: Model)
	local forceField = Instance.new("ForceField")
	forceField.Name = "SpawnProtection"
	forceField.Parent = character
	task.delay(SPAWN_PROTECTION, function()
		if forceField.Parent then
			forceField:Destroy()
		end
	end)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then
		return
	end

	humanoid.MaxHealth = 100
	humanoid.Health = humanoid.MaxHealth
	giveSpawnProtection(character)

	local spawnCFrame = getRandomSpawnCFrame()
	if spawnCFrame then
		character:PivotTo(spawnCFrame)
	end

	task.defer(function()
		syncAllTools(player)
	end)

	humanoid.Died:Connect(function()
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local deaths = stats:FindFirstChild("Deaths")
			if deaths then
				deaths.Value += 1
			end
		end

		task.delay(RESPAWN_DELAY, function()
			if matchState == MatchState.GameOver then
				return
			end
			if not anyPlayerAlive() and matchState == MatchState.Wave then
				matchState = MatchState.GameOver
				broadcastMatchState()
				broadcastWaveUpdate({ message = "Game Over!" })
				return
			end
			player:LoadCharacter()
		end)
	end)
end

local function onNPCKilled(npc: Model, killer: Player?)
	local npcType = npc:GetAttribute("NPCType") or "Enemy"
	if killer then
		addKill(killer)
		KillFeed:FireAllClients({
			killer = killer.Name,
			victim = npcType,
			weapon = "",
			isNPC = true,
		})
	end
end

local function hookNPCDeaths()
	local folder = NPCSpawner.getSpawnFolder()
	folder.ChildAdded:Connect(function(child)
		if not child:IsA("Model") then
			return
		end
		local humanoid = child:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		humanoid.Died:Connect(function()
			local killer = DamageService.getKillCredit(humanoid)
			onNPCKilled(child, killer)
			DamageService.clearHumanoid(humanoid)
			task.defer(function()
				broadcastWaveUpdate()
				if matchState == MatchState.Wave and NPCSpawner.countAlive() == 0 then
					startIntermission()
				end
			end)
		end)
	end)
end

function startIntermission()
	if matchState ~= MatchState.Wave then
		return
	end
	matchState = MatchState.Intermission
	intermissionEndTime = tick() + WaveSystem.getIntermissionDuration()
	updateWaveReached()

	for _, player in Players:GetPlayers() do
		addCurrency(player, CURRENCY_PER_WAVE)
	end

	broadcastMatchState()
	broadcastWaveUpdate({ message = "Shop open — next wave soon!" })

	task.delay(WaveSystem.getIntermissionDuration(), function()
		if matchState == MatchState.Intermission then
			startNextWave()
		end
	end)
end

function startNextWave()
	if not anyPlayerAlive() then
		matchState = MatchState.GameOver
		broadcastMatchState()
		return
	end

	currentWave += 1
	matchState = MatchState.Wave
	NPCSpawner.spawnWave(currentWave)
	broadcastMatchState()
	broadcastWaveUpdate({ message = "Wave " .. tostring(currentWave) .. "!" })
end

local function startGame()
	if matchState ~= MatchState.Waiting and matchState ~= MatchState.GameOver then
		return
	end
	currentWave = 0
	NPCSpawner.clearAll()
	matchState = MatchState.Wave
	startNextWave()
end

local function validateFirePayload(player: Player, payload: any): (boolean, string?)
	if typeof(payload) ~= "table" then
		return false, "bad payload"
	end
	if typeof(payload.origin) ~= "Vector3" or typeof(payload.direction) ~= "Vector3" then
		return false, "bad vectors"
	end
	if typeof(payload.weaponName) ~= "string" then
		return false, "bad weapon"
	end
	if not GunConfigs[payload.weaponName] then
		return false, "unknown weapon"
	end
	local equipped = getEquippedWeapon(player)
	if equipped ~= payload.weaponName then
		return false, "weapon not equipped"
	end
	return true, nil
end

local function processFire(player: Player, payload: any)
	local ok, err = validateFirePayload(player, payload)
	if not ok then
		return
	end

	local weaponName = payload.weaponName
	local config = GunConfigs[weaponName]
	local state = getWeaponState(player, weaponName)

	if state.reloading then
		if tick() >= state.reloadEnd then
			state.reloading = false
			state.ammo = config.magSize
		else
			return
		end
	end

	if state.ammo <= 0 then
		return
	end

	local now = tick()
	local minInterval = config.fireRate
	if lastFireTime[player] and now - lastFireTime[player] < minInterval * 0.85 then
		return
	end
	lastFireTime[player] = now

	local character = player.Character
	if not character then
		return
	end

	local ignoreList = { character }

	local hitSomething = false
	local pellets = config.pellets or 1

	for _ = 1, pellets do
		local direction = SharedUtils.applySpread(payload.direction, config.spread)
		local result = SharedUtils.raycast(payload.origin, direction, config.range, ignoreList)

		if result then
			local humanoid = SharedUtils.getHumanoidFromHit(result.Instance)
			if humanoid and humanoid.Health > 0 then
				local damage = DamageService.dealGunDamage(
					player,
					humanoid,
					config.damage,
					result.Instance,
					config.headshotMultiplier
				)
				if damage > 0 then
					hitSomething = true
					HitConfirm:FireClient(player, {
						headshot = SharedUtils.isHeadPart(result.Instance),
						damage = damage,
					})
				end
			end
		end
	end

	state.ammo -= 1
	syncToolAttributes(player, weaponName)
end

local function processReload(player: Player, weaponName: string)
	if not GunConfigs[weaponName] then
		return
	end
	local equipped = getEquippedWeapon(player)
	if equipped ~= weaponName then
		return
	end

	local config = GunConfigs[weaponName]
	local state = getWeaponState(player, weaponName)

	if state.reloading or state.ammo >= config.magSize then
		return
	end

	state.reloading = true
	state.reloadEnd = tick() + config.reloadTime
	syncToolAttributes(player, weaponName)

	task.delay(config.reloadTime, function()
		if not player.Parent then
			return
		end
		local s = getWeaponState(player, weaponName)
		s.reloading = false
		s.ammo = config.magSize
		syncToolAttributes(player, weaponName)
	end)
end

local function processShopPurchase(player: Player, itemName: string)
	if matchState ~= MatchState.Intermission then
		return
	end

	local item = SHOP_ITEMS[itemName]
	if not item then
		return
	end

	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end

	local currency = stats:FindFirstChild("Currency") :: IntValue?
	if not currency or currency.Value < item.cost then
		return
	end

	currency.Value -= item.cost

	if itemName == "AmmoRefill" then
		for weaponName in GunConfigs do
			local config = GunConfigs[weaponName]
			local state = getWeaponState(player, weaponName)
			state.ammo = config.magSize
			state.reloading = false
			syncToolAttributes(player, weaponName)
		end
	elseif itemName == "HealthBoost" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth += item.healthBonus
			humanoid.Health += item.healthBonus
		end
	end
end

FireWeapon.OnServerEvent:Connect(processFire)
ReloadWeapon.OnServerEvent:Connect(processReload)
ShopPurchase.OnServerEvent:Connect(processShopPurchase)

Players.PlayerAdded:Connect(function(player)
	ensureLeaderstats(player)
	playerWeaponState[player] = {}

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	task.defer(function()
		if matchState == MatchState.Waiting and #Players:GetPlayers() >= 1 then
			startGame()
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerWeaponState[player] = nil
	lastFireTime[player] = nil
end)

hookNPCDeaths()

-- Wave tick — catch edge cases where NPC dies without hook
task.spawn(function()
	while true do
		task.wait(1)
		if matchState == MatchState.Wave then
			broadcastWaveUpdate()
			if NPCSpawner.countAlive() == 0 and currentWave > 0 then
				startIntermission()
			end
			if not anyPlayerAlive() then
				matchState = MatchState.GameOver
				broadcastMatchState()
			end
		elseif matchState == MatchState.Intermission then
			broadcastWaveUpdate()
		end
	end
end)

-- Auto-start for solo testing in Studio
task.defer(function()
	task.wait(2)
	if matchState == MatchState.Waiting then
		startGame()
	end
end)
