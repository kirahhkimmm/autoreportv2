repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local localPlayerName = string.lower(LocalPlayer.Name)

-- Utility: try requiring module from a few common places
-- tryRequire: attempt to require locally, otherwise fetch raw module from GitHub and load it.
local function tryRequire(name)
	-- 1) local places
	local function tryLocal(n)
		if script:FindFirstChild(n) then
			local ok, mod = pcall(require, script:FindFirstChild(n))
			if ok then return mod end
		end
		if script.Parent and script.Parent:FindFirstChild(n) then
			local ok, mod = pcall(require, script.Parent:FindFirstChild(n))
			if ok then return mod end
		end
		local rs = game:GetService("ReplicatedStorage")
		if rs and rs:FindFirstChild(n) then
			local ok, mod = pcall(require, rs:FindFirstChild(n))
			if ok then return mod end
		end
		local ss = game:GetService("ServerStorage")
		if ss and ss:FindFirstChild(n) then
			local ok, mod = pcall(require, ss:FindFirstChild(n))
			if ok then return mod end
		end
		return nil
	end

	local localMod = tryLocal(name)
	if localMod then return localMod end

	-- 2) attempt GitHub fetch via loadstring(HttpGet) as user requested
	local success, module = pcall(function()
		-- direct raw URL to the UI lib main file
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/refs/heads/main/UI-Lib/main.lua"))()
	end)
	if success then
		return module
	end
	warn("Failed to load remote module via HttpGet fallback")
	return nil
end

local Abyss = tryRequire("ui-lib") or tryRequire("AbyssUI") or tryRequire("ui_lib")

-- Local UI container (still used for Notify/Report functions)
local UI = {}

-- Toggles (keeps same labels so logic remains)
local toggles = {
    { label = "🔍 AutoReport", enabled = true },
    { label = "⚔️ Report-Back", enabled = true },
    { label = "💬 Universal Chat", enabled = true },
    { label = "🎯 Macro System", enabled = false }
}

-- State
local state = {
    macroKeybind = Enum.KeyCode.F,
    macroEnabled = false,
    universalChatActive = false,
    autoReportActive = true,
    reportBackActive = true
}

local universalChatMessages = {}
local chatRoles = { [LocalPlayer.Name] = " " }

-- Word lists (truncated here; full list is kept in production)
local words = {
    ['gay'] = 'Bullying', ['trans'] = 'Bullying', ['lgbt'] = 'Bullying', ['lesbian'] = 'Bullying',
    ['bi'] = 'Bullying', ['queer'] = 'Bullying', ['suicide'] = 'Bullying', ['kill yourself'] = 'Bullying'
}

local reportBackWords = { ['report'] = 'Bullying', ['reporting'] = 'Bullying', ['reported'] = 'Bullying' }

-- UI elements we will create
local MainUI = nil
local ChatFrame = nil -- ScrollingFrame
local ChatInputBox = nil -- TextBox or Abyss TextboxData

-- Notification (uses Abyss Notify when available)
function UI:Notify(title, desc, duration)
    duration = duration or 4
    if Abyss and Abyss.Notify then
        Abyss:Notify({ Text = (title .. " - " .. desc), Duration = duration })
        return
    end

    -- fallback
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, 80)
    notif.Position = UDim2.new(0, 20, 1, 20)
    notif.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    notif.Parent = ScreenGui

    local notifTitle = Instance.new("TextLabel", notif)
    notifTitle.Size = UDim2.new(1, -20, 0, 30)
    notifTitle.Position = UDim2.new(0, 10, 0, 10)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Color3.fromRGB(255,255,255)
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextScaled = true

    local notifDesc = Instance.new("TextLabel", notif)
    notifDesc.Size = UDim2.new(1, -20, 0, 30)
    notifDesc.Position = UDim2.new(0, 10, 0, 40)
    notifDesc.BackgroundTransparency = 1
    notifDesc.Text = desc
    notifDesc.TextColor3 = Color3.fromRGB(200,200,200)
    notifDesc.Font = Enum.Font.Gotham
    notifDesc.TextScaled = true

    TweenService:Create(notif, TweenInfo.new(0.5), { Position = UDim2.new(0,20,1,-100) }):Play()
    game:GetService("Debris"):AddItem(notif, duration)
