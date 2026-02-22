local rs = game:GetService("ReplicatedStorage")

local events = rs.Events
local functions = rs.Functions

local module = require(script.SC_Dungeons_Data)

functions.GetUnlockedDungeon.OnServerInvoke = function(plr, id)
	return module.getUnlockedDungeon(plr, id)
end

functions.GetCompletedDungeon.OnServerInvoke = function(plr, id)
	return module.getCompletedDungeon(plr, id)
end

events.StartDungeon.OnServerEvent:Connect(module.startDungeon)
game.Players.PlayerAdded:Connect(module.Init)
game.Players.PlayerRemoving:Connect(module.SaveData)

for _, plr in game.Players:GetPlayers() do
	module.Init(plr)
end
