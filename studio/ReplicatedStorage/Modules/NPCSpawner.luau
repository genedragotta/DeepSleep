-- PASTE INTO: ReplicatedStorage > Modules > NPCSpawner (ModuleScript)

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveSystem = require(ReplicatedStorage.Modules.WaveSystem)

local NPCSpawner = {}

local NPC_WALK_SPEED = {
	Grunt = 14,
	Runner = 22,
	Tank = 8,
}

local NPC_DAMAGE = {
	Grunt = 10,
	Runner = 8,
	Tank = 18,
}

local NPC_ATTACK_RANGE = {
	Grunt = 5,
	Runner = 4,
	Tank = 6,
}

function NPCSpawner.getSpawnFolder(): Folder
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "NPCs"
		folder.Parent = workspace
	end
	return folder
end

function NPCSpawner.getSpawnPoints(): { BasePart }
	local points = {}
	local spawnFolder = workspace:FindFirstChild("SpawnPoints")
	if spawnFolder then
		for _, child in spawnFolder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child)
			end
		end
	end
	if #points == 0 then
		local fallback = workspace:FindFirstChild("Arena")
		if fallback and fallback:IsA("BasePart") then
			table.insert(points, fallback)
		end
	end
	return points
end

function NPCSpawner.spawnWave(waveNumber: number): { Model }
	local templates = ServerStorage:FindFirstChild("NPCTemplates")
	if not templates then
		warn("[NPCSpawner] Missing ServerStorage.NPCTemplates")
		return {}
	end

	local composition = WaveSystem.getWaveComposition(waveNumber)
	local spawnPoints = NPCSpawner.getSpawnPoints()
	local parent = NPCSpawner.getSpawnFolder()
	local spawned: { Model } = {}

	for npcName, count in composition do
		local template = templates:FindFirstChild(npcName)
		if not template then
			warn("[NPCSpawner] Missing NPC template:", npcName)
			continue
		end

		for _ = 1, count do
			local npc = template:Clone()
			npc:SetAttribute("IsNPC", true)
			npc:SetAttribute("NPCType", npcName)
			npc:SetAttribute("WaveNumber", waveNumber)
			npc:SetAttribute("AttackDamage", NPC_DAMAGE[npcName] or 10)
			npc:SetAttribute("AttackRange", NPC_ATTACK_RANGE[npcName] or 5)

			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local health = WaveSystem.getNPCHealth(npcName, waveNumber)
				humanoid.MaxHealth = health
				humanoid.Health = health
				humanoid.WalkSpeed = NPC_WALK_SPEED[npcName] or 14
			end

			local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
			if root and #spawnPoints > 0 then
				local point = spawnPoints[math.random(1, #spawnPoints)]
				local offset = Vector3.new(math.random(-8, 8), 3, math.random(-8, 8))
				npc:PivotTo(CFrame.new(point.Position + offset))
			end

			npc.Parent = parent
			table.insert(spawned, npc)
		end
	end

	return spawned
end

function NPCSpawner.countAlive(): number
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then
		return 0
	end
	local count = 0
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("IsNPC") then
			local humanoid = child:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				count += 1
			end
		end
	end
	return count
end

function NPCSpawner.clearAll()
	local folder = workspace:FindFirstChild("NPCs")
	if not folder then
		return
	end
	folder:ClearAllChildren()
end

return NPCSpawner
