-- PASTE INTO: StarterGui > ScoreboardGui > ScoreboardController (LocalScript)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = script.Parent :: ScreenGui
local panel = gui:WaitForChild("Panel") :: Frame
local playerList = panel:WaitForChild("PlayerList") :: ScrollingFrame

local function getStat(plr: Player, name: string): number
	local stats = plr:FindFirstChild("leaderstats")
	if not stats then
		return 0
	end
	local val = stats:FindFirstChild(name)
	if val and val:IsA("IntValue") then
		return val.Value
	end
	return 0
end

local function clearList()
	for _, child in playerList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function rebuildScoreboard()
	clearList()

	local rows = {}
	for _, plr in Players:GetPlayers() do
		table.insert(rows, plr)
	end

	table.sort(rows, function(a, b)
		local killsA = getStat(a, "Kills")
		local killsB = getStat(b, "Kills")
		if killsA ~= killsB then
			return killsA > killsB
		end
		return getStat(a, "WaveReached") > getStat(b, "WaveReached")
	end)

	for i, plr in rows do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -8, 0, 28)
		label.Position = UDim2.new(0, 4, 0, (i - 1) * 30)
		label.BackgroundTransparency = 0.5
		label.BackgroundColor3 = plr == player and Color3.fromRGB(40, 60, 90) or Color3.fromRGB(30, 30, 30)
		label.TextColor3 = Color3.fromRGB(230, 230, 230)
		label.Font = Enum.Font.Code
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = string.format(
			"  %-14s  K:%3d  D:%3d  W:%2d  $:%4d",
			plr.Name,
			getStat(plr, "Kills"),
			getStat(plr, "Deaths"),
			getStat(plr, "WaveReached"),
			getStat(plr, "Currency")
		)
		label.Parent = playerList
	end

	playerList.CanvasSize = UDim2.new(0, 0, 0, #rows * 30 + 8)
end

local function setVisible(visible: boolean)
	gui.Enabled = visible
	if visible then
		rebuildScoreboard()
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Tab then
		setVisible(not gui.Enabled)
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		if gui.Enabled then
			rebuildScoreboard()
		end
	end)
	local stats = plr:WaitForChild("leaderstats", 10)
	if stats then
		for _, stat in stats:GetChildren() do
			if stat:IsA("IntValue") then
				stat.Changed:Connect(function()
					if gui.Enabled then
						rebuildScoreboard()
					end
				end)
			end
		end
	end
end)

for _, plr in Players:GetPlayers() do
	task.spawn(function()
		local stats = plr:WaitForChild("leaderstats", 10)
		if stats then
			for _, stat in stats:GetChildren() do
				if stat:IsA("IntValue") then
					stat.Changed:Connect(function()
						if gui.Enabled then
							rebuildScoreboard()
						end
					end)
				end
			end
		end
	end)
end

-- Default layout hints if Panel missing children
if not panel:FindFirstChild("PlayerList") then
	local sf = Instance.new("ScrollingFrame")
	sf.Name = "PlayerList"
	sf.Size = UDim2.fromScale(0.95, 0.85)
	sf.Position = UDim2.fromScale(0.025, 0.1)
	sf.BackgroundTransparency = 1
	sf.ScrollBarThickness = 6
	sf.Parent = panel
end
