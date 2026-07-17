-- PASTE INTO: ReplicatedStorage > Modules > DamageService (ModuleScript)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedUtils = require(ReplicatedStorage.Modules.SharedUtils)

local DamageService = {}

-- [humanoid] = { player = Player, time = number }
local lastDamagerByHumanoid: { [Humanoid]: { player: Player, time: number } } = {}

function DamageService.getKillCredit(humanoid: Humanoid): Player?
	local record = lastDamagerByHumanoid[humanoid]
	if not record or not record.player then
		return nil
	end
	if tick() - record.time > 10 then
		return nil
	end
	return record.player
end

function DamageService.clearHumanoid(humanoid: Humanoid)
	lastDamagerByHumanoid[humanoid] = nil
end

function DamageService.dealGunDamage(
	attacker: Player,
	humanoid: Humanoid,
	baseDamage: number,
	hitPart: BasePart?,
	headshotMultiplier: number
): number
	if humanoid.Health <= 0 then
		return 0
	end

	local damage = baseDamage
	if SharedUtils.isHeadPart(hitPart) then
		damage *= headshotMultiplier
	end

	local character = attacker.Character
	if character and humanoid.Parent == character then
		return 0
	end

	lastDamagerByHumanoid[humanoid] = {
		player = attacker,
		time = tick(),
	}

	humanoid:TakeDamage(damage)
	return damage
end

return DamageService
