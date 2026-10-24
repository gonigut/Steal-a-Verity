-- Сохранение прогресса игрока: деньги и Verity на базе.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STORE_NAME = "StealAVerity_v1"
local AUTOSAVE_SECONDS = 60

local store = DataStoreService:GetDataStore(STORE_NAME)

local Data = {}

local profiles = {} -- [Player] = { Money = number, Slots = { ["1"] = "red", ... } }
local canSave = {} -- [Player] = true, только если загрузка прошла успешно

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function newProfile()
	return { Money = Config.StartMoney, Slots = {} }
end

function Data.Load(player)
	local ok, result
	for attempt = 1, 3 do
		ok, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			break
		end
		task.wait(attempt)
	end

	local profile = newProfile()
	if ok then
		canSave[player] = true
		if type(result) == "table" then
			profile.Money = tonumber(result.Money) or profile.Money
			if type(result.Slots) == "table" then
				for key, id in result.Slots do
					local slot = tonumber(key)
					if slot and slot >= 1 and slot <= Config.SlotCount and Config.ById[id] then
						profile.Slots[tostring(slot)] = id
					end
				end
			end
		end
	else
		-- Не перезаписываем сохранение пустым профилем, если загрузить не удалось.
		canSave[player] = false
		warn("[Data] Не удалось загрузить данные " .. player.Name .. ": " .. tostring(result))
	end

	profiles[player] = profile
	player:SetAttribute("Money", profile.Money)
	return profile
end

function Data.Get(player)
	return profiles[player]
end

function Data.AddMoney(player, delta)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Money = math.max(0, profile.Money + delta)
	player:SetAttribute("Money", profile.Money)
end

function Data.Save(player)
	local profile = profiles[player]
	if not profile or not canSave[player] then
		return false
	end

	local snapshot = { Money = profile.Money, Slots = table.clone(profile.Slots) }
	local lastError
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return snapshot
			end)
		end)
		if ok then
			return true
		end
		lastError = err
		task.wait(attempt)
	end
	warn("[Data] Не удалось сохранить данные " .. player.Name .. ": " .. tostring(lastError))
	return false
end

function Data.Release(player)
	Data.Save(player)
	profiles[player] = nil
	canSave[player] = nil
end

function Data.SaveAll()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			Data.Save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for player in profiles do
			task.spawn(Data.Save, player)
		end
	end
end)

return Data
