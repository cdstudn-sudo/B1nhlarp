-- B1NH BLADE BALL
task.spawn(function()

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "B1NH",
    SubTitle = "Paid Version",
    TabWidth = 100,
    Size = UDim2.fromOffset(480, 340),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Rage      = Window:AddTab({Title = "Autoparry", Icon = "sword"}),
    Spam      = Window:AddTab({Title = "Spam",       Icon = "skull"}),
    Detection = Window:AddTab({Title = "Detection",  Icon = "monitor"}),
    Player    = Window:AddTab({Title = "Player",     Icon = "user"}),
    Visuals   = Window:AddTab({Title = "Visuals",    Icon = "eye"}),
    Misc      = Window:AddTab({Title = "Misc",       Icon = "settings"}),
    Settings  = Window:AddTab({Title = "Settings",   Icon = "sliders"})
}

local Options = Fluent.Options

repeat task.wait(0.5) until game:IsLoaded()

local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local RunService = cloneref(game:GetService('RunService'))
local TweenService = cloneref(game:GetService('TweenService'))
local Stats = cloneref(game:GetService('Stats'))
local Debris = cloneref(game:GetService('Debris'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local HttpService = cloneref(game:GetService('HttpService'))
local Workspace = cloneref(game:GetService('Workspace'))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end

local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace.Runtime

local function Notify(t, c, d)
    pcall(function() Fluent:Notify({Title = t or "B1NH", Content = c or "", Duration = d or 2}) end)
end

-- ============================================================
-- AZURE TOKEN SYSTEM
-- ============================================================
local _token
local _tokenFound = false
for _, Function in getgc(true) do
    if type(Function) ~= 'function' or not debug.info(Function, 's'):find('PRY', 1, true) then continue end
    for _, value in debug.getupvalues(Function) do
        if type(value) == 'function' then
            _token = value
            _tokenFound = true
            break
        end
    end
    if _token then break end
end

if not _tokenFound then
    Notify("B1NH", "Remote not found!", 5)
    return
end

Notify("B1NH", "First block yourself", 3)

function _tokenize(_remote_uid)
    local time = tostring(math.floor(workspace:GetServerTimeNow() * 100))
    local key = _token(_remote_uid, 'TIME')
    local characters = table.create(#time)
    for index = 1, #time do
        characters[index] = string.char(bit32.bxor(
            (string.byte(time, index) + index) % 256,
            string.byte(key, (index - 1) % #key + 1)
        ))
    end
    return table.concat(characters)
end

local _reverted = {}
local _original = {}
local _capturedRemote = nil
local _capturedArgs = nil

function _is_valid(args) if not args or #args < 8 then return false end; return true end

function _hook(remote)
    if not remote then return end
    if _reverted[remote] then return end
    if _original[getrawmetatable(remote)] then return end
    _original[getrawmetatable(remote)] = true
    local _meta = getrawmetatable(remote)
    setreadonly(_meta, false)
    local _old = _meta.__index
    _meta.__index = function(self, key)
        if (key == 'FireServer' and self:IsA('RemoteEvent')) or
           (key == 'InvokeServer' and self:IsA('RemoteFunction')) then
            return function(_, ...)
                local _arguments = {...}
                if _is_valid(_arguments) then
                    if not _reverted[self] then
                        _reverted[self] = _arguments
                        _capturedRemote = self
                        _capturedArgs = _arguments
                    end
                end
                return _old(self, key)(_, unpack(_arguments))
            end
        end
        return _old(self, key)
    end
    setreadonly(_meta, true)
end

for _iterator, _remote in pairs(ReplicatedStorage:GetDescendants()) do
    if _remote:IsA('RemoteEvent') or _remote:IsA('RemoteFunction') then _hook(_remote) end
end

task.wait(5)

task.spawn(function()
    local attempts = 0
    while not _capturedRemote and attempts < 30 do
        task.wait(1)
        attempts = attempts + 1
    end
    if _capturedRemote then
        Notify("B1NH", "Remote hooked", 3)
    else
        Notify("B1NH", "Remote not found!", 5)
    end
end)

local function fireParryRemote(curveCF)
    if not _capturedRemote or not _capturedArgs then return false end
    local cam = workspace.CurrentCamera
    local aim_target
    if isMobile then
        local vp = cam.ViewportSize
        aim_target = {math.floor(vp.X / 2), math.floor(vp.Y / 2)}
    else
        local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
        if ok and mouse then
            aim_target = {math.floor(mouse.X), math.floor(mouse.Y)}
        else
            local vp = cam.ViewportSize
            aim_target = {math.floor(vp.X / 2), math.floor(vp.Y / 2)}
        end
    end
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok, sp = pcall(function() return cam:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if ok then event_data[entity.Name] = sp end
            end
        end
    end
    local packet = {
        _capturedArgs[1], _capturedArgs[2], _tokenize(_capturedArgs[2]),
        0.5, curveCF or cam.CFrame, event_data, aim_target, false
    }
    pcall(function()
        if _capturedRemote:IsA('RemoteEvent') then _capturedRemote:FireServer(unpack(packet))
        elseif _capturedRemote:IsA('RemoteFunction') then _capturedRemote:InvokeServer(unpack(packet)) end
    end)
    return true
end

-- ============================================================
-- SYSTEM
-- ============================================================
local System = {
    __properties = {
        __autoparry_enabled = false, __triggerbot_enabled = false,
        __manual_spam_enabled = false, __play_animation = false,
        __curve_mode = 1, __accuracy = 50, __divisor_multiplier = 1.1,
        __parried = false, __training_parried = false, __parries = 0,
        __grab_animation = nil, __tornado_time = tick(),
        __connections = {}, __infinity_active = false,
        __deathslash_active = false, __timehole_active = false,
        __slashesoffury_active = false, __slashesoffury_count = 0,
        __is_mobile = isMobile,
        __mobile_guis = {}, __headless_enabled = false, __korblox_enabled = false,
        __ball_velocity_gui = nil, __ball_velocity_enabled = false,
        __ball_velocity_peaks = {}, __ball_velocity_conn = nil,
        __ball_velocity_label = nil,
        __peak_velocity = 0, __last_ball_id = nil, __show_ping = false,
        __auto_ability_enabled = false, __cooldown_protection = false
    },
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High', 'Normal', 'Speed', 'Down', 'Left', 'Right'},
        __detections = {__infinity = false, __deathslash = false, __timehole = false, __slashesoffury = false, __phantom = false}
    },
    __triggerbot = {__enabled = false, __is_parrying = false, __parries = 0, __max_parries = 10000}
}

local function update_divisor()
    System.__properties.__divisor_multiplier = 0.7 + (System.__properties.__accuracy - 1) * (0.9/99)
end
update_divisor()

-- Animation
System.animation = {}
local SwordAPI = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SwordAPI")
local LastPlayedd = 0
local Sword_CP = false
local Sword_Spped = 1
local Grab_Parry = nil
local AnimFix_Cache = {}

local function GetParryAnimation(swordName)
    if not swordName or swordName == "" then return SwordAPI.Collection.Default:FindFirstChild("GrabParry") end
    if AnimFix_Cache[swordName] then return AnimFix_Cache[swordName] end
    local ok, swordData = pcall(function()
        return ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(swordName)
    end)
    if not ok or not swordData or type(swordData) ~= "table" or not swordData.AnimationType then
        AnimFix_Cache[swordName] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        return AnimFix_Cache[swordName]
    end
    for _, obj in pairs(SwordAPI.Collection:GetChildren()) do
        if obj.Name == swordData.AnimationType then
            local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
            if anim then AnimFix_Cache[swordName] = anim; return anim end
        end
    end
    AnimFix_Cache[swordName] = SwordAPI.Collection.Default:FindFirstChild("GrabParry")
    return AnimFix_Cache[swordName]
end

local function GrabParryPlay(track)
    if not track then return end
    pcall(function()
        track:Play(track:GetAttribute("PlayFadeTime") or 0, track:GetAttribute("PlayWeight") or 1, track:GetAttribute("PlaySpeed") or 1)
    end)
end

local function GrabParryStop(track)
    if not track then return end
    pcall(function() track:Stop(track:GetAttribute("StopFadeTime") or 0.1) end)
end

function System.animation.play_grab_parry()
    if not System.__properties.__play_animation then return end
    if not ((os.clock() - LastPlayedd) >= (Sword_Spped - 0.8) or Sword_CP) then return end
    LastPlayedd = os.clock()
    Sword_CP = false
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local currentSword
    if getgenv().skinChangerEnabled then
        currentSword = (getgenv().swordAnimations ~= "" and getgenv().swordAnimations)
                    or (getgenv().swordModel ~= "" and getgenv().swordModel)
                    or char:GetAttribute("CurrentlyEquippedSword")
    else
        currentSword = char:GetAttribute("CurrentlyEquippedSword")
    end
    local animation = GetParryAnimation(currentSword)
    if not animation then return end
    for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
        if track.Name == "GrabParry" or track.Name == "Grab" then
            track.TimePosition = 0
            GrabParryStop(track)
        elseif track.Name == "SuccessParry" or track.Name == "Success" then
            GrabParryStop(track)
        end
    end
    Grab_Parry = humanoid.Animator:LoadAnimation(animation)
    GrabParryPlay(Grab_Parry)
end

pcall(function()
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()
        Sword_CP = true
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Name == "GrabParry" or track.Name == "Grab" then GrabParryStop(track) end
        end
    end)
end)

-- Ball
System.ball = {}
function System.ball.get()
    local balls = Workspace:FindFirstChild('Balls'); if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then ball.CanCollide = false; return ball end
    end; return nil
end
function System.ball.get_all()
    local balls_table = {}; local balls = Workspace:FindFirstChild('Balls')
    if not balls then return balls_table end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then ball.CanCollide = false; table.insert(balls_table, ball) end
    end; return balls_table
end

System.player = {}
local Closest_Entity = nil; local last_closest_check = 0
function System.player.get_closest()
    local now = tick()
    if now - last_closest_check < 0.1 then return Closest_Entity end
    last_closest_check = now
    local max_distance = math.huge; local closest_entity = nil
    if not Alive then return nil end
    for _, entity in pairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character and entity.PrimaryPart then
            local distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
            if distance < max_distance then max_distance = distance; closest_entity = entity end
        end
    end
    Closest_Entity = closest_entity; return closest_entity
end

System.curve = {}
function System.curve.get_cframe()
    local Camera = Workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local root_pos = root and root.Position or Camera.CFrame.Position
    local targetPart
    do
        local bestDist = math.huge
        local mouseLoc = not isMobile and UserInputService:GetMouseLocation() or nil
        if Alive then
            for _, v in pairs(Alive:GetChildren()) do
                if v ~= LocalPlayer.Character and v.PrimaryPart then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                    if onScreen then
                        local dist
                        if mouseLoc then dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                        else local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude end
                        if dist < bestDist then bestDist = dist; targetPart = v.PrimaryPart end
                    end
                end
            end
        end
    end
    local target_pos = targetPart and targetPart.Position or (root_pos + Camera.CFrame.LookVector * 100)
    local Parry_Type = System.__config.__curve_names[System.__properties.__curve_mode]
    local cf
    if Parry_Type == "Camera" then cf = Camera.CFrame
    elseif Parry_Type == "Random" then
        local direction = (target_pos - root_pos).Unit
        local random_offset; local attempts = 0
        repeat
            random_offset = Vector3.new(math.random(-4000,4000), math.random(-4000,4000), math.random(-4000,4000))
            local curve_dir = (target_pos + random_offset - root_pos).Unit
            local dot = direction:Dot(curve_dir); attempts = attempts + 1
        until dot < 0.95 or attempts > 10
        cf = CFrame.new(root_pos, target_pos + random_offset)
    elseif Parry_Type == "Accelerated" then cf = CFrame.new(root_pos, target_pos + Vector3.new(0, 5, 0))
    elseif Parry_Type == "Backwards" then
        local direction = (root_pos - target_pos).Unit
        local backwards_pos = root_pos + direction * 10000 + Vector3.new(0, 1000, 0)
        cf = CFrame.new(Camera.CFrame.Position, backwards_pos)
    elseif Parry_Type == "Slow" then cf = CFrame.new(root_pos, target_pos + Vector3.new(0, -9e18, 0))
    elseif Parry_Type == "High" then cf = CFrame.new(root_pos, target_pos + Vector3.new(0, 9e18, 0))
    elseif Parry_Type == "Normal" then cf = CFrame.new(root_pos, root_pos + (root and root.CFrame.LookVector or Camera.CFrame.LookVector))
    elseif Parry_Type == "Speed" then cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.UpVector * 5)
    elseif Parry_Type == "Down" then cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.UpVector * -9e9)
    elseif Parry_Type == "Left" then cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Camera.CFrame.RightVector * 9e9)
    elseif Parry_Type == "Right" then cf = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.RightVector * 9e9)
    else cf = Camera.CFrame end
    return cf
