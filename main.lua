--====================================================
-- CONFIGURATION TABLE (YoloCC)
--====================================================
getgenv().YoloCC = getgenv().YoloCC or {

    ["Auth"] = {
        ["Key"] = "put_your_key_here"
    },

    ["Keybinds"] = {
        ["LockKey"] = Enum.KeyCode.T,
        ["WalkKey"] = Enum.KeyCode.C
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
-- ACCOUNT AUTHORIZATION (Different Key per UserID)
--====================================================
local Config = getgenv().YoloCC

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local AuthorizedUsers = {
    [1377661103]  = "yolo_1377",
    [10378796065] = "yolo_1037",
    [9946960712]  = "yolo_9946",
    [299971754]   = "yolo_2999",
    [4823006830]  = "yolo_4823",
    [496476050]   = "yolo_4964",
    [9198817302]  = "yolo_9198",
}

local requiredKey = AuthorizedUsers[LP.UserId]

if not requiredKey then
    warn("YoloCC: UserID not authorized.")
    return
elseif Config.Auth.Key ~= requiredKey then
    warn("YoloCC: Invalid Key provided for this UserID.")
    return
end

print("YoloCC: Authenticated Successfully (Streamable Mode).")

--====================================================
-- SERVICES
--====================================================
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

--====================================================
-- STATES
--====================================================
local States = {
    StickyEnabled = false,
    WalkEnabled = false,
    ESP = Config.Visuals.ESP
}

local LockedTarget = nil
local ESPObjects = {}

--====================================================
-- UTILITY FUNCTIONS
--====================================================
local function isVisible(targetChar)

    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        return false
    end

    local origin = Camera.CFrame.Position
    local direction = (targetChar.HumanoidRootPart.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LP.Character, targetChar}
    params.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, params)

    return result == nil
end


local function getClosestToMouse()

    local closest = nil
    local minDistance = math.huge
    local mousePos = UIS:GetMouseLocation()

    for _,p in pairs(Players:GetPlayers()) do

        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then

            local pos,onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)

            if onScreen then

                local dist = (Vector2.new(pos.X,pos.Y) - mousePos).Magnitude

                if dist < minDistance then

                    if not Config.Aim.WallCheck or isVisible(p.Character) then

                        minDistance = dist
                        closest = p

                    end

                end

            end

        end

    end

    return closest

end

--====================================================
-- STREAMPROOF ESP
--====================================================
local function createESP(player)

    if ESPObjects[player] then
        return
    end

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

    createESP(p)

end)


Players.PlayerRemoving:Connect(function(p)

    if ESPObjects[p] then
        ESPObjects[p]:Remove()
        ESPObjects[p] = nil
    end

end)


RunService.RenderStepped:Connect(function()

    for player,drawing in pairs(ESPObjects) do

        if States.ESP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then

            local root = player.Character.HumanoidRootPart
            local pos,onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then

                drawing.Position = Vector2.new(pos.X,pos.Y - 20)
                drawing.Text = player.DisplayName

                if LockedTarget == player then
                    drawing.Color = Color3.fromRGB(255,50,50)
                elseif Config.Aim.WallCheck and not isVisible(player.Character) then
                    drawing.Color = Color3.fromRGB(0,255,0)
                else
                    drawing.Color = Color3.fromRGB(255,255,255)
                end

                drawing.Visible = true

            else

                drawing.Visible = false

            end

        else

            drawing.Visible = false

        end

    end

end)

--====================================================
-- MOVEMENT + AIM LOOP
--====================================================
local currentSpeed = Config.Player.DefaultSpeed

RunService.RenderStepped:Connect(function()

    if LP.Character and LP.Character:FindFirstChild("Humanoid") then

        local targetSpeed = States.WalkEnabled and Config.Player.WalkSpeedValue or Config.Player.DefaultSpeed

        currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * 0.12

        LP.Character.Humanoid.WalkSpeed = currentSpeed

    end


    if States.StickyEnabled then

        if not LockedTarget or not LockedTarget.Character or not LockedTarget.Character:FindFirstChild("HumanoidRootPart") or LockedTarget.Character.Humanoid.Health <= 0 then

            LockedTarget = getClosestToMouse()

        end

        if LockedTarget and LockedTarget.Character then

            if Config.Aim.WallCheck and not isVisible(LockedTarget.Character) then
                return
            end

            local hrp = LockedTarget.Character.HumanoidRootPart

            local predictedPos =
                hrp.Position +
                (hrp.Velocity * Vector3.new(Config.Aim.PredictionX,Config.Aim.PredictionY,Config.Aim.PredictionX))

            Camera.CFrame =
                Camera.CFrame:Lerp(
                    CFrame.new(Camera.CFrame.Position,predictedPos),
                    Config.Aim.CamSmooth
                )

        end

    else

        LockedTarget = nil

    end

end)

--====================================================
-- BULLET MOD HOOK
--====================================================
local function applySpread(direction,spread)

    if spread <= 0 then
        return direction.Unit
    end

    local spreadRad = math.rad(spread)

    local randX = (math.random() - 0.5) * 2
    local randY = (math.random() - 0.5) * 2

    local offset =
        Vector3.new(randX,randY,0) * math.tan(spreadRad)

    local cf = CFrame.lookAt(Vector3.zero,direction.Unit)

    return (cf:VectorToWorldSpace(offset) + direction.Unit).Unit

end


local oldNamecall

oldNamecall =
hookmetamethod(game,"__namecall",newcclosure(function(self,...)

    local args = {...}
    local method = getnamecallmethod()

    if not checkcaller() and method == "Raycast" then

        local origin = args[1]
        local direction = args[2]

        if origin and direction then

            local modifiedDirection = direction.Unit

            local mods = Config.GunMods

            if mods.Spread.Enabled then
                modifiedDirection = applySpread(modifiedDirection,mods.Spread.Amount)
            end

            local distance =
                mods.Range.Enabled and mods.Range.Distance
                or direction.Magnitude

            args[2] = modifiedDirection * distance

            return oldNamecall(self,unpack(args))

        end

    end

    return oldNamecall(self,...)

end))

--====================================================
-- KEYBINDS
--====================================================
UIS.InputBegan:Connect(function(input,gameProcessed)

    if gameProcessed then
        return
    end

    local binds = Config.Keybinds

    if input.KeyCode == binds.LockKey then

        States.StickyEnabled = not States.StickyEnabled

    elseif input.KeyCode == binds.WalkKey then

        States.WalkEnabled = not States.WalkEnabled

    end

end)
