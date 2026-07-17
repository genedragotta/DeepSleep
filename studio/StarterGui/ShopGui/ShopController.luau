-- PASTE INTO: StarterGui > ShopGui > ShopController (LocalScript)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = script.Parent :: ScreenGui
local panel = gui:WaitForChild("Panel") :: Frame
local timerLabel = panel:WaitForChild("TimerLabel") :: TextLabel
local ammoButton = panel:WaitForChild("AmmoButton") :: TextButton
local healthButton = panel:WaitForChild("HealthButton") :: TextButton

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopPurchase = Remotes:WaitForChild("ShopPurchase") :: RemoteEvent
local MatchStateUpdate = Remotes:WaitForChild("MatchStateUpdate") :: RemoteEvent
local WaveUpdate = Remotes:WaitForChild("WaveUpdate") :: RemoteEvent

local intermissionEndTime = 0

local function getCurrency(): number
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return 0
	end
	local currency = stats:FindFirstChild("Currency")
	if currency and currency:IsA("IntValue") then
		return currency.Value
	end
	return 0
end

local function updateTimer()
	if intermissionEndTime <= 0 then
		timerLabel.Text = ""
		return
	end
	local remaining = math.max(0, math.ceil(intermissionEndTime - tick()))
	timerLabel.Text = "Next wave in: " .. tostring(remaining) .. "s  |  Cash: $" .. tostring(getCurrency())
end

local function setShopOpen(open: boolean, endTime: number?)
	gui.Enabled = open
	if open then
		intermissionEndTime = endTime or tick() + 15
		updateTimer()
	else
		intermissionEndTime = 0
	end
end

ammoButton.MouseButton1Click:Connect(function()
	ShopPurchase:FireServer("AmmoRefill")
	task.wait(0.1)
	updateTimer()
end)

healthButton.MouseButton1Click:Connect(function()
	ShopPurchase:FireServer("HealthBoost")
	task.wait(0.1)
	updateTimer()
end)

MatchStateUpdate.OnClientEvent:Connect(function(payload)
	if payload.matchState == "Intermission" then
		setShopOpen(true, payload.intermissionEndTime)
	elseif payload.matchState == "Wave" or payload.matchState == "GameOver" then
		setShopOpen(false)
	end
end)

WaveUpdate.OnClientEvent:Connect(function(payload)
	if payload.intermissionEndTime then
		intermissionEndTime = payload.intermissionEndTime
	end
	if payload.matchState == "Intermission" then
		setShopOpen(true, payload.intermissionEndTime)
	end
	updateTimer()
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		if gui.Enabled then
			updateTimer()
		end
	end
end)

-- Default panel styling if created empty
panel.Size = panel.Size == UDim2.new() and UDim2.fromOffset(320, 200) or panel.Size
panel.Position = panel.Position == UDim2.new() and UDim2.fromScale(0.5, 0.5) or panel.Position
panel.AnchorPoint = Vector2.new(0.5, 0.5)