end

System.parry = {}
function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end
    fireParryRemote(System.curve.get_cframe())
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end
    end)
end
function System.parry.keypress() System.parry.execute() end
function System.parry.execute_action() System.animation.play_grab_parry(); System.parry.execute() end

local function linear_predict(a,b,t) return a+(b-a)*t end
System.detection = { __ball_properties = {__aerodynamic_time=tick(),__last_warping=tick(),__lerp_radians=0,__curving=tick()} }
function System.detection.is_curved()
    local props = System.detection.__ball_properties
    local ball = System.ball.get(); if not ball then return false end
    local zoomies = ball:FindFirstChild("zoomies"); if not zoomies then return false end
    local velocity = zoomies.VectorVelocity; local speed = velocity.Magnitude
    if speed < 1 then return false end
    local ball_dir = velocity.Unit; local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return false end
    local pos = char.PrimaryPart.Position; local direction = (pos-ball.Position).Unit
    local dot = direction:Dot(ball_dir)
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()/1000
    local distance = (pos-ball.Position).Magnitude; local reach_time = distance/speed-ping
    local dot_threshold = math.clamp(0.55-(ping*0.75),-1,0.45)
    local speed_threshold = math.min(speed/100,45)
    local ball_distance_threshold = 15-math.min(distance/1000,15)+speed_threshold
    local clamped_dot = math.clamp(dot,-1,1); local radians = math.asin(clamped_dot)
    props.__lerp_radians = linear_predict(props.__lerp_radians,radians,0.85)
    if props.__lerp_radians < 0.016 then props.__last_warping = tick() end
    if distance < (ball_distance_threshold*0.85) then return false end
    if (tick()-props.__last_warping) < (reach_time/1.4) then return true end
    if (tick()-props.__curving) < (reach_time/1.1) then return true end
    return dot < dot_threshold
end

pcall(function()
    ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c,d) System.__properties.__deathslash_active = d or false end)
    ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a,b) System.__properties.__infinity_active = b or false end)
end)

pcall(function()
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args={...}; local player=args[1]
        if player==LocalPlayer or player==LocalPlayer.Name or (player and player.Name==LocalPlayer.Name) then
            System.__properties.__timehole_active=true
        end
    end)
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
        System.__properties.__timehole_active=false
    end)
end)

local maxParryCount = 36; local parryDelay = 0.05
pcall(function()
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args={...}; local player=args[1]
        if player==LocalPlayer or player==LocalPlayer.Name or (player and player.Name==LocalPlayer.Name) then
            System.__properties.__slashesoffury_active=true; System.__properties.__slashesoffury_count=0
        end
    end)
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        System.__properties.__slashesoffury_active=false; System.__properties.__slashesoffury_count=0
    end)
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function()
        System.__properties.__slashesoffury_count=System.__properties.__slashesoffury_count+1
    end)
    ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
        spawn(function()
            while System.__properties.__slashesoffury_active and System.__properties.__slashesoffury_count < maxParryCount do
                if System.__config.__detections.__slashesoffury then System.parry.execute(); task.wait(parryDelay)
                else break end
            end
        end)
    end)
end)

