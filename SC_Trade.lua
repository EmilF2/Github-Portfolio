local rs = game:GetService("ReplicatedStorage")
local mps = game:GetService("MarketplaceService")

local modules = rs.Modules
local events = rs.Events.Trading
local functions = rs.Functions
local rollModule = require(script.Parent.Parent.Data.SC_Roll_Handler.SC_Roll_Data)
local config = require(modules.ConfigModule)
local weapons = require(modules.Weapons)
local assets = require(modules.AssetManager)

local tradingTable = {
	trading = {},
	cooldown = {},
	selection = {},
	accepted = {},
	acceptDebounce = {},
	products = {}
}

local function playerAdded(plr)
	tradingTable.products[plr.UserId] = {passes = {}, shirts = {}}

	local passes, shirts = assets:GetAssets(plr)

	if not passes or not shirts then
		plr.Settings.CanTrade.Value = false
		events.Parent.DisableSetting:FireClient(plr, "CanTrade")
		return
	end

	for _, v in passes do
		if not v.IsForSale then continue end
		if v.creator.creatorId ~= plr.UserId then continue end
		tradingTable.products[plr.UserId].passes[#tradingTable.products[plr.UserId].passes+1] = {id = v.gamePassId, price = v.price}	
	end

	for _, v in shirts do
		if v.creatorName ~= plr.Name then continue end
		tradingTable.products[plr.UserId].shirts[#tradingTable.products[plr.UserId].shirts+1] = {id = v.id, price = v.price}	
	end
end

local function playerRemoving(plr)
	for _, v in tradingTable do
		v[plr.UserId] = nil
	end
end

local function canReady(plr)
	return not tradingTable.acceptDebounce[plr.UserId]
end

local function canTrade(plrId, targetId)
	if tonumber(tradingTable.trading[plrId]) then
		return false
	end
	
	if tonumber(tradingTable.trading[targetId]) then
		return false
	end
	
	if tradingTable.cooldown[plrId] == true then
		return false
	end

	if tradingTable.cooldown[targetId] == true then
		return false
	end
	
	return true
end

local function isTrading(plr)
	if tradingTable.trading[plr.UserId] and tonumber(tradingTable.trading[plr.UserId]) then
		return true
	else
		return false
	end
end

local function isReady(plr)
	return tradingTable.accepted[plr.UserId]
end

local function cleanUp(plrId, targetId)
	tradingTable.trading[plrId] = nil
	tradingTable.trading[targetId] = nil
	tradingTable.selection[plrId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
	tradingTable.selection[targetId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
	tradingTable.accepted[plrId] = false
	tradingTable.accepted[targetId] = false
end

events.TradeAccepted.OnServerEvent:Connect(function(plr)
	local targetId = tradingTable.trading[plr.UserId]
	if not targetId then return end
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	if not tradingTable.acceptDebounce[plr.UserId] then tradingTable.acceptDebounce[plr.UserId] = false end
	if not tradingTable.acceptDebounce[targetId] then tradingTable.acceptDebounce[targetId] = false end
	
	if tradingTable.acceptDebounce[plr.UserId] then return end
	
	tradingTable.acceptDebounce[targetId] = true
	tradingTable.acceptDebounce[plr.UserId] = true
	
	tradingTable.accepted[plr.UserId] = not tradingTable.accepted[plr.UserId]
	
	events.TradeAccepted:FireClient(target, tradingTable.accepted[plr.UserId])

	task.delay(3, function()
		tradingTable.acceptDebounce[targetId] = false
		tradingTable.acceptDebounce[plr.UserId] = false
	end)
	
	if tradingTable.accepted[plr.UserId] and tradingTable.accepted[targetId] then
		if tradingTable.selection[plr.UserId].robux.id ~= 0 then
			events.TradePrompt:FireClient(plr, tradingTable.selection[plr.UserId].robux)
			
			if tradingTable.selection[plr.UserId].robux["type"] == "shirt" then
				
				local plr, id, pur = mps.PromptPurchaseFinished:Wait()
				
				if id == tradingTable.selection[plr.UserId].robux.id then
					if not pur then
						cleanUp(plr.UserId, targetId)

						events.TradeCanceled:FireClient(plr)
						events.TradeCanceled:FireClient(target)
						return
					end
				end
			else
				local plr, id, pur = mps.PromptGamePassPurchaseFinished:Wait()
				
				if id == tradingTable.selection[plr.UserId].robux.id then
					if not pur then
						cleanUp(plr.UserId, targetId)

						events.TradeCanceled:FireClient(plr)
						events.TradeCanceled:FireClient(target)
						return
					end
				end
			end
		end
		
		if tradingTable.selection[targetId].robux.id ~= 0 then
			events.TradePrompt:FireClient(target, tradingTable.selection[targetId].robux)

			if tradingTable.selection[targetId].robux["type"] == "shirt" then

				local plr, id, pur = mps.PromptPurchaseFinished:Wait()

				if id == tradingTable.selection[plr.UserId].robux.id then
					if not pur then
						cleanUp(plr.UserId, targetId)

						events.TradeCanceled:FireClient(plr)
						events.TradeCanceled:FireClient(target)
						return
					end
				end
			else
				local plr, id, pur = mps.PromptGamePassPurchaseFinished:Wait()

				if id == tradingTable.selection[targetId].robux.id then
					if not pur then
						cleanUp(plr.UserId, targetId)

						events.TradeCanceled:FireClient(plr)
						events.TradeCanceled:FireClient(target)
						return
					end
				end
			end
		end
		
		for _, v in tradingTable.selection[plr.UserId].weapons do
			local place = target.Inventory:FindFirstChild(v)

			if place then
				place.Value = 1
			else
				local value = Instance.new("IntValue", target.Inventory)
				value.Value = 1
				value.Name = v
			end
			
			plr.Inventory:FindFirstChild(v):Destroy()
			
			rs.Events.DeleteWeapon:FireClient(plr, v)
			rs.Events.InitializeInventory:FireClient(target, {[v] = {[1] = 1, [2] = rollModule.CalculateDisplayChance(weapons.weapons["Guns"][v].chance)}})
		end
		
		for _, v in tradingTable.selection[targetId].weapons do
			local place = plr.Inventory:FindFirstChild(v)

			if place then
				place.Value = 1
			else
				local value = Instance.new("IntValue", plr.Inventory)
				value.Value = 1
				value.Name = v
			end

			target.Inventory:FindFirstChild(v):Destroy()
			
			rs.Events.DeleteWeapon:FireClient(target, v)
			rs.Events.InitializeInventory:FireClient(plr, {[v] = {[1] = 1, [2] = rollModule.CalculateDisplayChance(weapons.weapons["Guns"][v].chance)}})
		end
		
		cleanUp(plr.UserId, targetId)
		events.TradeFinished:FireClient(plr)
		events.TradeFinished:FireClient(target)
	end
end)

events.TradeSelected.OnServerEvent:Connect(function(plr, name)
	local targetId = tradingTable.trading[plr.UserId]
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	if not tradingTable.selection[plr.UserId] then tradingTable.selection[plr.UserId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}} end
	
	if not tonumber(name) then
		local selected = plr.Inventory:FindFirstChild(name)
		local index = table.find(tradingTable.selection[plr.UserId].weapons, name)

		if selected and selected.Value > 0 then
			if index then
				table.remove(tradingTable.selection[plr.UserId].weapons, index)
			else
				table.insert(tradingTable.selection[plr.UserId].weapons, name)
			end
		else
			plr:Kick("Cheating")
		end

		events.TradeSelected:FireClient(target, name, index ~= nil)
	else
		if name <= 0 then
			tradingTable.selection[plr.UserId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
			events.TradeSelected:FireClient(plr, 0, targetId)
			return
		end
		
		for _, v in tradingTable.products[targetId].passes do
			if v.price == name then
				if mps:UserOwnsGamePassAsync(plr.UserId, v.id) then continue end
				tradingTable.selection[plr.UserId].robux["id"] = v.id
				tradingTable.selection[plr.UserId].robux["type"] = "gamepass"
				tradingTable.selection[targetId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
				events.TradeSelected:FireClient(target, v.price, nil)
				events.TradeRobuxCancel:FireClient(plr)
				return
			end
		end
		
		for _, v in tradingTable.products[targetId].shirts do
			if v.price == name then
				if mps:PlayerOwnsAsset(plr, v.id) then continue end
				tradingTable.selection[plr.UserId].robux["id"] = v.id
				tradingTable.selection[plr.UserId].robux["type"] = "shirt"
				tradingTable.selection[targetId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
				events.TradeSelected:FireClient(target, v.price, nil)
				events.TradeRobuxCancel:FireClient(plr)
				return
			end
		end
		
		tradingTable.selection[plr.UserId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
		events.TradeSelected:FireClient(plr, -1, targetId)
	end
end)

events.Message.OnServerEvent:Connect(function(plr, message)
	local targetId = tradingTable.trading[plr.UserId]
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	events.Message:FireClient(target, message)
end)

events.Request.OnServerEvent:Connect(function(plr, targetId)
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	if not tradingTable.trading[plr.UserId] then tradingTable.trading[plr.UserId] = nil end
	if not tradingTable.trading[targetId] then tradingTable.trading[targetId] = nil end
	
	if not tradingTable.cooldown[plr.UserId] then tradingTable.cooldown[plr.UserId] = false end
	if not tradingTable.cooldown[targetId] then tradingTable.cooldown[targetId] = false end

	if not canTrade(plr.UserId, targetId) then return end
	
	tradingTable.cooldown[plr.UserId] = true
	tradingTable.cooldown[targetId] = true
	
	events.Request:FireClient(target, plr.UserId)
	
	task.delay(config.tradeDelay, function()
		tradingTable.cooldown[plr.UserId] = false
		tradingTable.cooldown[targetId] = false
	end)
end)

events.RequestAccepted.OnServerEvent:Connect(function(plr, targetId)
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	tradingTable.trading[plr.UserId] = targetId
	tradingTable.trading[targetId] = plr.UserId
	
	tradingTable.selection[plr.UserId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
	tradingTable.selection[targetId] = {weapons = {}, robux = {["id"] = 0, ["type"] = ""}}
	
	events.RequestAccepted:FireClient(target, plr.UserId)
end)

events.TradeCanceled.OnServerEvent:Connect(function(plr)
	local targetId = tradingTable.trading[plr.UserId]
	local target = game.Players:GetPlayerByUserId(targetId)
	if not target then return end
	
	cleanUp(plr.UserId, targetId)
	
	events.TradeCanceled:FireClient(plr)
	events.TradeCanceled:FireClient(target)
end)

game.Players.PlayerRemoving:Connect(playerRemoving)
game.Players.PlayerAdded:Connect(playerAdded)
functions.IsTrading.OnServerInvoke = isTrading
functions.IsReady.OnServerInvoke = isReady
functions.CanReady.OnServerInvoke = canReady

for _, plr in game.Players:GetPlayers() do
	playerAdded(plr)
end