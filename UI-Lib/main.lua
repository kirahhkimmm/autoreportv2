-- AbyssUI Library
-- Modern Roblox UI Library with animations and drag support

local AbyssUI = {}
AbyssUI.__index = AbyssUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local ScreenGui = nil
local Library = nil

-- Default theme
local Theme = {
    Accent = Color3.fromRGB(0, 162, 255),
    BackgroundPrimary = Color3.fromRGB(25, 25, 35),
    BackgroundSecondary = Color3.fromRGB(35, 35, 45),
    BackgroundTertiary = Color3.fromRGB(45, 45, 55),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Border = Color3.fromRGB(60, 60, 70),
    Stroke = Color3.fromRGB(0, 162, 255),
    Success = Color3.fromRGB(0, 200, 100),
    Error = Color3.fromRGB(255, 85, 85),
    Warning = Color3.fromRGB(255, 180, 0)
}

-- Animation info
local AnimInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Create main ScreenGui
function AbyssUI:Init()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AbyssUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    Library = Instance.new("Frame")
    Library.Name = "Library"
    Library.Size = UDim2.new(0, 0, 0, 0)
    Library.Position = UDim2.new(0.5, 0, 0.5, 0)
    Library.AnchorPoint = Vector2.new(0.5, 0.5)
    Library.BackgroundTransparency = 1
    Library.Parent = ScreenGui
    
    self.Theme = Theme
    return self
end

-- Create Window
function AbyssUI:CreateWindow(options)
    options = options or {}
    local windowName = options.Name or "AbyssUI"
    local windowSize = options.Size or UDim2.new(0, 550, 0, 400)
    
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Size = windowSize
    Window.Position = UDim2.new(0.5, 0, 0.5, 0)
    Window.AnchorPoint = Vector2.new(0.5, 0.5)
    Window.BackgroundColor3 = self.Theme.BackgroundPrimary
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true
    Window.Parent = Library
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Window
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = self.Theme.Border
    Stroke.Thickness = 1
    Stroke.Parent = Window
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundColor3 = self.Theme.BackgroundSecondary
    Header.BorderSizePixel = 0
    Header.Parent = Window
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local HeaderStroke = Instance.new("UIStroke")
    HeaderStroke.Color = self.Theme.Accent
    HeaderStroke.Thickness = 1.5
    HeaderStroke.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = windowName
    Title.TextColor3 = self.Theme.TextPrimary
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -40, 0.5, -15)
    CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
    CloseButton.BackgroundColor3 = self.Theme.Error
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.new(1,1,1)
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = Header
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton
    
    -- Content Frame
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -75)
    Content.Position = UDim2.new(0, 10, 0, 60)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 6
    Content.ScrollBarImageColor3 = self.Theme.Accent
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Parent = Window
    
    local ContentList = Instance.new("UIListLayout")
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Padding = UDim.new(0, 8)
    ContentList.Parent = Content
    
    -- Drag functionality
    self:MakeDraggable(Window, Header)
    
    -- Close functionality
    CloseButton.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            Window:Destroy()
        end)
    end)
    
    -- Auto-resize canvas
    ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
    end)
    
    local WindowData = {
        Window = Window,
        Content = Content,
        Header = Header,
        Title = Title,
        Tabs = {},
        ActiveTab = nil
    }
    
    WindowData.CreateTab = function(tabOptions)
        return self:CreateTab(WindowData, tabOptions)
    end
    
    -- Initial animation
    Window.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(Window, AnimInfo, {Size = windowSize})
    openTween:Play()
    
    return WindowData
end