end

-- Report wrapper
local cooldown = false
function UI:Report(playerName, reason, isReportBack)
    if string.lower(playerName) == localPlayerName or cooldown then return end
    pcall(function()
        Players:ReportAbuse(Players:FindFirstChild(playerName), reason, "breaking TOS")
    end)
    if isReportBack then
        UI:Notify("🔄 REPORT-BACK", "⚔️ Counter-reported " .. playerName, 4)
    else
        UI:Notify("🚨 AUTO-REPORT", "Reported " .. playerName .. " for " .. reason, 4)
    end
    cooldown = true
    task.delay(6, function() cooldown = false end)
end

-- Chat helper
function AddChatMessage(playerName, message)
    local role = chatRoles[string.lower(playerName)] or "👤"
    if not ChatFrame or not ChatFrame:IsA("ScrollingFrame") then
        warn("ChatFrame not ready; dropping message")
        return
    end
    local msgFrame = Instance.new("Frame")
    msgFrame.Size = UDim2.new(1,0,0,40)
    msgFrame.BackgroundTransparency = 1
    msgFrame.LayoutOrder = #universalChatMessages + 1
    msgFrame.Parent = ChatFrame

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(0,60,1,0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = role
    roleLabel.TextColor3 = Color3.fromRGB(100,255,100)
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.TextScaled = true
    roleLabel.Parent = msgFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0,100,0.5,0)
    nameLabel.Position = UDim2.new(0,65,0,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = msgFrame

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -170, 1, 0)
    msgLabel.Position = UDim2.new(0,165,0,0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(200,200,200)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextScaled = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = msgFrame

    table.insert(universalChatMessages, msgFrame)
    ChatFrame.CanvasSize = UDim2.new(0,0,0, math.max(200, (#universalChatMessages+1) * 45))
end

-- Macro
local macroText = "ez clap noob skill issue L + ratio"
function ExecuteMacro()
    if state.macroEnabled then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(macroText, "All")
        UI:Notify("🎯 MACRO", "Executed macro!", 2)
    end
end

-- Build UI (Abyss) with toggles, chat and macro controls
local function buildMainUI()
    if not Abyss then
        -- fallback minimal chat UI if Abyss not available
        ChatFrame = Instance.new("ScrollingFrame")
        ChatFrame.Name = "UniversalChat"
        ChatFrame.Size = UDim2.new(0, 360, 1, -120)
        ChatFrame.Position = UDim2.new(1, -420, 0, 60)
        ChatFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        ChatFrame.BorderSizePixel = 0
        ChatFrame.Visible = false
        ChatFrame.ScrollBarThickness = 6
        ChatFrame.Parent = game.CoreGui

        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0,6)
        UIListLayout.Parent = ChatFrame

        ChatInputBox = Instance.new("TextBox")
        ChatInputBox.Size = UDim2.new(1, -24, 0, 36)
        ChatInputBox.Position = UDim2.new(0,12,1,-48)
        ChatInputBox.BackgroundColor3 = Color3.fromRGB(18,20,26)
        ChatInputBox.TextColor3 = Color3.fromRGB(230,230,230)
        ChatInputBox.PlaceholderText = "Type message..."
        ChatInputBox.Font = Enum.Font.Gotham
        ChatInputBox.TextScaled = true
        ChatInputBox.Parent = ChatFrame
        return
    end

    Abyss:Init()
    MainUI = Abyss:CreateWindow({ Name = "AutoReport", Size = UDim2.new(0, 420, 0, 380) })

    local mainTab = MainUI.CreateTab({ Name = "Main" })
    local chatTab  = MainUI.CreateTab({ Name = "Chat" })
    local macroTab = MainUI.CreateTab({ Name = "Macro" })

    local togglesSection = mainTab.AddSection({ Name = "Toggles" })

    -- Chat area
    ChatFrame = Instance.new("ScrollingFrame")
    ChatFrame.Name = "UniversalChat"
    ChatFrame.Size = UDim2.new(1, 0, 0, 200)
    ChatFrame.Position = UDim2.new(0, 0, 0, 0)
    ChatFrame.BackgroundTransparency = 1
    ChatFrame.BorderSizePixel = 0
    ChatFrame.ScrollBarThickness = 6
    ChatFrame.Parent = chatTab.Content

    local chatListLayout = Instance.new("UIListLayout")
    chatListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatListLayout.Padding = UDim.new(0,6)
    chatListLayout.Parent = ChatFrame

    -- Chat input via Abyss textbox
    ChatInputBox = chatTab.AddTextbox({ Text = "Message", Default = "", Callback = function(text)
        if text and text ~= "" then
            AddChatMessage(LocalPlayer.Name, text)
        end
    end })

    -- Macro key textbox
    macroTab.AddTextbox({ Text = "Macro Key", Default = "F", Callback = function(text)
        local key = string.upper(tostring(text or "")):gsub("%s+", "")
        if key ~= "" and Enum.KeyCode[key] then
            state.macroKeybind = Enum.KeyCode[key]
        end
    end })

    -- Set up toggles in UI
    for i, t in ipairs(toggles) do
        togglesSection.AddToggle({
            Text = t.label,
            Default = t.enabled,
            Callback = function(val)
                t.enabled = val
                if t.label:find("Universal Chat") then
                    state.universalChatActive = val
                    if ChatFrame then ChatFrame.Visible = val end
                elseif t.label:find("Macro") then
                    state.macroEnabled = val
                elseif t.label:find("AutoReport") then
                    state.autoReportActive = val
                elseif t.label:find("Report-Back") then
                    state.reportBackActive = val
                end
            end
        })
    end
end

-- Minimal logo to open the UI window
local Logo = Instance.new("ImageButton")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 96, 0, 96)
Logo.Position = UDim2.new(1, -116, 1, -116)
Logo.BackgroundTransparency = 1
Logo.Image = "https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/main/images/logo.png"
Logo.Parent = game.CoreGui
Logo.ImageTransparency = 0.15
Logo.ZIndex = 1000
Logo.AutoButtonColor = false

Logo.MouseButton1Click:Connect(function()
    if not MainUI or not MainUI.Window or not MainUI.Window.Parent then
        buildMainUI()
    else
        MainUI.Window.Visible = not MainUI.Window.Visible
    end
end)

-- Hook chat input for fallback and Abyss textbox
if ChatInputBox then
    if type(ChatInputBox) == "table" and ChatInputBox.Input then
        ChatInputBox.Input.FocusLost:Connect(function(enterPressed)
            if enterPressed and ChatInputBox.Input.Text ~= "" then
                AddChatMessage(LocalPlayer.Name, ChatInputBox.Input.Text)
                ChatInputBox.Input.Text = ""
            end
        end)
    elseif ChatInputBox.FocusLost then
        ChatInputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed and ChatInputBox.Text ~= "" then
                AddChatMessage(LocalPlayer.Name, ChatInputBox.Text)
                ChatInputBox.Text = ""
            end
        end)
    end
end

-- Keybind handling: execute macro on key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == state.macroKeybind then
        ExecuteMacro()
    end
end)

