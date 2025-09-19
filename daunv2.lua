-- Gabungan dari Skrip Anti-Cheat dan Auto-Summit
-- Skrip ini menggabungkan fitur anti-cheat, teleportasi otomatis, dan fitur tambahan lainnya.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ====================================
-- ANTI-CHEAT DESTROYER
-- ====================================
-- Menghancurkan LocalScript anti-cheat yang ditemukan
local function antiCheatDestroyer()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") and v.Name:lower():find("anticheat") then
            warn("[ANTI-AC] Destroyed: " .. v.Name)
            v:Destroy()
        end
    end
    print("[ANTI-AC] Protection Enabled!")
end

-- Jalankan setiap beberapa detik untuk perlindungan terus-menerus
task.spawn(function()
    while task.wait(5) do
        antiCheatDestroyer()
    end
end)

-- ====================================
-- AUTO SUMMIT & EXTRA FEATURES
-- ====================================
-- Cari root part
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or nil
end

-- Daftar checkpoint
local checkpoints = {
    {name = "Basecamp", pos = Vector3.new(-7.21, 13.11, -9.01)},
    {name = "CP 1",     pos = Vector3.new(-621.72, 249.48, -383.89)},
    {name = "CP 2",     pos = Vector3.new(-1203.19, 260.84, -487.08)},
    {name = "CP 3",     pos = Vector3.new(-1399.29, 577.59, -949.93)},
    {name = "CP 4",     pos = Vector3.new(-1701.05, 815.79, -1399.99)},
    {name = "Summit",   pos = Vector3.new(-3234.00, 1713.83, -2584.00)},
}

-- === CP UI Integration ===
local function getCheckpointFromUI()
    local label = player:WaitForChild("PlayerGui")
        :WaitForChild("CheckpointHUD")
        :WaitForChild("CheckpointContainer")
        :WaitForChild("CheckpointLabel")

    if label and label:IsA("TextLabel") then
        local plainText = label.Text:gsub("<.->", "")
        local cpNum = tonumber(plainText:match("(%d+)"))
        return cpNum or 0
    end
    return 0
end

-- State CP terakhir
local lastCheckpointIndex = 1

-- GUI indikator
local statusLabel
local function updateStatus()
    if statusLabel then
        statusLabel.Text = "Last CP: " .. checkpoints[lastCheckpointIndex].name
    end
end

-- Teleport
local function teleportTo(vec)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(vec + Vector3.new(0, 8, 0))
    task.wait(0.25)
    root.CFrame = root.CFrame * CFrame.new(0, 0, -1)
    return true
end

-- Climb sekali
local function climbOnce(startIndex)
    startIndex = startIndex or lastCheckpointIndex
    for i = startIndex, #checkpoints do
        local cp = checkpoints[i]
        teleportTo(cp.pos)
        print("[AutoClimb] Teleport ke " .. cp.name)

        local success = false
        local startTime = tick()
        local targetUI = i - 1

        while tick() - startTime < 10 do
            local cpNum = getCheckpointFromUI()
            if cpNum == targetUI then
                success = true
                break
            end
            task.wait(1)
        end

        if success then
            print("[AutoClimb] CP UI terupdate: " .. checkpoints[i].name)
            lastCheckpointIndex = i
            player:SetAttribute("LastCP", lastCheckpointIndex)
            updateStatus()
            task.wait(90)
        else
            warn("[AutoClimb] Timeout tunggu CP UI, berhenti climb.")
            break
        end
    end
    print("[AutoClimb] Selesai.")
end

-- Loop climb
local loopRunning = false
local function loopClimb()
    loopRunning = true
    while loopRunning do
        climbOnce(lastCheckpointIndex)
        if lastCheckpointIndex >= #checkpoints then
            print("[LoopClimb] Sampai Summit, restart dari Basecamp...")
            lastCheckpointIndex = 1
            player:SetAttribute("LastCP", 1)
            updateStatus()
        end
        task.wait(2)
    end
end

-- ====================================
-- AUTO JUMP EDGE
-- ====================================
local AutoJump = false
task.spawn(function()
    while task.wait(0.05) do
        if AutoJump then
            local root = getRoot()
            if root and root.Velocity.Y < -30 then
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.02)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end
        end
    end