-- Create Tab
function AbyssUI:CreateTab(windowData, options)
    options = options or {}
    local tabName = options.Name or "Tab"
    
    -- Tab Button
    local TabButton = Instance.new("TextButton")
    TabButton.Name = tabName .. "Button"
    TabButton.Size = UDim2.new(0, 120, 0, 35)
    TabButton.BackgroundColor3 = self.Theme.BackgroundTertiary
    TabButton.BorderSizePixel = 0
    TabButton.Text = tabName
    TabButton.TextColor3 = self.Theme.TextSecondary
    TabButton.TextSize = 14
    TabButton.Font = Enum.Font.GothamSemibold
    TabButton.Parent = windowData.Header
    
    local TabButtonCorner = Instance.new("UICorner")
    TabButtonCorner.CornerRadius = UDim.new(0, 8)
    TabButtonCorner.Parent = TabButton
    
    local TabButtonStroke = Instance.new("UIStroke")
    TabButtonStroke.Color = self.Theme.Border
    TabButtonStroke.Thickness = 1
    TabButtonStroke.Parent = TabButton
    
    -- Tab Content
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = tabName .. "Content"
    TabContent.Size = UDim2.new(1, 0, 1, 0)
    TabContent.Position = UDim2.new(0, 0, 0, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = self.Theme.Accent
    TabContent.Visible = false
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContent.Parent = windowData.Content
    
    local TabContentList = Instance.new("UIListLayout")
    TabContentList.SortOrder = Enum.SortOrder.LayoutOrder
    TabContentList.Padding = UDim.new(0, 6)
    TabContentList.Parent = TabContent
    
    TabContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContentList.AbsoluteContentSize.Y + 20)
    end)
    
    local TabData = {
        Name = tabName,
        Button = TabButton,
        Content = TabContent,
        Elements = {}
    }
    
    table.insert(windowData.Tabs, TabData)
    
    -- Tab functionality
    TabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(windowData, TabData)
    end)
    
    if #windowData.Tabs == 1 then
        self:SwitchTab(windowData, TabData)
    end
    
    -- Element creation methods
    TabData.AddSection = function(sectionOptions)
        return self:CreateSection(TabData, sectionOptions)
    end
    
    TabData.AddButton = function(buttonOptions)
        return self:CreateButton(TabData, buttonOptions)
    end
    
    TabData.AddToggle = function(toggleOptions)
        return self:CreateToggle(TabData, toggleOptions)
    end
    
    TabData.AddSlider = function(sliderOptions)
        return self:CreateSlider(TabData, sliderOptions)
    end
    
    TabData.AddDropdown = function(dropdownOptions)
        return self:CreateDropdown(TabData, dropdownOptions)
    end
    
    TabData.AddTextbox = function(textboxOptions)
        return self:CreateTextbox(TabData, textboxOptions)
    end
    
    TabData.AddColorPicker = function(colorOptions)
        return self:CreateColorPicker(TabData, colorOptions)
    end
    
    return TabData
end

-- Switch Tab
function AbyssUI:SwitchTab(windowData, tabData)
    for _, tab in pairs(windowData.Tabs) do
        tab.Button.TextColor3 = self.Theme.TextSecondary
        local buttonStroke = tab.Button:FindFirstChild("UIStroke")
        if buttonStroke then
            buttonStroke.Color = self.Theme.Border
        end
        tab.Content.Visible = false
    end
    
    tabData.Button.TextColor3 = self.Theme.TextPrimary
    local buttonStroke = tabData.Button:FindFirstChild("UIStroke")
    if buttonStroke then
        buttonStroke.Color = self.Theme.Accent
    end
    tabData.Content.Visible = true
    
    windowData.ActiveTab = tabData
end

