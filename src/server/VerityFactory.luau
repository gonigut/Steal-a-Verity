-- Собирает модель Verity из обычных частей: милый шарик с глазками и ножками.
-- Лицо модели смотрит в -Z. Корневая часть (Body) заякорена, остальное приварено к ней.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local VerityFactory = {}

-- Расстояние от центра тела до низа ножек: так модель встаёт на пол.
VerityFactory.FeetOffset = 2.5

local function addPart(model, body, name, shape, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.Anchored = false
	part.CFrame = body.CFrame * CFrame.new(offset)
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function addLabelLine(parent, text, color, order, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height)
	label.LayoutOrder = order
	label.Font = Enum.Font.GothamBold
	label.TextSize = height - 2
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = parent
end

local function addInfo(body, def, showPrice)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(200, showPrice and 90 or 66)
	gui.StudsOffset = Vector3.new(0, 3.8, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = gui

	addLabelLine(gui, def.RarityInfo.Name, def.RarityInfo.Color, 1, 20)
	addLabelLine(gui, def.Name, Color3.new(1, 1, 1), 2, 22)
	addLabelLine(gui, Format.Money(def.Income) .. "/сек", Color3.fromRGB(120, 255, 140), 3, 22)
	if showPrice then
		addLabelLine(gui, "Цена: " .. Format.Money(def.Price), Color3.fromRGB(255, 225, 120), 4, 22)
	end
	gui.Parent = body
end

-- options.ShowPrice — показывать цену (для конвейера)
function VerityFactory.Build(id, options)
	options = options or {}
	local def = Config.ById[id]
	assert(def, "Unknown verity id: " .. tostring(id))

	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("VerityId", def.Id)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(4, 4, 4)
	body.Color = def.Color
	body.Material = def.Rainbow and Enum.Material.Neon or Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.Anchored = true
	body.CFrame = CFrame.new()
	body.Parent = model
	model.PrimaryPart = body

	if def.Rainbow then
		CollectionService:AddTag(body, "RainbowPart")
	end

	local white = Color3.new(1, 1, 1)
	local black = Color3.fromRGB(20, 20, 25)
	local footColor = def.Color:Lerp(Color3.new(0, 0, 0), 0.25)
	local ball = Enum.PartType.Ball
	local block = Enum.PartType.Block

	for _, side in { -1, 1 } do
		addPart(model, body, "Eye", ball, Vector3.new(1.1, 1.1, 1.1), Vector3.new(0.75 * side, 0.6, -1.7), white)
		addPart(model, body, "Pupil", ball, Vector3.new(0.55, 0.55, 0.55), Vector3.new(0.75 * side, 0.6, -2.15), black)
		addPart(model, body, "Foot", ball, Vector3.new(1.4, 1.4, 1.4), Vector3.new(0.9 * side, -1.8, -0.4), footColor)
	end
	addPart(model, body, "Mouth", block, Vector3.new(0.9, 0.18, 0.1), Vector3.new(0, -0.35, -1.95), black)

	addInfo(body, def, options.ShowPrice == true)
	return model
end

return VerityFactory
