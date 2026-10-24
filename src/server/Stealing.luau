-- Кража: вор забирает Verity с чужой базы и должен донести его до своей.
-- Если вора шлёпнули, он умер или вышел, Verity возвращается хозяину.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(script.Parent.Remotes)
local VerityFactory = require(script.Parent.VerityFactory)

local Stealing = {}

local deps = {} -- Bases
local carrying = {} -- [Player] = { Id, Model, FromUserId, FromSlot, WarnedFull }

local function humanoidOf(player)
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
end

local function inside(base, position)
	local rel = base.Origin:PointToObjectSpace(position)
	return math.abs(rel.X) < 22 and math.abs(rel.Z) < 22 and rel.Y > -2 and rel.Y < 20
end

local function attachCarry(char, hrp, id)
	local model = VerityFactory.Build(id)
	model:ScaleTo(0.6)
	model:PivotTo(hrp.CFrame * CFrame.new(0, 4.2, 0))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.Massless = true
			d.CanCollide = false
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = char
	return model
end

function Stealing.Init(injected)
	deps = injected

	-- Проверяем доставку добычи и живых воров.
	task.spawn(function()
		while true do
			task.wait(0.2)
			for thief, carry in carrying do
				local hum, hrp = humanoidOf(thief)
				if not hum or hum.Health <= 0 or not hrp then
					Stealing.Drop(thief)
				else
					local base = deps.Bases.OfPlayer(thief)
					if base and inside(base, hrp.Position) then
						local slot = deps.Bases.FreeSlot(base)
						if slot then
							carrying[thief] = nil
							carry.Model:Destroy()
							hum.WalkSpeed = Config.WalkSpeed
							thief:SetAttribute("Carrying", nil)
							deps.Bases.PlaceVerity(base, slot, carry.Id)
							Remotes.To(thief, "🎉 Ты украл " .. Config.ById[carry.Id].Name .. "!", "good")
						elseif not carry.WarnedFull then
							carry.WarnedFull = true
							Remotes.To(thief, "Нет места на базе! Продай кого-нибудь (F).", "bad")
						end
					end
				end
			end
		end
	end)
end

function Stealing.IsCarrying(player)
	return carrying[player] ~= nil
end

function Stealing.TrySteal(thief, base, slot, model)
	local hum, hrp = humanoidOf(thief)
	if not hum or hum.Health <= 0 or not hrp then
		return
	end
	if carrying[thief] then
		Remotes.To(thief, "Ты уже несёшь Verity! Беги на свою базу.", "bad")
		return
	end
	local victim = base.Owner
	if not victim or victim == thief then
		return
	end
	if base.Locked then
		Remotes.To(thief, "🔒 База защищена!", "bad")
		return
	end
	local entry = base.Placed[slot]
	if not entry or entry.Model ~= model then
		return
	end
	if (hrp.Position - model:GetPivot().Position).Magnitude > 20 then
		return
	end
	local myBase = deps.Bases.OfPlayer(thief)
	if not myBase or not deps.Bases.FreeSlot(myBase) then
		Remotes.To(thief, "Освободи место на своей базе, чтобы украсть!", "bad")
		return
	end

	local id = deps.Bases.RemoveVerity(base, slot)
	local def = Config.ById[id]
	carrying[thief] = {
		Id = id,
		Model = attachCarry(thief.Character, hrp, id),
		FromUserId = victim.UserId,
		FromSlot = slot,
	}
	thief:SetAttribute("Carrying", id)
	hum.WalkSpeed = Config.CarrySpeed

	Remotes.To(thief, "Ты схватил " .. def.Name .. "! Беги на свою базу!", "good")
	Remotes.To(victim, "⚠️ " .. thief.DisplayName .. " украл твоего " .. def.Name .. "! Догони и шлёпни!", "alert")
end

-- Вор потерял добычу: Verity возвращается хозяину, если он ещё в игре и есть место.
function Stealing.Drop(thief)
	local carry = carrying[thief]
	if not carry then
		return
	end
	carrying[thief] = nil
	carry.Model:Destroy()
	thief:SetAttribute("Carrying", nil)
	local hum = humanoidOf(thief)
	if hum then
		hum.WalkSpeed = Config.WalkSpeed
	end

	local def = Config.ById[carry.Id]
	Remotes.To(thief, "Ты потерял " .. def.Name .. "!", "bad")

	local owner = Players:GetPlayerByUserId(carry.FromUserId)
	local ownerBase = owner and deps.Bases.OfPlayer(owner)
	if not ownerBase then
		return
	end
	local slot = carry.FromSlot
	if ownerBase.Placed[slot] then
		slot = deps.Bases.FreeSlot(ownerBase)
	end
	if slot and deps.Bases.PlaceVerity(ownerBase, slot, carry.Id) then
		Remotes.To(owner, "✅ " .. def.Name .. " вернулся на твою базу!", "good")
	end
end

function Stealing.DropAll()
	for thief in carrying do
		Stealing.Drop(thief)
	end
end

return Stealing