-- Create Section
function AbyssUI:CreateSection(tabData, options)
    options = options or {}
    local sectionName = options.Name or "Section"
    
    local SectionFrame = Instance.new("Frame")
    SectionFrame.Name = sectionName
    SectionFrame.BackgroundColor3 = self.Theme.BackgroundTertiary
    SectionFrame.BorderSizePixel = 0
    SectionFrame.Parent = tabData.Content
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 8)
    SectionCorner.Parent = SectionFrame
    
    local SectionStroke = Instance.new("UIStroke")
    SectionStroke.Color = self.Theme.Border
    SectionStroke.Thickness = 1
    SectionStroke.Parent = SectionFrame
    
    local SectionTitle = Instance.new("TextLabel")
    SectionTitle.Name = "Title"
    SectionTitle.Size = UDim2.new(1, -20, 0, 35)
    SectionTitle.Position = UDim2.new(0, 10, 0, 0)
    SectionTitle.BackgroundTransparency = 1
    SectionTitle.Text = sectionName
    SectionTitle.TextColor3 = self.Theme.TextPrimary
    SectionTitle.TextSize = 14
    SectionTitle.Font = Enum.Font.GothamSemibold
    SectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    SectionTitle.Parent = SectionFrame
    
    local SectionContent = Instance.new("Frame")
    SectionContent.Name = "Content"
    SectionContent.Size = UDim2.new(1, -20, 1, -45)
    SectionContent.Position = UDim2.new(0, 10, 0, 40)
    SectionContent.BackgroundTransparency = 1
    SectionContent.Parent = SectionFrame
    
    local SectionContentList = Instance.new("UIListLayout")
    SectionContentList.SortOrder = Enum.SortOrder.LayoutOrder
    SectionContentList.Padding = UDim.new(0, 6)
    SectionContentList.Parent = SectionContent
    
    local SectionData = {
        Frame = SectionFrame,
        Content = SectionContent,
        Elements = {}
    }
    
    table.insert(tabData.Elements, SectionData)
    
    SectionData.AddButton = function(options)
        return self:CreateButtonInContainer(SectionData, options)
    end
    
    SectionData.AddToggle = function(options)
        return self:CreateToggleInContainer(SectionData, options)
    end
    
    SectionData.AddSlider = function(options)
        return self:CreateSliderInContainer(SectionData, options)
    end
    
    SectionData.AddTextbox = function(options)
        return self:CreateTextboxInContainer(SectionData, options)
    end
    
    return SectionData
end

-- Button
function AbyssUI:CreateButton(tabData, options)
    local buttonData = self:CreateButtonInContainer({Content = tabData.Content}, options)
    table.insert(tabData.Elements, buttonData)
    return buttonData
end

function AbyssUI:CreateButtonInContainer(containerData, options)
    options = options or {}
    local buttonText = options.Text or "Button"
    local callback = options.Callback or function() end
    
    local Button = Instance.new("TextButton")
    Button.Name = "Button"
    Button.Size = UDim2.new(1, -20, 0, 35)
    Button.BackgroundColor3 = self.Theme.BackgroundSecondary
    Button.BorderSizePixel = 0
    Button.Text = buttonText
    Button.TextColor3 = self.Theme.TextPrimary
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamSemibold
    Button.Parent = containerData.Content
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    local ButtonStroke = Instance.new("UIStroke")
    ButtonStroke.Color = self.Theme.Border
    ButtonStroke.Thickness = 1
    ButtonStroke.Parent = Button
    
    local hoverTween = TweenService:Create(Button, TweenInfo.new(0.2), {
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(1, -18, 0, 36)
    })
    
    local normalTween = TweenService:Create(Button, TweenInfo.new(0.2), {
        BackgroundColor3 = self.Theme.BackgroundSecondary,
        Size = UDim2.new(1, -20, 0, 35)
    })
    
    Button.MouseEnter:Connect(function()
        hoverTween:Play()
    end)
    
    Button.MouseLeave:Connect(function()
        normalTween:Play()
    end)
    
    Button.MouseButton1Click:Connect(function()
        local clickTween = TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Size = UDim2.new(1, -22, 0, 33)
        })
        clickTween:Play()
        clickTween.Completed:Connect(function()
            normalTween:Play()
        end)
        callback()
    end)
    
    local ButtonData = {
        Button = Button,
        UpdateText = function(text)
            Button.Text = text
        end,
        SetCallback = function(newCallback)
            callback = newCallback
        end
    }
    
    table.insert(containerData.Elements, ButtonData)
    return ButtonData
end