end)

-- ====================================
-- AUTO WALK
-- ====================================
local AutoWalk = false
local Checkpoints = {
    [0] = Vector3.new(-7.21, 13.11, -9.01),
    [1] = Vector3.new(-621.72, 249.48, -383.89),
    [2] = Vector3.new(-1203.19, 260.84, -487.08),
    [3] = Vector3.new(-1399.29, 577.59, -949.93),
    [4] = Vector3.new(-1701.05, 815.79, -1399.99),
}

local function getCurrentCP()
    local label = player:WaitForChild("PlayerGui")
        :WaitForChild("CheckpointHUD")
        .CheckpointContainer.CheckpointLabel
    local text = label.Text
    local num = text:match(">(%d+)<")
    return tonumber(num) or 0
end

task.spawn(function()
    while task.wait(1) do
        if AutoWalk then
            local cp = getCurrentCP()
            local target = Checkpoints[cp + 1]
            if target then
                local root = getRoot()
                if root then
                    root.CFrame = CFrame.new(target + Vector3.new(0, 5, 0))
                end
            else
                AutoWalk = false
            end
        end
    end
end)

-- ====================================
-- SPEEDHACK
-- ====================================
local SpeedHack = false
local WalkSpeed = 32

task.spawn(function()
    while task.wait(0.5) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            if SpeedHack then
                char.Humanoid.WalkSpeed = WalkSpeed
            else
                char.Humanoid.WalkSpeed = 16
            end
        end
    end
end)

---
## ANTI FALL DAMAGE
---
local AntiFallDamage = false
local lastHumanoid = nil

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    lastHumanoid = hum
    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Freefall and AntiFallDamage then
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        end
    end)
end)

task.spawn(function()
    while task.wait(0.1) do
        if AntiFallDamage and lastHumanoid and lastHumanoid.Parent and lastHumanoid.Health > 0 then
            lastHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        end
    end
end)

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "AutoSummitMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 335)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Auto Summit Menu"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

-- status label
statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, -20, 0, 24)
statusLabel.Position = UDim2.new(0, 10, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255,255,0)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
updateStatus()

-- tombol Auto Summit (1x)
local summitBtn = Instance.new("TextButton", frame)
summitBtn.Size = UDim2.new(1, -20, 0, 34)
summitBtn.Position = UDim2.new(0, 10, 0, 70)
summitBtn.Text = "Auto Summit (1x)"
summitBtn.BackgroundColor3 = Color3.fromRGB(0,120,0)
summitBtn.TextColor3 = Color3.new(1,1,1)
summitBtn.Font = Enum.Font.SourceSansBold
summitBtn.TextSize = 16
summitBtn.MouseButton1Click:Connect(function()
    spawn(function()
        climbOnce(lastCheckpointIndex)
    end)
end)

-- tombol Loop Climb
local loopBtn = Instance.new("TextButton", frame)
loopBtn.Size = UDim2.new(1, -20, 0, 34)
loopBtn.Position = UDim2.new(0, 10, 0, 110)
loopBtn.Text = "Start Loop Climb"
loopBtn.BackgroundColor3 = Color3.fromRGB(0,80,160)
loopBtn.TextColor3 = Color3.new(1,1,1)
loopBtn.Font = Enum.Font.SourceSansBold
loopBtn.TextSize = 16

loopBtn.MouseButton1Click:Connect(function()
    if loopRunning then
        loopRunning = false
        loopBtn.Text = "Start Loop Climb"
        loopBtn.BackgroundColor3 = Color3.fromRGB(0,80,160)
    else
        loopBtn.Text = "Stop Loop Climb"
        loopBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
        spawn(loopClimb)
    end
end)

