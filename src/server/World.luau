-- Строит карту кодом: земля, конвейер посередине и 8 баз (по 4 с каждой стороны).
-- В локальной системе базы +Z — это "перед" (сторона, обращённая к конвейеру).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local World = {}

local BASE_SIZE = 44
local WALL_HEIGHT = 12
local GATE_WIDTH = 14
local BELT_HALF_LENGTH = 130
local BELT_WIDTH = 12

local BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 170, 90),
	Color3.fromRGB(250, 225, 90),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(90, 210, 220),
	Color3.fromRGB(110, 150, 255),
	Color3.fromRGB(180, 120, 255),
	Color3.fromRGB(255, 130, 200),
}

local function makePart(parent, name, size, cframe, color, material, transparency, collide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.CanCollide = collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addBillboard(adornee, text, offsetY, width, height)
	local gui = Instance.new("BillboardGui")
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	return label
end

local function buildBase(parent, index, origin, color)
	local model = Instance.new("Model")
	model.Name = "Base" .. index
	model.Parent = parent

	local function at(x, y, z)
		return origin * CFrame.new(x, y, z)
	end

	local wallColor = color:Lerp(Color3.new(1, 1, 1), 0.45)
	local half = BASE_SIZE / 2
	local wallY = 1 + WALL_HEIGHT / 2
	local frontWidth = (BASE_SIZE - GATE_WIDTH) / 2

	makePart(model, "Floor", Vector3.new(BASE_SIZE, 1, BASE_SIZE), at(0, 0.5, 0), color)
	makePart(model, "WallBack", Vector3.new(BASE_SIZE, WALL_HEIGHT, 1), at(0, wallY, -half + 0.5), wallColor)
	makePart(model, "WallLeft", Vector3.new(1, WALL_HEIGHT, BASE_SIZE), at(-half + 0.5, wallY, 0), wallColor)
	makePart(model, "WallRight", Vector3.new(1, WALL_HEIGHT, BASE_SIZE), at(half - 0.5, wallY, 0), wallColor)
	makePart(model, "WallFrontL", Vector3.new(frontWidth, WALL_HEIGHT, 1), at(-(GATE_WIDTH + frontWidth) / 2, wallY, half - 0.5), wallColor)
	makePart(model, "WallFrontR", Vector3.new(frontWidth, WALL_HEIGHT, 1), at((GATE_WIDTH + frontWidth) / 2, wallY, half - 0.5), wallColor)

	-- Ворота: невидимы и проходимы, пока защита выключена.
	local gate = makePart(
		model,
		"Gate",
		Vector3.new(GATE_WIDTH, WALL_HEIGHT, 1),
		at(0, wallY, half - 0.5),
		Color3.fromRGB(255, 70, 70),
		Enum.Material.Neon,
		1,
		false
	)

	-- Табличка с именем хозяина над воротами (видна снаружи).
	local sign = makePart(model, "Sign", Vector3.new(18, 4, 1), at(0, 15, half - 0.5), Color3.fromRGB(35, 35, 45))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Font = Enum.Font.GothamBlack
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Text = "Свободно"
	signLabel.Parent = surface

	-- Места для Verity.
	local slotCFrames = {}
	for i = 1, Config.SlotCount do
		local col = (i - 1) % Config.SlotColumns
		local row = (i - 1) // Config.SlotColumns
		local x = -16 + col * 8
		local z = -13 + row * 10
		makePart(model, "Slot" .. i, Vector3.new(6, 0.4, 6), at(x, 1.2, z), Color3.fromRGB(235, 235, 240))
		-- Вращаем на 180°, чтобы лицо Verity смотрело на ворота.
		slotCFrames[i] = at(x, 1.4 + 2.5, z) * CFrame.Angles(0, math.pi, 0)
	end

	-- Касса: сюда стекается доход, надо наступить, чтобы забрать.
	local collectPad = makePart(model, "CollectPad", Vector3.new(10, 0.4, 6), at(-12, 1.2, 13), Color3.fromRGB(80, 220, 120), Enum.Material.Neon)
	local stashLabel = addBillboard(collectPad, "💰 КАССА\n$0", 4, 200, 70)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = at(12, 1.5, 13)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 0.6
	spawn.Color = Color3.fromRGB(255, 255, 255)
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = model

	return {
		Index = index,
		Origin = origin,
		Model = model,
		Gate = gate,
		SignLabel = signLabel,
		SlotCFrames = slotCFrames,
		CollectPad = collectPad,
		StashLabel = stashLabel,
		SpawnLocation = spawn,
	}
end

function World.Build()
	local root = Instance.new("Folder")
	root.Name = "World"
	root.Parent = workspace

	Lighting.ClockTime = 14
	Lighting.Brightness = 2

	makePart(root, "Ground", Vector3.new(420, 1, 220), CFrame.new(0, -0.5, 0), Color3.fromRGB(110, 190, 110), Enum.Material.Grass)

	-- Конвейер: верх на высоте y = 1.
	local belt = makePart(root, "Belt", Vector3.new(BELT_HALF_LENGTH * 2 + 20, 1, BELT_WIDTH), CFrame.new(0, 0.5, 0), Color3.fromRGB(60, 60, 68), Enum.Material.Metal)
	belt.Name = "Belt"
	for _, side in { -1, 1 } do
		makePart(root, "BeltStripe", Vector3.new(BELT_HALF_LENGTH * 2 + 20, 0.2, 0.6), CFrame.new(0, 1.05, side * (BELT_WIDTH / 2 - 0.5)), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, 0, false)
	end

	local bases = {}
	local xs = { -90, -30, 30, 90 }
	for i, x in xs do
		-- Северный ряд: перед (+Z) смотрит на конвейер.
		table.insert(bases, buildBase(root, i, CFrame.new(x, 0, -45), BASE_COLORS[i]))
	end
	for i, x in xs do
		-- Южный ряд развёрнут на 180°.
		table.insert(bases, buildBase(root, i + 4, CFrame.new(x, 0, 45) * CFrame.Angles(0, math.pi, 0), BASE_COLORS[i + 4]))
	end

	return {
		Bases = bases,
		Belt = {
			StartX = -BELT_HALF_LENGTH,
			EndX = BELT_HALF_LENGTH,
			Z = 0,
			TopY = 1,
		},
	}
end

return World