-- Toggle
function AbyssUI:CreateToggle(tabData, options)
    local toggleData = self:CreateToggleInContainer({Content = tabData.Content}, options)
    table.insert(tabData.Elements, toggleData)
    return toggleData
end

function AbyssUI:CreateToggleInContainer(containerData, options)
    options = options or {}
    local toggleText = options.Text or "Toggle"
    local default = options.Default or false
    local callback = options.Callback or function() end
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = "Toggle"
    ToggleFrame.Size = UDim2.new(1, -20, 0, 35)
    ToggleFrame.BackgroundColor3 = self.Theme.BackgroundSecondary
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = containerData.Content
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = self.Theme.Border
    ToggleStroke.Thickness = 1
    ToggleStroke.Parent = ToggleFrame
    
    local ToggleText = Instance.new("TextLabel")
    ToggleText.Name = "Text"
    ToggleText.Size = UDim2.new(1, -60, 1, 0)
    ToggleText.Position = UDim2.new(0, 15, 0, 0)
    ToggleText.BackgroundTransparency = 1
    ToggleText.Text = toggleText
    ToggleText.TextColor3 = self.Theme.TextPrimary
    ToggleText.TextSize = 14
    ToggleText.Font = Enum.Font.Gotham
    ToggleText.TextXAlignment = Enum.TextXAlignment.Left
    ToggleText.Parent = ToggleFrame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 25, 0, 15)
    ToggleButton.Position = UDim2.new(1, -35, 0.5, -7.5)
    ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    ToggleButton.BackgroundColor3 = default and self.Theme.Success or self.Theme.Error
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = ""
    ToggleButton.Parent = ToggleFrame
    
    local ToggleButtonCorner = Instance.new("UICorner")
    ToggleButtonCorner.CornerRadius = UDim.new(0, 8)
    ToggleButtonCorner.Parent = ToggleButton
    
    local ToggleIndicator = Instance.new("Frame")
    ToggleIndicator.Name = "Indicator"
    ToggleIndicator.Size = UDim2.new(0, 11, 0, 11)
    ToggleIndicator.Position = default and UDim2.new(0, 2, 0.5, -5.5) or UDim2.new(0, 1, 0.5, -5.5)
    ToggleIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
    ToggleIndicator.BackgroundColor3 = Color3.new(1,1,1)
    ToggleIndicator.BorderSizePixel = 0
    ToggleIndicator.Parent = ToggleButton
    
    local ToggleIndicatorCorner = Instance.new("UICorner")
    ToggleIndicatorCorner.CornerRadius = UDim.new(0, 5.5)
    ToggleIndicatorCorner.Parent = ToggleIndicator
    
    local state = default
    
    local function updateToggle()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart)
        local buttonTween = TweenService:Create(ToggleButton, tweenInfo, {
            BackgroundColor3 = state and self.Theme.Success or self.Theme.Error
        })
        local indicatorTween = TweenService:Create(ToggleIndicator, tweenInfo, {
            Position = state and UDim2.new(0, 12, 0.5, -5.5) or UDim2.new(0, 1, 0.5, -5.5)
        })
        buttonTween:Play()
        indicatorTween:Play()
        callback(state)
    end
    
    ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
    end)
    
    local ToggleData = {
        Frame = ToggleFrame,
        Toggle = ToggleButton,
        Set = function(value)
            state = value
            updateToggle()
        end,
        Toggle = function()
            state = not state
            updateToggle()
        end,
        Get = function()
            return state
        end
    }
    
    if default then
        callback(true)
    end
    
    table.insert(containerData.Elements, ToggleData)
    return ToggleData
end

-- Slider
function AbyssUI:CreateSlider(tabData, options)
    local sliderData = self:CreateSliderInContainer({Content = tabData.Content}, options)
    table.insert(tabData.Elements, sliderData)
    return sliderData
end

