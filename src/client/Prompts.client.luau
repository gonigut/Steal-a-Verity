-- Показываем «Украсть» только чужим Verity на незащищённых базах, а «Продать» — только своим.
-- Это лишь удобство интерфейса: все проверки всё равно делает сервер.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function refresh(prompt)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local mine = model:GetAttribute("OwnerId") == player.UserId
	local locked = model:GetAttribute("Locked") == true
	local kind = prompt:GetAttribute("Kind")

	local want
	if kind == "Steal" then
		want = not mine and not locked
	elseif kind == "Sell" then
		want = mine
	else
		return
	end

	if prompt.Enabled ~= want then
		prompt.Enabled = want
	end
end

local function setup(prompt)
	task.defer(function()
		refresh(prompt)
		local model = prompt:FindFirstAncestorOfClass("Model")
		if not model then
			return
		end
		-- Сервер мог перезаписать Enabled — применяем своё значение снова.
		prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
			refresh(prompt)
		end)
		model:GetAttributeChangedSignal("Locked"):Connect(function()
			refresh(prompt)
		end)
		model:GetAttributeChangedSignal("OwnerId"):Connect(function()
			refresh(prompt)
		end)
	end)
end

for _, prompt in CollectionService:GetTagged("VerityPrompt") do
	setup(prompt)
end
CollectionService:GetInstanceAddedSignal("VerityPrompt"):Connect(setup)
