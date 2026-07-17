-- PASTE INTO: StarterPlayer > StarterPlayerScripts > GunController (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local GunConfigs = require(ReplicatedStorage.Modules.GunConfigs)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireWeapon = Remotes:WaitForChild("FireWeapon") :: RemoteEvent
local ReloadWeapon = Remotes:WaitForChild("ReloadWeapon") :: RemoteEvent

local currentTool: Tool? = nil
local currentWeaponName: string? = nil
local firing = false
local connections: { RBXScriptConnection } = {}

local function disconnectAll()
	for _, conn in connections do
		conn:Disconnect()
	end
	table.clear(connections)
end

local function getWeaponNameFromTool(tool: Tool): string?
	local attr = tool:GetAttribute("WeaponName")
	if typeof(attr) == "string" and GunConfigs[attr] then
		return attr
	end
	if GunConfigs[tool.Name] then
		return tool.Name
	end
	return nil
end

local function getCameraRay(): (Vector3, Vector3)
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero, Vector3.new(0, 0, -1)
	end
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	return origin, direction
end

local function canFire(): boolean
	if not currentTool or not currentWeaponName then
		return false
	end
	local config = GunConfigs[currentWeaponName]
	if not config then
		return false
	end
	if currentTool:GetAttribute("Reloading") then
		return false
	end
	local ammo = currentTool:GetAttribute("Ammo")
	if typeof(ammo) == "number" and ammo <= 0 then
		return false
	end
	return true
end

local function fireOnce()
	if not canFire() then
		return
	end

	local origin, direction = getCameraRay()
	FireWeapon:FireServer({
		origin = origin,
		direction = direction,
		weaponName = currentWeaponName,
		timestamp = tick(),
	})
end

local function startFiring()
	if firing then
		return
	end
	firing = true

	task.spawn(function()
		while firing and currentTool do
			fireOnce()
			local config = GunConfigs[currentWeaponName :: string]
			if config then
				task.wait(config.fireRate)
			else
				task.wait(0.1)
			end
		end
	end)
end

local function stopFiring()
	firing = false
end

local function reload()
	if not currentWeaponName then
		return
	end
	ReloadWeapon:FireServer(currentWeaponName)
end

local function bindTool(tool: Tool)
	disconnectAll()
	currentTool = tool
	currentWeaponName = getWeaponNameFromTool(tool)

	table.insert(connections, tool.Activated:Connect(function()
		startFiring()
	end))

	table.insert(connections, tool.Deactivated:Connect(function()
		stopFiring()
	end))

	table.insert(connections, tool.Unequipped:Connect(function()
		stopFiring()
		if currentTool == tool then
			currentTool = nil
			currentWeaponName = nil
		end
	end))
end

local function onCharacterAdded(character: Model)
	disconnectAll()
	currentTool = nil
	currentWeaponName = nil

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			bindTool(child)
		end
	end)

	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			bindTool(child)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		reload()
	end
end)

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Backpack tools equipped later
player.Backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and player.Character and child.Parent == player.Character then
		bindTool(child)
	end
end)