function AbyssUI:CreateSliderInContainer(containerData, options)
    options = options or {}
    local sliderText = options.Text or "Slider"
    local min = options.Min or 0
    local max = options.Max or 100
    local default = options.Default or min
    local callback = options.Callback or function() end
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = "Slider"
    SliderFrame.Size = UDim2.new(1, -20, 0, 50)
    SliderFrame.BackgroundColor3 = self.Theme.BackgroundSecondary
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = containerData.Content
    
    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 8)
    SliderCorner.Parent = SliderFrame
    
    local SliderStroke = Instance.new("UIStroke")
    SliderStroke.Color = self.Theme.Border
    SliderStroke.Thickness = 1
    SliderStroke.Parent = SliderFrame
    
    local SliderText = Instance.new("TextLabel")
    SliderText.Name = "Text"
    SliderText.Size = UDim2.new(1, -20, 0, 20)
    SliderText.Position = UDim2.new(0, 10, 0, 5)
    SliderText.BackgroundTransparency = 1
    SliderText.Text = sliderText .. ": " .. default
    SliderText.TextColor3 = self.Theme.TextPrimary
    SliderText.TextSize = 14
    SliderText.Font = Enum.Font.Gotham
    SliderText.TextXAlignment = Enum.TextXAlignment.Left
    SliderText.Parent = SliderFrame
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "Bar"
    SliderBar.Size = UDim2.new(1, -20, 0, 6)
    SliderBar.Position = UDim2.new(0, 10, 0, 35)
    SliderBar.BackgroundColor3 = self.Theme.BackgroundTertiary
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = SliderFrame
    
    local SliderBarCorner = Instance.new("UICorner")
    SliderBarCorner.CornerRadius = UDim.new(0, 3)
    SliderBarCorner.Parent = SliderBar
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "Fill"
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.Position = UDim2.new(0, 0, 0, 0)
    SliderFill.BackgroundColor3 = self.Theme.Accent
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBar
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(0, 3)
    SliderFillCorner.Parent = SliderFill
    
    local dragging = false
    local currentValue = default
    
    local function updateSlider(value)
        value = math.clamp(value, min, max)
        currentValue = value
        SliderFill:TweenSize(UDim2.new((value - min) / (max - min), 0, 1, 0), "Out", "Quad", 0.1, true)
        SliderText.Text = sliderText .. ": " .. math.floor(value)
        callback(value)
    end
    
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    SliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = UserInputService:GetMouseLocation()
            local relativeX = math.clamp((mouse.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * relativeX
            updateSlider(value)
        end
    end)
    
    updateSlider(default)
    
    local SliderData = {
        Frame = SliderFrame,
        Set = function(value)
            updateSlider(value)
        end,
        Get = function()
            return currentValue
        end
    }
    
    table.insert(containerData.Elements, SliderData)
    return SliderData
end

-- Textbox
function AbyssUI:CreateTextbox(tabData, options)
    local textboxData = self:CreateTextboxInContainer({Content = tabData.Content}, options)
    table.insert(tabData.Elements, textboxData)
    return textboxData
end

function AbyssUI:CreateTextboxInContainer(containerData, options)
    options = options or {}
    local textboxText = options.Text or "Textbox"
    local default = options.Default or ""
    local callback = options.Callback or function() end
    
    local TextboxFrame = Instance.new("Frame")
    TextboxFrame.Name = "Textbox"
    TextboxFrame.Size = UDim2.new(1, -20, 0, 35)
    TextboxFrame.BackgroundColor3 = self.Theme.BackgroundSecondary
    TextboxFrame.BorderSizePixel = 0
    TextboxFrame.Parent = containerData.Content
    
    local TextboxCorner = Instance.new("UICorner")
    TextboxCorner.CornerRadius = UDim.new(0, 8)
    TextboxCorner.Parent = TextboxFrame
    
    local TextboxStroke = Instance.new("UIStroke")
    TextboxStroke.Color = self.Theme.Border
    TextboxStroke.Thickness = 1
    TextboxStroke.Parent = TextboxFrame
    
    local TextboxLabel = Instance.new("TextLabel")
    TextboxLabel.Name = "Label"
    TextboxLabel.Size = UDim2.new(1, -140, 1, 0)
    TextboxLabel.Position = UDim2.new(0, 15, 0, 0)
    TextboxLabel.BackgroundTransparency = 1
    TextboxLabel.Text = textboxText
    TextboxLabel.TextColor3 = self.Theme.TextSecondary
    TextboxLabel.TextSize = 14
    TextboxLabel.Font = Enum.Font.Gotham
    TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextboxLabel.TextYAlignment = Enum.TextYAlignment.Center
    TextboxLabel.Parent = TextboxFrame
    
    local TextboxInput = Instance.new("TextBox")
    TextboxInput.Name = "Input"
    TextboxInput.Size = UDim2.new(0, 110, 0, 25)
    TextboxInput.Position = UDim2.new(1, -130, 0.5, -12.5)
    TextboxInput.AnchorPoint = Vector2.new(0.5, 0.5)
    TextboxInput.BackgroundColor3 = self.Theme.BackgroundTertiary
    TextboxInput.BorderSizePixel = 0
    TextboxInput.Text = default
    TextboxInput.TextColor3 = self.Theme.TextPrimary
    TextboxInput.PlaceholderText = "Enter text..."
    TextboxInput.PlaceholderColor3 = self.Theme.TextSecondary
    TextboxInput.TextSize = 13
    TextboxInput.Font = Enum.Font.Gotham
    TextboxInput.TextXAlignment = Enum.TextXAlignment.Left
    TextboxInput.ClearTextOnFocus = false
    TextboxInput.Parent = TextboxFrame
    
    local TextboxInputCorner = Instance.new("UICorner")
    TextboxInputCorner.CornerRadius = UDim.new(0, 6)
    TextboxInputCorner.Parent = TextboxInput
    
    TextboxInput.FocusLost:Connect(function(enterPressed)
        callback(TextboxInput.Text)
    end)
    
    local TextboxData = {
        Frame = TextboxFrame,
        Input = TextboxInput,
        Set = function(text)
            TextboxInput.Text = text
        end,
        Get = function()
            return TextboxInput.Text
        end
    }
    
    table.insert(containerData.Elements, TextboxData)
    return TextboxData
end

-- Dropdown (simplified)
function AbyssUI:CreateDropdown(tabData, options)
    options = options or {}
    local dropdownText = options.Text or "Dropdown"
    local items = options.Items or {}
    local default = options.Default or items[1]
    local callback = options.Callback or function() end
    
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = "Dropdown"
    DropdownFrame.Size = UDim2.new(1, -20, 0, 40)
    DropdownFrame.BackgroundColor3 = self.Theme.BackgroundSecondary
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.Parent = tabData.Content
    
    local DropdownCorner = Instance.new("UICorner")
    DropdownCorner.CornerRadius = UDim.new(0, 8)
    DropdownCorner.Parent = DropdownFrame
    
    local DropdownStroke = Instance.new("UIStroke")
    DropdownStroke.Color = self.Theme.Border
    DropdownStroke.Thickness = 1
    DropdownStroke.Parent = DropdownFrame
    
    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Name = "Label"
    DropdownLabel.Size = UDim2.new(1, -20, 0.5, 0)
    DropdownLabel.Position = UDim2.new(0, 15, 0, 5)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = dropdownText
    DropdownLabel.TextColor3 = self.Theme.TextSecondary
    DropdownLabel.TextSize = 14
    DropdownLabel.Font = Enum.Font.Gotham
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = DropdownFrame
    
    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Name = "Button"
    DropdownButton.Size = UDim2.new(1, -20, 0.5, 0)
    DropdownButton.Position = UDim2.new(0, 10, 0.5, 0)
    DropdownButton.BackgroundColor3 = self.Theme.BackgroundTertiary
    DropdownButton.BorderSizePixel = 0
    DropdownButton.Text = default or "Select..."
    DropdownButton.TextColor3 = self.Theme.TextPrimary
    DropdownButton.TextSize = 13
    DropdownButton.Font = Enum.Font.Gotham
    DropdownButton.Parent = DropdownFrame
    
    local DropdownButtonCorner = Instance.new("UICorner")
    DropdownButtonCorner.CornerRadius = UDim.new(0, 6)
    DropdownButtonCorner.Parent = DropdownButton
    
    local DropdownList = Instance.new("Frame")
    DropdownList.Name = "List"
    DropdownList.Size = UDim2.new(1, 0, 0, 0)
    DropdownList.Position = UDim2.new(0, 0, 1, 5)
    DropdownList.BackgroundColor3 = self.Theme.BackgroundPrimary
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.Parent = DropdownFrame
    
    local DropdownListCorner = Instance.new("UICorner")
    DropdownListCorner.CornerRadius = UDim.new(0, 8)
    DropdownListCorner.Parent = DropdownList
    
    local DropdownListStroke = Instance.new("UIStroke")
    DropdownListStroke.Color = self.Theme.Border
    DropdownListStroke.Thickness = 1
    DropdownListStroke.Parent = DropdownList
    
    local DropdownListLayout = Instance.new("UIListLayout")
    DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    DropdownListLayout.Padding = UDim.new(0, 1)
    DropdownListLayout.Parent = DropdownList
    
    local isOpen = false
    
    local function populateList()
        for _, child in pairs(DropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for i, item in ipairs(items) do
            local ItemButton = Instance.new("TextButton")
            ItemButton.Name = item
            ItemButton.Size = UDim2.new(1, 0, 0, 30)
            ItemButton.BackgroundColor3 = self.Theme.BackgroundSecondary
            ItemButton.BorderSizePixel = 0
            ItemButton.Text = item
            ItemButton.TextColor3 = self.Theme.TextPrimary
            ItemButton.TextSize = 13
            ItemButton.Font = Enum.Font.Gotham
            ItemButton.Parent = DropdownList
            
            ItemButton.MouseButton1Click:Connect(function()
                DropdownButton.Text = item
                callback(item)
                isOpen = false
                DropdownList.Visible = false
            end)
        end
        
        DropdownListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            DropdownList.Size = UDim2.new(1, 0, 0, DropdownListLayout.AbsoluteContentSize.Y)
        end)
    end
    
    populateList()
    
    DropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        DropdownList.Visible = isOpen
    end)
    
    local DropdownData = {
        Frame = DropdownFrame,
        SetItems = function(newItems)
            items = newItems
            populateList()
        end,
        Get = function()
            return DropdownButton.Text
        end
    }
    
    table.insert(tabData.Elements, DropdownData)
    return DropdownData
