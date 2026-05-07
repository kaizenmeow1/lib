--[[
    Speed Hub X V5 - Photo Style Responsive UI Library
    Reworked to match the dark/red layout shown in the screenshots.

    Drop-in style API:
        local Library = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        local Window = Library:CreateWindow({Title = "Speed Hub X", Description = "Version 5.0.0", ["Tab Width"] = 135, SizeUi = UDim2.fromOffset(550, 350)})
        local Tab = Window:CreateTab({Name = "Main", Icon = "rbxassetid://..."})
        local Section = Tab:AddSection("Automation Crafting", true)
        Section:AddToggle({Title = "Auto Collect Loot", Default = false, Callback = function(v) print(v) end})
        Section:AddDropdown({Title = "Source Slime", Options = {"None", "quest", "ninja"}, Default = "None", Callback = function(v) print(v) end})
        Section:AddInput({Title = "Delay", Default = "1", Callback = function(v) print(v) end})
        Section:AddSlider({Title = "Speed", Min = 1, Max = 100, Default = 25, Callback = function(v) print(v) end})
        Section:AddButton({Title = "Run", Callback = function() print("clicked") end})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.Unloaded = false
Library.Windows = {}

local Theme = {
    Accent = Color3.fromRGB(255, 77, 86),
    AccentDark = Color3.fromRGB(130, 27, 31),
    Background = Color3.fromRGB(18, 8, 10),
    Background2 = Color3.fromRGB(26, 12, 14),
    Top = Color3.fromRGB(20, 8, 10),
    Side = Color3.fromRGB(23, 11, 13),
    Row = Color3.fromRGB(43, 31, 32),
    RowHover = Color3.fromRGB(54, 39, 41),
    RowDark = Color3.fromRGB(33, 22, 24),
    Popup = Color3.fromRGB(102, 24, 25),
    Stroke = Color3.fromRGB(70, 47, 50),
    StrokeLight = Color3.fromRGB(98, 68, 72),
    Text = Color3.fromRGB(245, 245, 245),
    Muted = Color3.fromRGB(160, 151, 154),
    MutedDark = Color3.fromRGB(112, 104, 108),
    ToggleOff = Color3.fromRGB(98, 92, 93),
    Input = Color3.fromRGB(61, 45, 48)
}

local function create(className, props, parent)
    local inst = Instance.new(className)
    props = props or {}
    for prop, value in pairs(props) do
        if prop ~= "Parent" then
            inst[prop] = value
        end
    end
    inst.Parent = parent or props.Parent
    return inst
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0)
    }, parent)
end

local function tween(object, time, goal, style, direction)
    local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(object, info, goal)
    t:Play()
    return t
end

local function safeCallback(callback, ...)
    if typeof(callback) == "function" then
        local args = table.pack(...)
        task.spawn(function()
            local ok, err = pcall(function()
                callback(table.unpack(args, 1, args.n))
            end)
            if not ok then
                warn("[Speed Hub X UI] callback error:", err)
            end
        end)
    end
end

local function getGuiParent()
    if RunService:IsStudio() and LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    local okHui, hui = pcall(function()
        return gethui()
    end)
    if okHui and hui then
        return hui
    end

    local okClone, cloned = pcall(function()
        return cloneref(CoreGui)
    end)
    if okClone and cloned then
        return cloned
    end

    return CoreGui
end

local function parseTextConfig(config, defaultTitle, defaultContent, defaultCallback)
    if typeof(config) == "table" then
        return config.Title or config.Name or config[1] or defaultTitle or "",
            config.Content or config.Description or config.Desc or config[2] or defaultContent or "",
            config.Callback or config.CallBack or config[3] or defaultCallback
    end
    return tostring(config or defaultTitle or ""), tostring(defaultTitle or defaultContent or ""), defaultCallback
end

local function disconnectAll(list)
    for _, connection in ipairs(list) do
        if connection and connection.Disconnect then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    table.clear(list)
end

local function getOffsetSize(size, fallbackX, fallbackY)
    fallbackX = fallbackX or 550
    fallbackY = fallbackY or 350
    if typeof(size) ~= "UDim2" then
        return fallbackX, fallbackY
    end
    local x = size.X.Offset
    local y = size.Y.Offset
    if x <= 0 then x = fallbackX end
    if y <= 0 then y = fallbackY end
    return x, y
end

local function textSize(text, font, size, width)
    local ok, result = pcall(function()
        return TextService:GetTextSize(tostring(text or ""), size or 13, font or Enum.Font.Gotham, Vector2.new(width or 300, math.huge))
    end)
    if ok then
        return result
    end
    return Vector2.new(0, size or 13)
end

local function isImageIcon(icon)
    icon = tostring(icon or "")
    return icon:find("rbxassetid://") == 1 or icon:find("http") == 1
end

