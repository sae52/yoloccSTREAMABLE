--====================================================
-- CONFIGURATION TABLE (VISIBLE TO USER)
--====================================================
getgenv().YoloCC = {

    ["Auth"] = {
        ["Key"] = "yolo123"
    },

    ["Keybinds"] = {
        ["LockKey"] = "T",
        ["WalkKey"] = "C"
    },

    ["Visuals"] = {
        ["ESP"] = true
    },

    ["Aim"] = {
        ["PredictionX"] = 0.3,
        ["PredictionY"] = 0.3,
        ["CamSmooth"] = 0.15,
        ["WallCheck"] = false
    },

    ["Player"] = {
        ["WalkSpeedValue"] = 50,
        ["DefaultSpeed"] = 16
    },

    ["GunMods"] = {
        ["Spread"] = {
            ["Enabled"] = true,
            ["Amount"] = 2
        },

        ["Range"] = {
            ["Enabled"] = true,
            ["Distance"] = 5000
        }
    }
}

--====================================================
-- SCRIPT (PRIVATE LOGIC)
--====================================================

local Config = getgenv().YoloCC

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer

--====================================================
-- USER AUTH
--====================================================

local AuthorizedUsers = {
    [1377661103]  = "yolo123",
    [10378796065] = "yolo_1037",
    [9946960712]  = "yolo_9946",
    [299971754]   = "yolo_2999",
    [4823006830]  = "yolo_4823",
    [496476050]   = "yolo_4964",
    [9198817302]  = "yolo_9198",
}

local requiredKey = AuthorizedUsers[LP.UserId]

if not requiredKey then
    warn("UserID not authorized")
    return
end

if Config.Auth.Key ~= requiredKey then
    warn("Invalid key for this UserID")
    return
end

--====================================================
-- STATES
--====================================================

local States = {
    Aimlock = false,
    Walk = false
}

local LockedTarget = nil
local ESPObjects = {}

--====================================================
-- ESP
--====================================================

local function createESP(player)

    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Font = 2
    text.Size = 13
    text.Color = Color3.fromRGB(255,255,255)

    ESPObjects[player] = text
end

for _,p in pairs(Players:GetPlayers()) do
    if p ~= LP then
        createESP(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LP then
        createESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        ESPObjects[p]:Remove()
        ESPObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()

    if not Config.Visuals.ESP then
        for _,draw in pairs(ESPObjects) do
            draw.Visible = false
        end
        return
    end

    for player,draw in pairs(ESPObjects) do

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then

            local root = player.Character.HumanoidRootPart
            local pos,onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                draw.Position = Vector2.new(pos.X,pos.Y-20)
                draw.Text = player.DisplayName
                draw.Visible = true
            else
                draw.Visible = false
            end

        else
            draw.Visible = false
        end

    end

end)

--====================================================
-- TARGET FINDER
--====================================================

local function getClosest()

    local closest
    local dist = math.huge

    local mouse = UIS:GetMouseLocation()

    for _,p in pairs(Players:GetPlayers()) do

        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then

            local pos,onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)

            if onScreen then

                local mag = (Vector2.new(pos.X,pos.Y) - mouse).Magnitude

                if mag < dist then
                    dist = mag
                    closest = p
                end

            end

        end

    end

    return closest
end

--====================================================
-- AIMLOCK + WALKSPEED
--====================================================

local currentSpeed = Config.Player.DefaultSpeed

RunService.RenderStepped:Connect(function()

    if LP.Character and LP.Character:FindFirstChild("Humanoid") then

        local targetSpeed = States.Walk and Config.Player.WalkSpeedValue or Config.Player.DefaultSpeed

        currentSpeed = currentSpeed + (targetSpeed-currentSpeed)*0.12

        LP.Character.Humanoid.WalkSpeed = currentSpeed

    end

    if States.Aimlock then

        if not LockedTarget or not LockedTarget.Character then
            LockedTarget = getClosest()
        end

        if LockedTarget and LockedTarget.Character and LockedTarget.Character:FindFirstChild("HumanoidRootPart") then

            local hrp = LockedTarget.Character.HumanoidRootPart

            local predX = Config.Aim.PredictionX
            local predY = Config.Aim.PredictionY

            local predicted = hrp.Position + (hrp.Velocity * Vector3.new(predX,predY,predX))

            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position,predicted),
                Config.Aim.CamSmooth
            )

        end

    else
        LockedTarget = nil
    end

end)

--====================================================
-- INPUT HANDLER
--====================================================

UIS.InputBegan:Connect(function(input,gp)

    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local key = input.KeyCode.Name

    if key == Config.Keybinds.LockKey then
        States.Aimlock = not States.Aimlock
    end

    if key == Config.Keybinds.WalkKey then
        States.Walk = not States.Walk
    end

end)