end

-- Color Picker (simplified)
function AbyssUI:CreateColorPicker(tabData, options)
    options = options or {}
    local defaultColor = options.Color or Color3.fromRGB(255, 255, 255)
    local callback = options.Callback or function() end
    
    local ColorPickerFrame = Instance.new("Frame")
    ColorPickerFrame.Name = "ColorPicker"
    ColorPickerFrame.Size = UDim2.new(1, -20, 0, 35)
    ColorPickerFrame.BackgroundColor3 = self.Theme.BackgroundSecondary
    ColorPickerFrame.BorderSizePixel = 0
    ColorPickerFrame.Parent = tabData.Content
    
    local ColorPickerCorner = Instance.new("UICorner")
    ColorPickerCorner.CornerRadius = UDim.new(0, 8)
    ColorPickerCorner.Parent = ColorPickerFrame
    
    local ColorPreview = Instance.new("Frame")
    ColorPreview.Name = "Preview"
    ColorPreview.Size = UDim2.new(0, 25, 0, 25)
    ColorPreview.Position = UDim2.new(0, 15, 0.5, -12.5)
    ColorPreview.AnchorPoint = Vector2.new(0.5, 0.5)
    ColorPreview.BackgroundColor3 = defaultColor
    ColorPreview.BorderSizePixel = 0
    ColorPreview.Parent = ColorPickerFrame
    
    local ColorPreviewCorner = Instance.new("UICorner")
    ColorPreviewCorner.CornerRadius = UDim.new(0, 5)
    ColorPreviewCorner.Parent = ColorPreview
    
    local ColorLabel = Instance.new("TextLabel")
    ColorLabel.Name = "Label"
    ColorLabel.Size = UDim2.new(1, -60, 1, 0)
    ColorLabel.Position = UDim2.new(0, 50, 0, 0)
    ColorLabel.BackgroundTransparency = 1
    ColorLabel.Text = "Color Picker"
    ColorLabel.TextColor3 = self.Theme.TextPrimary
    ColorLabel.TextSize = 14
    ColorLabel.Font = Enum.Font.Gotham
    ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
    ColorLabel.Parent = ColorPickerFrame
    
    -- Simple color preset buttons
    local colors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)
    }
    
    for i, color in ipairs(colors) do
        local ColorButton = Instance.new("TextButton")
        ColorButton.Size = UDim2.new(0, 20, 0, 20)
        ColorButton.Position = UDim2.new(0, 50 + (i-1) * 25, 0.5, -10)
        ColorButton.BackgroundColor3 = color
        ColorButton.BorderSizePixel = 1
        ColorButton.BorderColor3 = self.Theme.Border
        ColorButton.Text = ""
        ColorButton.Parent = ColorPickerFrame
        
        ColorButton.MouseButton1Click:Connect(function()
            ColorPreview.BackgroundColor3 = color
            callback(color)
        end)
    end
    
    local ColorPickerData = {
        Frame = ColorPickerFrame,
        SetColor = function(color)
            ColorPreview.BackgroundColor3 = color
            callback(color)
        end
    }
    
    table.insert(tabData.Elements, ColorPickerData)
    return ColorPickerData
