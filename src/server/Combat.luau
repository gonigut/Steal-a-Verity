-- Шлёпалка: ближайший игрок рядом роняет добычу и на секунду замирает.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(script.Parent.Remotes)

local Combat = {}

local deps = {} -- Stealing
local lastSlap = {} -- [Player] = os.clock()
local stunToken = {} -- [Player] = number

local function stun(target)
	local char = target.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local token = (stunToken[target] or 0) + 1
	stunToken[target] = token
	hum.WalkSpeed = 0
	hum.JumpHeight = 0
	task.delay(Config.StunSeconds, function()
		if stunToken[target] ~= token or not hum.Parent then
			return
		end
		hum.WalkSpeed = deps.Stealing.IsCarrying(target) and Config.CarrySpeed or Config.WalkSpeed
		hum.JumpHeight = 7.2
	end)
end

local function nearestTarget(player, hrp)
	local best, bestDistance = nil, Config.SlapRange
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			local otherHum = other.Character:FindFirstChildOfClass("Humanoid")
			if otherRoot and otherHum and otherHum.Health > 0 then
				local distance = (otherRoot.Position - hrp.Position).Magnitude
				if distance <= bestDistance then
					best, bestDistance = other, distance
				end
			end
		end
	end
	return best
end

local function makeTool()
	local tool = Instance.new("Tool")
	tool.Name = "Шлёпалка"
	tool.ToolTip = "Шлёпни вора, чтобы он выронил Verity!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 3.5)
	handle.Color = Color3.fromRGB(255, 120, 190)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	tool.Activated:Connect(function()
		local char = tool.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not player or not hrp then
			return
		end

		local now = os.clock()
		if now - (lastSlap[player] or 0) < Config.SlapCooldown then
			return
		end
		lastSlap[player] = now

		local target = nearestTarget(player, hrp)
		if not target then
			return
		end
		deps.Stealing.Drop(target)
		stun(target)
		Remotes.To(target, "💥 " .. player.DisplayName .. " тебя шлёпнул!", "alert")
	end)

	return tool
end

function Combat.Init(injected)
	deps = injected
	Players.PlayerRemoving:Connect(function(player)
		lastSlap[player] = nil
		stunToken[player] = nil
	end)
end

function Combat.GiveTool(player)
	local backpack = player:WaitForChild("Backpack")
	if not backpack:FindFirstChild("Шлёпалка") then
		makeTool().Parent = backpack
	end
end

return Combat
