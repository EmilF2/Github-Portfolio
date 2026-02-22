local rs = game:GetService("ReplicatedStorage")
local dss = game:GetService("DataStoreService")
local ss = game:GetService("ServerStorage")
local runService = game:GetService("RunService")
local ds = dss:GetDataStore("Dungeons_"..ss.data.Value)

local modules = rs.Modules
local events = rs.Events

local dungeons = require(modules.Dungeons)
local multipliers = require(modules.Multipliers)
local potions = require(modules.Potions)

local RANGE = 3

local module = {}

local completedDungeons = {}
local unlockedDungeons = {}

function module.ChooseReward(amount, rewardTable)
	local pickTable = {}

	for i = 1, amount do

		local totalWeight = 0
		local rewardWeights = {}

		for rewardName, v in pairs(rewardTable) do

			if v.chance then
				local weight = v.chance

				rewardWeights[rewardName] = weight
				totalWeight = totalWeight + weight
			end
		end

		local randomChoice = math.random() * totalWeight
		local runningSum = 0

		for rewardName, weight in pairs(rewardWeights) do
			runningSum = runningSum + weight
			if runningSum >= randomChoice then
				table.insert(pickTable, rewardName)
				break
			end
		end
	end

	return pickTable
end

local function rewardPlayer(plr, id)
	if not table.find(completedDungeons[plr.UserId], id) then
		table.insert(completedDungeons[plr.UserId], id)
		events.DungeonCompleted:FireClient(plr, id)
	end
	
	if not table.find(unlockedDungeons[plr.UserId], id+1) then
		table.insert(unlockedDungeons[plr.UserId], id+1)
		events.DungeonUnlocked:FireClient(plr, id+1)
	end
	
	local reward = module.ChooseReward(dungeons.dungeons[id].dropAmount, dungeons.dungeons[id].drops)
	
	for _, v in reward do
		if dungeons.dungeons[id].drops[v].stat.name == "Coins" then
			plr.leaderstats.Coins.Value += dungeons.dungeons[id].drops[v].amount * multipliers.GetCoinMulti(plr)
		elseif dungeons.dungeons[id].drops[v].stat.stat == "Potions" then
			local potion = plr[dungeons.dungeons[id].drops[v].stat.stat]:FindFirstChild(dungeons.dungeons[id].drops[v].stat.name)
			
			if potion then
				potion.Value += dungeons.dungeons[id].drops[v].amount
			else
				potion = Instance.new("NumberValue", plr.Potions)
				potion.Name = dungeons.dungeons[id].drops[v].stat.name
				potion.Value += 1
			end
			
			events.InitializePotions:FireClient(plr, {[potion.Name] = {[1] = potion.Value, [2] = potions.Potions[potion.Name].rarity}})
		end
	end
	
	events.DungeonReward:FireClient(plr, reward, id)
end

function module.SaveData(plr)
	local saveTable = {unlockedDungeons[plr.UserId], completedDungeons[plr.UserId]}

	local success, err = pcall(function()
		ds:SetAsync(plr.UserId, saveTable)
	end)

	if not success then
		warn(err)
	end

	table.remove(unlockedDungeons, plr.UserId)
	table.remove(completedDungeons, plr.UserId)
end

function module.Init(plr)
	local folder = Instance.new("Folder")
	folder.Parent = workspace.Enemys
	folder.Name = plr.UserId
	
	local data = nil

	local success, err = pcall(function()
		data = ds:GetAsync(plr.UserId)
	end)
	
	if success then
		if data then
			unlockedDungeons[plr.UserId] = data[1]
			completedDungeons[plr.UserId] = data[2]
		else
			unlockedDungeons[plr.UserId] = {1}
			completedDungeons[plr.UserId] = {}
		end
	end
end

function module.getUnlockedDungeon(plr, id)
	return table.find(unlockedDungeons[plr.UserId], id)
end

function module.getCompletedDungeon(plr, id)
	return table.find(completedDungeons[plr.UserId], id)
end

function module.startDungeon(plr, id)
	if not table.find(unlockedDungeons[plr.UserId], id) then return end
	local char = plr.Character or plr.CharacterAdded:Wait()
	local newMap = dungeons.dungeons[id].location.map:Clone()
	newMap.Parent = workspace.DungeonMaps
	newMap:PivotTo(CFrame.new(0, 1000*#workspace.DungeonMaps:GetChildren(), 0))
	char:PivotTo(newMap:GetPivot())
	
	plr:SetAttribute("InDungeon", true)
	
	task.wait(4)
	
	for number, v in dungeons.dungeons[id].waves do
		for	e, stat in v do
			for i = 1, stat.amount do
				local connection
				local enemy = dungeons.enemys[e].rig:Clone()
				enemy.Parent = workspace.Enemys[plr.UserId]
				local c = script.Overhead:Clone()
				c.Parent = enemy.Head
				c.Frame.name.Text = enemy.Name
				enemy.Humanoid.MaxHealth = dungeons.enemys[e].baseHealth * stat.healthMultiplier
				enemy.Humanoid.Health = dungeons.enemys[e].baseHealth * stat.healthMultiplier
				enemy:PivotTo(newMap:FindFirstChild("Spawn"..math.random(1, #dungeons.dungeons[id].location.spawns)).CFrame)
				
				local db = {}
				
				enemy.Humanoid.Animator:LoadAnimation(enemy.Animate.run.RunAnim):Play()
				
				connection = runService.Heartbeat:Connect(function()
					enemy.Humanoid.WalkToPoint = char.HumanoidRootPart.Position
					
					c.Frame.bar.fill.Size = UDim2.fromScale(math.clamp(enemy.Humanoid.Health/enemy.Humanoid.MaxHealth, 0, 1), 1)
					
					if (enemy.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude <= RANGE then
						if db[plr.UserId] then return end
						db[plr.UserId] = true
						
						char.Humanoid:TakeDamage(dungeons.enemys[e].baseDamage * stat.damageMultiplier / multipliers.GetArmorMulti(plr))
						
						task.delay(1, function()
							db[plr.UserId] = false
						end)
					end
				end)
				
				char.Humanoid.Died:Connect(function()
					connection:Disconnect()
					enemy:Destroy()
					char:PivotTo(workspace.Destinations.Lobby.CFrame)
					newMap:Destroy()
					plr:SetAttribute("InDungeon", false)
				end)
				
				game.Players.PlayerRemoving:Connect(function(leavePlr)
					if leavePlr.UserId == plr.UserId then
						connection:Disconnect()
						enemy:Destroy()
						newMap:Destroy()
					end
				end)
				
				enemy.Humanoid.Died:Connect(function()
					connection:Disconnect()
					
					task.delay(1, function()
						enemy:Destroy()
					end)
				end)
			end
		end
		
		repeat task.wait() until #workspace.Enemys[plr.UserId]:GetChildren() <= 0
		
		if plr and plr:GetAttribute("InDungeon") then
			if number < #dungeons.dungeons[id].waves then
				events.StartCountdown:FireClient(plr)
				task.wait(4)
			else
				char:PivotTo(workspace.Destinations.Lobby.CFrame)
				newMap:Destroy()
				rewardPlayer(plr, id)
				plr:SetAttribute("InDungeon", false)
			end
		else
			break
		end
	end
end

return module
