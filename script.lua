local player = game.Players.LocalPlayer
local workspace = game.Workspace

-- Путь, куда будут спавниться питомцы
local spawnPosition = Vector3.new(0, 5, 0)

-- Список питомцев для спавна (замени на реальные модели из игры)
local petsToSpawn = {
    "DarkWolf",
    "ShadowDragon",
    "NightCat"
}

-- Функция для создания эффекта спавна
local function spawnEffect(position)
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.5
    part.Size = Vector3.new(5, 1, 5)
    part.Position = position
    part.BrickColor = BrickColor.new("Really black")
    part.Material = Enum.Material.Neon
    part.Parent = workspace

    game.Debris:AddItem(part, 3) -- удалит часть через 3 секунды

    -- Добавляем свет
    local light = Instance.new("PointLight", part)
    light.Color = Color3.new(0, 0, 0)
    light.Range = 15
    light.Brightness = 2
end

-- Функция спавна питомца
local function spawnPet(petName)
    -- Здесь нужно получить модель питомца из ReplicatedStorage или другого места
    local petsStorage = game:GetService("ReplicatedStorage"):FindFirstChild("Pets")
    if not petsStorage then
        warn("Питомцы не найдены в ReplicatedStorage.Pets")
        return
    end

    local petModel = petsStorage:FindFirstChild(petName)
    if not petModel then
        warn("Питомец " .. petName .. " не найден")
        return
    end

    local petClone = petModel:Clone()
    petClone.Parent = workspace
    petClone:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

    spawnEffect(spawnPosition)
    print("Питомец " .. petName .. " заспавнен!")
end

-- Пример: спавним первого питомца из списка
spawnPet(petsToSpawn[1])
