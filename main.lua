local Config = getgenv().YoloCC
if not Config then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--================ AUTH =================

local AuthorizedUsers = {
    [1377661103] = "yolo_1377"
}

local requiredKey = AuthorizedUsers[LP.UserId]

if not requiredKey then
    warn("Unauthorized user")
    return
end

if Config.Auth.Key ~= requiredKey then
    warn("Invalid key")
    return
end

--================ STATES =================

local States = {
    Aimlock = false,
    WalkSpeed = false
}

local LockedTarget = nil
local ESPObjects = {}

--================ TARGETING =================

local function getClosest()

    local closest = nil
    local dist = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _,plr in pairs(Players:GetPlayers()) do

        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then

            local pos,vis = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)

            if vis then

                local mag = (Vector2.new(pos.X,pos.Y) - screenCenter).Magnitude

                if mag < dist then
                    dist = mag
                    closest = plr
                end

            end
        end
    end

    return closest
end

--================ ESP =================

local function createESP(player)

    if ESPObjects[player] then return end

    local text = Drawing.new("Text")

    text.Center = true
    text.Outline = true
    text.Size = 12
    text.Visible = false
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

--================ RENDER LOOP =================

local currentSpeed = Config.Player.DefaultSpeed

RunService.RenderStepped:Connect(function()

    if LP.Character and LP.Character:FindFirstChild("Humanoid") then

        local targetSpeed = States.WalkSpeed and Config.Player.WalkSpeedValue or Config.Player.DefaultSpeed
        currentSpeed = currentSpeed + (targetSpeed-currentSpeed)*0.2
        LP.Character.Humanoid.WalkSpeed = currentSpeed

    end

    if States.Aimlock then

        if not LockedTarget then
            LockedTarget = getClosest()
        end

        if LockedTarget and LockedTarget.Character and LockedTarget.Character:FindFirstChild("HumanoidRootPart") then

            local hrp = LockedTarget.Character.HumanoidRootPart

            local pred = hrp.Velocity * Vector3.new(Config.Aim.PredictionX,Config.Aim.PredictionY,Config.Aim.PredictionX)

            local predicted = hrp.Position + pred

            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position,predicted),
                Config.Aim.CamSmooth
            )

        end

    else
        LockedTarget = nil
    end

    if Config.Visuals.ESP then

        for player,draw in pairs(ESPObjects) do

            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then

                local pos,vis = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)

                if vis then
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

    end

end)

--================ GUN MODS =================

local oldNamecall
oldNamecall = hookmetamethod(game,"__namecall",newcclosure(function(self,...)

    local args = {...}
    local method = getnamecallmethod()

    if not checkcaller() and method == "Raycast" then

        local origin = args[1]
        local direction = args[2]

        if origin and direction then

            local newDir = direction.Unit
            local dist = direction.Magnitude

            if Config.GunMods.Range.Enabled then
                dist = Config.GunMods.Range.Distance
            end

            args[2] = newDir * dist

            return oldNamecall(self,unpack(args))

        end
    end

    return oldNamecall(self,...)

end))

--================ KEYBINDS =================

UIS.InputBegan:Connect(function(input,gp)

    if gp then return end

    if input.KeyCode == Config.Keybinds.LockKey then
        States.Aimlock = not States.Aimlock
    end

    if input.KeyCode == Config.Keybinds.WalkKey then
        States.WalkSpeed = not States.WalkSpeed
    end

end)
