-- PASTE INTO: ReplicatedStorage > Modules > GunConfigs (ModuleScript)

local GunConfigs = {
	Rifle = {
		slot = "Primary",
		damage = 25,
		fireRate = 0.12,
		range = 500,
		spread = 0.02,
		magSize = 30,
		reloadTime = 2.0,
		headshotMultiplier = 2,
		pellets = 1,
	},
	Shotgun = {
		slot = "Primary",
		damage = 12,
		fireRate = 0.9,
		range = 80,
		spread = 0.12,
		magSize = 6,
		reloadTime = 2.5,
		headshotMultiplier = 1.5,
		pellets = 8,
	},
	SMG = {
		slot = "Primary",
		damage = 14,
		fireRate = 0.07,
		range = 350,
		spread = 0.05,
		magSize = 40,
		reloadTime = 1.8,
		headshotMultiplier = 1.8,
		pellets = 1,
	},
}

return GunConfigs