Runtime.ChildAdded:Connect(function(Object)
    if System.__config.__detections.__phantom then
        if Object.Name=="maxTransmission" or Object.Name=="transmissionpart" then
            local Weld=Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                if Character and Weld.Part1==Character.HumanoidRootPart then
                    local CurrentBall=System.ball.get(); Weld:Destroy()
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection=RunService.RenderStepped:Connect(function()
                            local Highlighted=CurrentBall:GetAttribute("highlighted")
                            if Highlighted==true then
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                System.__properties.__parried=true
                                task.delay(1,function() System.__properties.__parried=false end)
                            elseif Highlighted==false then FocusConnection:Disconnect() end
                        end)
                        task.delay(3,function() if FocusConnection and FocusConnection.Connected then FocusConnection:Disconnect() end end)
                    end
                end
            end
        end
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_,root)
    if root.Parent and root.Parent ~= LocalPlayer.Character then
        if not Alive or root.Parent.Parent ~= Alive then return end
    end
    local closest=System.player.get_closest(); local ball=System.ball.get()
    if not ball or not closest then return end
    local target_distance=(LocalPlayer.Character.PrimaryPart.Position-closest.PrimaryPart.Position).Magnitude
    local distance=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Magnitude
    local direction=(LocalPlayer.Character.PrimaryPart.Position-ball.Position).Unit
    local dot=direction:Dot(ball.AssemblyLinearVelocity.Unit)
    local curve_detected=System.detection.is_curved()
    if target_distance < 15 and distance < 15 and dot > -0.25 then
        if curve_detected then System.parry.execute_action() end
    end
    if System.__properties.__grab_animation then System.__properties.__grab_animation:Stop() end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if not Alive or LocalPlayer.Character.Parent ~= Alive then return end
    if System.__properties.__grab_animation then System.__properties.__grab_animation:Stop() end
end)

-- TRIGGERBOT
System.triggerbot = {}
local TRIGGERBOT_COOLDOWN = 0.03
local TRIGGERBOT_PARSE_TIME = 0.02

function System.triggerbot.trigger(ball)
    if System.__triggerbot.__is_parrying or System.__triggerbot.__parries > System.__triggerbot.__max_parries then return end
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end
    System.__triggerbot.__is_parrying = true
    System.__triggerbot.__parries = System.__triggerbot.__parries + 1
    System.parry.execute()
    if System.__properties.__play_animation then System.animation.play_grab_parry() end
    task.delay(TRIGGERBOT_COOLDOWN, function()
        if System.__triggerbot.__parries > 0 then System.__triggerbot.__parries = System.__triggerbot.__parries - 1 end
    end)
    task.spawn(function()
        local start_time = tick()
        repeat RunService.Heartbeat:Wait()
        until (tick()-start_time >= TRIGGERBOT_PARSE_TIME or not System.__triggerbot.__is_parrying)
        System.__triggerbot.__is_parrying = false
    end)
end

function System.triggerbot.loop()
    if not System.__triggerbot.__enabled then return end
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end
    local balls = Workspace:FindFirstChild('Balls'); if not balls then return end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:IsA('BasePart') and ball:GetAttribute('target') == LocalPlayer.Name then
            System.triggerbot.trigger(ball)
            break
        end
    end
end

function System.triggerbot.enable(enabled)
    System.__triggerbot.__enabled = enabled
    if enabled then
        if not System.__properties.__connections.__triggerbot then
            System.__properties.__connections.__triggerbot = RunService.PreSimulation:Connect(System.triggerbot.loop)
        end
    else
        if System.__properties.__connections.__triggerbot then
            System.__properties.__connections.__triggerbot:Disconnect()
            System.__properties.__connections.__triggerbot = nil
        end
        System.__triggerbot.__is_parrying = false
        System.__triggerbot.__parries = 0
    end
end

-- MANUAL SPAM
System.manual_spam = {}
local macroAnimFix = false
local spam_accumulator = 0
local SPAM_RATE = 0.01

function System.manual_spam.start() System.__properties.__manual_spam_enabled = true end
function System.manual_spam.stop() System.__properties.__manual_spam_enabled = false end

RunService.Heartbeat:Connect(function(dt)
    if not System.__properties.__manual_spam_enabled then
        spam_accumulator = 0
        return
    end
    spam_accumulator = spam_accumulator + dt
    local maxFires = 5
    local fired = 0
    while spam_accumulator >= SPAM_RATE and fired < maxFires do
        spam_accumulator = spam_accumulator - SPAM_RATE
        fired = fired + 1
        if getgenv().ManualSpamMode == "Keypress" then
            pcall(function() System.parry.keypress() end)
        else
            pcall(function() System.parry.execute() end)
            if getgenv().ManualSpamAnimationFix and macroAnimFix then
                pcall(function() System.animation.play_grab_parry() end)
            end
        end
    end
    if spam_accumulator > SPAM_RATE * 10 then spam_accumulator = 0 end
end)

-- AUTO PARRY
System.autoparry = {}
function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        local balls = System.ball.get_all(); local one_ball = System.ball.get()
        local training_ball = nil
        if Workspace:FindFirstChild("TrainingBalls") then
            for _, Instance in pairs(Workspace.TrainingBalls:GetChildren()) do
                if Instance:GetAttribute("realBall") then training_ball = Instance; break end
            end
        end
        for _, ball in pairs(balls) do
            if System.__triggerbot.__enabled then return end
            if not ball then continue end
            local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then continue end
            ball:GetAttributeChangedSignal('target'):Once(function() System.__properties.__parried = false end)
            if System.__properties.__parried then continue end
            local ball_target = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
            local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            local curved = System.detection.is_curved()
            if ball:FindFirstChild('AeroDynamicSlashVFX') then
                ball.AeroDynamicSlashVFX:Destroy(); System.__properties.__tornado_time = tick()
            end
            if Runtime:FindFirstChild('Tornado') then
                if (tick()-System.__properties.__tornado_time) < (Runtime.Tornado:GetAttribute('TornadoTime') or 1)+0.314159 then continue end
            end
            if one_ball and one_ball:GetAttribute('target')==LocalPlayer.Name and curved then continue end
            if ball:FindFirstChild('ComboCounter') then continue end
            if LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            if System.__config.__detections.__infinity and System.__properties.__infinity_active then continue end
            if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then continue end
            if System.__config.__detections.__timehole and System.__properties.__timehole_active then continue end
            if System.__config.__detections.__slashesoffury and System.__properties.__slashesoffury_active then continue end

            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if System.__properties.__auto_ability_enabled then
                    local AbilityCD = LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient
                    if AbilityCD and AbilityCD.Offset.Y == 0.5 then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Abilities") then
                            local abilities = LocalPlayer.Character.Abilities
                            if (abilities:FindFirstChild("Raging Deflection") and abilities["Raging Deflection"].Enabled) or
                               (abilities:FindFirstChild("Rapture") and abilities["Rapture"].Enabled) or
                               (abilities:FindFirstChild("Calming Deflection") and abilities["Calming Deflection"].Enabled) or
                               (abilities:FindFirstChild("Aerodynamic Slash") and abilities["Aerodynamic Slash"].Enabled) or
                               (abilities:FindFirstChild("Fracture") and abilities["Fracture"].Enabled) or
                               (abilities:FindFirstChild("Death Slash") and abilities["Death Slash"].Enabled) then
                                System.__properties.__parried = true
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                task.wait(2.432)
                                local ds = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DeathSlashShootActivation")
                                if ds then pcall(function() ds:FireServer(true) end) end
                                continue
                            end
                        end
                    end
                end
            end

            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if System.__properties.__cooldown_protection then
                    local AbilityCD = LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient
                    if AbilityCD and AbilityCD.Offset.Y == 0.5 then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Abilities") then
                            local abilities = LocalPlayer.Character.Abilities
                            if (abilities:FindFirstChild("Raging Deflection") and abilities["Raging Deflection"].Enabled) or
                               (abilities:FindFirstChild("Rapture") and abilities["Rapture"].Enabled) or
                               (abilities:FindFirstChild("Calming Deflection") and abilities["Calming Deflection"].Enabled) then
                                System.__properties.__parried = true
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                continue
                            end
                        end
                    end
                end
            end

            if ball_target==LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().AutoParryMode=="Keypress" then System.parry.keypress()
                else System.parry.execute_action() end
                System.__properties.__parried=true
            end
            local last_parrys=tick()
            repeat RunService.Stepped:Wait()
            until (tick()-last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried=false
        end
        if training_ball then
            local zoomies=training_ball:FindFirstChild('zoomies')
            if zoomies then
                training_ball:GetAttributeChangedSignal('target'):Once(function() System.__properties.__training_parried=false end)
                if not System.__properties.__training_parried then
                    local ball_target=training_ball:GetAttribute('target')
                    local velocity=zoomies.VectorVelocity
                    local distance=LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local speed=velocity.Magnitude
                    local ping=Stats.Network.ServerStatsItem['Data Ping']:GetValue()/10
                    local ping_threshold=math.clamp(ping/10,5,17)
                    local capped_speed_diff=math.min(math.max(speed-9.5,0),650)
                    local speed_divisor=(2.4+capped_speed_diff*0.002)*System.__properties.__divisor_multiplier
                    local parry_accuracy=ping_threshold+math.max(speed/speed_divisor,9.5)
                    if ball_target==LocalPlayer.Name and distance <= parry_accuracy then
                        if getgenv().AutoParryMode=="Keypress" then System.parry.keypress()
                        else System.parry.execute_action() end
                        System.__properties.__training_parried=true
                        local last_parrys=tick()
                        repeat RunService.Stepped:Wait()
                        until (tick()-last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried=false
                    end
                end
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end

-- HEADLESS & KORBLOX
local Byte_Library = {}
function Byte_Library.Korblox(char)
    if not char then return end
    local leg = char:FindFirstChild("Right Leg"); if not leg then return end
    if not leg:FindFirstChild("KorbloxMesh") then
        for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
        local m = Instance.new("SpecialMesh"); m.Name = "KorbloxMesh"
        m.MeshId = "rbxassetid://902942096"; m.TextureId = "rbxassetid://902843398"
        m.Offset = Vector3.new(0, 0.7, 0); m.Parent = leg
    end
end
function Byte_Library.Restore_Leg(char)
    if not char then return end
    local leg = char:FindFirstChild("Right Leg"); if not leg then return end
    for _, v in leg:GetChildren() do if v:IsA("SpecialMesh") then v:Destroy() end end
end
function Byte_Library.Headless(char)
    if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    head.Transparency = 1
    for _, child in head:GetChildren() do
        if child:IsA("Decal") or child.Name == "face" then child.Transparency = 1
        elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
            if not child:GetAttribute("OriginalScale") then
                child:SetAttribute("OriginalScale", child.Scale); child.Scale = Vector3.new(0, 0, 0)
            end
        end
    end
end
function Byte_Library.Restore_Head(char)
    if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    head.Transparency = 0
    for _, child in head:GetChildren() do
        if child:IsA("Decal") or child.Name == "face" then child.Transparency = 0
        elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
            local orig = child:GetAttribute("OriginalScale")
            if orig then child.Scale = orig; child:SetAttribute("OriginalScale", nil) end
        end
    end
end
local function ApplyHeadlessKorblox()
    local char = LocalPlayer.Character; if not char then return end
    if System.__properties.__headless_enabled then Byte_Library.Headless(char) end
    if System.__properties.__korblox_enabled then Byte_Library.Korblox(char) end
end
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); ApplyHeadlessKorblox() end)

