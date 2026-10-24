-- Все настройки баланса игры в одном месте.
local Config = {}

Config.StartMoney = 100
Config.SlotCount = 10 -- мест для Verity на базе
Config.SlotColumns = 5
Config.SellRatio = 0.5 -- сколько цены возвращается при продаже

Config.ConveyorSpeed = 12 -- студов в секунду
Config.ConveyorSpawnInterval = 3 -- секунд между появлением Verity

Config.WalkSpeed = 16
Config.CarrySpeed = 12 -- скорость вора с добычей
Config.StealHoldSeconds = 2 -- сколько держать кнопку, чтобы украсть

Config.SlapCooldown = 1.5
Config.SlapRange = 9
Config.StunSeconds = 1.5

Config.LockDuration = 30 -- сколько секунд работает защита базы
Config.LockCooldown = 45 -- перезарядка защиты после её окончания

Config.Rarities = {
	Common = { Name = "Обычный", Color = Color3.fromRGB(205, 205, 205), Order = 1 },
	Uncommon = { Name = "Необычный", Color = Color3.fromRGB(110, 225, 110), Order = 2 },
	Rare = { Name = "Редкий", Color = Color3.fromRGB(80, 165, 255), Order = 3 },
	Epic = { Name = "Эпический", Color = Color3.fromRGB(195, 105, 255), Order = 4 },
	Legendary = { Name = "Легендарный", Color = Color3.fromRGB(255, 205, 50), Order = 5 },
	Mythic = { Name = "Мифический", Color = Color3.fromRGB(255, 85, 125), Order = 6 },
	Secret = { Name = "СЕКРЕТНЫЙ", Color = Color3.fromRGB(255, 255, 255), Order = 7 },
}

-- Price — цена на конвейере, Income — доход в секунду, Weight — шанс появления (больше = чаще).
Config.Verities = {
	{ Id = "red", Name = "Красный Verity", Color = Color3.fromRGB(235, 64, 52), Rarity = "Common", Price = 50, Income = 2, Weight = 25 },
	{ Id = "blue", Name = "Синий Verity", Color = Color3.fromRGB(52, 120, 235), Rarity = "Common", Price = 80, Income = 3, Weight = 25 },
	{ Id = "green", Name = "Зелёный Verity", Color = Color3.fromRGB(60, 200, 90), Rarity = "Uncommon", Price = 250, Income = 8, Weight = 15 },
	{ Id = "yellow", Name = "Жёлтый Verity", Color = Color3.fromRGB(250, 220, 50), Rarity = "Uncommon", Price = 400, Income = 12, Weight = 12 },
	{ Id = "orange", Name = "Оранжевый Verity", Color = Color3.fromRGB(255, 150, 40), Rarity = "Rare", Price = 1500, Income = 40, Weight = 8 },
	{ Id = "purple", Name = "Фиолетовый Verity", Color = Color3.fromRGB(150, 80, 230), Rarity = "Rare", Price = 2500, Income = 65, Weight = 6 },
	{ Id = "pink", Name = "Розовый Verity", Color = Color3.fromRGB(255, 130, 200), Rarity = "Epic", Price = 10000, Income = 220, Weight = 4 },
	{ Id = "black", Name = "Чёрный Verity", Color = Color3.fromRGB(35, 35, 40), Rarity = "Epic", Price = 20000, Income = 400, Weight = 2.5 },
	{ Id = "gold", Name = "Золотой Verity", Color = Color3.fromRGB(255, 200, 40), Rarity = "Legendary", Price = 100000, Income = 2000, Weight = 1.5 },
	{ Id = "ice", Name = "Ледяной Verity", Color = Color3.fromRGB(90, 230, 250), Rarity = "Mythic", Price = 500000, Income = 11000, Weight = 0.8 },
	{ Id = "rainbow", Name = "Радужный Verity", Color = Color3.fromRGB(255, 255, 255), Rarity = "Secret", Price = 5000000, Income = 150000, Weight = 0.2, Rainbow = true },
}

Config.ById = {}
for _, def in Config.Verities do
	def.RarityInfo = Config.Rarities[def.Rarity]
	Config.ById[def.Id] = def
end

return Config
