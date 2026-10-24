local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = ReplicatedStorage

local function make(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

Remotes.NotifyEvent = make("Notify") -- сервер -> клиент: (text, kind)
Remotes.LockBaseEvent = make("LockBase") -- клиент -> сервер: включить защиту базы

-- kind: "info" | "good" | "bad" | "alert" | "rare"
function Remotes.To(player, text, kind)
	Remotes.NotifyEvent:FireClient(player, text, kind or "info")
end

function Remotes.All(text, kind)
	Remotes.NotifyEvent:FireAllClients(text, kind or "info")
end

return Remotes
