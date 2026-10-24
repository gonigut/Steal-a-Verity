-- Базы игроков: места, размещение Verity, касса с доходом, защита ворот, продажа.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(script.Parent.Remotes)
local VerityFactory = require(script.Parent.VerityFactory)

local Bases = {}

local list = {}
local byPlayer = {}
local deps = {} -- Data, OnSteal(player, base, slot, model)

local function updateStashLabel(base)
	base.StashLabel.Text = "💰 КАССА\n" .. Format.Money(base.Stash)
end

function Bases.IncomeOf(base)
	local total = 0
	for _, entry in base.Placed do
		total += Config.ById[entry.Id].Income
	end
	return total
end

local function refreshIncome(base)
	if base.Owner then
		base.Owner:SetAttribute("Income", Bases.IncomeOf(base))
	end
end

local function setLocked(base, locked)
	base.Locked = locked
	base.Gate.CanCollide = locked
	base.Gate.Transparency = locked and 0.45 or 1
	for _, entry in base.Placed do
		entry.Model:SetAttribute("Locked", locked)
	end
end

local function collect(base, hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or player ~= base.Owner or base.Stash < 1 then
		return
	end
	local amount = math.floor(base.Stash)
	base.Stash -= amount
	deps.Data.AddMoney(player, amount)
	Remotes.To(player, "Собрано " .. Format.Money(amount), "good")
	updateStashLabel(base)
end

function Bases.Init(world, injected)
	list = world.Bases
	deps = injected
	for _, base in list do
		base.Owner = nil
		base.Placed = {} -- [slot] = { Id, Model }
		base.Locked = false
		base.LockToken = 0
		base.ReadyAt = 0
		base.Stash = 0
		base.CollectPad.Touched:Connect(function(hit)
			collect(base, hit)
		end)
	end

	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in list do
				if base.Owner then
					local income = Bases.IncomeOf(base)
					if income > 0 then
						base.Stash += income
						updateStashLabel(base)
					end
				end
			end
		end
	end)
end

function Bases.OfPlayer(player)
	return byPlayer[player]
end

function Bases.FreeSlot(base)
	for slot = 1, Config.SlotCount do
		if not base.Placed[slot] then
			return slot
		end
	end
	return nil
end

function Bases.PlaceVerity(base, slot, id)
	local def = Config.ById[id]
	if not def or base.Placed[slot] or not base.Owner then
		return false
	end

	local model = VerityFactory.Build(id)
	model:PivotTo(base.SlotCFrames[slot])
	model:SetAttribute("OwnerId", base.Owner.UserId)
	model:SetAttribute("Locked", base.Locked)

	local body = model.PrimaryPart

	local steal = Instance.new("ProximityPrompt")
	steal.ActionText = "Украсть"
	steal.ObjectText = def.Name
	steal.KeyboardKeyCode = Enum.KeyCode.E
	steal.HoldDuration = Config.StealHoldSeconds
	steal.MaxActivationDistance = 10
	steal.RequiresLineOfSight = false
	steal:SetAttribute("Kind", "Steal")
	steal.Triggered:Connect(function(player)
		deps.OnSteal(player, base, slot, model)
	end)
	steal.Parent = body
	CollectionService:AddTag(steal, "VerityPrompt")

	local sell = Instance.new("ProximityPrompt")
	sell.ActionText = "Продать за " .. Format.Money(math.floor(def.Price * Config.SellRatio))
	sell.ObjectText = def.Name
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell.GamepadKeyCode = Enum.KeyCode.ButtonY
	sell.HoldDuration = 1
	sell.MaxActivationDistance = 10
	sell.RequiresLineOfSight = false
	sell:SetAttribute("Kind", "Sell")
	sell.Triggered:Connect(function(player)
		Bases.TrySell(player, base, slot, model)
	end)
	sell.Parent = body
	CollectionService:AddTag(sell, "VerityPrompt")

	model.Parent = base.Model
	base.Placed[slot] = { Id = id, Model = model }

	local profile = deps.Data.Get(base.Owner)
	if profile then
		profile.Slots[tostring(slot)] = id
	end
	refreshIncome(base)
	return true
end

-- Убирает Verity с места и возвращает его id (или nil).
function Bases.RemoveVerity(base, slot)
	local entry = base.Placed[slot]
	if not entry then
		return nil
	end
	base.Placed[slot] = nil
	entry.Model:Destroy()

	if base.Owner then
		local profile = deps.Data.Get(base.Owner)
		if profile then
			profile.Slots[tostring(slot)] = nil
		end
		refreshIncome(base)
	end
	return entry.Id
end

function Bases.TrySell(player, base, slot, model)
	if base.Owner ~= player then
		return
	end
	local entry = base.Placed[slot]
	if not entry or entry.Model ~= model then
		return
	end
	local def = Config.ById[entry.Id]
	Bases.RemoveVerity(base, slot)
	local refund = math.floor(def.Price * Config.SellRatio)
	deps.Data.AddMoney(player, refund)
	Remotes.To(player, "Продано: " .. def.Name .. " за " .. Format.Money(refund), "info")
end

function Bases.Assign(player)
	local base
	for _, candidate in list do
		if not candidate.Owner then
			base = candidate
			break
		end
	end
	if not base then
		return nil
	end

	base.Owner = player
	byPlayer[player] = base
	base.Stash = 0
	base.ReadyAt = 0
	updateStashLabel(base)
	base.SignLabel.Text = "🏠 " .. player.DisplayName
	player:SetAttribute("LockUntil", 0)
	player:SetAttribute("LockReadyAt", 0)
	player.RespawnLocation = base.SpawnLocation

	local profile = deps.Data.Get(player)
	if profile then
		local saved = {}
		for key, id in profile.Slots do
			table.insert(saved, { Slot = tonumber(key), Id = id })
		end
		for _, item in saved do
			Bases.PlaceVerity(base, item.Slot, item.Id)
		end
	end
	refreshIncome(base)
	return base
end

function Bases.Release(player)
	local base = byPlayer[player]
	if not base then
		return
	end
	byPlayer[player] = nil

	-- Невыбранный доход не пропадает.
	if base.Stash >= 1 then
		deps.Data.AddMoney(player, math.floor(base.Stash))
	end

	for _, entry in base.Placed do
		entry.Model:Destroy()
	end
	base.Placed = {}
	base.Owner = nil
	base.Stash = 0
	base.ReadyAt = 0
	base.LockToken += 1
	setLocked(base, false)
	updateStashLabel(base)
	base.SignLabel.Text = "Свободно"
end

function Bases.Lock(player)
	local base = byPlayer[player]
	if not base then
		return
	end
	local now = workspace:GetServerTimeNow()
	if base.Locked or now < base.ReadyAt then
		return
	end

	base.ReadyAt = now + Config.LockDuration + Config.LockCooldown
	player:SetAttribute("LockUntil", now + Config.LockDuration)
	player:SetAttribute("LockReadyAt", base.ReadyAt)
	setLocked(base, true)
	Remotes.To(player, "🔒 База защищена на " .. Config.LockDuration .. " сек!", "good")

	base.LockToken += 1
	local token = base.LockToken
	task.delay(Config.LockDuration, function()
		if base.LockToken == token and base.Locked then
			setLocked(base, false)
			if base.Owner then
				Remotes.To(base.Owner, "🔓 Защита закончилась", "info")
			end
		end
	end)
end

return Bases
