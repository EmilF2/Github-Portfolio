-- Video example: https://streamable.com/o1jhpo

local m = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Profiles = require(game:GetService("ServerScriptService").S.S_Data).Profiles
local R = ReplicatedStorage:WaitForChild("R")

local Events = R.R_Rounds.Events.Quests

local S_GameplayData = require(ServerScriptService.S.S_Rounds.S_GameplayData)
local R_QuestConfigs = require(R.R_QuestConfigs)
local R_Rounds = require(ReplicatedStorage.R.R_Rounds)

local SERVER_RESET_TIME = 0
local SERVER_LAST_REFRESH_DATE = nil
local REFRESH_HOUR = 9 -- 9AM UTC / 4AM Eastern
local REFRESH_MINUTE = 0
local REFRESH_SECOND = 0

local WEEKLY_REFRESH_HOUR = 9 -- 9AM UTC / 4AM Eastern
local WEEKLY_REFRESH_MINUTE = 0
local WEEKLY_REFRESH_SECOND = 0
local SERVER_WEEKLY_RESET_TIME = 0
local SERVER_LAST_WEEKLY_REFRESH_DATE = nil

math.randomseed(os.time())

local function GetRandomQuestsFromPool(poolType, count)
	local questPool = R_QuestConfigs.QUEST_POOL[poolType]
	print("Debug - Quest Pool for type", poolType, ":", questPool and #questPool or "nil")
	if not questPool then
		return {}
	end

	local availableQuests = table.clone(questPool)
	local selectedQuests = {}

	print("Debug - Available quests count:", #availableQuests)
	print("Debug - Requested count:", count)

	for i = 1, math.min(count, #availableQuests) do
		local randomIndex = math.random(1, #availableQuests)
		table.insert(selectedQuests, availableQuests[randomIndex])
		table.remove(availableQuests, randomIndex)
	end

	print("Debug - Selected quests count:", #selectedQuests)
	return selectedQuests
end

function m.GetQuestData(player)
	local profile = Profiles[player]
	if not profile then
		return nil
	end

	if not profile.Data.Flags.Quests then
		-- Initialize with yesterday's date to ensure quest generation
		profile.Data.Flags.Quests = {
			Daily = {
				LastRefreshData = 0,
				Quests = {},
			},
			Weekly = {
				LastRefreshData = 0,
				Quests = {},
			},
			Milestone = {
				Quests = {},
			},
		}
	end

	return profile.Data.Flags.Quests
end

function m.CalculateNextResetTime()
	local currentTime = os.time()
	local currentDate = os.date("!*t", currentTime)

	local todayResetTime = os.time({
		year = currentDate.year,
		month = currentDate.month,
		day = currentDate.day,
		hour = REFRESH_HOUR,
		min = REFRESH_MINUTE,
		sec = REFRESH_SECOND,
	})

	if currentTime >= todayResetTime then
		return todayResetTime + 86400
	else
		return todayResetTime
	end
end

-- This function calculates weekly reset time
function m.CalculateWeeklyResetTime()
	local currentTime = os.time()
	local currentDate = os.date("!*t", currentTime)

	-- Find next Sunday (or whichever day you want to reset)
	local daysUntilSunday = (7 - currentDate.wday + 1) % 7
	if daysUntilSunday == 0 then
		daysUntilSunday = 7
	end

	local resetTime = os.time({
		year = currentDate.year,
		month = currentDate.month,
		day = currentDate.day + daysUntilSunday,
		hour = WEEKLY_REFRESH_HOUR,
		min = WEEKLY_REFRESH_MINUTE,
		sec = WEEKLY_REFRESH_SECOND,
	})

	return resetTime
end

function m.RefreshQuestsForAllPlayers(isWeekly)
	local currentDate = os.date("!*t", os.time())

	if isWeekly then
		if
			SERVER_LAST_WEEKLY_REFRESH_DATE
			and os.difftime(os.time(currentDate), os.time(SERVER_LAST_WEEKLY_REFRESH_DATE)) < 7 * 86400
		then
			return false
		end

		print("Refreshing weekly quests for all players")
		SERVER_LAST_WEEKLY_REFRESH_DATE = currentDate
		SERVER_WEEKLY_RESET_TIME = m.CalculateWeeklyResetTime()

		for _, player in pairs(Players:GetPlayers()) do
			local questData = m.GetQuestData(player)
			if questData then
				questData.Weekly.LastRefreshData = os.time()
				questData.Weekly.Quests = {}

				local randomQuests =
					GetRandomQuestsFromPool(R_QuestConfigs.TYPES.WEEKLY, R_QuestConfigs.SETTINGS.MAX_WEEKLY_QUESTS)

				print("Generated " .. #randomQuests .. " weekly quests for player " .. player.Name)

				for _, questTemplate in ipairs(randomQuests) do
					table.insert(questData.Weekly.Quests, {
						id = questTemplate.id,
						progress = 0,
						status = "Active",
					})
				end

				m.SendQuestDataToClient(player, questData)
			end
		end

		return true
	else
		-- Original daily refresh code
		if
			SERVER_LAST_REFRESH_DATE
			and SERVER_LAST_REFRESH_DATE.year == currentDate.year
			and SERVER_LAST_REFRESH_DATE.month == currentDate.month
			and SERVER_LAST_REFRESH_DATE.day == currentDate.day
		then
			return false
		end

		print("Refreshing daily quests for all players")
		SERVER_LAST_REFRESH_DATE = currentDate
		SERVER_RESET_TIME = m.CalculateNextResetTime()

		for _, player in pairs(Players:GetPlayers()) do
			local questData = m.GetQuestData(player)
			if questData then
				questData.Daily.LastRefreshData = os.time()
				questData.Daily.Quests = {}

				local randomQuests =
					GetRandomQuestsFromPool(R_QuestConfigs.TYPES.DAILY, R_QuestConfigs.SETTINGS.MAX_DAILY_QUESTS)

				print("Generated " .. #randomQuests .. " daily quests for player " .. player.Name)

				for _, questTemplate in ipairs(randomQuests) do
					table.insert(questData.Daily.Quests, {
						id = questTemplate.id,
						progress = 0,
						status = "Active",
					})
				end

				m.SendQuestDataToClient(player, questData)
			end
		end

		return true
	end
end

-- Helper function to send quest data to client
function m.SendQuestDataToClient(player, questData)
	local clientData = {
		Daily = {
			Quests = questData.Daily and questData.Daily.Quests,
			NextResetTime = SERVER_RESET_TIME,
		},
		Weekly = {
			Quests = questData.Weekly and questData.Weekly.Quests,
			NextResetTime = SERVER_WEEKLY_RESET_TIME,
		},
		Milestone = {
			Quests = questData.Milestone and questData.Milestone.Quests,
		},
	}
	Events.SCE_UpdateQuests:FireClient(player, clientData)
end

-- Update SyncPlayerWithServerQuests to handle weekly quests
function m.SyncPlayerWithServerQuests(player)
	local questData = m.GetQuestData(player)
	if not questData then
		return
	end

	-- Handle daily quests refresh
	local dailyForceRefresh = not questData.Daily.Quests or #questData.Daily.Quests == 0
	local playerDailyRefreshDate = os.date("!*t", questData.Daily.LastRefreshData)
	local dailyShouldRefresh = dailyForceRefresh
		or (
			SERVER_LAST_REFRESH_DATE
			and (
				playerDailyRefreshDate.year < SERVER_LAST_REFRESH_DATE.year
				or (playerDailyRefreshDate.year == SERVER_LAST_REFRESH_DATE.year and playerDailyRefreshDate.month < SERVER_LAST_REFRESH_DATE.month)
				or (
					playerDailyRefreshDate.year == SERVER_LAST_REFRESH_DATE.year
					and playerDailyRefreshDate.month == SERVER_LAST_REFRESH_DATE.month
					and playerDailyRefreshDate.day < SERVER_LAST_REFRESH_DATE.day
				)
			)
		)

	-- Handle weekly quests refresh
	local weeklyForceRefresh = not questData.Weekly.Quests or #questData.Weekly.Quests == 0
	local weeklyRefreshNeeded = weeklyForceRefresh
		or (
			SERVER_LAST_WEEKLY_REFRESH_DATE
			and os.difftime(os.time(SERVER_LAST_WEEKLY_REFRESH_DATE), questData.Weekly.LastRefreshData) > 0
		)

	-- Handle milestone initialization
	if not questData.Milestone.Quests or #questData.Milestone.Quests == 0 then
		for _, milestoneTemplate in ipairs(R_QuestConfigs.QUEST_POOL[R_QuestConfigs.TYPES.MILESTONE]) do
			table.insert(questData.Milestone.Quests, {
				id = milestoneTemplate.id,
				progress = 0,
				status = "Active",
			})
		end
	end

	local anyRefresh = false

	-- Refresh daily quests if needed
	if dailyShouldRefresh then
		questData.Daily.LastRefreshData = os.time()
		questData.Daily.Quests = {}

		local randomQuests =
			GetRandomQuestsFromPool(R_QuestConfigs.TYPES.DAILY, R_QuestConfigs.SETTINGS.MAX_DAILY_QUESTS)

		for _, questTemplate in ipairs(randomQuests) do
			table.insert(questData.Daily.Quests, {
				id = questTemplate.id,
				progress = 0,
				status = "Active",
			})
		end

		anyRefresh = true
	end

	-- Refresh weekly quests if needed
	if weeklyRefreshNeeded then
		questData.Weekly.LastRefreshData = os.time()
		questData.Weekly.Quests = {}

		local randomQuests =
			GetRandomQuestsFromPool(R_QuestConfigs.TYPES.WEEKLY, R_QuestConfigs.SETTINGS.MAX_WEEKLY_QUESTS)

		for _, questTemplate in ipairs(randomQuests) do
			table.insert(questData.Weekly.Quests, {
				id = questTemplate.id,
				progress = 0,
				status = "Active",
			})
		end

		anyRefresh = true
	end

	m.SendQuestDataToClient(player, questData)
	return anyRefresh
end

-- This function looks up quest templates by ID
function m.GetQuestTemplateById(questId)
	-- Check daily quests
	for _, template in ipairs(R_QuestConfigs.QUEST_POOL[R_QuestConfigs.TYPES.DAILY]) do
		if template.id == questId then
			return template
		end
	end

	-- Check weekly quests
	for _, template in ipairs(R_QuestConfigs.QUEST_POOL[R_QuestConfigs.TYPES.WEEKLY]) do
		if template.id == questId then
			return template
		end
	end

	-- Check milestone quests
	for _, template in ipairs(R_QuestConfigs.QUEST_POOL[R_QuestConfigs.TYPES.MILESTONE]) do
		if template.id == questId then
			return template
		end
	end

	warn("Could not find quest template with ID: " .. tostring(questId))
	return nil
end

-- Update your progress tracking function to handle milestones correctly
function m.UpdateQuestProgress(player, objectiveType, amount)
	local questData = m.GetQuestData(player)
	if not questData then
		return false
	end

	local updated = false
	amount = amount or 1

	-- Update daily quests
	for _, quest in ipairs(questData.Daily.Quests) do
		local questConfig = m.GetQuestTemplateById(quest.id)
		if quest.status == "Active" and questConfig.objective.type == objectiveType then
			quest.progress = math.min(quest.progress + amount, questConfig.objective.target)
			if quest.progress >= questConfig.objective.target then
				quest.status = "Completed"
			end
			updated = true
		end
	end

	-- Update weekly quests
	for _, quest in ipairs(questData.Weekly.Quests) do
		local questConfig = m.GetQuestTemplateById(quest.id)
		if quest.status == "Active" and questConfig.objective.type == objectiveType then
			quest.progress = math.min(quest.progress + amount, questConfig.objective.target)
			if quest.progress >= questConfig.objective.target then
				quest.status = "Completed"
			end
			updated = true
		end
	end

	-- Update milestone quests (these progress the same way but don't reset)
	for _, quest in ipairs(questData.Milestone.Quests) do
		local questConfig = m.GetQuestTemplateById(quest.id)
		if quest.status == "Active" and questConfig.objective.type == objectiveType then
			quest.progress = math.min(quest.progress + amount, questConfig.objective.target)
			if quest.progress >= questConfig.objective.target then
				quest.status = "Completed"
			end
			updated = true
		end
	end

	if updated then
		m.SendQuestDataToClient(player, questData)
	end

	return updated
end

function m.CompleteQuest(player, questId)
	local questData = m.GetQuestData(player)
	if not questData then
		return false
	end

	-- Check all quest types (daily, weekly, milestone)
	local questTypes = { "Daily", "Weekly", "Milestone" }

	for _, questType in ipairs(questTypes) do
		for i, quest in ipairs(questData[questType].Quests) do
			local questConfig = m.GetQuestTemplateById(quest.id)
			if quest.id == questId and quest.status == "Completed" then
				quest.status = "Claimed"

				-- Process rewards
				for _, reward in ipairs(questConfig.rewards) do
					if reward.type == "coins" then
						Profiles[player].Data.Coins += reward.amount
						--print(`Awarded {reward.amount} coins to {player.Name}`)
						R.R_Rounds.Events.Shop.SCE_UpdateCoins:FireClient(player, Profiles[player].Data.Coins)
					elseif reward.type == "xp" then
						-- Implement XP reward if needed
					end
				end

				m.SendQuestDataToClient(player, questData)
				return true
			end
		end
	end

	return false
end

-- Add weekly quest reset loop
function m.StartWeeklyResetLoop()
	task.spawn(function()
		while true do
			local currentTime = os.time()
			local resetTime = m.CalculateWeeklyResetTime()
			local timeUntilReset = resetTime - currentTime

			if timeUntilReset <= 0 then
				m.RefreshQuestsForAllPlayers(true) -- true for weekly
				resetTime = m.CalculateWeeklyResetTime()
				timeUntilReset = resetTime - currentTime
			end

			task.wait(math.min(timeUntilReset + 1, 86400)) -- Wait at most a day
		end
	end)
end

function m.StartDailyResetLoop()
	task.spawn(function()
		while true do
			local currentTime = os.time()
			local resetTime = m.CalculateNextResetTime()
			local timeUntilReset = resetTime - currentTime

			if timeUntilReset <= 0 then
				m.RefreshQuestsForAllPlayers()
				resetTime = m.CalculateNextResetTime()
				timeUntilReset = resetTime - currentTime
			end

			task.wait(timeUntilReset + 1)
			m.RefreshQuestsForAllPlayers()
		end
	end)
end

function m.Setup()
	Events.CSE_RequestQuests.OnServerEvent:Connect(function(player)
		local questData = m.GetQuestData(player)
		if questData then
			m.SendQuestDataToClient(player, questData)
		end
	end)
	Events.CSE_ClaimQuest.OnServerEvent:Connect(function(player, questId)
		m.CompleteQuest(player, questId)
	end)

	-- This function handles player joins
	local function OnPlayerAdded(player)
		-- Wait for the profile to load
		local attempts = 0
		while not Profiles[player] and attempts < 10 do
			attempts += 1
			task.wait(0.5)
		end

		if not Profiles[player] then
			warn("Failed to get profile for " .. player.Name)
			return
		end

		-- Initialize quest data structure if needed
		local questData = m.GetQuestData(player)
		if not questData then
			return
		end

		-- Make sure structure has all required fields
		if not questData.Daily then
			questData.Daily = {
				LastRefreshData = os.time() - 86400, -- Yesterday
				Quests = {},
			}
		end

		if not questData.Weekly then
			questData.Weekly = {
				LastRefreshData = os.time() - 86400, -- Yesterday
				Quests = {},
			}
		end

		if not questData.Milestone then
			questData.Milestone = {
				Quests = {},
			}
		end

		-- Sync player with current server quest state
		--print("Syncing quests for player " .. player.Name)
		local refreshed = m.SyncPlayerWithServerQuests(player)

		if refreshed then
			--print("Refreshed quests for " .. player.Name)
		else
			--print("No quest refresh needed for " .. player.Name)
		end
	end

	Players.PlayerAdded:Connect(OnPlayerAdded)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(OnPlayerAdded, player)
	end

	R.R_Rounds.Events.SSE_EndGamePhase.Event:Connect(function(GamePhase, BossWinStatus, RoundTimer)
		if GamePhase ~= R_Rounds.PHASES.GAMEPLAY then
			return
		end

		local bossWon = (BossWinStatus == R_Rounds.BOSS_WIN_STATUS.WIN)
		local bossPlayer = Players:GetPlayerByUserId(tonumber(S_GameplayData.Data.Boss.Id))

		for userIdString, playerName in pairs(S_GameplayData.Data.DisplayName.Players) do
			local player = Players:GetPlayerByUserId(tonumber(userIdString))
			local survived = not S_GameplayData.Data.Died.Players[userIdString]

			if bossWon then
				if player and player == bossPlayer then
					m:AwardProgress(player, "BOSS_WIN", 1)
				end
			else
				if player and player ~= bossPlayer then
					m:AwardProgress(player, "BOSS_DEFEAT", 1)
					m:AwardProgress(player, "ENEMIES_KILLED", 1)
				end
			end

			if player == bossPlayer then
				local enemiesKilled = 0
				for _, enemyId in pairs(S_GameplayData.Data.Died.Bots) do
					enemiesKilled += 1
				end
				for _, enemyId in pairs(S_GameplayData.Data.Died.Players) do
					enemiesKilled += 1
				end

				m:AwardProgress(player, "ENEMIES_KILLED", enemiesKilled)
			end

			if survived then
				m:AwardProgress(player, "ROUNDS_SURVIVED", 1)
			end
		end
	end)
end

local AwardProgressQueue: { [Player]: { [string]: number } } = {}
function m:AwardProgress(player: Player, objectiveType: string, amount: number?)
	if not player then return end
	-- Queuing system to batch updates so we don't spam the server with updates
	if not AwardProgressQueue[player] then
		AwardProgressQueue[player] = {}

		task.delay(5, function()
			if AwardProgressQueue[player] then
				for thisObjectiveType, thisAmount in pairs(AwardProgressQueue[player]) do
					m.UpdateQuestProgress(player, thisObjectiveType, thisAmount)
				end
				AwardProgressQueue[player] = nil
			end
		end)
	end
	if not AwardProgressQueue[player][objectiveType] then
		AwardProgressQueue[player][objectiveType] = 0
	end
	AwardProgressQueue[player][objectiveType] = (AwardProgressQueue[player][objectiveType] or 0) + (amount or 1)

	-- local updated = m.UpdateQuestProgress(player, objectiveType, amount)
	-- if updated then
	-- 	print(`Awarded {amount} progress for {objectiveType} to {player.Name}`)
	-- else
	-- 	print(`No active quest found for {objectiveType} on {player.Name}`)
	-- end
end

function m:DebugTimeTravelToNextDay()
	local currentDate = os.date("!*t")
	SERVER_LAST_REFRESH_DATE = {
		year = currentDate.year,
		month = currentDate.month,
		day = currentDate.day - 1,
	}

	-- Force daily reset
	m.RefreshQuestsForAllPlayers(false)

	print("Time traveled to next day - Daily quests refreshed!")
end

function m:DebugTimeTravelToNextWeek()
	SERVER_LAST_WEEKLY_REFRESH_DATE = os.date("!*t", os.time() - (7 * 86400))

	m.RefreshQuestsForAllPlayers(true)

	print("Time traveled to next week - Weekly quests refreshed!")
end

m.Setup()

SERVER_RESET_TIME = m.CalculateNextResetTime()
m.StartDailyResetLoop()
SERVER_WEEKLY_RESET_TIME = m.CalculateWeeklyResetTime()
m.StartWeeklyResetLoop()

return m
