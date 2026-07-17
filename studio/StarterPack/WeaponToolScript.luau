-- PASTE INTO: StarterPack > [Rifle/Shotgun/SMG] > WeaponScript (LocalScript)
-- Tool name must match GunConfigs key (Rifle, Shotgun, or SMG)

local tool = script.Parent :: Tool

tool:SetAttribute("WeaponName", tool.Name)

-- GunController in StarterPlayerScripts handles input; this script tags the weapon.
-- Optional: hide the handle mesh in first person
local handle = tool:FindFirstChild("Handle")
if handle and handle:IsA("BasePart") then
	handle.LocalTransparencyModifier = 0
end