-- MOBILE UI
local mobile_ui_button = nil
local function create_mobile_ui_button()
    if mobile_ui_button and mobile_ui_button.gui then
        pcall(function() mobile_ui_button.gui:Destroy() end)
    end
    local gui = Instance.new('ScreenGui')
    gui.Name = 'B1NHMobileUI'; gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9999; gui.Parent = CoreGui
    local button = Instance.new('TextButton')
    button.Name = 'UIButton'; button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = UDim2.new(0.90, 0, 0.15, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BackgroundTransparency = 0.3; button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Draggable = true; button.AutoButtonColor = true
    button.ZIndex = 10000; button.Text = ""; button.Parent = gui
    Instance.new('UICorner', button).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new('UIStroke', button); stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2; stroke.Transparency = 0.3
    local text = Instance.new('TextLabel')
    text.Size = UDim2.new(1, 0, 1, 0); text.BackgroundTransparency = 1
    text.Text = "B"; text.Font = Enum.Font.GothamBold; text.TextSize = 22
    text.TextColor3 = Color3.fromRGB(255, 255, 255); text.ZIndex = 10001; text.Parent = button
    button.MouseButton1Click:Connect(function()
        pcall(function() Window:Minimize(not Window.Minimized) end)
    end)
    mobile_ui_button = { gui = gui, button = button }
    return mobile_ui_button
end

local function create_mobile_button(name, position_y, color, x_pos)
    local gui = Instance.new('ScreenGui')
    gui.Name = 'B1NH_' .. name .. '_Mobile'; gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 9998; gui.Parent = CoreGui
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(0, 130, 0, 55)
    button.Position = UDim2.new(x_pos or 0.15, 0, position_y, 0)
    button.BackgroundTransparency = 1; button.AnchorPoint = Vector2.new(0.5, 0)
    button.Draggable = true; button.AutoButtonColor = false; button.ZIndex = 2
    local bg = Instance.new('Frame'); bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); bg.Parent = button
    Instance.new('UICorner', bg).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new('UIStroke', bg); stroke.Color = color
    stroke.Thickness = 2; stroke.Transparency = 0.3
    local text = Instance.new('TextLabel')
    text.Size = UDim2.new(1, 0, 1, 0); text.BackgroundTransparency = 1; text.Text = name
    text.Font = Enum.Font.GothamBold; text.TextSize = 17
    text.TextColor3 = Color3.fromRGB(255, 255, 255); text.ZIndex = 3; text.Parent = button
    button.Parent = gui
    return {gui = gui, button = button, text = text, bg = bg}
end

local function destroy_mobile_gui(gui_data) if gui_data and gui_data.gui then gui_data.gui:Destroy() end end

-- SKIN CHANGER
local SKIN_SAVE_FILE = "B1NH/skin.json"
local function loadSkinSave()
    local data = {}
    pcall(function()
        if isfile and isfile(SKIN_SAVE_FILE) then
            local decoded = HttpService:JSONDecode(readfile(SKIN_SAVE_FILE))
            if type(decoded) == "table" then data = decoded end
        end
    end)
    return data
end
local function saveSkinData()
    pcall(function()
        if isfolder and makefolder and not isfolder("B1NH") then makefolder("B1NH") end
        if writefile then writefile(SKIN_SAVE_FILE, HttpService:JSONEncode({swordModel = getgenv().swordModel or ""})) end
    end)
end
getgenv().saveLastEquippedSword = saveSkinData
local savedSkin = loadSkinSave()
getgenv().skinChanger = false
getgenv().skinChangerEnabled = false
getgenv().swordModel = savedSkin.swordModel or ""
getgenv().swordAnimations = savedSkin.swordModel or ""
getgenv().swordFX = savedSkin.swordModel or ""
getgenv().slashName = "SlashEffect"