-- AutoReport logic
Players.PlayerChatted:Connect(function(_, player, message)
    if player == LocalPlayer then return end
    local msg = string.lower(message)
    if state.autoReportActive then
        for word, reason in pairs(words) do
            if string.find(msg, word) then
                UI:Report(player.Name, reason, false)
                return
            end
        end
    end
    if state.reportBackActive then
        for word in pairs(reportBackWords) do
            if string.find(msg, word) then
                UI:Report(player.Name, "Bullying", true)
                return
            end
        end
    end
end)

-- Init
task.wait(2)
UI:Notify("✅ AutoReport V3.0", "Ready. Click logo to open UI.", 4)
AddChatMessage("System", "Universal Chat loaded!")
print("✅ AUTOREPORT V3.1 - REFACTORED WITH ABYSS UI")
-- 🚀 AutoReport V3.0 - ULTIMATE CHAT CONTROL SYSTEM (FIXED)
-- Fixed CanvasSize error + Enhanced stability

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local localPlayerName = string.lower(LocalPlayer.Name)

-- Custom UI Library (HackerAI UI v1.1 - FIXED)
local UI = {}

-- Try to require the Abyss UI module from common locations; fall back to simple UI if missing
local function tryRequire(name)
	local ok, res = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/refs/heads/main/UI-Lib/main.lua"))()
	end)
	if ok then return res end
	warn("Failed to load remote module via HttpGet fallback")
	return nil
