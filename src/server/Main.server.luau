-- Точка входа сервера: собирает мир и связывает системы между собой.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = require(script.Parent.Remotes)
local Data = require(script.Parent.Data)
local World = require(script.Parent.World)
local Bases = require(script.Parent.Bases)
local Conveyor = require(script.Parent.Conveyor)
local Stealing = require(script.Parent.Stealing)
local Combat = require(script.Parent.Combat)

-- Персонажей создаём сами, чтобы игрок сразу появлялся на своей базе.
Players.CharacterAutoLoads = false

local world = World.Build()
Bases.Init(world, {
	Data = Data,
	OnSteal = function(player, base, slot, model)
		Stealing.TrySteal(player, base, slot, model)
	end,
})
Stealing.Init({ Bases = Bases })
Conveyor.Init(world, { Bases = Bases, Data = Data })
Combat.Init({ Stealing = Stealing })

Remotes.LockBaseEvent.OnServerEvent:Connect(function(player)
	Bases.Lock(player)
end)

local function onCharacterAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid")
	Combat.GiveTool(player)
	humanoid.Died:Connect(function()
		Stealing.Drop(player)
		task.wait(Players.RespawnTime)
		if player.Parent then
			player:LoadCharacter()
		end
	end)
end

local function onPlayerAdded(player)
	Data.Load(player)
	if not player.Parent then
		Data.Release(player)
		return
	end

	local base = Bases.Assign(player)
	if not base then
		player:Kick("Сервер заполнен, попробуй зайти на другой!")
		Data.Release(player)
		return
	end

	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	player:LoadCharacter()
end

local function onPlayerRemoving(player)
	-- Порядок важен: сначала возвращаем добычу, потом освобождаем базу, потом сохраняем.
	Stealing.Drop(player)
	Bases.Release(player)
	Data.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	Stealing.DropAll()
	if RunService:IsStudio() then
		Data.SaveAll()
		return
	end
	-- На реальном сервере PlayerRemoving сам сохранит каждого; даём ему время.
	local deadline = os.clock() + 20
	while #Players:GetPlayers() > 0 and os.clock() < deadline do
		task.wait(0.2)
	end
end)