task.spawn(function()
    local rs = game:GetService("ReplicatedStorage")
    local swordInstancesInstance = rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
    local swordInstances = require(swordInstancesInstance)
    local swordsController
    task.spawn(function()
        while task.wait(0.25) and not swordsController do
            local ok, conns = pcall(getconnections, rs.Remotes.FireSwordInfo.OnClientEvent)
            if ok and conns then
                for _, v in ipairs(conns) do
                    if v.Function and islclosure and islclosure(v.Function) then
                        local ok2, up = pcall(getupvalues, v.Function)
                        if ok2 and #up == 1 and type(up[1]) == "table" then swordsController = up[1]; break end
                    end
                end
            end
        end
    end)
    local function getSlashName(swordName)
        local ok, sln = pcall(function() return swordInstances:GetSword(swordName) end)
        return (ok and sln and sln.SlashName) or "SlashEffect"
    end
    local function refreshSlashName()
        local fxName = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
        if fxName ~= "" then getgenv().slashName = getSlashName(fxName)
        else getgenv().slashName = "SlashEffect" end
    end
    refreshSlashName()
    local function setSword()
        if not getgenv().skinChanger then return end
        if not LocalPlayer.Character then return end
        pcall(function()
            local f = rawget(swordInstances, "EquipSwordTo")
            if type(f) == "function" then
                local ups = getupvalues(f)
                for i = 1, #ups do if type(ups[i]) == "boolean" then setupvalue(f, i, false); break end end
            end
        end)
        pcall(function() swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel) end)
        task.spawn(function()
            local attempts = 0
            while not swordsController and attempts < 20 do task.wait(0.5); attempts = attempts + 1 end
            if not swordsController then return end
            pcall(function()
                if swordsController.SetSword then
                    swordsController:SetSword(getgenv().swordAnimations ~= "" and getgenv().swordAnimations or getgenv().swordModel)
                end
            end)
            pcall(function()
                local targetSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                if rs.Remotes:FindFirstChild("FireSwordInfo") then rs.Remotes.FireSwordInfo:FireServer(targetSword) end
                if swordsController.currentSword ~= nil then pcall(function() swordsController.currentSword = targetSword end) end
                if swordsController.SwordFX ~= nil then pcall(function() swordsController.SwordFX = targetSword end) end
            end)
        end)
    end
    local hookedFuncs = {}
    task.spawn(function()
        local remotesToHook = {"ParrySuccessAll", "ParryAttempt", "ParrySuccess", "PlaySound", "PlayVisuals"}
        while task.wait(1) do
            for _, remoteName in ipairs(remotesToHook) do
                local remote = rs.Remotes:FindFirstChild(remoteName)
                if remote and remote:IsA("RemoteEvent") then
                    local ok, conns = pcall(getconnections, remote.OnClientEvent)
                    if ok and type(conns) == "table" then
                        for _, v in ipairs(conns) do
                            local func = v.Function
                            if func and not hookedFuncs[func] then
                                hookedFuncs[func] = true
                                v:Disable()
                                local targetFunc = func
                                local ourFunc
                                ourFunc = function(...)
                                    local args = { ... }
                                    local isLocal = false
                                    for _, arg in ipairs(args) do
                                        if tostring(arg) == LocalPlayer.Name or (typeof(arg) == "Instance" and (arg == LocalPlayer.Character or arg == LocalPlayer)) then
                                            isLocal = true; break
                                        end
                                    end
                                    if isLocal and getgenv().skinChanger then
                                        local fxSword = getgenv().swordFX ~= "" and getgenv().swordFX or getgenv().swordModel
                                        refreshSlashName()
                                        local swordFound = false; local slashFound = false
                                        for i, arg in ipairs(args) do
                                            if type(arg) == "string" then
                                                if fxSword ~= "" and not slashFound and (arg:match("Slash") or arg == "Default" or arg:match("Effect")) then
                                                    args[i] = getgenv().slashName; slashFound = true
                                                elseif fxSword ~= "" and not swordFound then
                                                    local isSword = false
                                                    pcall(function()
                                                        if rs.Shared.ReplicatedInstances.Swords:FindFirstChild(arg) then isSword = true end
                                                    end)
                                                    if isSword or arg == LocalPlayer:GetAttribute("CurrentlyEquippedSword") then
                                                        args[i] = fxSword; swordFound = true
                                                    end
                                                end
                                            end
                                        end
                                        if fxSword ~= "" and not slashFound and type(args[1]) == "string" then args[1] = getgenv().slashName end
                                        if fxSword ~= "" and not swordFound and type(args[3]) == "string" then args[3] = fxSword end
                                    end
                                    if setthreadidentity then pcall(setthreadidentity, 2) end
                                    pcall(targetFunc, unpack(args))
                                end
                                hookedFuncs[ourFunc] = true
                                remote.OnClientEvent:Connect(ourFunc)
                            end
                        end
                    end
                end
            end
        end
    end)
    getgenv().updateSword = function()
        refreshSlashName()
        if getgenv().skinChanger and getgenv().swordModel ~= "" then saveSkinData() end
        setSword()
    end
    task.spawn(function()
        while task.wait(1) do
            if getgenv().skinChanger and getgenv().swordModel ~= "" then
                local char = LocalPlayer.Character
                if char then
                    if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then setSword() end
                    if not char:FindFirstChild(getgenv().swordModel) then setSword() end
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("Model") and v.Name ~= getgenv().swordModel then v:Destroy() end
                        task.wait()
                    end
                end
            end
        end
    end)
    LocalPlayer.CharacterAdded:Connect(function()
        if getgenv().skinChanger then
            getgenv().skinChanger = false
            task.wait(2)
            getgenv().skinChanger = true
            task.wait(0.5)
            pcall(function() getgenv().updateSword() end)
        end
    end)
end)

-- AVATAR CHANGER
local __players = cloneref(game:GetService('Players'))
local __localplayer = __players.LocalPlayer

local function saveOriginalAppearance()
    if _G.OriginalAppearance then return end
    local char = __localplayer.Character; if not char then return end
    _G.OriginalAppearance = {Face = nil, Shirt = nil, Pants = nil, BodyColors = nil, HeadMesh = nil, Accessories = {}, CharacterMeshes = {}}
    local head = char:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChildOfClass("Decal"); if face then _G.OriginalAppearance.Face = face.Texture end
        local headMesh = head:FindFirstChildOfClass("SpecialMesh"); if headMesh then _G.OriginalAppearance.HeadMesh = headMesh:Clone() end
    end
    local shirt = char:FindFirstChildOfClass("Shirt"); if shirt then _G.OriginalAppearance.Shirt = shirt.ShirtTemplate end
    local pants = char:FindFirstChildOfClass("Pants"); if pants then _G.OriginalAppearance.Pants = pants.PantsTemplate end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then
        _G.OriginalAppearance.BodyColors = {HeadColor3 = bc.HeadColor3, LeftArmColor3 = bc.LeftArmColor3, RightArmColor3 = bc.RightArmColor3, LeftLegColor3 = bc.LeftLegColor3, RightLegColor3 = bc.RightLegColor3, TorsoColor3 = bc.TorsoColor3}
    end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Accoutrement") then table.insert(_G.OriginalAppearance.Accessories, obj:Clone())
        elseif obj:IsA("CharacterMesh") then table.insert(_G.OriginalAppearance.CharacterMeshes, obj:Clone()) end
    end
end

local function restoreOriginalAppearance()
    local char = __localplayer.Character; if not char or not _G.OriginalAppearance then return end
    pcall(function()
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Accoutrement") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") or obj:IsA("ShirtGraphic") then obj:Destroy() end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChildOfClass("Decal"); if face then face:Destroy() end
            if _G.OriginalAppearance.Face then
                local newFace = Instance.new("Decal"); newFace.Name = "face"; newFace.Texture = _G.OriginalAppearance.Face; newFace.Parent = head
            end
            local headMesh = head:FindFirstChildOfClass("SpecialMesh"); if headMesh then headMesh:Destroy() end
            if _G.OriginalAppearance.HeadMesh then _G.OriginalAppearance.HeadMesh:Clone().Parent = head end
        end
        if _G.OriginalAppearance.Shirt then
            local shirt = Instance.new("Shirt"); shirt.Name = "Shirt"; shirt.ShirtTemplate = _G.OriginalAppearance.Shirt; shirt.Parent = char
        end
        if _G.OriginalAppearance.Pants then
            local pants = Instance.new("Pants"); pants.Name = "Pants"; pants.PantsTemplate = _G.OriginalAppearance.Pants; pants.Parent = char
        end
        if _G.OriginalAppearance.BodyColors then
            local bc = Instance.new("BodyColors")
            for k, v in pairs(_G.OriginalAppearance.BodyColors) do bc[k] = v end
            bc.Parent = char
        end
        for _, mesh in ipairs(_G.OriginalAppearance.CharacterMeshes) do mesh:Clone().Parent = char end
        for _, acc in ipairs(_G.OriginalAppearance.Accessories) do acc:Clone().Parent = char end
    end)
end

local function attachAccessoryManually(char, acc)
    local handle = acc:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then return end
    local accAttachment = handle:FindFirstChildOfClass("Attachment")
    local charAttachment
    if accAttachment then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                charAttachment = part:FindFirstChild(accAttachment.Name)
                if charAttachment then break end
            end
        end
    end
    if charAttachment then
        acc.Parent = char; handle.CanCollide = false; handle.Anchored = false
        local part = charAttachment.Parent
        if charAttachment:IsA("Attachment") and accAttachment then
            handle.CFrame = part.CFrame * charAttachment.CFrame * accAttachment.CFrame:Inverse()
        else handle.CFrame = part.CFrame * CFrame.new(0, 0, 0) end
        local weld = Instance.new("Weld"); weld.Name = "AccessoryWeld"; weld.Part0 = handle; weld.Part1 = part
        weld.C0 = accAttachment and accAttachment.CFrame or CFrame.new(0, 0.6, 0)
        weld.C1 = charAttachment:IsA("Attachment") and charAttachment.CFrame or CFrame.new()
        weld.Parent = handle
    else
        local part = char:FindFirstChild("Head")
        if part then
            acc.Parent = char; handle.CanCollide = false; handle.Anchored = false
            handle.CFrame = part.CFrame * CFrame.new(0, 0.6, 0)
            local weld = Instance.new("Weld"); weld.Name = "AccessoryWeld"; weld.Part0 = handle; weld.Part1 = part
            weld.C0 = CFrame.new(0, 0.6, 0); weld.C1 = CFrame.new(); weld.Parent = handle
        else acc.Parent = char end
    end
