-- PASTE INTO: ServerStorage > NPCTemplates > [each NPC] > NPCBrain (Script)

local RunService = game:GetService("RunService")

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid") :: Humanoid
local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart

if not root then
	warn("[NPCBrain] No HumanoidRootPart on", npc.Name)
	return
end

local ATTACK_COOLDOWN = 1.2
local RETARGET_INTERVAL = 0.5
local lastAttack = 0
local lastRetarget = 0
local currentTarget: Model? = nil

local attackDamage = npc:GetAttribute("AttackDamage") or 10
local attackRange = npc:GetAttribute("AttackRange") or 5

local function findNearestPlayer(): Model?
	local nearest: Model? = nil
	local nearestDist = math.huge
	local rootPos = root.Position

	for _, player in game:GetService("Players"):GetPlayers() do
		local character = player.Character
		local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
			local dist = (targetRoot.Position - rootPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = character
			end
		end
	end

	return nearest
end

local function tryAttack(target: Model)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetHumanoid or not targetRoot then
		return
	end

	local dist = (targetRoot.Position - root.Position).Magnitude
	if dist > attackRange then
		return
	end

	local now = tick()
	if now - lastAttack < ATTACK_COOLDOWN then
		return
	end
	lastAttack = now

	-- Skip damage if target has spawn protection
	if target:FindFirstChild("SpawnProtection") then
		return
	end

	targetHumanoid:TakeDamage(attackDamage)
end

humanoid.Died:Connect(function()
	script:Destroy()
end)

RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 then
		return
	end

	local now = tick()
	if now - lastRetarget >= RETARGET_INTERVAL then
		lastRetarget = now
		currentTarget = findNearestPlayer()
	end

	if currentTarget then
		local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			humanoid:MoveTo(targetRoot.Position)
			tryAttack(currentTarget)
		else
			currentTarget = nil
		end
	end
end)