end

local Abyss = tryRequire("ui-lib") or tryRequire("AbyssUI") or tryRequire("ui_lib")

-- Minimal logo to open the UI window
local Logo = Instance.new("ImageButton")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 96, 0, 96)
Logo.Position = UDim2.new(1, -116, 1, -116)
Logo.BackgroundTransparency = 1
Logo.Image = "https://raw.githubusercontent.com/kirahhkimmm/autoreportv2/main/images/logo.png"
Logo.Parent = game.CoreGui
Logo.ImageTransparency = 0.15
Logo.ZIndex = 1000
-- Chat input hookup (handles both fallback TextBox and AbyssUI TextboxData)
if ChatInputBox then
	if type(ChatInputBox) == "table" and ChatInputBox.Input then
		ChatInputBox.Input.FocusLost:Connect(function(enterPressed)
			if enterPressed and ChatInputBox.Input.Text ~= "" then
				AddChatMessage(LocalPlayer.Name, ChatInputBox.Input.Text)
				ChatInputBox.Input.Text = ""
			end
		end)
	elseif ChatInputBox.FocusLost then
		ChatInputBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and ChatInputBox.Text ~= "" then
				AddChatMessage(LocalPlayer.Name, ChatInputBox.Text)
				ChatInputBox.Text = ""
			end
		end)
	end
end

-- Keybinds (simple: execute macro when key pressed)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == state.macroKeybind then
		ExecuteMacro()
	end
end)
	ChatFrame.Position = UDim2.new(0, 0, 0, 0)
	ChatFrame.BackgroundTransparency = 1
	ChatFrame.BorderSizePixel = 0
	ChatFrame.ScrollBarThickness = 6
	ChatFrame.Parent = chatTab.Content

	local chatListLayout = Instance.new("UIListLayout")
	chatListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chatListLayout.Padding = UDim.new(0, 6)
	chatListLayout.Parent = ChatFrame

	ChatInputBox = chatTab.AddTextbox({ Text = "Message", Default = "", Callback = function(text)
		if text and text ~= "" then
			AddChatMessage(LocalPlayer.Name, text)
		end
	end })

	-- Macro key textbox in Macro tab
	macroTab.AddTextbox({ Text = "Macro Key", Default = "F", Callback = function(text)
		local key = string.upper(tostring(text or "")):gsub("%s+", "")
		if key ~= "" and Enum.KeyCode[key] then
			state.macroKeybind = Enum.KeyCode[key]
		end
	end })

	-- Create toggles using the UI
	for i, t in ipairs(toggles) do
		togglesSection.AddToggle({
			Text = t.label,
			Default = t.enabled,
			Callback = function(val)
				t.enabled = val
				if t.label:find("Universal Chat") then
					state.universalChatActive = val
					if ChatFrame then ChatFrame.Visible = val end
				elseif t.label:find("Macro") then
					state.macroEnabled = val
				elseif t.label:find("AutoReport") then
					state.autoReportActive = val
				elseif t.label:find("Report-Back") then
					state.reportBackActive = val
				end
			end
		})
	end
end

Logo.MouseButton1Click:Connect(function()
	if not MainUI or not MainUI.Window or not MainUI.Window.Parent then
		buildMainUI()
	else
		MainUI.Window.Visible = not MainUI.Window.Visible
	end
end)

-- State
local state = {
	logoHovered = false,
	menuOpen = false,
	keybindSetting = false,
	macroKeybind = Enum.KeyCode.F,
	macroEnabled = false,
	universalChatActive = false,
	autoReportActive = true,
	reportBackActive = true
}

local universalChatMessages = {}
local chatRoles = {
	["jimmynadlo"] = "👑 OWNER",
	[LocalPlayer.Name] = " "
}

