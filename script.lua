-- Улучшенный скрипт спавна питомцев для Roblox
-- Функции:
--   spawnPet(petName)   - спавнит питомца по имени (если разрешено и модель найдена)
--   spawnEffect(position) - создаёт визуальный эффект спавна
-- Конфигурация:
--   allowedPlaceIds - список PlaceId, на которых разрешён спавн; пустой = разрешён везде

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

-- Конфиг: позиция спавна и список питомцев
local spawnPosition = Vector3.new(0, 5, 0)
local petsToSpawn = {
    "DarkWolf",
    "ShadowDragon",
    "NightCat"
}

-- Whitelist карт: если пустой, то разрешены все карты.
local allowedPlaceIds = {
    -- [12345678] = true, -- пример: включите конкретные PlaceId, если нужно
}

-- Вспомог: проверка, разрешён ли спавн на текущей карте
local function isPlaceAllowed()
    if next(allowedPlaceIds) == nil then
        return true -- пустой список = разрешены все карты
    end
    local placeId = game.PlaceId
    return allowedPlaceIds[placeId] == true
end

-- Эффект спавна (безопасно создаём экземпляры)
local function spawnEffect(position)
    local success, err = pcall(function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.5
        part.Size = Vector3.new(5, 1, 5)
        part.Position = position
        part.BrickColor = BrickColor.new("Really black")
        part.Material = Enum.Material.Neon
        part.Parent = Workspace

        Debris:AddItem(part, 3)

        local light = Instance.new("PointLight")
        light.Parent = part
        light.Color = Color3.fromRGB(0, 0, 0)
        light.Range = 15
        light.Brightness = 2
    end)
    if not success then
        warn("spawnEffect error: " .. tostring(err))
    end
end

-- Спавн одного питомца по имени
local function spawnPet(petName)
    if not isPlaceAllowed() then
        warn("Спавн питомцев запрещён на этой карте (PlaceId = " .. tostring(game.PlaceId) .. ")")
        return false, "place_not_allowed"
    end

    if typeof(petName) ~= "string" or petName == "" then
        warn("Неверное имя питомца")
        return false, "invalid_name"
    end

    local petsStorage = ReplicatedStorage:FindFirstChild("Pets")
    if not petsStorage then
        warn("ReplicatedStorage.Pets не найден")
        return false, "pets_storage_missing"
    end

    local petModel = petsStorage:FindFirstChild(petName)
    if not petModel then
        warn("Питомец '" .. petName .. "' не найден в ReplicatedStorage.Pets")
        return false, "pet_not_found"
    end

    local petClone = petModel:Clone()
    if not petClone then
        warn("Не удалось клонировать модель питомца: " .. petName)
        return false, "clone_failed"
    end

    -- Попытка установить PrimaryPart; если его нет - ищем коробку-центр или ставим модель на позицию без SetPrimaryPartCFrame
    local success, err = pcall(function()
        petClone.Parent = Workspace
        if petClone.PrimaryPart then
            -- Поднимаем по высоте, чтобы питомец не застрял в земле
            local offset = Vector3.new(0, (petClone.PrimaryPart.Size.Y / 2) + 0.5, 0)
            petClone:SetPrimaryPartCFrame(CFrame.new(spawnPosition + offset))
        else
            -- Попытка найти первую деталь и поместить её
            local firstPart = nil
            for _, descendant in ipairs(petClone:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    firstPart = descendant
                    break
                end
            end
            if firstPart then
                firstPart.Position = spawnPosition
            else
                warn("У модели питомца нет частей (BasePart), позиция не установлена.")
            end
        end
    end)

    if not success then
        warn("Ошибка при позиционировании питомца: " .. tostring(err))
        -- Вы всё ещё добавили модель в Workspace; можно удалить при ошибке
        if petClone and petClone.Parent == Workspace then
            petClone:Destroy()
        end
        return false, "positioning_failed"
    end

    spawnEffect(spawnPosition)
    print("Питомец " .. petName .. " заспавнен!")
    return true
end

-- Пример: спавним всех питомцев из списка по очереди (с небольшой задержкой)
spawn(function()
    for _, name in ipairs(petsToSpawn) do
        local ok, reason = spawnPet(name)
        if not ok then
            warn("Не удалось заспавнить " .. tostring(name) .. ": " .. tostring(reason))
        end
        wait(0.5)
    end
end)
