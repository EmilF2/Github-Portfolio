-- Services --

local rs = game:GetService("ReplicatedStorage")
local ss = game:GetService("ServerStorage")
local dss = game:GetService("DataStoreService")

-- Datastore --
local ds = dss:GetDataStore("Pets_"..ss.data.Value)

-- Variables --
local events = rs.Events
local modules = rs.Modules

-- Modules --
local petsModule = require(modules.Pets)

local module = {}

-- Creates the pet models with the provided ids
function module.CreateModels()
	local petsFolder = Instance.new("Folder", rs)
	petsFolder.Name = "PetModels"
	
	for id, v in petsModule.Pets do
		-- Create the pet model inside of the petsFolder
		local petModel = Instance.new("Model", petsFolder)
		petModel.Name = id
		
		-- Create the visual part of the pet and sizing and positioning it for later use
		local petPart = Instance.new("Part", petModel)
		petPart.Name = id.."Part"
		petPart.CanCollide = false
		petPart.Rotation = Vector3.new(0, 180, 0)
		petPart.Anchored = true
		petPart.Size = Vector3.new(3.467, 4.467, 5.533)
		petPart.Position = Vector3.new(119.019, 105.923, 91.802)
		petModel.PrimaryPart = petPart
		
		-- Create the mesh that gives the pet it's texture and shape
		local petMesh = Instance.new("SpecialMesh", petPart)
		petMesh.Scale = Vector3.new(1.5, 1.5, 1.5)
		petMesh.MeshId = v.meshId
		petMesh.TextureId = v.textureId
		
		-- This StringValue decides if it flies or walks
		if v.state == "Walks" then
			local state = Instance.new("StringValue", petModel)
			state.Name = "Walks"
		end
	end
end

-- Initiate the setup for the player
function module.Init(plr)
	-- Create the pet folder for the player this is the folder the Pet Models will be inside once equipped
	local PetsFolder = workspace:WaitForChild("Player_Pets")
	
	local folder = Instance.new("Folder")
	folder.Name = plr.Name
	folder.Parent = PetsFolder
	
	-- Create the pets folder which is the players pet inventory
	local pets = Instance.new("Folder", plr)
	pets.Name = "Pets"
	
	-- Create the values folder containing all the nessesary values for the pet system
	local values = Instance.new("Folder", plr)
	values.Name = "Values"
	
	local maxPetsEquipped = Instance.new("IntValue", values)
	maxPetsEquipped.Name = "MaxPetsEquipped"
	maxPetsEquipped.Value = 6
	
	local maxPetStorage = Instance.new("IntValue", values)
	maxPetStorage.Name = "MaxPetStorage"
	maxPetStorage.Value = 150
	
	local luck = Instance.new("IntValue", values)
	luck.Name = "Luck"
	luck.Value = 0
	
	
	-- Load the data for the player
	local valuesData = {}

	local success, err = pcall(function()
		valuesData = ds:GetAsync(plr.UserId)
	end)

	if success then
		if valuesData then
			for i, v in pairs(valuesData["Values"]) do
				values[i].Value = v
			end
		end
	else
		plr:Kick(err)
	end
	
	-- Load the pets for the player
	local data = {}
	
	local success, err = pcall(function()
		data = ds:GetAsync(plr.UserId)
	end)
	
	if success then
		if data then
			for _, id in pairs(data["Pets"]) do
				local pet = Instance.new("NumberValue", pets)
				pet.Name = petsModule.Pets[id].name
				pet.Value = id
			end
		end
	else
		plr:Kick(err)
	end
	
	-- Save the data for the player
	game.Players.PlayerRemoving:Connect(function(plr)
		local saveTable = {
			["Pets"] = {},
			["Values"] = {}
		}
		
		for i, v in plr.Pets:GetChildren() do
			saveTable["Pets"][i] = v.Value
		end
		
		for i, v in plr.Values:GetChildren() do
			saveTable["Values"][v.Name] = v.Value
		end
		
		local success, err = pcall(function()
			ds:SetAsync(plr.UserId, saveTable)
		end)
		
		if not success then
			warn(err)
		end
		
		if PetsFolder:FindFirstChild(plr.Name) then
			PetsFolder:FindFirstChild(plr.Name):Destroy()
		end
	end)
	
	-- Initialize the inventory for the player on the client
	local initTable = {}
	
	for i, v in plr.Pets:GetChildren() do
		initTable[i] = v.Value
	end 
	
	events.InitializeInventory:FireClient(plr, initTable)