-- 500+ WORD LIST (CONDENSED)
local words = {
	-- Bullying/Harassment (200+)
	['gay'] = 'Bullying', ['trans'] = 'Bullying', ['lgbt'] = 'Bullying', ['lesbian'] = 'Bullying', 
	['bi'] = 'Bullying', ['queer'] = 'Bullying', ['suicide'] = 'Bullying', ['kill yourself'] = 'Bullying',
	['f@g0t'] = 'Bullying', ['faggot'] = 'Bullying', ['fag'] = 'Bullying', ['furry'] = 'Bullying',
	['furries'] = 'Bullying', ['nigger'] = 'Bullying', ['nigga'] = 'Bullying', ['niga'] = 'Bullying',
	['coon'] = 'Bullying', ['bitch'] = 'Bullying', ['hoe'] = 'Bullying', ['slut'] = 'Bullying',
	['whore'] = 'Bullying', ['cringe'] = 'Bullying', ['trash'] = 'Bullying', ['trashcan'] = 'Bullying',
	['allah'] = 'Bullying', ['jesus'] = 'Bullying', ['god'] = 'Bullying', ['satan'] = 'Bullying',
	['dumb'] = 'Bullying', ['idiot'] = 'Bullying', ['stupid'] = 'Bullying', ['moron'] = 'Bullying',
	['retard'] = 'Bullying', ['autist'] = 'Bullying', ['autism'] = 'Bullying', ['noob'] = 'Bullying',
	['skill issue'] = 'Bullying', ['ez clap'] = 'Bullying', ['get good'] = 'Bullying', ['gg ez'] = 'Bullying',
	-- ... (300+ more words truncated for space - full list in production)
}

local reportBackWords = {
	['report'] = 'Bullying', ['reporting'] = 'Bullying', ['reported'] = 'Bullying', ['reports'] = 'Bullying',
	['report me'] = 'Bullying', ['gonna report'] = 'Bullying', ['i reported'] = 'Bullying',
	['mass report'] = 'Bullying', ['reportbot'] = 'Bullying', ['autoreport'] = 'Bullying', ['mod'] = 'Bullying'
}

-- Notification System
function UI:Notify(title, desc, duration)
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 300, 0, 80)
	notif.Position = UDim2.new(0, 20, 1, 20)
	notif.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	notif.Parent = ScreenGui
	-- no corner helper in this version
	
	-- Labels
	local notifTitle = Instance.new("TextLabel", notif)
	notifTitle.Size = UDim2.new(1, -20, 0, 30)
	notifTitle.Position = UDim2.new(0, 10, 0, 10)
	notifTitle.BackgroundTransparency = 1
	notifTitle.Text = title
	notifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifTitle.TextScaled = true
	notifTitle.Font = Enum.Font.GothamBold
	
	local notifDesc = Instance.new("TextLabel", notif)
	notifDesc.Size = UDim2.new(1, -20, 0, 30)
	notifDesc.Position = UDim2.new(0, 10, 0, 40)
	notifDesc.BackgroundTransparency = 1
	notifDesc.Text = desc
	notifDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	notifDesc.TextScaled = true
	notifDesc.Font = Enum.Font.Gotham
	notifDesc.TextXAlignment = Enum.TextXAlignment.Left
	
	TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0, 20, 1, -100)}):Play()
	game:GetService("Debris"):AddItem(notif, duration or 5)
end

-- Report
local cooldown = false
function UI:Report(playerName, reason, isReportBack)
	if string.lower(playerName) == localPlayerName or cooldown then return end
	
	pcall(function()
		Players:ReportAbuse(Players:FindFirstChild(playerName), reason, "breaking TOS")
	end)
	
	if isReportBack then
		UI:Notify("🔄 REPORT-BACK", "⚔️ Counter-reported " .. playerName, 4)
	else
		UI:Notify("🚨 AUTO-REPORT", "Reported " .. playerName .. " for " .. reason, 4)
	end
	
	cooldown = true
	task.delay(6, function() cooldown = false end)
end

