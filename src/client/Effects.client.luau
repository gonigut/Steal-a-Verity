-- Радужный Verity переливается всеми цветами (локально, без нагрузки на сервер).
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local rainbowParts = {}

local function track(part)
	rainbowParts[part] = true
end

for _, part in CollectionService:GetTagged("RainbowPart") do
	track(part)
end
CollectionService:GetInstanceAddedSignal("RainbowPart"):Connect(track)
CollectionService:GetInstanceRemovedSignal("RainbowPart"):Connect(function(part)
	rainbowParts[part] = nil
end)

RunService.RenderStepped:Connect(function()
	local color = Color3.fromHSV((os.clock() * 0.3) % 1, 0.75, 1)
	for part in rainbowParts do
		if part.Parent then
			part.Color = color
		else
			rainbowParts[part] = nil
		end
	end
end)
