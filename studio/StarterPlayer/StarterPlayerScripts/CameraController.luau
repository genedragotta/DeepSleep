-- PASTE INTO: StarterPlayer > StarterPlayerScripts > CameraController (LocalScript)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local GunConfigs = require(ReplicatedStorage.Modules.GunConfigs)

local MOUSE_SENSITIVITY = 0.4

local function isGunEquipped(character: Model?): boolean
	if not character then
		return false
	end
	for weaponName in GunConfigs do
		if character:FindFirstChild(weaponName) then
			return true
		end
	end
	return false
end

local function updateCamera()
	local character = player.Character
	if not character then
		return
	end

	if isGunEquipped(character) then
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMaxZoomDistance = 0.5
		player.CameraMinZoomDistance = 0.5
	else
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = 128
		player.CameraMinZoomDistance = 0.5
	end
end

RunService.RenderStepped:Connect(function()
	updateCamera()
end)

player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(updateCamera)
	character.ChildRemoved:Connect(updateCamera)
	updateCamera()
end)

if player.Character then
	updateCamera()
end

-- Optional: expose sensitivity via attribute for future settings UI
player:SetAttribute("MouseSensitivity", MOUSE_SENSITIVITY)