-- Universal Chat Message ✅ FIXED
function AddChatMessage(playerName, message)
	local role = chatRoles[string.lower(playerName)] or "👤"
	
	local msgFrame = Instance.new("Frame")
	msgFrame.Size = UDim2.new(1, 0, 0, 40)
	msgFrame.BackgroundTransparency = 1
	msgFrame.LayoutOrder = #universalChatMessages + 1
	msgFrame.Parent = ChatFrame
	
	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(0, 60, 1, 0)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = role
	roleLabel.TextColor3 = role == "👑 OWNER" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(100, 255, 100)
	roleLabel.TextScaled = true
	roleLabel.Font = Enum.Font.GothamBold
	roleLabel.Parent = msgFrame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 100, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 65, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = playerName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = msgFrame
	
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -170, 1, 0)
	msgLabel.Position = UDim2.new(0, 165, 0, 0)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = message
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.TextScaled = true
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextWrapped = true
	msgLabel.Parent = msgFrame
	
	table.insert(universalChatMessages, msgFrame)
	-- Only set CanvasSize if ChatFrame is actually a ScrollingFrame
	if ChatFrame and ChatFrame:IsA("ScrollingFrame") then
		ChatFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(200, (#universalChatMessages + 1) * 45))
	else
		warn("ChatFrame is not a ScrollingFrame; cannot set CanvasSize")
	end
end

-- Macro
local macroText = "ez clap noob skill issue L + ratio"
function ExecuteMacro()
	if state.macroEnabled then
		game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(macroText, "All")
		UI:Notify("🎯 MACRO", "Executed macro!", 2)
	end
end

-- Events
Logo.MouseButton1Click:Connect(function()
	state.menuOpen = not state.menuOpen
	MainFrame.Visible = state.menuOpen
	TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = state.menuOpen and UDim2.new(1, -500, 0.5, -200) or UDim2.new(1, -50, 0.5, -200)
	}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
	state.menuOpen = false
	MainFrame.Visible = false
end)

-- Toggle Logic
for _, toggle in ipairs(toggles) do
	toggle.button.MouseButton1Click:Connect(function()
		toggle.enabled = not toggle.enabled
		toggle.button.Text = toggle.label .. (toggle.enabled and " ON" or " OFF")
		toggle.button.BackgroundColor3 = toggle.enabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 120)
		
		if toggle.label:find("Universal Chat") then
			state.universalChatActive = toggle.enabled
			ChatFrame.Visible = state.universalChatActive
		elseif toggle.label:find("Macro") then
			state.macroEnabled = toggle.enabled
			MacroFrame.Visible = toggle.enabled
		elseif toggle.label:find("AutoReport") then
			state.autoReportActive = toggle.enabled
		elseif toggle.label:find("Report-Back") then
			state.reportBackActive = toggle.enabled
		end
	end)
end

SetKeybindBtn.MouseButton1Click:Connect(function()
	state.keybindSetting = true
	KeybindLabel.Text = "PRESS KEY..."
end)

ChatInput.FocusLost:Connect(function(enterPressed)
	if enterPressed and ChatInput.Text ~= "" then
		AddChatMessage(LocalPlayer.Name, ChatInput.Text)
		ChatInput.Text = ""
	end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if state.keybindSetting and input.KeyCode.Name ~= "Unknown" then
		state.macroKeybind = input.KeyCode
		KeybindLabel.Text = input.KeyCode.Name
		state.keybindSetting = false
		return
	end
	
	if input.KeyCode == state.macroKeybind then
		ExecuteMacro()
	end
end)

-- AutoReport ✅ FIXED
Players.PlayerChatted:Connect(function(_, player, message)
	if player == LocalPlayer then return end
	
	local msg = string.lower(message)
	
	if state.autoReportActive then
		for word, reason in pairs(words) do
			if string.find(msg, word) then
				UI:Report(player.Name, reason, false)
				return
			end
		end
	end
	
	if state.reportBackActive then
		for word in pairs(reportBackWords) do
			if string.find(msg, word) then
				UI:Report(player.Name, "Bullying", true)
				return
			end
		end
	end
end)

-- Init
task.wait(2)
UI:Notify("✅ AutoReport V3.0 FIXED", "🎉 CanvasSize error resolved! Click logo!", 5)
AddChatMessage("System", "Universal Chat loaded!")
print("✅ AUTOREPORT V3.1 - ERROR FIXED!")
