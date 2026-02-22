local dss = game:GetService("DataStoreService")
local ss = game:GetService("ServerStorage")
local ds = dss:GetDataStore("Armor_Test_"..ss.data.Value)
local rs = game:GetService("ReplicatedStorage")

local modules = rs.Modules
local armor = require(modules.Armor)

local equippedArmor = {}

local function playerAdded(plr)
	equippedArmor[plr.UserId] = {}
	
	local data = {}

	local inventory = Instance.new("Folder", plr)
	inventory.Name = "Armor"
	
	local success, err = pcall(function()
		data = ds:GetAsync(plr.UserId)
	end)

	if success then
		if data ~= nil and data ~= {} then
			for i, v in data do
				if i == "equipped" then continue end
				local value = Instance.new("StringValue", inventory)
				value.Name = i
			end
			
			if data["equipped"] then
				equippedArmor[plr.UserId] = data["equipped"]
			end
		end
	else
		plr:Kick(err)
	end

	rs.Events.InitializeArmor:FireClient(plr, data, equippedArmor[plr.UserId])
end

local function playerRemoving(plr)
	local saveTable = {}

	for _, v in plr.Armor:GetChildren() do
		saveTable[v.Name] = {}
		saveTable[v.Name][1] = v.Value
	end
	
	saveTable["equipped"] = equippedArmor[plr.UserId]

	local success, err = pcall(function()
		if saveTable then
			ds:SetAsync(plr.UserId, saveTable)
		end
	end)

	if not success then 
		warn(err)
	end
end

local function equip(plr, index)
	local equipped = table.find(equippedArmor[plr.UserId], index) ~= nil
	local changes = {}
	local tag = armor.GetTagFromArmorIndex(index)
	
	if not equipped then
		for i, v in equippedArmor[plr.UserId] do
			if armor.GetTagFromArmorIndex(v) == tag then
				table.remove(equippedArmor[plr.UserId], i)
				table.insert(changes, v)
				break
			end
		end
		
		table.insert(equippedArmor[plr.UserId], index)
		table.insert(changes, index)
	else
		table.remove(equippedArmor[plr.UserId], table.find(equippedArmor[plr.UserId], index))
		table.insert(changes, index)
	end
	
	return changes
end

local function getEquippedArmor(plr)
	return equippedArmor[plr.UserId]
end

rs.Functions.GetEquippedArmorS.OnInvoke = getEquippedArmor
rs.Functions.GetEquippedArmor.OnServerInvoke = getEquippedArmor
rs.Functions.EquipArmor.OnServerInvoke = equip
game.Players.PlayerRemoving:Connect(playerRemoving)
game.Players.PlayerAdded:Connect(playerAdded)

for _, plr in game.Players:GetPlayers() do
	playerAdded(plr)
end
