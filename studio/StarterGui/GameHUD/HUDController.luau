-- PASTE INTO: StarterGui > GameHUD > HUDController (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent :: ScreenGui

local WaveLabel = gui:WaitForChild("WaveLabel") :: TextLabel
local EnemiesLabel = gui:WaitForChild("EnemiesLabel") :: TextLabel
local HealthBar = gui:WaitForChild("HealthBar") :: Frame
local HealthText = gui:WaitForChild("HealthText") :: TextLabel
local AmmoLabel = gui:WaitForChild("AmmoLabel") :: TextLabel
local HitMarker = gui:WaitForChild("HitMarker") :: TextLabel
local KillFeedFrame = gui:WaitForChild("KillFeed") :: Frame

local HealthFill = HealthBar:FindFirstChild("Fill") :: Frame?
if not HealthFill then
	HealthFill = Instance.new("Frame")
	HealthFill.Name = "Fill"
	HealthFill.Size = UDim2.fromScale(1, 1)
	HealthFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	HealthFill.BorderSizePixel = 0
	HealthFill.Parent = HealthBar
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WaveUpdate = Remotes:WaitForChild("WaveUpdate") :: RemoteEvent
local HitConfirm = Remotes:WaitForChild("HitConfirm") :: RemoteEvent
local KillFeed = Remotes:WaitForChild("KillFeed") :: RemoteEvent
local MatchStateUpdate = Remotes:WaitForChild("MatchStateUpdate") :: RemoteEvent

local GunConfigs = require(ReplicatedStorage.Modules.GunConfigs)

local MAX_KILL_FEED = 6
local killFeedEntries: { TextLabel } = {}

local function getEquippedTool(): Tool?
	local character = player.Character
	if not character then
		return nil
	end
	for weaponName in GunConfigs do
		local tool = character:FindFirstChild(weaponName)
		if tool and tool:IsA("Tool") then
			return tool
		end
	end
	return nil
end

local function updateHealth()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		HealthFill.Size = UDim2.fromScale(0, 1)
		HealthText.Text = "HP: --"
		return
	end

	local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	HealthFill.Size = UDim2.fromScale(ratio, 1)
	HealthText.Text = string.format("HP: %d / %d", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth))

	if ratio < 0.25 then
		HealthFill.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	else
		HealthFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	end
end

local function updateAmmo()
	local tool = getEquippedTool()
	if not tool then
		AmmoLabel.Text = ""
		return
	end

	local ammo = tool:GetAttribute("Ammo")
	local magSize = tool:GetAttribute("MagSize")
	local reloading = tool:GetAttribute("Reloading")

	if reloading then
		AmmoLabel.Text = "RELOADING..."
	elseif typeof(ammo) == "number" and typeof(magSize) == "number" then
		AmmoLabel.Text = string.format("%d / %d", ammo, magSize)
	else
		AmmoLabel.Text = ""
	end
end

local function showHitMarker(headshot: boolean)
	HitMarker.Visible = true
	HitMarker.Text = headshot and "X" or "+"
	HitMarker.TextColor3 = headshot and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
	task.delay(0.12, function()
		HitMarker.Visible = false
	end)
end

local function pushKillFeed(killer: string, victim: string)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Size = UDim2.new(1, 0, 0, 22)
	label.Text = string.format("%s  >  %s", killer, victim)
	label.Parent = KillFeedFrame

	table.insert(killFeedEntries, 1, label)

	while #killFeedEntries > MAX_KILL_FEED do
		local old = table.remove(killFeedEntries)
		if old then
			old:Destroy()
		end
	end

	task.delay(5, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

WaveUpdate.OnClientEvent:Connect(function(payload)
	if payload.wave then
		WaveLabel.Text = "Wave " .. tostring(payload.wave)
	end
	if payload.enemiesRemaining ~= nil then
		EnemiesLabel.Text = "Enemies: " .. tostring(payload.enemiesRemaining)
	end
	if payload.message then
		WaveLabel.Text = payload.message
		task.delay(2.5, function()
			if payload.wave then
				WaveLabel.Text = "Wave " .. tostring(payload.wave)
			end
		end)
	end
end)

HitConfirm.OnClientEvent:Connect(function(payload)
	showHitMarker(payload.headshot == true)
end)

KillFeed.OnClientEvent:Connect(function(payload)
	pushKillFeed(payload.killer or "?", payload.victim or "?")
end)

MatchStateUpdate.OnClientEvent:Connect(function(payload)
	if payload.matchState == "GameOver" then
		WaveLabel.Text = "Game Over"
	end
end)

RunService.RenderStepped:Connect(function()
	updateHealth()
	updateAmmo()
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(updateHealth)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
	updateHealth()
end)

if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.HealthChanged:Connect(updateHealth)
	end
end