-- tombol AutoJump
local jumpBtn = Instance.new("TextButton", frame)
jumpBtn.Size = UDim2.new(1, -20, 0, 30)
jumpBtn.Position = UDim2.new(0, 10, 0, 150)
jumpBtn.Text = "Toggle AutoJump (OFF)"
jumpBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
jumpBtn.TextColor3 = Color3.new(1,1,1)
jumpBtn.Font = Enum.Font.SourceSansBold
jumpBtn.TextSize = 16
jumpBtn.MouseButton1Click:Connect(function()
    AutoJump = not AutoJump
    if AutoJump then
        jumpBtn.Text = "Toggle AutoJump (ON)"
        jumpBtn.BackgroundColor3 = Color3.fromRGB(0,160,0)
    else
        jumpBtn.Text = "Toggle AutoJump (OFF)"
        jumpBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
    end
end)

-- tombol AutoWalk
local walkBtn = Instance.new("TextButton", frame)
walkBtn.Size = UDim2.new(1, -20, 0, 30)
walkBtn.Position = UDim2.new(0, 10, 0, 185)
walkBtn.Text = "Toggle AutoWalk (OFF)"
walkBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
walkBtn.TextColor3 = Color3.new(1,1,1)
walkBtn.Font = Enum.Font.SourceSansBold
walkBtn.TextSize = 16
walkBtn.MouseButton1Click:Connect(function()
    AutoWalk = not AutoWalk
    if AutoWalk then
        walkBtn.Text = "Toggle AutoWalk (ON)"
        walkBtn.BackgroundColor3 = Color3.fromRGB(0,160,0)
    else
        walkBtn.Text = "Toggle AutoWalk (OFF)"
        walkBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
    end
end)

-- tombol SpeedHack
local speedBtn = Instance.new("TextButton", frame)
speedBtn.Size = UDim2.new(1, -20, 0, 30)
speedBtn.Position = UDim2.new(0, 10, 0, 220)
speedBtn.Text = "Toggle SpeedHack (OFF)"
speedBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.Font = Enum.Font.SourceSansBold
speedBtn.TextSize = 16
speedBtn.MouseButton1Click:Connect(function()
    SpeedHack = not SpeedHack
    if SpeedHack then
        speedBtn.Text = "Toggle SpeedHack (ON)"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0,160,0)
    else
        speedBtn.Text = "Toggle SpeedHack (OFF)"
        speedBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
    end
end)

-- tombol Anti Fall Damage
local fallBtn = Instance.new("TextButton", frame)
fallBtn.Size = UDim2.new(1, -20, 0, 30)
fallBtn.Position = UDim2.new(0, 10, 0, 255)
fallBtn.Text = "Toggle Anti Fall Damage (OFF)"
fallBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
fallBtn.TextColor3 = Color3.new(1,1,1)
fallBtn.Font = Enum.Font.SourceSansBold
fallBtn.TextSize = 16
fallBtn.MouseButton1Click:Connect(function()
    AntiFallDamage = not AntiFallDamage
    if AntiFallDamage then
        fallBtn.Text = "Toggle Anti Fall Damage (ON)"
        fallBtn.BackgroundColor3 = Color3.fromRGB(0,160,0)
    else
        fallBtn.Text = "Toggle Anti Fall Damage (OFF)"
        fallBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
    end
end)

-- === CP UI Watcher ===
local function setupCheckpointWatcher()
    local label = player.PlayerGui.CheckpointHUD.CheckpointContainer.CheckpointLabel
    label:GetPropertyChangedSignal("Text"):Connect(function()
        local cpNum = getCheckpointFromUI()
        lastCheckpointIndex = math.clamp(cpNum + 1, 1, #checkpoints)
        player:SetAttribute("LastCP", lastCheckpointIndex)
        updateStatus()
        print("[AutoClimb] CP UI terdeteksi: " .. checkpoints[lastCheckpointIndex].name)
    end)
end

-- Init
task.spawn(function()
    local cpNum = getCheckpointFromUI()
    lastCheckpointIndex = math.clamp(cpNum + 1, 1, #checkpoints)
    updateStatus()
    print("[AutoClimb] Start dari " .. checkpoints[lastCheckpointIndex].name)
    setupCheckpointWatcher()
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    local cpNum = getCheckpointFromUI()
    lastCheckpointIndex = math.clamp(cpNum + 1, 1, #checkpoints)
    updateStatus()
    print("[AutoClimb] Respawn, lanjut dari " .. checkpoints[lastCheckpointIndex].name)
end)
