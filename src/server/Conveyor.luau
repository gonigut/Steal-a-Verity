-- Конвейер: Verity выезжают слева направо, их можно купить, пока они едут.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(script.Parent.Remotes)
local VerityFactory = require(script.Parent.VerityFactory)

local Conveyor = {}

local ANNOUNCE_FROM_ORDER = 5 -- с какой редкости объявлять всем (Легендарный и выше)

local belt
local deps = {} -- Bases, Data
local items = {}
local folder
local totalWeight = 0

local function roll()
	local r = math.random() * totalWeight
	for _, def in Config.Verities do
		r -= def.Weight
		if r <= 0 then
			return def
		end
	end
	return Config.Verities[1]
end

local function itemCFrame(item)
	local bob = math.sin(os.clock() * 3 + item.Phase) * 0.25
	local y = belt.TopY + VerityFactory.FeetOffset + bob
	-- Лицо (-Z) смотрит по ходу движения (+X).
	return CFrame.new(item.X, y, belt.Z) * CFrame.Angles(0, -math.pi / 2, 0)
end

function Conveyor.Buy(player, item)
	if item.Taken then
		return
	end
	local base = deps.Bases.OfPlayer(player)
	local profile = deps.Data.Get(player)
	if not base or not profile then
		return
	end

	local def = item.Def
	if profile.Money < def.Price then
		Remotes.To(player, "Не хватает денег! Нужно " .. Format.Money(def.Price), "bad")
		return
	end
	local slot = deps.Bases.FreeSlot(base)
	if not slot then
		Remotes.To(player, "Нет места на базе! Продай кого-нибудь (кнопка F у своего Verity).", "bad")
		return
	end

	item.Taken = true
	item.Model:Destroy()
	deps.Data.AddMoney(player, -def.Price)
	deps.Bases.PlaceVerity(base, slot, def.Id)
	Remotes.To(player, "Куплен: " .. def.Name .. "!", "good")
end

local function spawnItem()
	local def = roll()
	local model = VerityFactory.Build(def.Id, { ShowPrice = true })
	local item = { Def = def, Model = model, X = belt.StartX, Phase = math.random() * math.pi * 2, Taken = false }
	model:PivotTo(itemCFrame(item))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Купить за " .. Format.Money(def.Price)
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		Conveyor.Buy(player, item)
	end)
	prompt.Parent = model.PrimaryPart

	model.Parent = folder
	table.insert(items, item)

	if def.RarityInfo.Order >= ANNOUNCE_FROM_ORDER then
		Remotes.All("✨ На конвейере: " .. def.Name .. " (" .. def.RarityInfo.Name .. ")!", "rare")
	end
end

function Conveyor.Init(world, injected)
	belt = world.Belt
	deps = injected

	for _, def in Config.Verities do
		totalWeight += def.Weight
	end

	folder = Instance.new("Folder")
	folder.Name = "ConveyorItems"
	folder.Parent = workspace

	task.spawn(function()
		while true do
			spawnItem()
			task.wait(Config.ConveyorSpawnInterval)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for i = #items, 1, -1 do
			local item = items[i]
			if item.Taken then
				table.remove(items, i)
			else
				item.X += Config.ConveyorSpeed * dt
				if item.X > belt.EndX then
					item.Model:Destroy()
					table.remove(items, i)
				else
					item.Model:PivotTo(itemCFrame(item))
				end
			end
		end
	end)
end

return Conveyor
