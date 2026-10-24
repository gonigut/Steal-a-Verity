-- Интерфейс: деньги, доход, кнопка защиты базы, плашка «несёшь добычу» и уведомления.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared:WaitForChild("Config"))
local Format = require(ReplicatedStorage.Shared:WaitForChild("Format"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local KIND_COLORS = {
	info = Color3.fromRGB(235, 235, 245),
	good = Color3.fromRGB(120, 255, 140),
	bad = Color3.fromRGB(255, 130, 120),
	alert = Color3.fromRGB(255, 190, 70),
	rare = Color3.fromRGB(255, 225, 90),
}

local function make(className, props, children)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function stroke(thickness)
	return make("UIStroke", { Thickness = thickness, Color = Color3.new(0, 0, 0) })
end

local gui = make("ScreenGui", { Name = "VerityHUD", ResetOnSpawn = false, Parent = playerGui })

local moneyLabel = make("TextLabel", {
	Name = "Money",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(280, 50),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(120, 255, 140),
	Text = "$0",
	Parent = gui,
}, { stroke(2.5) })

local incomeLabel = make("TextLabel", {
	Name = "Income",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 58),
	Size = UDim2.fromOffset(220, 24),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "+$0/сек",
	Parent = gui,
}, { stroke(1.5) })

local carryLabel = make("TextLabel", {
	Name = "Carry",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 86),
	Size = UDim2.fromOffset(420, 30),
	BackgroundColor3 = Color3.fromRGB(200, 40, 40),
	BackgroundTransparency = 0.2,
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
	Visible = false,
	Parent = gui,
}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })

local toastHolder = make("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 124),
	Size = UDim2.fromOffset(420, 200),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local lockButton = make("TextButton", {
	Name = "Lock",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(160, 56),
	BackgroundColor3 = Color3.fromRGB(60, 140, 255),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextWrapped = true,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "🔒 Защитить базу",
	AutoButtonColor = true,
	Parent = gui,
}, { make("UICorner", { CornerRadius = UDim.new(0, 12) }), stroke(2) })

lockButton.Activated:Connect(function()
	Remotes.LockBase:FireServer()
end)

local function refreshMoney()
	moneyLabel.Text = Format.Money(player:GetAttribute("Money") or 0)
end

local function refreshIncome()
	incomeLabel.Text = "+" .. Format.Money(player:GetAttribute("Income") or 0) .. "/сек"
end

local function refreshCarry()
	local def = Config.ById[player:GetAttribute("Carrying")]
	carryLabel.Visible = def ~= nil
	if def then
		carryLabel.Text = "Ты несёшь: " .. def.Name .. "! Беги на свою базу! 🏃"
	end
end

player:GetAttributeChangedSignal("Money"):Connect(refreshMoney)
player:GetAttributeChangedSignal("Income"):Connect(refreshIncome)
player:GetAttributeChangedSignal("Carrying"):Connect(refreshCarry)
refreshMoney()
refreshIncome()
refreshCarry()

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	elapsed = 0

	local now = workspace:GetServerTimeNow()
	local lockUntil = player:GetAttribute("LockUntil") or 0
	local readyAt = player:GetAttribute("LockReadyAt") or 0
	if now < lockUntil then
		lockButton.Text = string.format("🔒 Защита: %dс", math.ceil(lockUntil - now))
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 200, 110)
	elseif now < readyAt then
		lockButton.Text = string.format("Заряжается: %dс", math.ceil(readyAt - now))
		lockButton.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
	else
		lockButton.Text = "🔒 Защитить базу"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
	end
end)

Remotes.Notify.OnClientEvent:Connect(function(text, kind)
	local label = make("TextLabel", {
		Size = UDim2.new(0, 420, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(20, 20, 30),
		BackgroundTransparency = 0.25,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextWrapped = true,
		TextColor3 = KIND_COLORS[kind] or KIND_COLORS.info,
		Text = text,
		Parent = toastHolder,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 8) }),
		make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }),
	})

	task.delay(4, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		label:Destroy()
	end)
end)
