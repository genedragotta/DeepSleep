-- PASTE INTO: ReplicatedStorage > Modules > WaveSystem (ModuleScript)

local WaveSystem = {}

local PRESET_WAVES = {
	{ Grunt = 5 },
	{ Grunt = 8, Runner = 3 },
	{ Grunt = 10, Tank = 2 },
	{ Grunt = 12, Runner = 6, Tank = 2 },
	{ Grunt = 8, Runner = 8, Tank = 4 },
}

local NPC_BASE_HEALTH = {
	Grunt = 80,
	Runner = 50,
	Tank = 200,
}

local INTERMISSION_DURATION = 15

function WaveSystem.getIntermissionDuration(): number
	return INTERMISSION_DURATION
end

function WaveSystem.getWaveComposition(waveNumber: number): { [string]: number }
	local preset = PRESET_WAVES[waveNumber]
	if preset then
		return preset
	end

	-- Infinite scaling after preset table
	local extra = waveNumber - #PRESET_WAVES
	local grunt = 10 + extra * 3
	local runner = math.floor(4 + extra * 1.5)
	local tank = math.floor(2 + extra * 0.8)
	return {
		Grunt = grunt,
		Runner = runner,
		Tank = tank,
	}
end

function WaveSystem.getNPCHealth(npcName: string, waveNumber: number): number
	local base = NPC_BASE_HEALTH[npcName] or 80
	local scale = 1 + (waveNumber - 1) * 0.12
	return math.floor(base * scale)
end

function WaveSystem.getTotalEnemyCount(composition: { [string]: number }): number
	local total = 0
	for _, count in composition do
		total += count
	end
	return total
end

return WaveSystem
