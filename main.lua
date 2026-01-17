repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local localPlayerName = LocalPlayer and string.lower(LocalPlayer.Name) or ""

-- Simple, robust remote loader (uses loadstring(HttpGet) as requested)
local function loadRemoteUI()
    local ok, res = pcall(function()
        local raw = game:HttpGet("https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/refs/heads/main/UI-Lib/main.lua")
        local fn, err = loadstring(raw)
        if not fn then error(err) end
        return fn()
    end)
    if ok and type(res) == "table" then
        return res
    end
    warn("loadRemoteUI failed:", res)
    return nil
end

local Abyss = loadRemoteUI()

-- Public UI helpers used by the script (will use Abyss when available)
local UI = {}

-- configurable state
local toggles = {
    { label = "🔍 AutoReport", enabled = true },
    { label = "⚔️ Report-Back", enabled = true },
    { label = "💬 Universal Chat", enabled = true },
    { label = "🎯 Macro System", enabled = false }
}

local state = {
    macroKeybind = Enum.KeyCode.F,
    macroEnabled = false,
    universalChatActive = true,
    autoReportActive = true,
    reportBackActive = true,
    espSkeleton = false,
    espBox = false
}

local universalChatMessages = {}
local chatRoles = { [string.lower(LocalPlayer.Name or "")] = " " }

-- Example word lists (trimmed). Keep full lists in production.
local words = { ['gay'] = 'Bullying', ['trans'] = 'Bullying' }
local reportBackWords = { ['report'] = 'Bullying' }

local ChatFrame
local ChatInputBox
local espData = {}

local function updateEspForPlayer(player)
    if not player or player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local data = espData[player] or {}
    espData[player] = data

    -- Skeleton (using Highlight outline)
    if state.espSkeleton then
        if not data.skel then
            local ok, h = pcall(function()
                local hl = Instance.new("Highlight")
                hl.Name = "AutoReportESP_Highlight"
                hl.FillTransparency = 1
                hl.OutlineTransparency = 0
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,0,0)
                hl.Adornee = char
                hl.Parent = workspace
                return hl
            end)
            if ok then data.skel = h end
        end
    else
        if data.skel then pcall(function() data.skel:Destroy() end); data.skel = nil end
    end

    -- 3D box (BoxHandleAdornment)
    if state.espBox then
        if not data.box then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            if hrp then
                local ok, box = pcall(function()
                    local b = Instance.new("BoxHandleAdornment")
                    b.Name = "AutoReportESP_Box"
                    b.Adornee = hrp
                    b.Color3 = Color3.fromRGB(255,0,0)
                    b.Size = Vector3.new(2, 5, 1)
                    b.AlwaysOnTop = true
                    b.ZIndex = 10
                    b.Parent = hrp
                    return b
                end)
                if ok then data.box = box end
            end
        end
    else
        if data.box then pcall(function() data.box:Destroy() end); data.box = nil end
    end
end

local function clearEspForPlayer(player)
    local data = espData[player]
    if not data then return end
    if data.skel then pcall(function() data.skel:Destroy() end) end
    if data.box then pcall(function() data.box:Destroy() end) end
    espData[player] = nil
end

function UI:Notify(title, desc, duration)
    duration = duration or 4
    if Abyss and Abyss.Notify then
        pcall(function() Abyss:Notify({ Text = title.." - "..desc, Duration = duration }) end)
        return
    end
    -- minimal fallback
    local sg = Instance.new("ScreenGui")
    sg.Name = "AutoReportFallback"
    sg.Parent = game.CoreGui
    sg.ResetOnSpawn = false
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 300, 0, 80)
    f.Position = UDim2.new(0, 20, 1, 20)
    f.BackgroundColor3 = Color3.fromRGB(25,25,35)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,-20,0,30); t.Position = UDim2.new(0,10,0,10); t.BackgroundTransparency = 1
    t.Text = title; t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = Color3.new(1,1,1)
    local d = Instance.new("TextLabel", f)
    d.Size = UDim2.new(1,-20,0,30); d.Position = UDim2.new(0,10,0,40); d.BackgroundTransparency = 1
    d.Text = desc; d.Font = Enum.Font.Gotham; d.TextScaled = true; d.TextColor3 = Color3.fromRGB(200,200,200)
    TweenService:Create(f, TweenInfo.new(0.4), { Position = UDim2.new(0,20,1,-100) }):Play()
    Debris:AddItem(sg, duration)