end

local function applyAvatarLocally(userId)
    local char = __localplayer.Character; if not char then return end
    local success, model = pcall(function() return __players:CreateHumanoidModelFromUserId(userId) end)
    if not success or not model then return end
    pcall(function()
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Accoutrement") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") or obj:IsA("ShirtGraphic") then obj:Destroy() end
        end
        local head = char:FindFirstChild("Head")
        local modelHead = model:FindFirstChild("Head")
        if head and modelHead then
            local face = head:FindFirstChildOfClass("Decal"); if face then face:Destroy() end
            local modelFace = modelHead:FindFirstChildOfClass("Decal"); if modelFace then modelFace:Clone().Parent = head end
            local headMesh = head:FindFirstChildOfClass("SpecialMesh")
            local modelMesh = modelHead:FindFirstChildOfClass("SpecialMesh")
            if modelMesh then if headMesh then headMesh:Destroy() end; modelMesh:Clone().Parent = head
            elseif headMesh then headMesh:Destroy() end
            head.Size = modelHead.Size; head.Color = modelHead.Color
        end
        for _, obj in ipairs(model:GetChildren()) do
            if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then obj:Clone().Parent = char
            elseif obj:IsA("Accessory") or obj:IsA("Accoutrement") then pcall(function() attachAccessoryManually(char, obj:Clone()) end) end
        end
        model:Destroy()
    end)
end

local __avatar_changer_target = ""
local __avatar_changer_enabled = false
local function __resolveTargetId(value)
    if value == nil or value == "" then return nil end
    local id = tonumber(value); if id then return id end
    local ok, resolved = pcall(function() return __players:GetUserIdFromNameAsync(value) end)
    if ok and resolved then return resolved end
    return nil
end

-- ABILITY ESP
local abilityEspBillboards = {}
local abilityEspConnections = {}
local abilityEspPlayerAddedConnection = nil

local function create_ability_esp_for_player(player)
    task.spawn(function()
        local character = player.Character
        while not character or not character.Parent do task.wait(0.5); character = player.Character end
        local head = character:WaitForChild('Head', 10)
        if not head or not getgenv().AbilityESP then return end
        local existing = head:FindFirstChild('AbilityESPGui'); if existing then existing:Destroy() end
        local billboard = Instance.new('BillboardGui')
        billboard.Name = 'AbilityESPGui'; billboard.Adornee = head
        billboard.Size = UDim2.new(0, 220, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0); billboard.AlwaysOnTop = true
        billboard.Parent = head
        local label = Instance.new('TextLabel')
        label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255); label.TextSize = 14
        label.TextStrokeTransparency = 0; label.Font = Enum.Font.Roboto
        label.RichText = true; label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center; label.Parent = billboard
        label.Visible = false
        abilityEspBillboards[player] = label
        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
        local heartbeatConnection
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            if not (character and character.Parent) then
                if heartbeatConnection then heartbeatConnection:Disconnect() end
                pcall(function() billboard:Destroy() end)
                abilityEspBillboards[player] = nil; return
            end
            if getgenv().AbilityESP then
                label.Visible = true
                local ability = player:GetAttribute('EquippedAbility')
                if ability then label.Text = '<b>' .. player.DisplayName .. ' [' .. ability .. ']' .. '</b>'
                else label.Text = '<b>' .. player.DisplayName .. '</b>' end
            else label.Visible = false end
        end)
        abilityEspConnections[player] = heartbeatConnection
    end)
end

local function add_ability_esp_player(player)
    if player == LocalPlayer then return end
    if abilityEspConnections[player] then
        pcall(function() abilityEspConnections[player]:Disconnect() end)
        abilityEspConnections[player] = nil
    end
    player.CharacterAdded:Connect(function() create_ability_esp_for_player(player) end)
    if player.Character then task.spawn(function() create_ability_esp_for_player(player) end) end
end

function start_ability_esp()
    if abilityEspPlayerAddedConnection and next(abilityEspConnections) then return end
    getgenv().AbilityESP = true
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then add_ability_esp_player(player) end
    end
    if not abilityEspPlayerAddedConnection then
        abilityEspPlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
            if getgenv().AbilityESP then add_ability_esp_player(player) end
        end)
    end
end

function stop_ability_esp()
    if not getgenv().AbilityESP then return end
    getgenv().AbilityESP = false
    if abilityEspPlayerAddedConnection then
        pcall(function() abilityEspPlayerAddedConnection:Disconnect() end)
        abilityEspPlayerAddedConnection = nil
    end
    for _, connection in pairs(abilityEspConnections) do pcall(function() connection:Disconnect() end) end
    abilityEspConnections = {}
    for _, label in pairs(abilityEspBillboards) do
        pcall(function() if label and label.Parent then label.Parent:Destroy() end end)
    end
    abilityEspBillboards = {}
end

-- ============================================================
-- BALL VELOCITY (OXY STYLE)
-- ============================================================
System.__properties.__ball_velocity_gui = nil
System.__properties.__ball_velocity_label = nil
System.__properties.__ball_velocity_peaks = {}
System.__properties.__ball_velocity_conn = nil
System.__properties.__ball_velocity_enabled = false

function System.start_ball_velocity()
    -- Cleanup old
    if System.__properties.__ball_velocity_conn then
        pcall(function() System.__properties.__ball_velocity_conn:Disconnect() end)
        System.__properties.__ball_velocity_conn = nil
    end
    if System.__properties.__ball_velocity_gui then
        pcall(function() System.__properties.__ball_velocity_gui:Destroy() end)
        System.__properties.__ball_velocity_gui = nil
    end
    System.__properties.__ball_velocity_peaks = {}
    System.__properties.__ball_velocity_label = nil

    -- Build ScreenGui (Oxy style)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "B1NH_BallVelocity"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = CoreGui

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
    TextLabel.Position = UDim2.new(0.7, 0, 0.1, 0)
    TextLabel.TextSize = 26
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.Font = Enum.Font.Fantasy
    TextLabel.Text = "waiting..."
    TextLabel.Parent = ScreenGui

    System.__properties.__ball_velocity_gui = ScreenGui
    System.__properties.__ball_velocity_label = TextLabel

    -- Oxy-style heartbeat loop
    System.__properties.__ball_velocity_conn = RunService.Heartbeat:Connect(function()
        if not System.__properties.__ball_velocity_enabled then return end
        local label = System.__properties.__ball_velocity_label
        if not label or not label.Parent then return end

        local currentBalls = System.ball.get_all()
        if #currentBalls == 0 then
            label.Text = "waiting..."
            label.TextColor3 = Color3.new(1, 1, 1)
            return
        end

        -- Build lookup of current balls
        local aliveSet = {}
        for _, b in ipairs(currentBalls) do
            aliveSet[b] = true
        end

        -- Prune peaks of dead balls
        for k in pairs(System.__properties.__ball_velocity_peaks) do
            if not aliveSet[k] then
                System.__properties.__ball_velocity_peaks[k] = nil
            end
        end

        -- Find max speed across all balls
        local maxSpeed = 0
        local bestBall = nil
        for _, ball in ipairs(currentBalls) do
            local zoomies = ball:FindFirstChild("zoomies")
            if zoomies then
                local speed = zoomies.VectorVelocity.Magnitude
                local peak = math.max(System.__properties.__ball_velocity_peaks[ball] or 0, speed)
                System.__properties.__ball_velocity_peaks[ball] = peak
                if peak > maxSpeed then
                    maxSpeed = peak
                    bestBall = ball
                end
            end
        end

        if bestBall then
            local isLimit = maxSpeed >= 2200
            label.Text = string.format("ball velocity: %.0f", maxSpeed) .. (isLimit and " (LIMIT!)" or "")
            label.TextColor3 = isLimit and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
        else
            label.Text = "waiting..."
            label.TextColor3 = Color3.new(1, 1, 1)
        end
    end)
end