end

-- This function deletes a pet from the players inventory
function module.RemovePet(plr, id)
	for _, v in plr.Pets:GetChildren() do
		if v.Value == id then
			v:Destroy()
			break
		end
	end
end

-- This function adds a pet to the players inventory
function module.AddPet(plr, id)
	local pet = petsModule.Pets[id]
	
	if pet then
		local value = Instance.new("NumberValue", plr.Pets)
		value.Name = pet.name
		value.Value = id
	end
end

-- This function equips a pet to the player
function module.Equip(plr, id)
	local canEquip = #workspace.Player_Pets:FindFirstChild(plr.Name):GetChildren() < plr.Values.MaxPetsEquipped.Value
	if not canEquip then return canEquip end
	
	local playerPets = workspace.Player_Pets:FindFirstChild(plr.Name)
	local petModel = rs.PetModels:FindFirstChild(id):Clone()
	petModel.Parent = playerPets
	
	return canEquip
end

-- This function unequips a pet from the player
function module.Unequip(plr, id)
	local canUnequip = #workspace.Player_Pets:FindFirstChild(plr.Name):GetChildren() > 0
	if not canUnequip then return canUnequip end
	
	local playerPets = workspace.Player_Pets:FindFirstChild(plr.Name)
	playerPets:FindFirstChild(id):Destroy()

	return canUnequip
end

-- This function returns the power and wins multipliers for the player
function module.GetMulti(plr)
	local powerMulti = 0
	local winMulti = 0
	
	for _, v in workspace.Player_Pets:FindFirstChild(plr.Name):GetChildren() do
		local pet = petsModule.Pets[tonumber(v.Name)]
		powerMulti += pet.powerBoost
		winMulti += pet.winsBoost
	end

	if powerMulti == 0 then
		powerMulti = 1
	end
	
	if winMulti == 0 then
		winMulti = 1
	end
	
	return powerMulti, winMulti
end

-- Calculates the chance of getting a pet based on a luck increment
function module.CalculateChance(luck, chance)
	local K = 100

	if chance <= 0 then
		warn("Chance must be greater than 0")
		return 0
	end

	if luck < 0 then
		warn("Luck cannot be negative")
		return 0
	end

	local baseChance = chance

	local chance = baseChance * math.pow(1.5, luck)

	if chance > 1 then
		chance = 1
	end

	return chance
end

-- Chooses a pet based on the players luck and the pets chance using the previous function
function module.ChoosePet(luck, egg, amount)
	local resultTable = {}
	
	for i = 1, amount do
		local totalWeight = 0
		local petWeights = {}

		for id, v in pairs(petsModule.Pets) do
			if v.egg ~= egg then continue end
			local chance = module.CalculateChance(luck, v.chance)

			local weight = chance  

			petWeights[id] = weight
			totalWeight = totalWeight + weight
		end

		local randomChoice = math.random() * totalWeight
		local runningSum = 0

		for id, weight in pairs(petWeights) do
			runningSum = runningSum + weight
			if runningSum >= randomChoice then
				table.insert(resultTable, id)
				break
			end
		end
	end
	
	return resultTable
end

-- This function hatches the chossen egg
function module.Hatch(plr, egg, amount)
	local storage = #plr.Pets:GetChildren()
	local results = module.ChoosePet(plr.Values.Luck.Value, egg, amount)
	local currency = workspace.Eggs:FindFirstChild(egg):GetAttribute("Currency")
	local price = workspace.Eggs:FindFirstChild(egg):GetAttribute("Price")
	
	if amount == 3 then
		if plr.boosts.TripleHatchBoost.Value < plr.playerstats.Playtime.Value and not plr.gamepasses.HasTripleHatch.Value then return "gamepass" end
	end
	
	if storage+amount > plr.Values.MaxPetStorage.Value then return end
	
	if plr.playerstats[currency].Value < price*amount then return end
	plr.playerstats[currency].Value -= price*amount
	
	for _, id in results do
		module.AddPet(plr, id)
	end
	
	return results
end

return module