end

local reportCooldown = false
function UI:Report(playerName, reason, isReportBack)
    if not playerName or string.lower(playerName) == localPlayerName or reportCooldown then return end
    pcall(function()
        local target = Players:FindFirstChild(playerName)
        if target then
            Players:ReportAbuse(target, reason, "breaking TOS")
        end
    end)
    if isReportBack then
        UI:Notify("🔄 REPORT-BACK", "Counter-reported "..playerName, 4)
    else
        UI:Notify("🚨 AUTO-REPORT", "Reported "..playerName.." for "..tostring(reason), 4)
    end
    reportCooldown = true
    task.delay(6, function() reportCooldown = false end)
end

function AddChatMessage(playerName, message)
    if not ChatFrame or not ChatFrame:IsA("ScrollingFrame") then return end
    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1,0,0,40); msgFrame.BackgroundTransparency = 1; msgFrame.LayoutOrder = #universalChatMessages + 1
    msgFrame.Parent = ChatFrame
    local roleLabel = Instance.new("TextLabel", msgFrame)
    roleLabel.Size = UDim2.new(0,60,1,0); roleLabel.BackgroundTransparency = 1; roleLabel.Text = chatRoles[string.lower(playerName or "")] or "👤"
    roleLabel.TextColor3 = Color3.fromRGB(100,255,100); roleLabel.Font = Enum.Font.GothamBold; roleLabel.TextScaled = true
    local nameLabel = Instance.new("TextLabel", msgFrame)
    nameLabel.Size = UDim2.new(0,100,0.5,0); nameLabel.Position = UDim2.new(0,65,0,0); nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName; nameLabel.TextColor3 = Color3.fromRGB(255,255,255); nameLabel.Font = Enum.Font.GothamSemibold; nameLabel.TextScaled = true; nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    local msgLabel = Instance.new("TextLabel", msgFrame)
    msgLabel.Size = UDim2.new(1,-170,1,0); msgLabel.Position = UDim2.new(0,165,0,0); msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message; msgLabel.TextColor3 = Color3.fromRGB(200,200,200); msgLabel.Font = Enum.Font.Gotham; msgLabel.TextScaled = true; msgLabel.TextXAlignment = Enum.TextXAlignment.Left; msgLabel.TextWrapped = true
    table.insert(universalChatMessages, msgFrame)
    if ChatFrame and ChatFrame:IsA("ScrollingFrame") then
        ChatFrame.CanvasSize = UDim2.new(0,0,0, math.max(200, (#universalChatMessages+1) * 45))
    end
end

local macroText = "ez clap noob skill issue L + ratio"
function ExecuteMacro()
    if state.macroEnabled then
        pcall(function()
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(macroText, "All")
        end)
        UI:Notify("🎯 MACRO", "Executed macro!", 2)
    end
end

-- Build UI (Abyss or fallback)
local MainUI
local function buildMainUI()
    -- clean previous Abyss instance if present
    if Abyss and Abyss.Init then
        pcall(function()
            local core = game:GetService("CoreGui")
            local prev = core:FindFirstChild("AbyssUI")
            if prev then prev:Destroy() end
            Abyss:Init()
            MainUI = Abyss:CreateWindow({ Name = "AutoReport", Size = UDim2.new(0,420,0,380) })
            -- remove/disable any built-in close button ("X") to use Insert key instead
            pcall(function()
                if MainUI and MainUI.Window then
                    for _,d in ipairs(MainUI.Window:GetDescendants()) do
                        if d:IsA("TextButton") then
                            local t = tostring(d.Text or "")
                            if t == "X" or t == "x" or (d.Name and string.find(string.lower(d.Name), "close")) then
                                d.Visible = false
                            end
                        end
                    end
                end
            end)
            local mainTab = MainUI.CreateTab({ Name = "Main" })
            local chatTab = MainUI.CreateTab({ Name = "Chat" })
            local macroTab = MainUI.CreateTab({ Name = "Macro" })
            local togglesSection = mainTab.AddSection({ Name = "Toggles" })
            local universalTab = MainUI.CreateTab({ Name = "Universal" })
            local espTab = MainUI.CreateTab({ Name = "ESP" })
            local universalSection = universalTab.AddSection({ Name = "Universal Options" })
            local espSection = espTab.AddSection({ Name = "ESP Options" })

            -- Chat area
            ChatFrame = Instance.new("ScrollingFrame")
            ChatFrame.Name = "UniversalChat"
            ChatFrame.Size = UDim2.new(1,0,0,200)
            ChatFrame.BackgroundTransparency = 1
            ChatFrame.BorderSizePixel = 0
            ChatFrame.ScrollBarThickness = 6
            ChatFrame.Parent = chatTab.Content
            local chatListLayout = Instance.new("UIListLayout", ChatFrame)
            chatListLayout.SortOrder = Enum.SortOrder.LayoutOrder; chatListLayout.Padding = UDim.new(0,6)

            ChatInputBox = chatTab.AddTextbox({ Text = "Message", Default = "", Callback = function(text)
                if text and text ~= "" then AddChatMessage(LocalPlayer.Name, text) end
            end })

            macroTab.AddTextbox({ Text = "Macro Key", Default = "F", Callback = function(text)
                local key = string.upper(tostring(text or "")):gsub("%s+","")
                if key ~= "" and Enum.KeyCode[key] then state.macroKeybind = Enum.KeyCode[key] end
            end })

            for _, t in ipairs(toggles) do
                togglesSection.AddToggle({ Text = t.label, Default = t.enabled, Callback = function(val)
                    t.enabled = val
                    if t.label:find("Universal Chat") then state.universalChatActive = val; if ChatFrame then ChatFrame.Visible = val end
                    elseif t.label:find("Macro") then state.macroEnabled = val
                    elseif t.label:find("AutoReport") then state.autoReportActive = val
                    elseif t.label:find("Report-Back") then state.reportBackActive = val end
                end })
            end

            -- Universal tab: simple controls (in a section so they display)
            universalSection.AddButton({ Text = "Clear Chat", Callback = function()
                if ChatFrame and ChatFrame:IsA("ScrollingFrame") then
                    for _,c in ipairs(ChatFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                    universalChatMessages = {}
                    UI:Notify("🧹 Universal", "Cleared chat", 2)
                end
            end })

            universalSection.AddToggle({ Text = "Show System Messages", Default = true, Callback = function(val)
                -- placeholder: user can implement behavior
                UI:Notify("⚙️ Universal", "Show System Messages: "..tostring(val), 2)
            end })

            -- ESP tab: skeletons and 3D boxes (put controls into the ESP section)
            espSection.AddToggle({ Text = "Skeletons", Default = state.espSkeleton, Callback = function(val)
                state.espSkeleton = val
                for _,pl in ipairs(Players:GetPlayers()) do updateEspForPlayer(pl) end
            end })
            espSection.AddToggle({ Text = "3D Boxes", Default = state.espBox, Callback = function(val)
                state.espBox = val
                for _,pl in ipairs(Players:GetPlayers()) do updateEspForPlayer(pl) end
            end })
        end)
        return
    end

    -- Fallback minimal chat UI
    if ChatFrame and ChatFrame.Parent then ChatFrame:Destroy() end
    ChatFrame = Instance.new("ScrollingFrame")
    ChatFrame.Name = "UniversalChat"
    ChatFrame.Size = UDim2.new(0,360,0,240)
    ChatFrame.Position = UDim2.new(1,-400,1,-300)
    ChatFrame.BackgroundColor3 = Color3.fromRGB(12,14,20)
    ChatFrame.BorderSizePixel = 0
    ChatFrame.ScrollBarThickness = 6
    ChatFrame.Parent = game.CoreGui
    local UIListLayout = Instance.new("UIListLayout", ChatFrame)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0,6)
    ChatInputBox = Instance.new("TextBox")
    ChatInputBox.Size = UDim2.new(1, -24, 0, 36)
    ChatInputBox.Position = UDim2.new(0,12,1,-48)
    ChatInputBox.BackgroundColor3 = Color3.fromRGB(18,20,26)
    ChatInputBox.TextColor3 = Color3.fromRGB(230,230,230)
    ChatInputBox.PlaceholderText = "Type message..."
    ChatInputBox.Font = Enum.Font.Gotham
    ChatInputBox.TextScaled = true
    ChatInputBox.Parent = ChatFrame
end

-- Logo to toggle UI
local logo = game.CoreGui:FindFirstChild("AutoReportLogo")
if not logo then
    logo = Instance.new("ImageButton")
    logo.Name = "AutoReportLogo"
    logo.Size = UDim2.new(0,96,0,96)
    logo.Position = UDim2.new(1,-116,1,-116)
    logo.BackgroundTransparency = 1
    logo.Image = "https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/main/images/logo.png"
    logo.Parent = game.CoreGui
    logo.ImageTransparency = 0.15
    logo.AutoButtonColor = false
end

logo.MouseButton1Click:Connect(function()
    if not MainUI or (MainUI and not MainUI.Window) then buildMainUI() else MainUI.Window.Visible = not MainUI.Window.Visible end
end)

-- Hook chat input for fallback textbox
if ChatInputBox and ChatInputBox:IsA("TextBox") then
    ChatInputBox.FocusLost:Connect(function(enter)
        if enter and ChatInputBox.Text ~= "" then AddChatMessage(LocalPlayer.Name, ChatInputBox.Text); ChatInputBox.Text = "" end
    end)
end

-- Keybind handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == state.macroKeybind then ExecuteMacro() end
    -- Insert toggles the UI (acts as close/open)
    if input.KeyCode == Enum.KeyCode.Insert then
        if MainUI and MainUI.Window and MainUI.Window.Parent then
            MainUI.Window.Visible = not MainUI.Window.Visible
        else
            if ChatFrame then ChatFrame.Visible = not ChatFrame.Visible end
        end
        return
    end
end)

-- Chat hook: auto-report
Players.PlayerChatted:Connect(function(_, player, message)
    if not player or player == LocalPlayer then return end
    local msg = string.lower(tostring(message or ""))
    if state.autoReportActive then
        for word, reason in pairs(words) do if string.find(msg, word) then UI:Report(player.Name, reason, false); return end end
    end
    if state.reportBackActive then
        for word in pairs(reportBackWords) do if string.find(msg, word) then UI:Report(player.Name, "Bullying", true); return end end
    end
end)

-- ESP management: track players and characters
Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function() updateEspForPlayer(pl) end)
end)
Players.PlayerRemoving:Connect(function(pl)
    clearEspForPlayer(pl)
end)
for _,pl in ipairs(Players:GetPlayers()) do
    if pl.Character then updateEspForPlayer(pl) end
    pl.CharacterAdded:Connect(function() updateEspForPlayer(pl) end)
end

-- Init
task.defer(function()
    buildMainUI()
    UI:Notify("✅ AutoReport", "UI restarted (clean) — click logo to open.", 4)
    AddChatMessage("System", "Universal Chat ready")
    print("✅ AUTOREPORT V3.1 - CLEANED")
end)