function System.stop_ball_velocity()
    if System.__properties.__ball_velocity_conn then
        pcall(function() System.__properties.__ball_velocity_conn:Disconnect() end)
        System.__properties.__ball_velocity_conn = nil
    end
    if System.__properties.__ball_velocity_gui then
        pcall(function() System.__properties.__ball_velocity_gui:Destroy() end)
        System.__properties.__ball_velocity_gui = nil
    end
    System.__properties.__ball_velocity_peaks = {}
    System.__properties.__ball_velocity_label = nil
end

-- PING GUI
local PingGui = Instance.new("ScreenGui", CoreGui)
PingGui.Name = "B1NHPing"; PingGui.ResetOnSpawn = false
PingGui.IgnoreGuiInset = true; PingGui.DisplayOrder = 999; PingGui.Enabled = false
local PingFrame = Instance.new("Frame", PingGui)
PingFrame.Size = UDim2.new(0, 110, 0, 35); PingFrame.Position = UDim2.new(0, 15, 0.88, 0)
PingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); PingFrame.BackgroundTransparency = 0.3
PingFrame.BorderSizePixel = 0; PingFrame.Active = true; PingFrame.Draggable = true
Instance.new("UICorner", PingFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", PingFrame).Color = Color3.fromRGB(60, 60, 60)
local PingLabel = Instance.new("TextLabel", PingFrame)
PingLabel.Size = UDim2.new(1, 0, 1, 0); PingLabel.Text = "Ping: 0ms"
PingLabel.TextColor3 = Color3.fromRGB(255, 255, 255); PingLabel.BackgroundTransparency = 1
PingLabel.Font = Enum.Font.GothamBold; PingLabel.TextSize = 14
PingLabel.TextXAlignment = Enum.TextXAlignment.Center

task.spawn(function()
    while task.wait(0.5) do
        if System.__properties.__show_ping then
            local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
            local color = Color3.fromRGB(0, 255, 0)
            if ping > 150 then color = Color3.fromRGB(255, 165, 0)
            elseif ping > 300 then color = Color3.fromRGB(255, 0, 0) end
            PingLabel.Text = string.format("Ping: <font color='#%02x%02x%02x'>%dms</font>", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255), ping)
            PingLabel.RichText = true
        end
    end
end)

-- ============================================================
-- UI TABS CONTENT (FLUENT STYLE)
-- ============================================================