end

-- Drag functionality
function AbyssUI:MakeDraggable(frame, dragBar)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    dragBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Notification system
function AbyssUI:Notify(options)
    options = options or {}
    local text = options.Text or "Notification"
    local duration = options.Duration or 3
    
    if not ScreenGui then return end
    
    local Notification = Instance.new("Frame")
    Notification.Name = "Notification"
    Notification.Size = UDim2.new(0, 300, 0, 60)
    Notification.Position = UDim2.new(1, -320, 0, 20)
    Notification.BackgroundColor3 = self.Theme.BackgroundSecondary
    Notification.BorderSizePixel = 0
    Notification.Parent = ScreenGui
    
    local NotificationCorner = Instance.new("UICorner")
    NotificationCorner.CornerRadius = UDim.new(0, 8)
    NotificationCorner.Parent = Notification
    
    local NotificationStroke = Instance.new("UIStroke")
    NotificationStroke.Color = self.Theme.Accent
    NotificationStroke.Thickness = 1.5
    NotificationStroke.Parent = Notification
    
    local NotificationText = Instance.new("TextLabel")
    NotificationText.Size = UDim2.new(1, -20, 1, -10)
    NotificationText.Position = UDim2.new(0, 10, 0, 5)
    NotificationText.BackgroundTransparency = 1
    NotificationText.Text = text
    NotificationText.TextColor3 = self.Theme.TextPrimary
    NotificationText.TextSize = 14
    NotificationText.Font = Enum.Font.Gotham
    NotificationText.TextWrapped = true
    NotificationText.Parent = Notification
    
    -- Slide in animation
    local slideIn = TweenService:Create(Notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 0, 20)
    })
    local slideOut = TweenService:Create(Notification, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 0, 0, 20)
    })
    
    Notification.Position = UDim2.new(1, 0, 0, 20)
    slideIn:Play()
    
    game:GetService("Debris"):AddItem(Notification, duration)
    wait(duration - 0.3)
    slideOut:Play()
end

-- Change theme colors
function AbyssUI:SetTheme(newTheme)
    self.Theme = newTheme
    -- Update all existing elements would go here
end

return AbyssUI
