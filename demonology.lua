-- bro obfuscated this script in Base 64 ðŸ’€ Chat gpt 100%
-- DÐµÐ¾Ð¬fuÑ•ÑÐ°tÐµd bÑƒ LeÐ°ÎºD | discord.gg/qteAQmfJmP

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  Demonology Hub  |  v1.0   (analysed live via MCP)
--  Game : DEMONOLOGY (Phasmophobia-style ghost hunt) | GameId 6170143659
--         ("Site d'emploi"is just the lobby sub-place)
--  Creator group: Blaqk Magic Blue
--
--  Analysis notes:
--   â€¢ No VM, no client anti-cheat, no position/speed validation.
--   â€¢ Movement + Stamina are 100% CLIENT-SIDE (Humanoid.WalkSpeed is set locally;
--     Stamina is a LocalPlayer attribute drained/regen'd in a local loop)  Speed,
--     Infinite Stamina, NoClip, Fly all work cleanly.
--   â€¢ workspace.Ghost is a real model in Workspace and exposes attributes:
--     CurrentRoom (live), FavoriteRoom (nest), Age, Gender, VisualModel, IsGhost,
--     and Hunting / EventActive during a hunt  Ghost ESP + Hunt detection.
--   â€¢ All 25 ghost-type modules expose their Evidence list client-side  Solver.
--   â€¢ Death is SERVER-authoritative â€” true godmode isn't possible. Instead the
--     ghost ground-pathfinds, so Auto-Escape (lift you up) reliably survives hunts.
--   â€¢ Money is server-side player data (can't be set); the script earns it fast by
--     trivialising the contract loop (find ghost  ID  objectives  survive).
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

if not game:IsLoaded() then game.Loaded:Wait() end

-- â”€â”€ UI library loader (Y2k Core one-liner) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local Y2k = loadstring(game:HttpGet("https://y2kscript.xyz/lib?f=Core.lua&cb=" .. tostring(math.random(1, 1e7))))()
local Library, ThemeManager, SaveManager = Y2k.Library, Y2k.ThemeManager, Y2k.SaveManager
local StatsPanel, Watermark, Keybinds = Y2k.StatsPanel, Y2k.Watermark, Y2k.Keybinds
local Toggles, Options = Y2k.Toggles, Y2k.Options

if Y2k.claim and not Y2k.claim("Demonology") then
    pcall(function() Library:Notify({ Title = "Demonology", Description = "Already running - press Right Ctrl to toggle the menu.", Time = 5 }) end)
    return
end

-- â”€â”€ services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local SoundService      = game:GetService("SoundService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera

local Events = ReplicatedStorage:WaitForChild("Events")
local Modules = ReplicatedStorage:WaitForChild("Modules")

-- â”€â”€ executor-identity stealth (precautionary; no AC actually present) â”€â”€â”€â”€â”€â”€â”€â”€
pcall(function()
    if type(hookfunction) == "function" and type(identifyexecutor) == "function" then
        local fake = newcclosure and newcclosure(function() return "Synapse Z", "3.0.0" end) or function() return "Synapse Z", "3.0.0" end
        pcall(hookfunction, identifyexecutor, fake)
        if getgenv then getgenv().identifyexecutor = function() return "Synapse Z", "3.0.0" end end
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  CONFIG
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local Cfg = {
    -- ghost
    GhostESP = false, GhostTracer = false, GhostInfo = true, GhostChams = true,
    RoomHL = false, StatsPanel = true,
    -- solver
    Found = {},                 -- evidenceNumber -> true (confirmed present)
    -- survival
    HuntWarn = false, AutoEscape = false, EscapeHeight = 300, AutoRevive = false,
    -- auto-task
    AutoTask = false, AutoPhoto = false, AutoCursed = false, AutoLeave = false, LeaveAfter = 4,
    -- movement
    WalkSpeed = false, WalkSpeedAmt = 26, InfStamina = false, InfJump = false,
    NoClip = false, Fly = false, FlySpeed = 70, FlyKey = "F",
    -- items
    ItemESP = false, CursedESP = false, ItemMax = 700, PickupRange = false, PickupAmt = 30,
    InstantDoors = false,
    -- visuals
    Fullbright = false, NightVision = false, NoFog = false, NoShake = false,
    NoScreenFX = false, FOV = false, FOVValue = 90, Crosshair = false,
    -- players
    PlayerESP = false, PlayerMax = 1500,
    -- misc
    AntiAFK = true,
    _dead = false,
}

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function notify(t, d, dur) pcall(function() Library:Notify({ Title = t, Description = d, Time = dur or 4 }) end) end
local function char() return LocalPlayer.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = char(); return c and (c.PrimaryPart or c:FindFirstChild("HumanoidRootPart")) end
local function getGhost() return Workspace:FindFirstChild("Ghost") end
local function ghostRoot() local g = getGhost(); return g and (g.PrimaryPart or g:FindFirstChild("HumanoidRootPart")) end
local function dist(a, b) if not (a and b) then return math.huge end return (a.Position - b.Position).Magnitude end

local req = (syn and syn.request) or http_request or request or (http and http.request)

-- â”€â”€ contract / auto-task helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function finishJob()
    pcall(function() Events.RequestReturnToLobby:FireServer() end)   -- the truck "Finish Job"
end
local function tryEquip(name)
    pcall(function() Events.RequestItemEquip:FireServer(name) end)
end
local function tryPhoto()
    local g, r = getGhost(), root()
    if not (g and r) then return end
    tryEquip("Photo Camera")
    task.wait(0.45)
    local gr = ghostRoot()
    if gr then pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, gr.Position) end) end
    task.wait(0.1)
    pcall(function() Events.TakePhotoWithCamera:InvokeServer() end)   -- server validates ghost-in-frame
end
local function tryCursed()
    local h = Workspace:FindFirstChild("CursedPossessionHolder")
    if not h then return end
    if typeof(fireproximityprompt) ~= "function" then return end
    for _, c in ipairs(h:GetDescendants()) do
        if c:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(c) end) end
    end
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  EVIDENCE / GHOST DATA  (built live from the game's own modules)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local EVID_NAME = { [1]="EMF Level 5",[2]="Spirit Box",[3]="Ghost Writing",[4]="Freezing Temps",
                    [5]="Ghost Orb",[6]="Fingerprints",[7]="Laser Projector",[8]="Wither" }
local GHOST_DATA = {}        -- { name = {ev1,ev2,ev3} }
pcall(function()
    local GT = Modules:FindFirstChild("GhostTypes")
    if not GT then return end
    for _, m in ipairs(GT:GetChildren()) do
        if m:IsA("ModuleScript") then
            local ok, d = pcall(require, m)
            if ok and type(d) == "table" and d.Evidence then
                local set = {}
                for _, ev in ipairs(d.Evidence) do set[#set + 1] = tonumber(ev) end
                GHOST_DATA[d.Name or m.Name] = set
            end
        end
    end
end)

local function solveGhosts()
    -- returns list of candidate ghost names whose evidence set contains all confirmed evidences
    local out = {}
    for name, set in pairs(GHOST_DATA) do
        local ok = true
        for evNum in pairs(Cfg.Found) do
            local has = false
            for _, e in ipairs(set) do if e == evNum then has = true break end end
            if not has then ok = false break end
        end
        if ok then out[#out + 1] = name end
    end
    table.sort(out)
    return out
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ESP STORAGE
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local espHolder = Instance.new("Folder"); espHolder.Name = "\0SiteESP"; espHolder.Parent = game:GetService("CoreGui")
local ghostTags, itemTags, playerTags = {}, {}, {}

local function makeHighlight(parent, fill, outline)
    local h = Instance.new("Highlight")
    h.FillColor = fill; h.OutlineColor = outline or Color3.new(1,1,1)
    h.FillTransparency = 0.55; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = parent; h.Parent = espHolder
    return h
end
local function makeLabel(adornee, color)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(220, 36); bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true; bb.Adornee = adornee; bb.Parent = espHolder
    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1; tl.Size = UDim2.fromScale(1,1); tl.Font = Enum.Font.GothamBold
    tl.TextSize = 14; tl.TextColor3 = color or Color3.new(1,1,1); tl.TextStrokeTransparency = 0
    tl.Parent = bb
    return bb, tl
end
local function clearTags(tbl)
    for k, t in pairs(tbl) do
        pcall(function() if t.hl then t.hl:Destroy() end if t.bb then t.bb:Destroy() end if t.tracer then t.tracer:Remove() end end)
        tbl[k] = nil
    end
end

-- â”€â”€ tracer (Drawing) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function newTracer(col)
    local ok, l = pcall(function() return Drawing.new("Line") end)
    if not ok or not l then return nil end
    l.Thickness = 1.6; l.Color = col or Color3.fromRGB(255,80,80); l.Transparency = 1; l.Visible = false
    return l
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  WINDOW
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local Window = Library:CreateWindow({
    Title = "Demonology  â€¢  Y2K Script",
    Footer = "GHOST HUNT",
    NotifySide = "Right", ShowCustomCursor = true, Center = true, AutoShow = true, Resizable = true, CornerRadius = 10,
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Tabs = {
    Ghost    = Window:AddTab("Ghost",    "ghost"),
    Survival = Window:AddTab("Survival", "shield"),
    Movement = Window:AddTab("Movement", "activity"),
    Items    = Window:AddTab("Items",    "package"),
    Visual   = Window:AddTab("Visuals",  "eye"),
    Players  = Window:AddTab("Players",  "users"),
    Settings = Window:AddTab("Settings", "settings"),
    Credits  = Window:AddTab("Credits",  "info"),
}

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  GHOST TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local ghL = Tabs.Ghost:AddLeftGroupbox("Ghost ESP", "ghost")
ghL:AddToggle("GhostESP", { Text = "Ghost Highlight", Default = false,
    Tooltip = "Highlights the ghost (workspace.Ghost) through walls.",
    Callback = function(v) Cfg.GhostESP = v notify("Ghost Highlight", v and "ON" or "OFF") end })
ghL:AddToggle("GhostInfo", { Text = "Ghost Info Tag", Default = true,
    Tooltip = "Floating tag: distance, current room, favorite room, age, gender, model.",
    Callback = function(v) Cfg.GhostInfo = v notify("Ghost Info Tag", v and "ON" or "OFF") end })
ghL:AddToggle("GhostTracer", { Text = "Ghost Tracer Line", Default = false,
    Callback = function(v) Cfg.GhostTracer = v notify("Ghost Tracer Line", v and "ON" or "OFF") end })
ghL:AddToggle("RoomHL", { Text = "Highlight Ghost Room", Default = false,
    Tooltip = "Outlines the room the ghost is currently in.",
    Callback = function(v) Cfg.RoomHL = v notify("Highlight Ghost Room", v and "ON" or "OFF") end })

local ghInfo = Tabs.Ghost:AddLeftGroupbox("Live Ghost Data", "search")
ghInfo:AddLabel({ Text = "Shows a live stats panel (room, nest, bio, hunt state). Toggle it from the Settings tab.", DoesWrap = true })

-- â”€â”€ Ghost Solver â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local slv = Tabs.Ghost:AddRightGroupbox("Ghost Solver", "book")
slv:AddLabel({ Text = "Tick each evidence you confirm in-game. The list narrows to the matching ghost(s).", DoesWrap = true })
local lblSolve = slv:AddLabel({ Text = "Candidates: all 25", DoesWrap = true })
local function refreshSolver()
    local cand = solveGhosts()
    local conf = {}
    for n in pairs(Cfg.Found) do conf[#conf + 1] = EVID_NAME[n] end
    if #cand == 1 then
        pcall(function() lblSolve:SetText("GHOST: " .. cand[1] .. "\nEvidence: " .. (#conf > 0 and table.concat(conf, ", ") or "none yet")) end)
    else
        pcall(function() lblSolve:SetText("Candidates (" .. #cand .. "): " .. (table.concat(cand, ", "))) end)
    end
end
for n = 1, 8 do
    slv:AddToggle("Ev" .. n, { Text = EVID_NAME[n], Default = false, Callback = function(v)
        if v then Cfg.Found[n] = true else Cfg.Found[n] = nil end
        refreshSolver()
    notify(EVID_NAME[n], v and "ON" or "OFF") end })
end
slv:AddButton({ Text = "Reset Evidence", Func = function()
    Cfg.Found = {}
    for n = 1, 8 do pcall(function() Toggles["Ev" .. n]:SetValue(false) end) end
    refreshSolver()
notify("Reset Evidence", "done") end })
slv:AddDivider()
local refBox = Tabs.Ghost:AddRightGroupbox("Evidence Reference", "list")
refBox:AddLabel({ Text = "Each ghost = 3 evidences. Open this if you want the full chart.", DoesWrap = true })
local chartShown = false
local lblChart = refBox:AddLabel({ Text = "(hidden)", DoesWrap = true })
refBox:AddButton({ Text = "Toggle Full Chart", Func = function()
    chartShown = not chartShown
    if not chartShown then pcall(function() lblChart:SetText("(hidden)") end) return end
    local lines = {}
    local names = {}
    for nm in pairs(GHOST_DATA) do names[#names + 1] = nm end
    table.sort(names)
    for _, nm in ipairs(names) do
        local evs = {}
        for _, e in ipairs(GHOST_DATA[nm]) do evs[#evs + 1] = EVID_NAME[e] or tostring(e) end
        lines[#lines + 1] = nm .. ": " .. table.concat(evs, ", ")
    end
    pcall(function() lblChart:SetText(table.concat(lines, "\n")) end)
notify("Toggle Full Chart", "done") end })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  SURVIVAL TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local svL = Tabs.Survival:AddLeftGroupbox("Anti-Hunt", "shield")
svL:AddLabel({ Text = "Death is server-side (no true godmode). The ghost pathfinds on the ground, so lifting you up survives a hunt.", DoesWrap = true })
svL:AddToggle("HuntWarn", { Text = "Hunt Warning", Default = false,
    Tooltip = "Big alert + sound when the ghost starts hunting.",
    Callback = function(v) Cfg.HuntWarn = v notify("Hunt Warning", v and "ON" or "OFF") end })
svL:AddToggle("AutoEscape", { Text = "Auto-Escape (lift up on hunt)", Default = false, Risky = true,
    Tooltip = "Anchors and raises you while the ghost hunts, drops you back when it ends.",
    Callback = function(v) Cfg.AutoEscape = v notify("Auto-Escape (lift up on hunt)", v and "ON" or "OFF") end })
svL:AddSlider("EscapeHeight", { Text = "Escape Height", Default = 300, Min = 80, Max = 600, Rounding = 0, Suffix = "studs",
    Callback = function(v) Cfg.EscapeHeight = v end })

local svR = Tabs.Survival:AddRightGroupbox("Revive", "heart")
svR:AddToggle("AutoRevive", { Text = "Auto-Revive", Default = false,
    Tooltip = "Instantly requests revive when you go down (a teammate must be able to revive you).",
    Callback = function(v) Cfg.AutoRevive = v notify("Auto-Revive", v and "ON" or "OFF") end })
svR:AddButton({ Text = "Request Revive Now", Func = function()
    pcall(function() Events.RequestRevive:FireServer() end)
notify("Request Revive Now", "done") end })

-- â”€â”€ Auto-Task (contract) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local atL = Tabs.Survival:AddLeftGroupbox("Auto-Task (Contract)", "clipboard")
atL:AddLabel({ Text = "Tracks the board's objectives, auto-does the doable ones, then leaves via the truck to bank your pay.", DoesWrap = true })
local lblObj = atL:AddLabel({ Text = "Objectives done: 0  â€¢  Reward: $0", DoesWrap = true })
atL:AddToggle("AutoTask", { Text = "Auto-Task (run best-effort actions)", Default = false, Risky = true,
    Tooltip = "Repeatedly performs the automatable objective actions while on.",
    Callback = function(v) Cfg.AutoTask = v notify("Auto-Task (run best-effort actions)", v and "ON" or "OFF") end })
atL:AddToggle("AutoPhoto", { Text = " â€¢ Auto-Photo Ghost", Default = false,
    Tooltip = "Equips a Photo Camera (you must own one), aims at the ghost, snaps. Server-validated  best-effort.",
    Callback = function(v) Cfg.AutoPhoto = v notify(" â€¢ Auto-Photo Ghost", v and "ON" or "OFF") end })
atL:AddToggle("AutoCursed", { Text = " â€¢ Auto-Trigger Cursed Hunt", Default = false,
    Tooltip = "Interacts the cursed possession to provoke a hunt. Best-effort.",
    Callback = function(v) Cfg.AutoCursed = v notify(" â€¢ Auto-Trigger Cursed Hunt", v and "ON" or "OFF") end })
atL:AddToggle("AutoLeave", { Text = "Auto-Leave when objectives done", Default = false,
    Callback = function(v) Cfg.AutoLeave = v notify("Auto-Leave when objectives done", v and "ON" or "OFF") end })
atL:AddSlider("LeaveAfter", { Text = "Leave after N objectives", Default = 4, Min = 1, Max = 5, Rounding = 0,
    Callback = function(v) Cfg.LeaveAfter = v end })
atL:AddDivider()
atL:AddButton({ Text = "Photo Ghost (try now)", Func = function() task.spawn(tryPhoto) notify("Photo Ghost (try now)", "done") end })
atL:AddButton({ Text = "Trigger Cursed Hunt", Func = function() task.spawn(tryCursed) notify("Trigger Cursed Hunt", "done") end })
atL:AddButton({ Text = "Finish Job (Leave Now)", Func = function() finishJob(); notify("Finish Job (Leave Now)", "done") end})
atL:AddLabel({ Text = "Identify the ghost with the Solver (Ghost tab). Team-escape needs real teammates â€” can't be forced solo.", DoesWrap = true })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  MOVEMENT TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local mvL = Tabs.Movement:AddLeftGroupbox("Character", "user")
mvL:AddToggle("WalkSpeed", { Text = "WalkSpeed Override", Default = false,
    Callback = function(v) Cfg.WalkSpeed = v notify("WalkSpeed Override", v and "ON" or "OFF") end })
mvL:AddSlider("WalkSpeedAmt", { Text = "Speed", Default = 26, Min = 16, Max = 120, Rounding = 0, Suffix = "w/s",
    Callback = function(v) Cfg.WalkSpeedAmt = v end })
mvL:AddToggle("InfStamina", { Text = "Infinite Stamina / Sprint", Default = false,
    Tooltip = "Stamina is client-managed in this game â€” keeps your sprint bar full.",
    Callback = function(v) Cfg.InfStamina = v notify("Infinite Stamina / Sprint", v and "ON" or "OFF") end })
mvL:AddToggle("InfJump", { Text = "Infinite Jump", Default = false,
    Callback = function(v) Cfg.InfJump = v notify("Infinite Jump", v and "ON" or "OFF") end })
mvL:AddToggle("NoClip", { Text = "NoClip", Default = false, Risky = true,
    Tooltip = "Walk through walls. Useful to reach the ghost room / locked items.",
    Callback = function(v) Cfg.NoClip = v notify("NoClip", v and "ON" or "OFF") end })

local mvR = Tabs.Movement:AddRightGroupbox("Fly", "activity")
mvR:AddToggle("Fly", { Text = "Fly", Default = false, Risky = true,
    Callback = function(v) Cfg.Fly = v notify("Fly", v and "ON" or "OFF") end }):AddKeyPicker("FlyKey", { Default = "F", Text = "Fly toggle", Mode = "Toggle",
    Callback = function() Toggles.Fly:SetValue(not Cfg.Fly) end })
mvR:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 70, Min = 20, Max = 250, Rounding = 0,
    Callback = function(v) Cfg.FlySpeed = v end })

local tpBox = Tabs.Movement:AddRightGroupbox("Teleport", "map-pin")
tpBox:AddButton({ Text = "TP to Ghost", Func = function()
    local r, gr = root(), ghostRoot()
    if r and gr then r.CFrame = gr.CFrame * CFrame.new(0, 0, 6) end
notify("TP to Ghost", "done") end })
tpBox:AddButton({ Text = "TP to Ghost Room (above)", Func = function()
    local r, gr = root(), ghostRoot()
    if r and gr then r.CFrame = gr.CFrame + Vector3.new(0, 40, 0) end
notify("TP to Ghost Room (above)", "done") end })
tpBox:AddButton({ Text = "TP to Exit / Truck", Func = function()
    local r = root(); if not r then return end
    local spawns = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Spawns")
    local exit = Workspace.Doors and Workspace.Doors:FindFirstChild("ExitDoor")
    local target = exit and (exit.PrimaryPart or exit:FindFirstChildWhichIsA("BasePart", true))
    if (not target) and spawns then target = spawns:FindFirstChildWhichIsA("BasePart", true) end
    if target then r.CFrame = target.CFrame + Vector3.new(0, 4, 0) end
notify("TP to Exit / Truck", "done") end })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ITEMS TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local itL = Tabs.Items:AddLeftGroupbox("Item ESP", "package")
itL:AddToggle("ItemESP", { Text = "Objective / Pickup Items", Default = false,
    Tooltip = "Highlights items in workspace.Items (evidence + objective pickups).",
    Callback = function(v) Cfg.ItemESP = v notify("Objective / Pickup Items", v and "ON" or "OFF") end })
itL:AddToggle("CursedESP", { Text = "Cursed Possessions / Valuables", Default = false,
    Tooltip = "Highlights interactables (Pocket Pals, cursed possessions) worth cash.",
    Callback = function(v) Cfg.CursedESP = v notify("Cursed Possessions / Valuables", v and "ON" or "OFF") end })
itL:AddSlider("ItemMax", { Text = "Max Distance", Default = 700, Min = 100, Max = 3000, Rounding = 0, Suffix = "studs",
    Callback = function(v) Cfg.ItemMax = v end })

local itR = Tabs.Items:AddRightGroupbox("Interact", "hand")
itR:AddToggle("PickupRange", { Text = "Auto-Pickup Nearby Items", Default = false, Risky = true,
    Tooltip = "Fires RequestItemPickup on close items automatically.",
    Callback = function(v) Cfg.PickupRange = v notify("Auto-Pickup Nearby Items", v and "ON" or "OFF") end })
itR:AddSlider("PickupAmt", { Text = "Pickup Range", Default = 30, Min = 8, Max = 80, Rounding = 0, Suffix = "studs",
    Callback = function(v) Cfg.PickupAmt = v end })
itR:AddButton({ Text = "Open All Doors", Func = function()
    local doors = Workspace:FindFirstChild("Doors")
    if not doors then return end
    for _, d in ipairs(doors:GetChildren()) do pcall(function() Events.RequestDoorOpen:FireServer(d) end) end
notify("Open All Doors", "done") end })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  VISUALS TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local vsL = Tabs.Visual:AddLeftGroupbox("World", "sun")
vsL:AddToggle("Fullbright", { Text = "Fullbright", Default = false,
    Callback = function(v) Cfg.Fullbright = v notify("Fullbright", v and "ON" or "OFF") end })
vsL:AddToggle("NightVision", { Text = "Night Vision Tint", Default = false,
    Callback = function(v) Cfg.NightVision = v notify("Night Vision Tint", v and "ON" or "OFF") end })
vsL:AddToggle("NoFog", { Text = "No Fog / Clear Atmosphere", Default = false,
    Callback = function(v) Cfg.NoFog = v notify("No Fog / Clear Atmosphere", v and "ON" or "OFF") end })

local vsR = Tabs.Visual:AddRightGroupbox("Camera / Screen", "video")
vsR:AddToggle("NoShake", { Text = "No Camera Shake", Default = false,
    Tooltip = "Disables the CameraShake event connections.",
    Callback = function(v) Cfg.NoShake = v notify("No Camera Shake", v and "ON" or "OFF") end })
vsR:AddToggle("NoScreenFX", { Text = "No Screen Blur / DOF", Default = false,
    Callback = function(v) Cfg.NoScreenFX = v notify("No Screen Blur / DOF", v and "ON" or "OFF") end })
vsR:AddToggle("FOV", { Text = "Custom FOV", Default = false, Callback = function(v) Cfg.FOV = v notify("Custom FOV", v and "ON" or "OFF") end })
vsR:AddSlider("FOVValue", { Text = "Field of View", Default = 90, Min = 70, Max = 120, Rounding = 0,
    Callback = function(v) Cfg.FOVValue = v end })
vsR:AddToggle("Crosshair", { Text = "Crosshair Dot", Default = false, Callback = function(v) Cfg.Crosshair = v notify("Crosshair Dot", v and "ON" or "OFF") end })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  PLAYERS TAB
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local plL = Tabs.Players:AddLeftGroupbox("Player ESP", "users")
plL:AddToggle("PlayerESP", { Text = "Teammate ESP", Default = false, Callback = function(v) Cfg.PlayerESP = v notify("Teammate ESP", v and "ON" or "OFF") end })
plL:AddSlider("PlayerMax", { Text = "Max Distance", Default = 1500, Min = 100, Max = 4000, Rounding = 0, Suffix = "studs",
    Callback = function(v) Cfg.PlayerMax = v end })

local plR = Tabs.Players:AddRightGroupbox("Teleport to Player", "user")
local plDrop = plR:AddDropdown("TpTarget", { Text = "Player", Values = {}, Default = nil, AllowNull = true })
plR:AddButton({ Text = "Teleport", Func = function()
    local name = Options.TpTarget.Value
    if not name then return end
    local tp = Players:FindFirstChild(name)
    local r = root()
    if tp and tp.Character and r then
        local trp = tp.Character:FindFirstChild("HumanoidRootPart")
        if trp then r.CFrame = trp.CFrame + Vector3.new(0, 0, 4) end
    end
notify("Teleport", "done") end })
local function refreshPlayers()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then names[#names + 1] = p.Name end end
    pcall(function() plDrop:SetValues(names) end)
end
refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers); Players.PlayerRemoving:Connect(refreshPlayers)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  CREDITS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local crBox = Tabs.Credits:AddLeftGroupbox("Y2kScripts", "heart")
crBox:AddLabel({ Text = "Demonology ghost-hunt hub. Find the ghost, solve it, grab the loot, survive â€” fast contracts = fast money.", DoesWrap = true })
crBox:AddButton({ Text = "Join Discord", Func = function()
    if req then
        pcall(function()
            req({ Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
                Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
                Body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", nonce = HttpService:GenerateGUID(false), args = { code = "EFFKrfFkPQ" } }) })
        end)
    end
    if setclipboard then setclipboard("https://discord.gg/EFFKrfFkPQ") end
    notify("Discord", "Opening invite â€” link copied too.")
end })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  CROSSHAIR + HUNT ALERT GUI
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local scrGui = Instance.new("ScreenGui"); scrGui.Name = "\0SiteHUD"; scrGui.IgnoreGuiInset = true
scrGui.ResetOnSpawn = false; scrGui.Parent = game:GetService("CoreGui")
local dot = Instance.new("Frame"); dot.Size = UDim2.fromOffset(4,4); dot.AnchorPoint = Vector2.new(.5,.5)
dot.Position = UDim2.fromScale(.5,.5); dot.BackgroundColor3 = Color3.new(1,1,1); dot.BorderSizePixel = 0
dot.Visible = false; dot.Parent = scrGui
local huntLbl = Instance.new("TextLabel"); huntLbl.Size = UDim2.new(1,0,0,60); huntLbl.Position = UDim2.fromScale(0,.18)
huntLbl.BackgroundTransparency = 1; huntLbl.Font = Enum.Font.GothamBlack; huntLbl.TextSize = 42
huntLbl.TextColor3 = Color3.fromRGB(255,60,60); huntLbl.TextStrokeTransparency = 0
huntLbl.Text = "HUNT "; huntLbl.Visible = false; huntLbl.Parent = scrGui

local huntSound = Instance.new("Sound"); huntSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
huntSound.Volume = 1; huntSound.Parent = SoundService

-- â”€â”€ left-edge ghost stats panel (shared Y2k StatsPanel module) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local panel = StatsPanel.new(Library, { title = "GHOST DATA" })
panel:Line("room",  { size = 14, color = Color3.fromRGB(255, 220, 120) })
panel:Line("nest",  { size = 13, color = Color3.fromRGB(200, 200, 210) })
panel:Line("bio",   { size = 12, color = Color3.fromRGB(170, 170, 180) })
panel:Line("dist",  { size = 13, color = Color3.fromRGB(140, 200, 255) })
panel:Line("state", { size = 15, color = Color3.fromRGB(120, 255, 140), bold = true })

local wm = Watermark.new(Library, { title = "Y2k" })
wm:Bind(function()
    return ("Y2k  |  Demonology  |  %d fps"):format(math.floor(Y2k.fps()))
end, 1)

local kb = Keybinds.new(Library, { title = "Keybinds" })

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ANTI-HUNT STATE  (hunt watcher + auto-escape)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local escaping, savedCF, savedAnchor = false, nil, nil
local wasHunting = false
local function isHunting()
    local g = getGhost()
    if not g then return false end
    return g:GetAttribute("Hunting") == true or g:GetAttribute("EventActive") == true
end
local function startEscape()
    local r = root(); if not r then return end
    escaping = true
    savedCF = r.CFrame
    savedAnchor = r.Anchored
    r.Anchored = true
    r.CFrame = r.CFrame + Vector3.new(0, Cfg.EscapeHeight, 0)
end
local function endEscape()
    if not escaping then return end
    escaping = false
    local r = root()
    if r then
        r.Anchored = savedAnchor or false
        if savedCF then r.CFrame = savedCF + Vector3.new(0, 4, 0) end
    end
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  FLY
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local flyBV, flyBG
local function killFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local h = hum(); if h then h.PlatformStand = false end
end
local function doFly()
    local r, h = root(), hum()
    if not (r and h) then return end
    if not flyBV then
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1,1,1) * 9e9
        flyBV.P = 9e4; flyBV.Velocity = Vector3.zero; flyBV.Parent = r
        flyBG = Instance.new("BodyGyro"); flyBG.MaxForce = Vector3.new(1,1,1) * 9e9
        flyBG.P = 9e4; flyBG.Parent = r
        h.PlatformStand = true
    end
    flyBG.CFrame = Camera.CFrame
    local dir = Vector3.zero
    local cf = Camera.CFrame
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    flyBV.Velocity = dir * Cfg.FlySpeed
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  INFINITE JUMP
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
UIS.JumpRequest:Connect(function()
    if Cfg.InfJump and not Cfg._dead then
        local h = hum(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  AUTO-REVIVE
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
LocalPlayer:GetAttributeChangedSignal("Dead"):Connect(function()
    if Cfg.AutoRevive and LocalPlayer:GetAttribute("Dead") then
        task.wait(0.4)
        pcall(function() Events.RequestRevive:FireServer() end)
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  NO CAMERA SHAKE  (toggle connections on the shake bindable)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local shakeDisabled = false
local function setShake(disabled)
    if disabled == shakeDisabled then return end
    shakeDisabled = disabled
    pcall(function()
        local ev = LocalPlayer:FindFirstChild("PlayerScripts")
        ev = ev and ev:FindFirstChild("Events") and ev.Events:FindFirstChild("CameraShake")
        if ev and typeof(getconnections) == "function" then
            for _, c in ipairs(getconnections(ev.Event)) do
                if disabled then pcall(function() c:Disable() end) else pcall(function() c:Enable() end) end
            end
        end
    end)
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  FULLBRIGHT save/restore
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local lightSaved = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows,
    ExposureCompensation = Lighting.ExposureCompensation,
}
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "\0SiteCC"; colorCorrection.Enabled = false; colorCorrection.Parent = Lighting

local function getAtmosphere()
    return Lighting:FindFirstChildOfClass("Atmosphere") or (ReplicatedStorage:FindFirstChild("Atmosphere"))
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  MAIN HEARTBEAT LOOP
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
RunService.Heartbeat:Connect(function()
    if Cfg._dead then return end

    -- WalkSpeed
    if Cfg.WalkSpeed then local h = hum(); if h then h.WalkSpeed = Cfg.WalkSpeedAmt end end
    -- Infinite stamina (client attribute)
    if Cfg.InfStamina then
        local maxS = Workspace:GetAttribute("MaxStamina") or 100
        pcall(function() LocalPlayer:SetAttribute("Stamina", maxS) end)
    end
    -- NoClip
    if Cfg.NoClip then
        local c = char()
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
    end

    -- Hunt watcher
    local hunting = isHunting()
    if hunting ~= wasHunting then
        wasHunting = hunting
        if hunting then
            if Cfg.HuntWarn then huntLbl.Visible = true; pcall(function() huntSound:Play() end)
                notify("HUNT", "The ghost is hunting!", 3) end
            if Cfg.AutoEscape and not LocalPlayer:GetAttribute("Dead") then startEscape() end
        else
            huntLbl.Visible = false
            if escaping then endEscape() end
        end
    end
    if escaping and Cfg.AutoEscape then
        -- keep us pinned up high in case physics nudges
        local r = root()
        if r and savedCF then r.CFrame = CFrame.new(savedCF.Position + Vector3.new(0, Cfg.EscapeHeight, 0)) end
    end

    -- Live ghost data â€” left-edge panel (shared StatsPanel module)
    local g = getGhost()
    if Cfg.StatsPanel and g then
        pcall(function()
            panel:Set("room", "Room: " .. tostring(g:GetAttribute("CurrentRoom") or "â€”"))
            panel:Set("nest", "Nest: " .. tostring(g:GetAttribute("FavoriteRoom") or "â€”"))
            panel:Set("bio", ("%s â€¢ age %s â€¢ %s"):format(
                tostring(g:GetAttribute("Gender") or "?"),
                tostring(g:GetAttribute("Age") or "?"),
                tostring(g:GetAttribute("VisualModel") or "?")))
            local r, gr = root(), ghostRoot()
            panel:Set("dist", (r and gr) and ("Distance: " .. math.floor(dist(r, gr)) .. "m") or "Distance: â€”")
            panel:Set("state", hunting and "HUNTING" or "idle")
            kb:Set("ghostesp", Cfg.GhostESP); kb:Set("autoescape", Cfg.AutoEscape); kb:Set("walkspeed", Cfg.WalkSpeed)
        end)
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  RENDER LOOP  (fly, fullbright, fov, crosshair, esp tracers)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
RunService.RenderStepped:Connect(function()
    if Cfg._dead then return end

    if Cfg.Fly then doFly() elseif flyBV then killFly() end

    -- FOV
    if Cfg.FOV then Camera.FieldOfView = Cfg.FOVValue end

    -- Crosshair
    dot.Visible = Cfg.Crosshair

    -- No camera shake
    setShake(Cfg.NoShake)

    -- Fullbright
    if Cfg.Fullbright then
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(170,170,170)
        Lighting.OutdoorAmbient = Color3.fromRGB(170,170,170); Lighting.ExposureCompensation = 0.4
    end
    -- Night vision
    colorCorrection.Enabled = Cfg.NightVision
    if Cfg.NightVision then colorCorrection.TintColor = Color3.fromRGB(120,255,120); colorCorrection.Brightness = 0.15 end
    -- No fog / atmosphere
    if Cfg.NoFog then
        Lighting.FogEnd = 1e9; Lighting.FogStart = 1e8
        local atm = getAtmosphere()
        if atm then pcall(function() atm.Density = 0; atm.Haze = 0 end) end
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("BlurEffect") and Cfg.NoScreenFX then e.Size = 0 end
        end
    end
    -- No screen FX
    if Cfg.NoScreenFX then
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("BlurEffect") then e.Size = 0 end
            if e:IsA("DepthOfFieldEffect") then e.Enabled = false end
        end
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  GHOST + ITEM + PLAYER ESP LOOP  (slower, 0.4s)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local ghostTracer = newTracer(Color3.fromRGB(255,70,70))

local function updateGhostESP()
    local g = getGhost()
    local gr = ghostRoot()
    -- highlight
    if Cfg.GhostESP and g then
        if not ghostTags.hl then ghostTags.hl = makeHighlight(g, Color3.fromRGB(255,40,40), Color3.fromRGB(255,120,120)) end
        ghostTags.hl.Adornee = g
    elseif ghostTags.hl then ghostTags.hl:Destroy(); ghostTags.hl = nil end
    -- info tag
    if Cfg.GhostInfo and g and gr then
        if not ghostTags.bb then ghostTags.bb, ghostTags.tl = makeLabel(gr, Color3.fromRGB(255,90,90)) end
        ghostTags.bb.Adornee = gr
        local r = root()
        local d = r and math.floor(dist(r, gr)) or 0
        pcall(function() ghostTags.tl.Text = ("GHOST â€¢ %dm\n%s"):format(d, tostring(g:GetAttribute("CurrentRoom") or "?")) end)
    elseif ghostTags.bb then ghostTags.bb:Destroy(); ghostTags.bb = nil; ghostTags.tl = nil end
    -- tracer
    if ghostTracer then
        if Cfg.GhostTracer and gr then
            local sp, on = Camera:WorldToViewportPoint(gr.Position)
            if on then
                ghostTracer.Visible = true
                ghostTracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                ghostTracer.To = Vector2.new(sp.X, sp.Y)
            else ghostTracer.Visible = false end
        else ghostTracer.Visible = false end
    end
    -- room highlight
    if Cfg.RoomHL and g then
        local roomName = g:GetAttribute("CurrentRoom")
        local rooms = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Rooms")
        if rooms and roomName then
            local rm = rooms:FindFirstChild(roomName)
            if rm then
                if not ghostTags.room then ghostTags.room = makeHighlight(rm, Color3.fromRGB(255,170,40), Color3.fromRGB(255,210,120)); ghostTags.room.FillTransparency = 0.85 end
                ghostTags.room.Adornee = rm
            end
        end
    elseif ghostTags.room then ghostTags.room:Destroy(); ghostTags.room = nil end
end

local function espItems(folder, tbl, col, maxD)
    local r = root(); if not r then return end
    local present = {}
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") or m:IsA("BasePart") then
                local pp = (m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))) or m
                if pp and dist(r, pp) <= maxD then
                    present[m] = true
                    if not tbl[m] then
                        local hl = makeHighlight(m, col, col)
                        hl.FillTransparency = 0.7
                        local bb, tl = makeLabel(pp, col)
                        tl.TextSize = 12
                        tbl[m] = { hl = hl, bb = bb, tl = tl, pp = pp }
                    end
                    pcall(function()
                        tbl[m].tl.Text = ("%s â€¢ %dm"):format(m.Name, math.floor(dist(r, pp)))
                    end)
                end
            end
        end
    end
    for m, t in pairs(tbl) do
        if not present[m] then
            pcall(function() if t.hl then t.hl:Destroy() end if t.bb then t.bb:Destroy() end end)
            tbl[m] = nil
        end
    end
end

local itemTagsObj, cursedTagsObj = {}, {}
local function updateItemESP()
    if Cfg.ItemESP then espItems(Workspace:FindFirstChild("Items"), itemTagsObj, Color3.fromRGB(90,200,255), Cfg.ItemMax)
    else clearTags(itemTagsObj) end
    if Cfg.CursedESP then espItems(Workspace:FindFirstChild("Interactables"), cursedTagsObj, Color3.fromRGB(200,120,255), Cfg.ItemMax)
    else clearTags(cursedTagsObj) end
end

local function updatePlayerESP()
    local present = {}
    if Cfg.PlayerESP then
        local r = root()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr and r and dist(r, pr) <= Cfg.PlayerMax then
                    present[p] = true
                    if not playerTags[p] then
                        playerTags[p] = { hl = makeHighlight(p.Character, Color3.fromRGB(90,255,140), Color3.fromRGB(160,255,190)) }
                        playerTags[p].hl.FillTransparency = 0.7
                    end
                    playerTags[p].hl.Adornee = p.Character
                end
            end
        end
    end
    for p, t in pairs(playerTags) do
        if not present[p] then pcall(function() t.hl:Destroy() end) playerTags[p] = nil end
    end
end

task.spawn(function()
    while not Cfg._dead do
        pcall(updateGhostESP)
        pcall(updateItemESP)
        pcall(updatePlayerESP)
        task.wait(0.35)
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  AUTO-PICKUP LOOP
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
task.spawn(function()
    while not Cfg._dead do
        if Cfg.PickupRange then
            local r = root()
            local items = Workspace:FindFirstChild("Items")
            if r and items then
                for _, m in ipairs(items:GetChildren()) do
                    local pp = (m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))) or (m:IsA("BasePart") and m)
                    if pp and dist(r, pp) <= Cfg.PickupAmt then
                        pcall(function() Events.RequestItemPickup:FireServer(m) end)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  OBJECTIVE TRACKER  (ObjectiveCompleted is serverclient; fires the title)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local OBJ_REWARD, OBJ_PRETTY = {}, {}
pcall(function()
    local o = require(Modules:WaitForChild("ObjectiveInfo"))
    for _, t in ipairs(o) do
        if t.ObjectiveTitle then
            OBJ_REWARD[t.ObjectiveTitle] = t.Reward or 25
            OBJ_PRETTY[t.ObjectiveTitle] = t.ObjectiveHintText or t.ObjectiveTitle
        end
    end
end)
local completedObj, completedCount, completedReward = {}, 0, 0
local function refreshObjLbl()
    local names = {}
    for title in pairs(completedObj) do names[#names + 1] = OBJ_PRETTY[title] or title end
    local txt = ("Objectives done: %d  â€¢  Reward: $%d"):format(completedCount, completedReward)
    if #names > 0 then txt = txt .. "\n " .. table.concat(names, "\n ") end
    pcall(function() lblObj:SetText(txt) end)
end
pcall(function()
    Events.ObjectiveCompleted.OnClientEvent:Connect(function(title)
        if Cfg._dead then return end
        if title and not completedObj[title] then
            completedObj[title] = true
            completedCount = completedCount + 1
            completedReward = completedReward + (OBJ_REWARD[title] or 25)
            refreshObjLbl()
            notify("Objective Complete", (OBJ_PRETTY[title] or tostring(title)) .. " (+$" .. (OBJ_REWARD[title] or 25) .. ")", 4)
            if Cfg.AutoLeave and completedCount >= Cfg.LeaveAfter then
                task.wait(1.2); finishJob()
            end
        end
    end)
end)

-- â”€â”€ Auto-Task loop (best-effort doable actions while toggled) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
task.spawn(function()
    while not Cfg._dead do
        if Cfg.AutoTask then
            if Cfg.AutoPhoto then pcall(tryPhoto) end
            if Cfg.AutoCursed then pcall(tryCursed) end
        end
        task.wait(3)
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ANTI-AFK
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if Cfg.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  HUD KEYBINDS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
kb:Bind("ghostesp",   "Ghost Highlight", Enum.KeyCode.G, function(a) Cfg.GhostESP = a;   pcall(function() Toggles.GhostESP:SetValue(a) end) end)
kb:Bind("autoescape", "Auto-Escape",     Enum.KeyCode.H, function(a) Cfg.AutoEscape = a; pcall(function() Toggles.AutoEscape:SetValue(a) end) end)
kb:Bind("walkspeed",  "WalkSpeed",       Enum.KeyCode.J, function(a) Cfg.WalkSpeed = a;  pcall(function() Toggles.WalkSpeed:SetValue(a) end) end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  SETTINGS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
local stL = Tabs.Settings:AddLeftGroupbox("Interface", "monitor")
stL:AddDropdown("NotifySide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(v) Library:SetNotifySide(v) end })
stL:AddDropdown("DPI", { Values = { "75%", "100%", "125%", "150%" }, Default = "100%", Text = "UI Scale", Callback = function(v) Library:SetDPIScale(tonumber((v:gsub("%%", "")))) end })
stL:AddToggle("AntiAFK", { Text = "Anti-AFK", Default = true, Callback = function(v) Cfg.AntiAFK = v notify("Anti-AFK", v and "ON" or "OFF") end })
stL:AddLabel("Menu toggle key: Right Ctrl")
Y2k.modulesGroup(Tabs.Settings, { panel = panel, wm = wm, kb = kb })

local stR = Tabs.Settings:AddRightGroupbox("Server", "globe")
stR:AddButton({ Text = "Rejoin Server", Func = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
notify("Rejoin Server", "done") end })
stR:AddButton({ Text = "Return to Lobby", Func = function()
    pcall(function() Events.RequestReturnToLobby:FireServer() end)
notify("Return to Lobby", "done") end })
local function fullUnload()
    Cfg._dead = true
    for k, v in pairs(Cfg) do if type(v) == "boolean" then Cfg[k] = false end end
    pcall(endEscape)
    pcall(killFly)
    pcall(setShake, false)
    pcall(function() clearTags(itemTagsObj); clearTags(cursedTagsObj); clearTags(playerTags) end)
    pcall(function() if ghostTracer then ghostTracer:Remove() end end)
    pcall(function() espHolder:Destroy() end)
    pcall(function() scrGui:Destroy() end)
    pcall(function() colorCorrection:Destroy() end)
    -- restore lighting
    pcall(function()
        Lighting.Brightness = lightSaved.Brightness; Lighting.ClockTime = lightSaved.ClockTime
        Lighting.FogEnd = lightSaved.FogEnd; Lighting.Ambient = lightSaved.Ambient
        Lighting.OutdoorAmbient = lightSaved.OutdoorAmbient; Lighting.GlobalShadows = lightSaved.GlobalShadows
        Lighting.ExposureCompensation = lightSaved.ExposureCompensation
    end)
    local c = char()
    if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end end end
    pcall(function() panel:Destroy() end); pcall(function() wm:Destroy() end); pcall(function() kb:Destroy() end)
    pcall(function() Y2k.release("Demonology") end)
    pcall(function() Library:Unload() end)
end
stR:AddButton({ Text = "Unload", Func = function() fullUnload(); notify("Unload", "done") end })
pcall(function() Library:OnUnload(fullUnload) end)
pcall(function() if Y2k.setUnload then Y2k.setUnload("Demonology", fullUnload) end end)

ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({ "FlyKey" })
ThemeManager:SetFolder("DemonologyHub"); SaveManager:SetFolder("DemonologyHub/configs")
ThemeManager:ApplyToTab(Tabs.Settings)
pcall(function() SaveManager:LoadAutoloadConfig() end)

refreshSolver()
notify("Demonology Hub", "v1.0 loaded â€” Right Ctrl toggles the menu.", 6)