-- AUTOPARRY TAB
local AS = Tabs.Rage:AddSection("Auto Parry", "shield")
AS:AddToggle("AutoParryToggle", {
    Title = "Auto Parry",
    Description = "Automatically parries ball",
    Default = false,
    Callback = function(v)
        System.__properties.__autoparry_enabled = v
        System.__properties.__play_animation = v
        if v then System.autoparry.start() else System.autoparry.stop() end
        Notify("Auto Parry", v and "ON" or "OFF", 2)
    end
})
AS:AddDropdown("ParryMode", {Title = "Parry Mode", Values = {"Remote", "Keypress"}, Default = "Remote", Multi = false, Callback = function(v) getgenv().AutoParryMode = v end})
AS:AddDropdown("CurveMode", {Title = "Curve Mode", Values = System.__config.__curve_names, Default = "Camera", Multi = false, Callback = function(v)
    for i, n in ipairs(System.__config.__curve_names) do if n == v then System.__properties.__curve_mode = i; break end end
end})
AS:AddSlider("Accuracy", {Title = "Accuracy", Default = 50, Min = 1, Max = 100, Rounding = 1, Callback = function(v) System.__properties.__accuracy = v; update_divisor() end})
AS:AddToggle("RandomCurve", {Title = "Random Curve", Default = false, Callback = function(s)
    if s then
        if not System.__properties.__connections.__rc then
            System.__properties.__connections.__rc = RunService.PreSimulation:Connect(function()
                System.__properties.__curve_mode = math.random(1, #System.__config.__curve_names)
            end)
        end
    else
        if System.__properties.__connections.__rc then
            System.__properties.__connections.__rc:Disconnect()
            System.__properties.__connections.__rc = nil
        end
    end
end})
AS:AddToggle("AutoAbility", {Title = "Auto Ability", Default = false, Callback = function(v)
    System.__properties.__auto_ability_enabled = v
    Notify("Auto Ability", v and "ON" or "OFF", 2)
end})
AS:AddToggle("CooldownProtection", {Title = "Cooldown Protection", Default = false, Callback = function(v)
    System.__properties.__cooldown_protection = v
    Notify("Cooldown Protection", v and "ON" or "OFF", 2)
end})

-- TRIGGERBOT
local TBS = Tabs.Rage:AddSection("Triggerbot", "target")
TBS:AddToggle("TriggerbotToggle", {
    Title = "Triggerbot",
    Description = "Parries instantly if targeted",
    Default = false,
    Callback = function(v)
        System.__properties.__triggerbot_enabled = v
        System.triggerbot.enable(v)
        Notify("Triggerbot", v and "ON" or "OFF", 2)
        if isMobile then
            if v then
                if not System.__properties.__mobile_guis.triggerbot then
                    local tb = create_mobile_button('Trigger', 0.20, Color3.fromRGB(255, 100, 0), 0.15)
                    System.__properties.__mobile_guis.triggerbot = tb
                    tb.button.MouseButton1Click:Connect(function()
                        System.__properties.__triggerbot_enabled = not System.__properties.__triggerbot_enabled
                        System.triggerbot.enable(System.__properties.__triggerbot_enabled)
                        if System.__properties.__triggerbot_enabled then
                            tb.text.Text = "ON"
                            tb.text.TextColor3 = Color3.fromRGB(0, 255, 100)
                        else
                            tb.text.Text = "Trigger"
                            tb.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                        Notify("Triggerbot", System.__properties.__triggerbot_enabled and "ON" or "OFF", 2)
                    end)
                end
            else
                destroy_mobile_gui(System.__properties.__mobile_guis.triggerbot)
                System.__properties.__mobile_guis.triggerbot = nil
            end
        end
    end
})

-- DETECTION TAB
local DS1 = Tabs.Detection:AddSection("Infinity", "infinity")
DS1:AddToggle("DetInfinity", {Title = "Infinity Detection", Default = false, Callback = function(v) System.__config.__detections.__infinity = v end})
local DS2 = Tabs.Detection:AddSection("Death Slash", "skull")
DS2:AddToggle("DetDeathSlash", {Title = "Death Slash Detection", Default = false, Callback = function(v) System.__config.__detections.__deathslash = v end})
local DS3 = Tabs.Detection:AddSection("Time Hole", "clock")
DS3:AddToggle("DetTimeHole", {Title = "Time Hole Detection", Default = false, Callback = function(v) System.__config.__detections.__timehole = v end})
local DS4 = Tabs.Detection:AddSection("Slashes Of Fury", "swords")
DS4:AddToggle("DetSlashes", {Title = "Slashes Detection", Default = false, Callback = function(v) System.__config.__detections.__slashesoffury = v end})
DS4:AddSlider("SlashesDelay", {Title = "Parry Delay", Default = 0.05, Min = 0.05, Max = 0.25, Rounding = 2, Callback = function(v) parryDelay = v end})
DS4:AddSlider("SlashesMax", {Title = "Max Parry Count", Default = 36, Min = 1, Max = 100, Rounding = 0, Callback = function(v) maxParryCount = v end})
local DS5 = Tabs.Detection:AddSection("Anti-Phantom [BETA]", "ghost")
DS5:AddToggle("DetPhantom", {Title = "Anti-Phantom [BETA]", Default = false, Callback = function(v) System.__config.__detections.__phantom = v end})

-- SPAM TAB
local SP = Tabs.Spam:AddSection("Manual Spam", "zap")
SP:AddToggle("ManualSpamToggle", {
    Title = "Manual Spam",
    Description = "High-frequency parry spam",
    Default = false,
    Callback = function(v)
        System.__properties.__manual_spam_enabled = v
        Notify("Manual Spam", v and "ON" or "OFF", 2)
        if isMobile then
            if v then
                if not System.__properties.__mobile_guis.manual_spam then
                    local sm = create_mobile_button('Spam', 0.35, Color3.fromRGB(255, 255, 255), 0.15)
                    System.__properties.__mobile_guis.manual_spam = sm
                    sm.button.MouseButton1Click:Connect(function()
                        System.__properties.__manual_spam_enabled = not System.__properties.__manual_spam_enabled
                        if System.__properties.__manual_spam_enabled then
                            sm.text.Text = "ON"
                            sm.text.TextColor3 = Color3.fromRGB(0, 255, 100)
                        else
                            sm.text.Text = "Spam"
                            sm.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                        Notify("Manual Spam", System.__properties.__manual_spam_enabled and "ON" or "OFF", 2)
                    end)
                end
            else
                destroy_mobile_gui(System.__properties.__mobile_guis.manual_spam)
                System.__properties.__mobile_guis.manual_spam = nil
            end
        end
    end
})
SP:AddDropdown("SpamMode", {Title = "Mode", Values = {"Remote", "Keypress"}, Default = "Remote", Multi = false, Callback = function(v) getgenv().ManualSpamMode = v end})
SP:AddToggle("SpamAnimFix", {Title = "Animation Fix", Default = false, Callback = function(v)
    getgenv().ManualSpamAnimationFix = v
    macroAnimFix = v
end})

-- PLAYER TAB
local AVC = Tabs.Player:AddSection("Avatar Changer", "user")
AVC:AddInput("AvatarTarget", {Title = "Target Username", Placeholder = "Username or User ID", Default = "", Callback = function(t)
    __avatar_changer_target = t
end})
AVC:AddToggle("AvatarEnabled", {Title = "Enable Avatar Changer", Default = false, Callback = function(v)
    __avatar_changer_enabled = v
    if v then
        local userId = __resolveTargetId(__avatar_changer_target)
        if userId then
            saveOriginalAppearance(); applyAvatarLocally(userId)
            Notify("Avatar Changer", "Appearance changed!", 3)
        else Notify("Avatar Changer", "Invalid username or ID!", 3) end
    else
        restoreOriginalAppearance()
        Notify("Avatar Changer", "Appearance restored!", 2)
    end
end})

local HK = Tabs.Player:AddSection("Headless & Korblox", "user")
HK:AddToggle("Headless", {Title = "Headless", Default = false, Callback = function(v)
    System.__properties.__headless_enabled = v
    local c = LocalPlayer.Character
    if c then if v then Byte_Library.Headless(c) else Byte_Library.Restore_Head(c) end end
end})
HK:AddToggle("Korblox", {Title = "Korblox", Default = false, Callback = function(v)
    System.__properties.__korblox_enabled = v
    local c = LocalPlayer.Character
    if c then if v then Byte_Library.Korblox(c) else Byte_Library.Restore_Leg(c) end end
end})

-- VISUALS TAB
local VS = Tabs.Visuals:AddSection("Ball Stats", "gauge")
VS:AddToggle("BallVelocityToggle", {Title = "Ball Velocity", Default = false, Callback = function(v)
    System.__properties.__ball_velocity_enabled = v
    if v then
        System.start_ball_velocity()
        Notify("Ball Velocity", "ON", 2)
    else
        System.stop_ball_velocity()
        Notify("Ball Velocity", "OFF", 2)
    end
end})
VS:AddToggle("ShowPing", {Title = "Show Real Ping", Default = false, Callback = function(v)
    System.__properties.__show_ping = v
    PingGui.Enabled = v
end})

local AE = Tabs.Visuals:AddSection("Ability ESP", "eye")
AE:AddToggle("AbilityESP", {Title = "Ability ESP", Default = false, Callback = function(s)
    if s then start_ability_esp(); Notify("Ability ESP", "ON", 2)
    else stop_ability_esp(); Notify("Ability ESP", "OFF", 2) end
end})

-- MISC TAB
local SC = Tabs.Misc:AddSection("Skin Changer", "sword")
SC:AddToggle("SkinChanger", {Title = "Skin Changer", Default = false, Callback = function(v)
    getgenv().skinChanger = v
    getgenv().skinChangerEnabled = v
    if v and getgenv().swordModel ~= "" then
        if getgenv().updateSword then pcall(getgenv().updateSword) end
        Notify("Skin Changer", "Enabled", 2)
    else Notify("Skin Changer", "Disabled", 2) end
end})
SC:AddInput("SwordName", {Title = "Sword Name", Placeholder = "e.g. DualPrince", Default = "", Callback = function(t)
    getgenv().swordModel = t
    getgenv().swordAnimations = t
    getgenv().swordFX = t
    if getgenv().skinChangerEnabled and t ~= "" then
        if getgenv().updateSword then pcall(getgenv().updateSword) end
    end
    if getgenv().saveLastEquippedSword then pcall(getgenv().saveLastEquippedSword) end
end})

-- NO RENDER
local NR = Tabs.Misc:AddSection("No Render", "eye-off")
local Connections_Manager = {}
NR:AddToggle("NoRender", {Title = "No Render", Default = false, Callback = function(state)
    local effectScripts = LocalPlayer.PlayerScripts:FindFirstChild("EffectScripts")
    if effectScripts then
        local clientFX = effectScripts:FindFirstChild("ClientFX")
        if clientFX then clientFX.Disabled = state end
    end
    if state then
        Connections_Manager['No Render'] = Workspace.Runtime.ChildAdded:Connect(function(Value) Debris:AddItem(Value, 0) end)
    else
        if Connections_Manager['No Render'] then
            Connections_Manager['No Render']:Disconnect()
            Connections_Manager['No Render'] = nil
        end
    end
end})

-- AUTO JUMP
local AutoJump = false
local ajLastOnGround = false
local AJ = Tabs.Misc:AddSection("Auto Jump", "arrow-up")
AJ:AddToggle("AutoJumpToggle", {Title = "Auto Jump", Default = false, Callback = function(v)
    AutoJump = v
    if not v then ajLastOnGround = false end
    Notify("Auto Jump", v and "ON" or "OFF", 2)
end})

RunService.Heartbeat:Connect(function()
    if AutoJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local onGround = hum.FloorMaterial ~= Enum.Material.Air
            if onGround and not ajLastOnGround then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            ajLastOnGround = onGround
        end
    else ajLastOnGround = false end
end)

-- ============================================================
-- SAVE MANAGER / INTERFACE MANAGER
-- ============================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("B1NH")
SaveManager:SetFolder("B1NH/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

-- ============================================================
-- KEYBIND HANDLER (PC + Xbox + PS)
-- ============================================================
local spamKeyCode = Enum.KeyCode.E
local trigKeyCode = Enum.KeyCode.R
local jumpKeyCode = Enum.KeyCode.J

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local kc = input.KeyCode
    local cmap = {[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,[Enum.KeyCode.Six]=6,[Enum.KeyCode.Seven]=7,[Enum.KeyCode.Eight]=8,[Enum.KeyCode.Nine]=9}
    if cmap[kc] then
        System.__properties.__curve_mode = cmap[kc]
        Notify("Curve Mode", System.__config.__curve_names[cmap[kc]], 1)
    end
    if kc == spamKeyCode then
        System.__properties.__manual_spam_enabled = not System.__properties.__manual_spam_enabled
        Notify("Manual Spam", System.__properties.__manual_spam_enabled and "ON" or "OFF", 1)
    end
    if kc == trigKeyCode then
        local n = not System.__properties.__triggerbot_enabled
        System.__properties.__triggerbot_enabled = n
        System.triggerbot.enable(n)
        Notify("Triggerbot", n and "ON" or "OFF", 1)
    end
    if kc == jumpKeyCode then
        AutoJump = not AutoJump
        if not AutoJump then ajLastOnGround = false end
        Notify("Auto Jump", AutoJump and "ON" or "OFF", 1)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Gamepad1 and
       input.UserInputType ~= Enum.UserInputType.Gamepad2 then return end
    local kc = input.KeyCode
    if kc == spamKeyCode then
        System.__properties.__manual_spam_enabled = not System.__properties.__manual_spam_enabled
        Notify("Manual Spam", System.__properties.__manual_spam_enabled and "ON" or "OFF", 1)
    end
    if kc == trigKeyCode then
        local n = not System.__properties.__triggerbot_enabled
        System.__properties.__triggerbot_enabled = n
        System.triggerbot.enable(n)
        Notify("Triggerbot", n and "ON" or "OFF", 1)
    end
end)

-- ============================================================
-- MOBILE UI
-- ============================================================
if isMobile then
    task.spawn(function()
        task.wait(3)
        create_mobile_ui_button()
    end)
end

-- ============================================================
-- FINAL
-- ============================================================
Fluent:Notify({
    Title = "B1NH",
    Content = "Loaded successfully! First block yourself.",
    Duration = 8
})

print("B1NH | Loaded! | Mobile: " .. tostring(isMobile))

end)
