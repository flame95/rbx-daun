-- Teleport + Auto Climb (2 Mode: One-Time & Looping)
-- Dengan indikator Last Checkpoint + auto-resume (improved)
-- by ChatGPT

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- cari root part
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

-- daftar checkpoint
local checkpoints = {
    {name = "Basecamp", pos = Vector3.new(-7.21, 13.11, -9.01)},
    {name = "CP 1",     pos = Vector3.new(-621.72, 249.48, -383.89)},
    {name = "CP 2",     pos = Vector3.new(-1203.19, 260.84, -487.08)},
    {name = "CP 3",     pos = Vector3.new(-1399.29, 577.59, -949.93)},
    {name = "CP 4",     pos = Vector3.new(-1701.05, 815.79, -1399.99)},
    {name = "Summit",   pos = Vector3.new(-3234.00, 1713.83, -2584.00)},
}

-- state CP terakhir
local lastCheckpointIndex = 1 -- default Basecamp

-- update indicator di GUI
local statusLabel -- nanti diinisialisasi setelah GUI dibuat
local function updateStatus()
    if statusLabel then
        statusLabel.Text = "Last CP: " .. checkpoints[lastCheckpointIndex].name
    end
end

-- teleport instant (aman + gerakan kecil)
local function teleportTo(vec)
    local root = getRoot()
    if not root then return false end
    root.CFrame = CFrame.new(vec + Vector3.new(0, 8, 0))
    task.wait(0.25)
    root.CFrame = root.CFrame * CFrame.new(0, 0, -2)
    return true
end

-- tunggu notifikasi checkpoint (GUI bawaan game)
local function waitForCheckpoint(cpIndex, timeout)
    timeout = timeout or 90
    local start = tick()

    while tick() - start < timeout do
        task.wait(1)
        -- coba cek GUI game
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            local lbl = gui:FindFirstChild("CheckpointHUD", true)
            if lbl and lbl:FindFirstChild("CheckpointLabel") then
                local text = tostring(lbl.CheckpointLabel.Text)
                local num = tonumber(text:match("%d+"))
                if num and num == cpIndex then
                    return true
                end
            end
        end
    end
    return false
end

-- climb sekali, bisa mulai dari CP mana pun
local function climbOnce(startIndex)
    startIndex = startIndex or 1
    for i = startIndex, #checkpoints do
        local cp = checkpoints[i]
        teleportTo(cp.pos)
        print("[AutoClimb] Teleport ke " .. cp.name)

        if cp.name ~= "Basecamp" then
            local ok = waitForCheckpoint(i, 90)
            if ok then
                print("[AutoClimb] Checkpoint terdeteksi: " .. cp.name)
                lastCheckpointIndex = i
                player:SetAttribute("LastCP", i)
                updateStatus()
            else
                warn("[AutoClimb] Timeout menunggu checkpoint: " .. cp.name)
            end
        else
            task.wait(0.5)
        end
        task.wait(1) -- jeda aman antar teleport
    end
    print("[AutoClimb] Summit tercapai.")
end

-- loop climb
local loopRunning = false
local function loopClimb()
    loopRunning = true
    while loopRunning do
        climbOnce(lastCheckpointIndex)
        print("[LoopClimb] Restart dari Basecamp...")
        lastCheckpointIndex = 1
        player:SetAttribute("LastCP", 1)
        updateStatus()
        task.wait(2)
    end
end

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "TeleportMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 420)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Teleport Menu"
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

-- tombol manual CP
local y = 65
for i, cp in ipairs(checkpoints) do
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = cp.name
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.MouseButton1Click:Connect(function()
        teleportTo(cp.pos)
        lastCheckpointIndex = i
        player:SetAttribute("LastCP", i)
        updateStatus()
    end)
    y = y + 36
end

-- tombol Auto Summit (1x)
local summitBtn = Instance.new("TextButton", frame)
summitBtn.Size = UDim2.new(1, -20, 0, 34)
summitBtn.Position = UDim2.new(0, 10, 0, y)
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
y = y + 40

-- tombol Loop Climb
local loopBtn = Instance.new("TextButton", frame)
loopBtn.Size = UDim2.new(1, -20, 0, 34)
loopBtn.Position = UDim2.new(0, 10, 0, y)
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

-- === Auto resume handling ===
if player:GetAttribute("LastCP") then
    lastCheckpointIndex = player:GetAttribute("LastCP")
    updateStatus()
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    if player:GetAttribute("LastCP") then
        lastCheckpointIndex = player:GetAttribute("LastCP")
        updateStatus()
        print("[AutoClimb] Respawn, lanjut dari " .. checkpoints[lastCheckpointIndex].name)
    end
end)