local function setIcon(parent, icon, color)
    if not icon or icon == "" then
        return nil
    end

    if isImageIcon(icon) then
        local image = create("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = color or Theme.Text,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(18, 18)
        }, parent)
        return image
    end

    local label = create("TextLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Text = tostring(icon),
        Font = Enum.Font.GothamBold,
        TextColor3 = color or Theme.Text,
        TextSize = 16,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(18, 18)
    }, parent)
    return label
end

local function pointInside(guiObject, point)
    if not guiObject or not guiObject.Parent then
        return false
    end
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local activeInput = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            activeInput = input

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeInput = nil
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == activeInput and dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Library:SetNotification(config)
    config = config or {}
    local title = config.Title or config[1] or "Notification"
    local description = config.Description or config[2] or ""
    local content = config.Content or config[3] or ""
    local animTime = tonumber(config.Time or config[4] or 0.25) or 0.25
    local delayTime = tonumber(config.Delay or config[5] or 4) or 4

    local screenGui = create("ScreenGui", {
        Name = "SpeedHubX_Notification",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    }, getGuiParent())

    local holder = create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -22, 1, -22),
        Size = UDim2.fromOffset(320, 110)
    }, screenGui)

    local card = create("Frame", {
        Name = "Card",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 360, 1, -88),
        Size = UDim2.fromOffset(315, 86)
    }, holder)
    corner(card, 8)
    stroke(card, Theme.Stroke, 1, 0.1)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(title),
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -36, 0, 18)
    }, card)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(description),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(12, 27),
        Size = UDim2.new(1, -24, 0, 16)
    }, card)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(content),
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(12, 48),
        Size = UDim2.new(1, -24, 1, -54)
    }, card)

    local close = create("TextButton", {
        BackgroundTransparency = 1,
        Text = "X",
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.Text,
        TextSize = 14,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 7),
        Size = UDim2.fromOffset(22, 22)
    }, card)

    local notification = {}
    local closed = false
    function notification:Close()
        if closed then return end
        closed = true
        tween(card, animTime, {Position = UDim2.new(1, 360, 1, -88)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(animTime + 0.05, function()
            if screenGui then screenGui:Destroy() end
        end)
    end

    close.Activated:Connect(function()
        notification:Close()
    end)

    tween(card, animTime, {Position = UDim2.new(1, -315, 1, -88)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(delayTime, function()
        notification:Close()
    end)

    return notification
end

function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or config[1] or "Speed Hub X"
    local description = config.Description or config[2] or "Version 5.0.0"
    local tabWidth = tonumber(config["Tab Width"] or config.TabWidth or config[3] or 135) or 135
    local baseW, baseH = getOffsetSize(config.SizeUi or config[4] or UDim2.fromOffset(550, 350), 550, 350)
    baseW = math.max(baseW, 420)
    baseH = math.max(baseH, 300)

    local window = {}
    local connections = {}
    local tabs = {}
    local tabObjects = {}
    local currentTab = nil
    local minimized = false

    local screenGui = create("ScreenGui", {
        Name = "SpeedHubX_V5_PhotoStyle",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    }, getGuiParent())
    table.insert(Library.Windows, screenGui)

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(baseW, baseH),
        ClipsDescendants = true
    }, screenGui)
    corner(main, 9)
    stroke(main, Theme.Stroke, 1, 0.05)

    local scale = create("UIScale", {Scale = 1}, main)

    local function updateScale()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local scaleX = (viewport.X - 24) / baseW
        local scaleY = (viewport.Y - 24) / baseH
        local nextScale = math.clamp(math.min(scaleX, scaleY, 1), 0.62, 1)
        scale.Scale = nextScale
        if not minimized then
            main.Size = UDim2.fromOffset(baseW, baseH)
        end
    end
    updateScale()
    table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale))
    if workspace.CurrentCamera then
        table.insert(connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
    end

    local top = create("Frame", {
        Name = "Top",
        BackgroundColor3 = Theme.Top,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 40)
    }, main)

    create("Frame", {
        Name = "TopLine",
        BackgroundColor3 = Theme.Stroke,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1)
    }, top)

    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(title),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(11, 0),
        Size = UDim2.new(1, -100, 1, 0)
    }, top)

    local titleWidth = textSize(title, Enum.Font.GothamBold, 13, 400).X
    local descLabel = create("TextLabel", {
        Name = "Description",
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = tostring(description),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16 + titleWidth, 0),
        Size = UDim2.new(1, -(titleWidth + 125), 1, 0)
    }, top)

    local minButton = create("TextButton", {
        Name = "Minimize",
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "-",
        TextColor3 = Theme.Text,
        TextSize = 16,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -43, 0.5, 0),
        Size = UDim2.fromOffset(28, 28)
    }, top)

    local closeButton = create("TextButton", {
        Name = "Close",
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "X",
        TextColor3 = Theme.Text,
        TextSize = 14,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(28, 28)
    }, top)

    local side = create("Frame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(11, 54),
        Size = UDim2.new(0, tabWidth, 1, -64)
    }, main)

    local searchBack = create("Frame", {
        Name = "SearchBack",
        BackgroundColor3 = Theme.AccentDark,
        BackgroundTransparency = 0.66,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 27),
        Position = UDim2.fromOffset(0, 0)
    }, side)
    corner(searchBack, 4)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Q",
        TextColor3 = Color3.fromRGB(210, 195, 198),
        TextSize = 14,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.fromOffset(18, 27)
    }, searchBack)

    local search = create("TextBox", {
        Name = "Search",
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = "",
        Text = "",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.MutedDark,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(31, 0),
        Size = UDim2.new(1, -35, 1, 0)
    }, searchBack)

    local tabScroll = create("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0, 0)
    }, side)

    local tabLayout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabScroll)

    local layers = create("Frame", {
        Name = "Layers",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth + 23, 0, 52),
        Size = UDim2.new(1, -(tabWidth + 34), 1, -62)
    }, main)

    local nameTab = create("TextLabel", {
        Name = "NameTab",
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 0)
    }, layers)

    local pagesFolder = create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35)
    }, layers)

    local function updateTabCanvas()
        tabScroll.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 4)
    end
    table.insert(connections, tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas))

    local function selectTab(tabObject)
        if currentTab == tabObject then return end
        currentTab = tabObject
        nameTab.Text = tabObject.Name
        for _, item in ipairs(tabObjects) do
            item.Page.Visible = item == tabObject
            tween(item.Button, 0.16, {
                BackgroundTransparency = item == tabObject and 0.82 or 1,
                BackgroundColor3 = item == tabObject and Color3.fromRGB(255, 255, 255) or Theme.Row
            })
            tween(item.Label, 0.16, {
                TextColor3 = item == tabObject and Theme.Text or Color3.fromRGB(219, 211, 213)
            })
            if item.Icon then
                pcall(function()
                    item.Icon.ImageColor3 = item == tabObject and Theme.Text or Color3.fromRGB(219, 211, 213)
                end)
                pcall(function()
                    item.Icon.TextColor3 = item == tabObject and Theme.Text or Color3.fromRGB(219, 211, 213)
                end)
            end
        end
    end

    local function filterTabs()
        local query = string.lower(search.Text or "")
        for _, item in ipairs(tabObjects) do
            local visible = query == "" or string.find(string.lower(item.Name), query, 1, true) ~= nil
            item.Button.Visible = visible
        end
        updateTabCanvas()
    end
    table.insert(connections, search:GetPropertyChangedSignal("Text"):Connect(filterTabs))

    local function createRow(parent, titleText, contentText, height, selectable)
        local row = create("Frame", {
            BackgroundColor3 = Theme.Row,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, height or 44),
            ClipsDescendants = true
        }, parent)
        corner(row, 4)

        local titleY = (contentText and contentText ~= "") and 7 or 0
        local titleHeight = (contentText and contentText ~= "") and 15 or (height or 44)
        local titleLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = tostring(titleText or ""),
            TextColor3 = Theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Position = UDim2.fromOffset(10, titleY),
            Size = UDim2.new(1, -190, 0, titleHeight)
        }, row)

        local contentLabel = nil
        if contentText and contentText ~= "" then
            contentLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(contentText),
                TextColor3 = Theme.MutedDark,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(10, 22),
                Size = UDim2.new(1, -190, 0, 16)
            }, row)
        end

        if selectable then
            row.MouseEnter:Connect(function()
                tween(row, 0.12, {BackgroundColor3 = Theme.RowHover})
            end)
            row.MouseLeave:Connect(function()
                tween(row, 0.12, {BackgroundColor3 = Theme.Row})
            end)
        end

        return row, titleLabel, contentLabel
    end

    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or tabConfig.Title or tabConfig[1] or "Tab"
        local tabIcon = tabConfig.Icon or tabConfig[2] or ""
        local order = #tabObjects

        local button = create("TextButton", {
            Name = "Tab_" .. tostring(tabName),
            AutoButtonColor = false,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Size = UDim2.new(1, 0, 0, 31),
            Text = ""
        }, tabScroll)
        corner(button, 5)

        local iconObj = setIcon(button, tabIcon, Color3.fromRGB(219, 211, 213))

        local label = create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = tostring(tabName),
            TextColor3 = Color3.fromRGB(219, 211, 213),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(tabIcon ~= "" and 34 or 10, 0),
            Size = UDim2.new(1, -(tabIcon ~= "" and 39 or 15), 1, 0)
        }, button)

        local page = create("ScrollingFrame", {
            Name = "Page_" .. tostring(tabName),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.AccentDark,
            ScrollingDirection = Enum.ScrollingDirection.Y
        }, pagesFolder)

        local pageLayout = create("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, page)
        padding(page, 0, 2, 0, 4)

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 8)
        end)

        local tabObject = {
            Name = tostring(tabName),
            Button = button,
            Label = label,
            Icon = iconObj,
            Page = page,
            Sections = {},
            Layout = pageLayout
        }
        table.insert(tabObjects, tabObject)
        tabs[tostring(tabName)] = tabObject

        button.Activated:Connect(function()
            selectTab(tabObject)
        end)

        button.MouseEnter:Connect(function()
            if currentTab ~= tabObject then
                tween(button, 0.12, {BackgroundTransparency = 0.92, BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            end
        end)
        button.MouseLeave:Connect(function()
            if currentTab ~= tabObject then
                tween(button, 0.12, {BackgroundTransparency = 1})
            end
        end)

        local tabApi = {}

        function tabApi:AddSection(sectionTitle, open)
            local isOpen = open == true
            local sectionApi = {}
            local componentOrder = 0

            local section = create("Frame", {
                Name = "Section",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                LayoutOrder = #tabObject.Sections,
                Size = UDim2.new(1, 0, 0, 34)
            }, page)

            local header = create("Frame", {
                Name = "Header",
                BackgroundColor3 = Theme.Row,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32)
            }, section)
            corner(header, 4)

            local headerButton = create("TextButton", {
                BackgroundTransparency = 1,
                Text = "",
                Size = UDim2.fromScale(1, 1),
                AutoButtonColor = false
            }, header)

            local headerTitle = create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = tostring(sectionTitle or "Section"),
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -45, 1, 0)
            }, header)

            local arrow = create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = ">",
                TextColor3 = Theme.Text,
                TextSize = 24,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -11, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                Rotation = isOpen and 90 or 0
            }, header)

            local accentLine = create("Frame", {
                Name = "AccentLine",
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 33),
                Size = isOpen and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 0, 0, 1)
            }, section)

            local content = create("Frame", {
                Name = "Content",
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                Position = UDim2.fromOffset(0, 40),
                Size = UDim2.new(1, 0, 0, 0),
                Visible = isOpen
            }, section)

            local contentLayout = create("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, content)

            local function refreshSection(instant)
                local contentHeight = contentLayout.AbsoluteContentSize.Y
                local targetHeight = isOpen and (40 + contentHeight) or 34
                local sectionGoal = {Size = UDim2.new(1, 0, 0, targetHeight)}
                local contentGoal = {Size = UDim2.new(1, 0, 0, contentHeight)}
                local arrowGoal = {Rotation = isOpen and 90 or 0}
                local lineGoal = {Size = isOpen and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 0, 0, 1)}

                if isOpen then
                    content.Visible = true
                end

                if instant then
                    section.Size = sectionGoal.Size
                    content.Size = contentGoal.Size
                    arrow.Rotation = arrowGoal.Rotation
                    accentLine.Size = lineGoal.Size
                    content.Visible = isOpen
                else
                    tween(section, 0.2, sectionGoal)
                    tween(content, 0.2, contentGoal)
                    tween(arrow, 0.2, arrowGoal)
                    tween(accentLine, 0.2, lineGoal)
                    if not isOpen then
                        task.delay(0.22, function()
                            if not isOpen then
                                content.Visible = false
                            end
                        end)
                    end
                end

                page.CanvasSize = UDim2.fromOffset(0, pageLayout.AbsoluteContentSize.Y + 8)
            end

            contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                refreshSection(false)
            end)

            headerButton.Activated:Connect(function()
                isOpen = not isOpen
                refreshSection(false)
            end)

            function sectionApi:SetOpen(value)
                isOpen = value == true
                refreshSection(false)
            end

            function sectionApi:AddLabel(text)
                componentOrder += 1
                local row = create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = componentOrder,
                    Size = UDim2.new(1, 0, 0, 26)
                }, content)
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = tostring(text or ""),
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -20, 1, 0)
                }, row)
                refreshSection(true)
                return row
            end

            function sectionApi:AddLine()
                componentOrder += 1
                local holder = create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    LayoutOrder = componentOrder,
                    Size = UDim2.new(1, 0, 0, 8)
                }, content)
                create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.new(1, 0, 0, 1)
                }, holder)
                refreshSection(true)
                return holder
            end

            function sectionApi:AddParagraph(config)
                local titleText, contentText = parseTextConfig(config, "Paragraph", "")
                componentOrder += 1
                local bodySize = textSize(contentText, Enum.Font.GothamBold, 12, 330)
                local rowHeight = math.clamp(34 + bodySize.Y, 52, 110)
                local row, titleLabel = createRow(content, titleText, "", rowHeight, false)
                row.LayoutOrder = componentOrder
                titleLabel.Position = UDim2.fromOffset(10, 8)
                titleLabel.Size = UDim2.new(1, -20, 0, 16)
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = tostring(contentText or ""),
                    TextColor3 = Theme.Muted,
                    TextWrapped = true,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Position = UDim2.fromOffset(10, 28),
                    Size = UDim2.new(1, -20, 1, -32)
                }, row)
                refreshSection(true)
                return row
            end

            function sectionApi:AddButton(config, contentOrCallback, callback)
                local titleText, contentText, cb
                if typeof(config) == "table" then
                    titleText = config.Title or config.Name or config[1] or "Button"
                    contentText = config.Content or config.Description or config[2] or ""
                    cb = config.Callback or config.CallBack or config[3]
                else
                    titleText = tostring(config or "Button")
                    if typeof(contentOrCallback) == "function" then
                        contentText = ""
                        cb = contentOrCallback
                    else
                        contentText = tostring(contentOrCallback or "")
                        cb = callback
                    end
                end
                componentOrder += 1
                local row = createRow(content, titleText, contentText, 44, true)
                row.LayoutOrder = componentOrder

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = ">",
                    TextColor3 = Theme.Text,
                    TextSize = 23,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(22, 22)
                }, row)

                local click = create("TextButton", {
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.fromScale(1, 1),
                    AutoButtonColor = false
                }, row)
                click.Activated:Connect(function()
                    safeCallback(cb)
                end)

                refreshSection(true)
                return {Instance = row, Fire = function() safeCallback(cb) end}
            end

            function sectionApi:AddToggle(config, contentOrDefault, defaultOrCallback, callback)
                local titleText, contentText, default, cb
                if typeof(config) == "table" then
                    titleText = config.Title or config.Name or config[1] or "Toggle"
                    contentText = config.Content or config.Description or config[2] or ""
                    default = config.Default or config.Value or config[3] or false
                    cb = config.Callback or config.CallBack or config[4]
                else
                    titleText = tostring(config or "Toggle")
                    contentText = tostring(contentOrDefault or "")
                    default = defaultOrCallback == true
                    cb = callback
                end

                local state = default == true
                componentOrder += 1
                local row = createRow(content, titleText, contentText, 44, true)
                row.LayoutOrder = componentOrder

                local track = create("TextButton", {
                    Name = "Toggle",
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff,
                    BackgroundTransparency = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -9, 0.5, 0),
                    Size = UDim2.fromOffset(38, 21)
                }, row)
                corner(track, 999)

                local knob = create("Frame", {
                    Name = "Knob",
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                    Size = UDim2.fromOffset(15, 15)
                }, track)
                corner(knob, 999)

                local overlay = create("TextButton", {
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.fromScale(1, 1),
                    AutoButtonColor = false
                }, row)

                local toggleApi = {}
                function toggleApi:Set(value, noCallback)
                    state = value == true
                    tween(track, 0.16, {BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff})
                    tween(knob, 0.16, {Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
                    if not noCallback then
                        safeCallback(cb, state)
                    end
                end
                function toggleApi:Get()
                    return state
                end

                overlay.Activated:Connect(function()
                    toggleApi:Set(not state)
                end)

                refreshSection(true)
                return toggleApi
            end

            function sectionApi:AddInput(config, contentOrDefault, defaultOrCallback, callback)
                local titleText, contentText, default, placeholder, cb
                if typeof(config) == "table" then
                    titleText = config.Title or config.Name or config[1] or "Input"
                    contentText = config.Content or config.Description or config[2] or ""
                    default = config.Default or config.Value or config[3] or ""
                    placeholder = config.Placeholder or config.PlaceHolder or ""
                    cb = config.Callback or config.CallBack or config[4]
                else
                    titleText = tostring(config or "Input")
                    contentText = tostring(contentOrDefault or "")
                    default = tostring(defaultOrCallback or "")
                    placeholder = ""
                    cb = callback
                end

                componentOrder += 1
                local row = createRow(content, titleText, contentText, 44, false)
                row.LayoutOrder = componentOrder

                local boxBack = create("Frame", {
                    BackgroundColor3 = Theme.Input,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(158, 31)
                }, row)
                corner(boxBack, 4)

                local box = create("TextBox", {
                    BackgroundTransparency = 1,
                    ClearTextOnFocus = false,
                    Font = Enum.Font.GothamBold,
                    Text = tostring(default or ""),
                    PlaceholderText = tostring(placeholder or ""),
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.MutedDark,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -16, 1, 0)
                }, boxBack)

                box.Focused:Connect(function()
                    tween(boxBack, 0.14, {BackgroundColor3 = Theme.RowHover})
                end)
                box.FocusLost:Connect(function()
                    tween(boxBack, 0.14, {BackgroundColor3 = Theme.Input})
                    safeCallback(cb, box.Text)
                end)

                local inputApi = {}
                function inputApi:Set(value, noCallback)
                    box.Text = tostring(value or "")
                    if not noCallback then safeCallback(cb, box.Text) end
                end
                function inputApi:Get()
                    return box.Text
                end

                refreshSection(true)
                return inputApi
            end

            sectionApi.AddTextbox = sectionApi.AddInput
            sectionApi.AddTextBox = sectionApi.AddInput

            function sectionApi:AddSlider(config, contentOrMin, minOrMax, maxOrDefault, defaultOrCallback, callback)
                local titleText, contentText, minValue, maxValue, default, increment, cb
                if typeof(config) == "table" then
                    titleText = config.Title or config.Name or config[1] or "Slider"
                    contentText = config.Content or config.Description or config[2] or ""
                    minValue = tonumber(config.Min or config.Minimum or 0) or 0
                    maxValue = tonumber(config.Max or config.Maximum or 100) or 100
                    default = tonumber(config.Default or config.Value or minValue) or minValue
                    increment = tonumber(config.Increment or config.Step or 1) or 1
                    cb = config.Callback or config.CallBack or config[3]
                else
                    titleText = tostring(config or "Slider")
                    contentText = tostring(contentOrMin or "")
                    minValue = tonumber(minOrMax or 0) or 0
                    maxValue = tonumber(maxOrDefault or 100) or 100
                    default = tonumber(defaultOrCallback or minValue) or minValue
                    increment = 1
                    cb = callback
                end
                if maxValue < minValue then
                    minValue, maxValue = maxValue, minValue
                end

                componentOrder += 1
                local row = createRow(content, titleText, contentText, 54, true)
                row.LayoutOrder = componentOrder

                local valueLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = tostring(default),
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -10, 0, 6),
                    Size = UDim2.fromOffset(80, 18)
                }, row)

                local bar = create("Frame", {
                    BackgroundColor3 = Theme.Input,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 1),
                    Position = UDim2.new(1, -10, 1, -11),
                    Size = UDim2.fromOffset(170, 7)
                }, row)
                corner(bar, 999)

                local fill = create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(0, 1)
                }, bar)
                corner(fill, 999)

                local knob = create("Frame", {
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.fromOffset(13, 13)
                }, bar)
                corner(knob, 999)

                local dragging = false
                local currentValue = default

                local sliderApi = {}
                function sliderApi:Set(value, noCallback)
                    local num = tonumber(value) or minValue
                    num = math.clamp(num, minValue, maxValue)
                    if increment > 0 then
                        num = math.floor((num - minValue) / increment + 0.5) * increment + minValue
                    end
                    num = math.clamp(num, minValue, maxValue)
                    currentValue = num
                    local alpha = (maxValue == minValue) and 0 or ((num - minValue) / (maxValue - minValue))
                    valueLabel.Text = tostring(num)
                    tween(fill, 0.08, {Size = UDim2.fromScale(alpha, 1)})
                    tween(knob, 0.08, {Position = UDim2.fromScale(alpha, 0.5)})
                    if not noCallback then safeCallback(cb, num) end
                end
                function sliderApi:Get()
                    return currentValue
                end

                local function setFromInput(input)
                    local relative = (input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
                    relative = math.clamp(relative, 0, 1)
                    sliderApi:Set(minValue + (maxValue - minValue) * relative)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromInput(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        setFromInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                sliderApi:Set(default, true)
                refreshSection(true)
                return sliderApi
            end

            function sectionApi:AddDropdown(config, contentOrMulti, multiOrOptions, optionsOrDefault, defaultOrCallback, callback)
                local titleText, contentText, multi, options, default, cb
                if typeof(config) == "table" then
                    titleText = config.Title or config.Name or config[1] or "Dropdown"
                    contentText = config.Content or config.Description or config[2] or ""
                    multi = config.Multi or config.Multiple or false
                    options = config.Options or config.List or config.Values or {}
                    default = config.Default or config.Value
                    cb = config.Callback or config.CallBack
                else
                    titleText = tostring(config or "Dropdown")
                    contentText = tostring(contentOrMulti or "")
                    multi = multiOrOptions == true
                    options = typeof(optionsOrDefault) == "table" and optionsOrDefault or {}
                    default = defaultOrCallback
                    cb = callback
                end

                if typeof(options) ~= "table" then
                    options = {}
                end

                local selected = {}
                if multi then
                    if typeof(default) == "table" then
                        for _, v in ipairs(default) do selected[tostring(v)] = true end
                    elseif default ~= nil then
                        selected[tostring(default)] = true
                    end
                else
                    selected.Value = default ~= nil and tostring(default) or nil
                end

                componentOrder += 1
                local row = createRow(content, titleText, contentText, 44, false)
                row.LayoutOrder = componentOrder

                local button = create("TextButton", {
                    Name = "DropdownButton",
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Input,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    Text = "",
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(158, 31)
                }, row)
                corner(button, 4)

                local valueText = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "Select Options",
                    TextColor3 = Theme.Muted,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -34, 1, 0)
                }, button)

                local arrowSmall = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = ">",
                    Rotation = 90,
                    TextColor3 = Theme.Text,
                    TextSize = 20,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -5, 0.5, 0),
                    Size = UDim2.fromOffset(22, 22)
                }, button)

                local popup = nil
                local outsideConnection = nil

                local dropdownApi = {}

                local function getSelectedList()
                    local list = {}
                    for _, option in ipairs(options) do
                        if selected[tostring(option)] then
                            table.insert(list, option)
                        end
                    end
                    return list
                end

                local function updateText()
                    if multi then
                        local list = getSelectedList()
                        if #list == 0 then
                            valueText.Text = "Select Options"
                        else
                            local textList = {}
                            for _, value in ipairs(list) do
                                table.insert(textList, tostring(value))
                            end
                            valueText.Text = table.concat(textList, ", ")
                        end
                    else
                        valueText.Text = selected.Value or "Select Options"
                    end
                end

                local function fireCallback()
                    if multi then
                        safeCallback(cb, getSelectedList())
                    else
                        safeCallback(cb, selected.Value)
                    end
                end

                local function closePopup()
                    if outsideConnection then
                        outsideConnection:Disconnect()
                        outsideConnection = nil
                    end
                    if popup then
                        local old = popup
                        popup = nil
                        tween(old, 0.12, {BackgroundTransparency = 1, Size = UDim2.fromOffset(old.Size.X.Offset, 0)})
                        task.delay(0.13, function()
                            if old then old:Destroy() end
                        end)
                    end
                    tween(arrowSmall, 0.14, {Rotation = 90})
                end

                local function createOptionButton(listParent, option)
                    local optionText = tostring(option)
                    local active = multi and selected[optionText] or selected.Value == optionText
                    local optionButton = create("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = active and Theme.AccentDark or Theme.Popup,
                        BackgroundTransparency = active and 0.18 or 1,
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        Text = optionText,
                        TextColor3 = Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Size = UDim2.new(1, 0, 0, 31)
                    }, listParent)
                    padding(optionButton, 12, 8, 0, 0)

                    optionButton.MouseEnter:Connect(function()
                        tween(optionButton, 0.1, {BackgroundTransparency = 0.25, BackgroundColor3 = Theme.AccentDark})
                    end)
                    optionButton.MouseLeave:Connect(function()
                        local isActive = multi and selected[optionText] or selected.Value == optionText
                        tween(optionButton, 0.1, {
                            BackgroundTransparency = isActive and 0.18 or 1,
                            BackgroundColor3 = isActive and Theme.AccentDark or Theme.Popup
                        })
                    end)
                    optionButton.Activated:Connect(function()
                        if multi then
                            selected[optionText] = not selected[optionText]
                            updateText()
                            fireCallback()
                            optionButton.BackgroundTransparency = selected[optionText] and 0.18 or 1
                            optionButton.BackgroundColor3 = selected[optionText] and Theme.AccentDark or Theme.Popup
                        else
                            selected.Value = optionText
                            updateText()
                            fireCallback()
                            closePopup()
                        end
                    end)
                end

                local function openPopup()
                    if popup then
                        closePopup()
                        return
                    end

                    local popupWidth = 164
                    local maxVisible = math.min(#options, 7)
                    local popupHeight = 36 + math.max(maxVisible, 1) * 31 + 6
                    popupHeight = math.clamp(popupHeight, 78, 258)

                    local scaleValue = scale.Scale ~= 0 and scale.Scale or 1
                    local relX = (row.AbsolutePosition.X - main.AbsolutePosition.X) / scaleValue + row.AbsoluteSize.X / scaleValue - popupWidth
                    local relY = (row.AbsolutePosition.Y - main.AbsolutePosition.Y) / scaleValue + 2
                    relX = math.clamp(relX, 6, baseW - popupWidth - 8)
                    relY = math.clamp(relY, 43, baseH - popupHeight - 8)

                    popup = create("Frame", {
                        Name = "DropdownPopup",
                        BackgroundColor3 = Theme.Popup,
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Position = UDim2.fromOffset(relX, relY),
                        Size = UDim2.fromOffset(popupWidth, 0),
                        ZIndex = 50
                    }, main)
                    corner(popup, 5)
                    stroke(popup, Theme.StrokeLight, 1, 0)

                    local searchHolder = create("Frame", {
                        BackgroundColor3 = Theme.AccentDark,
                        BackgroundTransparency = 0.18,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(1, 1),
                        Size = UDim2.new(1, -2, 0, 34),
                        ZIndex = 51
                    }, popup)

                    local searchBox = create("TextBox", {
                        BackgroundTransparency = 1,
                        ClearTextOnFocus = false,
                        Font = Enum.Font.GothamBold,
                        PlaceholderText = "Search",
                        PlaceholderColor3 = Color3.fromRGB(196, 154, 157),
                        Text = "",
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Size = UDim2.fromScale(1, 1),
                        ZIndex = 52
                    }, searchHolder)

                    local optionScroll = create("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Position = UDim2.fromOffset(0, 38),
                        Size = UDim2.new(1, 0, 1, -40),
                        CanvasSize = UDim2.fromOffset(0, 0),
                        ScrollBarThickness = 3,
                        ScrollBarImageColor3 = Theme.StrokeLight,
                        ZIndex = 51
                    }, popup)
                    padding(optionScroll, 0, 0, 0, 4)
                    local optLayout = create("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder
                    }, optionScroll)

                    local function rebuild()
                        for _, child in ipairs(optionScroll:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end
                        local query = string.lower(searchBox.Text or "")
                        for _, option in ipairs(options) do
                            local text = tostring(option)
                            if query == "" or string.find(string.lower(text), query, 1, true) then
                                createOptionButton(optionScroll, option)
                            end
                        end
                        optionScroll.CanvasSize = UDim2.fromOffset(0, optLayout.AbsoluteContentSize.Y + 4)
                    end

                    optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        optionScroll.CanvasSize = UDim2.fromOffset(0, optLayout.AbsoluteContentSize.Y + 4)
                    end)
                    searchBox:GetPropertyChangedSignal("Text"):Connect(rebuild)

                    rebuild()
                    tween(popup, 0.14, {Size = UDim2.fromOffset(popupWidth, popupHeight)})
                    tween(arrowSmall, 0.14, {Rotation = -90})

                    outsideConnection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            if popup and not pointInside(popup, input.Position) and not pointInside(button, input.Position) then
                                closePopup()
                            end
                        end
                    end)
                end

                button.Activated:Connect(openPopup)

                function dropdownApi:Set(value, noCallback)
                    if multi then
                        table.clear(selected)
                        if typeof(value) == "table" then
                            for _, v in ipairs(value) do selected[tostring(v)] = true end
                        elseif value ~= nil then
                            selected[tostring(value)] = true
                        end
                    else
                        selected.Value = value ~= nil and tostring(value) or nil
                    end
                    updateText()
                    if not noCallback then fireCallback() end
                end
                function dropdownApi:Get()
                    if multi then
                        return getSelectedList()
                    end
                    return selected.Value
                end
                function dropdownApi:Refresh(newOptions, keepValue)
                    if typeof(newOptions) == "table" then
                        options = newOptions
                    end
                    if not keepValue then
                        if multi then table.clear(selected) else selected.Value = nil end
                    end
                    updateText()
                    closePopup()
                end

                updateText()
                refreshSection(true)
                return dropdownApi
            end

            task.defer(function()
                refreshSection(true)
            end)

            table.insert(tabObject.Sections, sectionApi)
            return sectionApi
        end

        -- aliases for people who like different naming
        tabApi.AddCategory = tabApi.AddSection
        tabApi.CreateSection = tabApi.AddSection

        if not currentTab then
            selectTab(tabObject)
        end
        updateTabCanvas()
        return tabApi
    end

    window.CreatePage = window.CreateTab

    function window:SetTitle(newTitle, newDescription)
        title = tostring(newTitle or title)
        description = tostring(newDescription or description)
        titleLabel.Text = title
        local newWidth = textSize(title, Enum.Font.GothamBold, 13, 400).X
        descLabel.Position = UDim2.fromOffset(16 + newWidth, 0)
        descLabel.Size = UDim2.new(1, -(newWidth + 125), 1, 0)
        descLabel.Text = description
    end

    function window:Minimize(value)
        minimized = value == nil and not minimized or value == true
        side.Visible = not minimized
        layers.Visible = not minimized
        if minimized then
            tween(main, 0.2, {Size = UDim2.fromOffset(baseW, 40)})
        else
            tween(main, 0.2, {Size = UDim2.fromOffset(baseW, baseH)})
        end
    end

    function window:Destroy()
        disconnectAll(connections)
        if screenGui then
            screenGui:Destroy()
        end
    end

    function window:GetTab(name)
        return tabs[tostring(name)]
    end

    closeButton.Activated:Connect(function()
        window:Destroy()
    end)

    minButton.Activated:Connect(function()
        window:Minimize()
    end)

    makeDraggable(top, main)

    return window
end

function Library:Unload()
    Library.Unloaded = true
    for _, gui in ipairs(Library.Windows) do
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    table.clear(Library.Windows)
end

return Library
