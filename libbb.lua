--[[
  Speed_Library — shadcn/ui Edition
  Same API as original, reskinned to zinc dark palette
]]

local Players          = game:GetService("Players")
local Player           = Players.LocalPlayer
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser      = game:GetService("VirtualUser")

-- ── Safe GUI parent ──────────────────────────────────────────────────────
local function _getGui()
  if RunService:IsStudio() then return Player.PlayerGui end
  if typeof(gethui) == "function" then
    local ok, h = pcall(gethui)
    if ok and h then return h end
  end
  if typeof(cloneref) == "function" then
    local ok, r = pcall(cloneref, game:GetService("CoreGui"))
    if ok and r then return r end
  end
  return game:GetService("CoreGui")
end

-- ── shadcn/ui zinc palette ───────────────────────────────────────────────
local Z = {
  bg       = Color3.fromRGB(9,   9,   11),   -- zinc-950
  card     = Color3.fromRGB(24,  24,  27),   -- zinc-900
  elevated = Color3.fromRGB(32,  32,  36),   -- zinc-850 (custom)
  border   = Color3.fromRGB(39,  39,  42),   -- zinc-800
  border2  = Color3.fromRGB(63,  63,  70),   -- zinc-700
  fg       = Color3.fromRGB(250, 250, 250),  -- zinc-50
  fgMuted  = Color3.fromRGB(161, 161, 170),  -- zinc-400
  muted    = Color3.fromRGB(113, 113, 122),  -- zinc-500
  accent   = Color3.fromRGB(139, 92,  246),  -- violet-500 (primary)
  success  = Color3.fromRGB(34,  197, 94),
  warn     = Color3.fromRGB(234, 179, 8),
  err      = Color3.fromRGB(239, 68,  68),
}

-- ── Instance helper ──────────────────────────────────────────────────────
local Custom = {}
Custom.ColorRGB = Z.accent   -- replaces the original red accent

function Custom:Create(Name, Properties, Parent)
  local inst = Instance.new(Name)
  for k, v in pairs(Properties) do inst[k] = v end
  if Parent then inst.Parent = Parent end
  return inst
end

function Custom:EnabledAFK()
  Player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
  end)
end

Custom:EnabledAFK()

-- ── Minimize pill ────────────────────────────────────────────────────────
local function OpenClose()
  local SG = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
  }, _getGui())

  local Pill = Custom:Create("Frame", {
    BackgroundColor3 = Z.card,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(0, 0),
    Position         = UDim2.new(0, 12, 0, 12),
    Size             = UDim2.new(0, 36, 0, 36),
    Visible          = false,
  }, SG)
  Custom:Create("UICorner",  { CornerRadius = UDim.new(0, 9999) }, Pill)
  Custom:Create("UIStroke",  { Color = Z.border, Thickness = 1 }, Pill)

  -- Icon dot
  local dot = Custom:Create("Frame", {
    BackgroundColor3 = Z.accent,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(0.5, 0.5),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
    Size             = UDim2.new(0, 10, 0, 10),
  }, Pill)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, dot)

  local Btn = Custom:Create("ImageButton", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 0),
    Size     = UDim2.new(1, 0, 1, 0),
    Image    = "",
    Visible  = false,
  }, SG)
  Btn.Parent = Pill

  -- Draggable
  local dragging, ds, sp = false, nil, nil
  Pill.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging, ds, sp = true, inp.Position, Pill.Position
      inp.Changed:Connect(function()
        if inp.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  Pill.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
      or inp.UserInputType == Enum.UserInputType.Touch) then
      local d = inp.Position - ds
      Pill.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
    end
  end)

  return Pill
end

local Open_Close = OpenClose()

-- ── Drag utility ─────────────────────────────────────────────────────────
local function MakeDraggable(handle, frame)
  local dragging, ds, sp = false, nil, nil
  handle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
      dragging, ds, sp = true, inp.Position, frame.Position
      inp.Changed:Connect(function()
        if inp.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  handle.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
      or inp.UserInputType == Enum.UserInputType.Touch) then
      local d = inp.Position - ds
      frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
    end
  end)
end

-- ── Ripple click ─────────────────────────────────────────────────────────
function CircleClick(Button, X, Y)
  task.spawn(function()
    Button.ClipsDescendants = true
    local Circle = Instance.new("ImageLabel")
    Circle.Image              = "rbxassetid://106471194043211"
    Circle.ImageColor3        = Color3.fromRGB(255, 255, 255)
    Circle.ImageTransparency  = 0.88
    Circle.BackgroundTransparency = 1
    Circle.ZIndex             = 10
    Circle.Name               = "Circle"
    Circle.Parent             = Button
    local nx = X - Button.AbsolutePosition.X
    local ny = Y - Button.AbsolutePosition.Y
    Circle.Position = UDim2.new(0, nx, 0, ny)
    local sz = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
    local tweenI = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(Circle, tweenI, {
      Size = UDim2.new(0, sz, 0, sz),
      Position = UDim2.new(0.5, -sz/2, 0.5, -sz/2),
      ImageTransparency = 1,
    })
    tw:Play()
    tw.Completed:Connect(function() Circle:Destroy() end)
  end)
end

local Speed_Library, Notification = {}, {}
Speed_Library.Unloaded = false

-- ══════════════════════════════════════════════════════════════════════════
--  SONNER-STYLE NOTIFICATION
-- ══════════════════════════════════════════════════════════════════════════
function Speed_Library:SetNotification(Config)
  local Title   = Config[1] or Config.Title       or ""
  local Desc    = Config[2] or Config.Description or ""
  local Content = Config[3] or Config.Content     or ""
  local Time    = Config[5] or Config.Time        or 0.3
  local Delay   = Config[6] or Config.Delay       or 5

  local NGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
  }, _getGui())

  -- Stack container bottom-right
  local Stack = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(1, -16, 1, -16),
    Size               = UDim2.new(0, 320, 1, 0),
  }, NGui)
  Custom:Create("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment   = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 8),
  }, Stack)

  local cardH = (Content ~= "") and 78 or 56

  local Card = Custom:Create("Frame", {
    BackgroundColor3 = Z.card,
    BorderSizePixel  = 0,
    Size             = UDim2.new(1, 0, 0, cardH),
    ClipsDescendants = true,
    Name             = "NCard",
  }, Stack)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Card)
  Custom:Create("UIStroke",  { Color = Z.border, Thickness = 1 }, Card)

  -- Accent left bar
  Custom:Create("Frame", {
    BackgroundColor3 = Z.accent,
    BorderSizePixel  = 0,
    Size             = UDim2.new(0, 3, 1, 0),
  }, Card)

  -- Title label
  Custom:Create("TextLabel", {
    Font               = Enum.Font.GothamBold,
    Text               = Title,
    TextColor3         = Z.fg,
    TextSize           = 13,
    TextXAlignment     = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Position           = UDim2.new(0, 14, 0, 10),
    Size               = UDim2.new(1, -40, 0, 16),
    TextTruncate       = Enum.TextTruncate.AtEnd,
  }, Card)

  -- Description
  local descLabel = Custom:Create("TextLabel", {
    Font               = Enum.Font.GothamBold,
    Text               = Desc,
    TextColor3         = Z.accent,
    TextSize           = 12,
    TextXAlignment     = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    Position           = UDim2.new(0, 14, 0, 28),
    Size               = UDim2.new(1, -40, 0, 14),
  }, Card)
  Custom:Create("UIStroke", { Color = Z.accent, Thickness = 0.4 }, descLabel)

  -- Content
  if Content ~= "" then
    Custom:Create("TextLabel", {
      Font               = Enum.Font.Gotham,
      Text               = Content,
      TextColor3         = Z.fgMuted,
      TextSize           = 11,
      TextXAlignment     = Enum.TextXAlignment.Left,
      TextWrapped        = true,
      BackgroundTransparency = 1,
      Position           = UDim2.new(0, 14, 0, 42),
      Size               = UDim2.new(1, -28, 0, 28),
    }, Card)
  end

  -- Progress bar
  local prog = Custom:Create("Frame", {
    BackgroundColor3 = Z.accent,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(0, 1),
    Position         = UDim2.new(0, 0, 1, 0),
    Size             = UDim2.new(1, 0, 0, 2),
  }, Card)

  -- Close button
  local CloseBtn = Custom:Create("TextButton", {
    Font               = Enum.Font.GothamBold,
    Text               = "×",
    TextColor3         = Z.muted,
    TextSize           = 18,
    BackgroundTransparency = 1,
    AnchorPoint        = Vector2.new(1, 0),
    Position           = UDim2.new(1, -4, 0, 4),
    Size               = UDim2.new(0, 24, 0, 24),
  }, Card)

  -- Animate in
  Card.Position = UDim2.new(1, 340, 0, 0)
  TweenService:Create(Card, TweenInfo.new(tonumber(Time)+0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Position = UDim2.new(0, 0, 0, 0)
  }):Play()

  local Waitted = false
  function Notification:Close()
    if Waitted then return end
    Waitted = true
    TweenService:Create(Card, TweenInfo.new(tonumber(Time), Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
      Position = UDim2.new(1, 340, 0, 0)
    }):Play()
    task.wait(tonumber(Time))
    NGui:Destroy()
    Waitted = false
  end

  TweenService:Create(prog, TweenInfo.new(tonumber(Delay), Enum.EasingStyle.Linear), {
    Size = UDim2.new(0, 0, 0, 2)
  }):Play()

  CloseBtn.Activated:Connect(function() Notification:Close() end)
  task.delay(tonumber(Delay), function() Notification:Close() end)

  return Notification
end

-- ══════════════════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ══════════════════════════════════════════════════════════════════════════
function Speed_Library:CreateWindow(Config)
  local Title    = Config[1] or Config.Title       or ""
  local Subtitle = Config[2] or Config.Description or ""
  local TabWidth = Config[3] or Config["Tab Width"] or 110
  local SizeUi   = Config[4] or Config.SizeUi      or UDim2.fromOffset(540, 310)

  local SpeedHubXGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn   = false,
  }, _getGui())

  -- Outer drop-shadow holder (same role as original)
  local DropShadowHolder = Custom:Create("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Size                   = SizeUi,
    ZIndex                 = 0,
    Name                   = "DropShadowHolder",
    AnchorPoint            = Vector2.new(0.5, 0.5),
    Position               = UDim2.new(0.5, 0, 0.5, 0),
  }, SpeedHubXGui)

  -- Soft shadow
  Custom:Create("ImageLabel", {
    Image              = "rbxassetid://1316045217",
    ImageColor3        = Color3.fromRGB(0, 0, 0),
    ImageTransparency  = 0.55,
    ScaleType          = Enum.ScaleType.Slice,
    SliceCenter        = Rect.new(10, 10, 118, 118),
    AnchorPoint        = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(0.5, 0, 0.5, 0),
    Size               = UDim2.new(1, 24, 1, 24),
    ZIndex             = 0,
  }, DropShadowHolder)

  -- Main card
  local Main = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(0.5, 0.5),
    BackgroundColor3   = Z.card,
    BorderSizePixel    = 0,
    Position           = UDim2.new(0.5, 0, 0.5, 0),
    Size               = UDim2.new(1, 0, 1, 0),
    ClipsDescendants   = true,
    Name               = "Main",
  }, DropShadowHolder)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, Main)
  Custom:Create("UIStroke",  { Color = Z.border, Thickness = 1 }, Main)

  -- ── Header ─────────────────────────────────────────────────────────────
  local Top = Custom:Create("Frame", {
    BackgroundColor3 = Z.bg,
    BorderSizePixel  = 0,
    Size             = UDim2.new(1, 0, 0, 40),
    Name             = "Top",
  }, Main)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 10) }, Top)
  -- Fill bottom corners
  Custom:Create("Frame", {
    BackgroundColor3 = Z.bg,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(0, 1),
    Position         = UDim2.new(0, 0, 1, 0),
    Size             = UDim2.new(1, 0, 0, 10),
  }, Top)
  -- Header bottom border
  Custom:Create("Frame", {
    BackgroundColor3 = Z.border,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(0, 1),
    Position         = UDim2.new(0, 0, 1, 0),
    Size             = UDim2.new(1, 0, 0, 1),
  }, Top)

  -- macOS traffic-light dots
  local dotCol = { Z.err, Z.warn, Z.success }
  for i = 1, 3 do
    local d = Custom:Create("Frame", {
      BackgroundColor3 = dotCol[i], BorderSizePixel = 0,
      AnchorPoint = Vector2.new(0, 0.5),
      Position    = UDim2.new(0, 10+(i-1)*16, 0.5, 0),
      Size        = UDim2.new(0, 10, 0, 10),
    }, Top)
    Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, d)
  end

  -- Title
  local TextLabel = Custom:Create("TextLabel", {
    Font               = Enum.Font.GothamBold,
    Text               = Title,
    TextColor3         = Z.fg,
    TextSize           = 13,
    TextXAlignment     = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    AnchorPoint        = Vector2.new(0, 0.5),
    Position           = UDim2.new(0, 64, 0.5, 0),
    Size               = UDim2.new(0, 120, 0, 20),
  }, Top)

  -- Subtitle (replaces original colored description)
  local TextLabel1 = Custom:Create("TextLabel", {
    Font               = Enum.Font.Gotham,
    Text               = Subtitle,
    TextColor3         = Z.fgMuted,
    TextSize           = 11,
    TextXAlignment     = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    AnchorPoint        = Vector2.new(0, 0.5),
    Position           = UDim2.new(0, 64+TextLabel.TextBounds.X+8, 0.5, 0),
    Size               = UDim2.new(0.4, 0, 0, 20),
  }, Top)

  -- Minimize button
  local Min = Custom:Create("TextButton", {
    Font               = Enum.Font.GothamBold,
    Text               = "−",
    TextColor3         = Z.fgMuted,
    TextSize           = 16,
    AnchorPoint        = Vector2.new(1, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(1, -40, 0.5, 0),
    Size               = UDim2.new(0, 28, 0, 28),
    Name               = "Min",
  }, Top)

  -- Close button
  local Close = Custom:Create("TextButton", {
    Font               = Enum.Font.GothamBold,
    Text               = "×",
    TextColor3         = Z.fgMuted,
    TextSize           = 18,
    AnchorPoint        = Vector2.new(1, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(1, -10, 0.5, 0),
    Size               = UDim2.new(0, 28, 0, 28),
    Name               = "Close",
  }, Top)

  -- Hover tint for header buttons
  for _, btn in ipairs({ Min, Close }) do
    btn.MouseEnter:Connect(function() btn.TextColor3 = Z.fg end)
    btn.MouseLeave:Connect(function() btn.TextColor3 = Z.fgMuted end)
  end

  -- Divider below header
  Custom:Create("Frame", {
    AnchorPoint      = Vector2.new(0.5, 0),
    BackgroundColor3 = Z.border,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0.5, 0, 0, 40),
    Size             = UDim2.new(1, 0, 0, 1),
  }, Main)

  -- ── Tab sidebar ─────────────────────────────────────────────────────────
  local LayersTab = Custom:Create("Frame", {
    BackgroundColor3       = Z.bg,
    BackgroundTransparency = 0,
    BorderSizePixel        = 0,
    Position               = UDim2.new(0, 0, 0, 41),
    Size                   = UDim2.new(0, TabWidth, 1, -41),
    Name                   = "LayersTab",
  }, Main)

  -- Thin right border on sidebar
  Custom:Create("Frame", {
    BackgroundColor3 = Z.border,
    BorderSizePixel  = 0,
    AnchorPoint      = Vector2.new(1, 0),
    Position         = UDim2.new(1, 0, 0, 0),
    Size             = UDim2.new(0, 1, 1, 0),
  }, LayersTab)

  local ScrollTab = Custom:Create("ScrollingFrame", {
    CanvasSize             = UDim2.new(0, 0, 0, 0),
    ScrollBarImageColor3   = Z.border2,
    ScrollBarThickness     = 0,
    Active                 = true,
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Position               = UDim2.new(0, 0, 0, 8),
    Size                   = UDim2.new(1, 0, 1, -8),
    Name                   = "ScrollTab",
  }, LayersTab)

  Custom:Create("UIListLayout", {
    Padding   = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, ScrollTab)

  Custom:Create("UIPadding", {
    PaddingLeft  = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
  }, ScrollTab)

  -- ── Content area ─────────────────────────────────────────────────────
  local Layers = Custom:Create("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Position               = UDim2.new(0, TabWidth+1, 0, 41),
    Size                   = UDim2.new(1, -(TabWidth+1), 1, -41),
    Name                   = "Layers",
  }, Main)

  local NameTab = Custom:Create("TextLabel", {
    Font               = Enum.Font.GothamBold,
    Text               = "",
    TextColor3         = Z.fg,
    TextSize           = 14,
    TextWrapped        = true,
    TextXAlignment     = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(0, 14, 0, 0),
    Size               = UDim2.new(1, -14, 0, 30),
    Name               = "NameTab",
  }, Layers)

  local LayersReal = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    ClipsDescendants   = true,
    Position           = UDim2.new(0, 0, 1, 0),
    Size               = UDim2.new(1, 0, 1, -33),
    Name               = "LayersReal",
  }, Layers)

  local LayersFolder = Custom:Create("Folder", { Name = "LayersFolder" }, LayersReal)
  local LayersPageLayout = Custom:Create("UIPageLayout", {
    SortOrder       = Enum.SortOrder.LayoutOrder,
    TweenTime       = 0.25,
    EasingDirection = Enum.EasingDirection.InOut,
    EasingStyle     = Enum.EasingStyle.Quart,
  }, LayersFolder)

  -- ── Dropdown overlay (same structure as original) ─────────────────────
  local MoreBlur = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(1, 1),
    BackgroundColor3   = Z.bg,
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    ClipsDescendants   = true,
    Position           = UDim2.new(1, 8, 1, 8),
    Size               = UDim2.new(1, 154, 1, 54),
    Visible            = false,
    Name               = "MoreBlur",
  }, Layers)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, MoreBlur)

  local ConnectButton = Custom:Create("TextButton", {
    Text               = "",
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Size               = UDim2.new(1, 0, 1, 0),
    Name               = "ConnectButton",
  }, MoreBlur)

  local DropdownSelect = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(1, 0.5),
    BackgroundColor3   = Z.elevated,
    BorderSizePixel    = 0,
    LayoutOrder        = 1,
    Position           = UDim2.new(1, 172, 0.5, 0),
    Size               = UDim2.new(0, 160, 1, -16),
    ClipsDescendants   = true,
    Name               = "DropdownSelect",
  }, MoreBlur)
  Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, DropdownSelect)
  Custom:Create("UIStroke",  { Color = Z.border2, Thickness = 1, Transparency = 0.3 }, DropdownSelect)

  ConnectButton.Activated:Connect(function()
    if MoreBlur.Visible then
      TweenService:Create(MoreBlur,       TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
      TweenService:Create(DropdownSelect, TweenInfo.new(0.18), {Position = UDim2.new(1, 172, 0.5, 0)}):Play()
      task.wait(0.2)
      MoreBlur.Visible = false
    end
  end)

  local DropdownSelectReal = Custom:Create("Frame", {
    AnchorPoint        = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel    = 0,
    Position           = UDim2.new(0.5, 0, 0.5, 0),
    Size               = UDim2.new(1, -8, 1, -8),
    Name               = "DropdownSelectReal",
    Parent             = DropdownSelect,
  })
  local DropdownFolder = Custom:Create("Folder", { Name = "DropdownFolder", Parent = DropdownSelectReal })
  local DropPageLayout = Custom:Create("UIPageLayout", {
    EasingDirection = Enum.EasingDirection.InOut,
    EasingStyle     = Enum.EasingStyle.Quart,
    TweenTime       = 0.01,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Name            = "DropPageLayout",
    Parent          = DropdownFolder,
  })

  -- UpdateSize helper for tab scroll
  local function UpdateSize()
    local total = 0
    for _, v in pairs(ScrollTab:GetChildren()) do
      if v.Name ~= "UIListLayout" and v.Name ~= "UIPadding" then
        total = total + 2 + v.Size.Y.Offset
      end
    end
    ScrollTab.CanvasSize = UDim2.new(0, 0, 0, total)
  end
  ScrollTab.ChildAdded:Connect(UpdateSize)
  ScrollTab.ChildRemoved:Connect(UpdateSize)

  -- Min / Close / Restore
  Min.Activated:Connect(function()
    CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y)
    DropShadowHolder.Visible = false
    Open_Close.Visible = true
  end)
  Open_Close.Activated:Connect(function()
    DropShadowHolder.Visible = true
    Open_Close.Visible = false
  end)
  Close.Activated:Connect(function()
    CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y)
    if SpeedHubXGui then SpeedHubXGui:Destroy() end
    Speed_Library.Unloaded = true
  end)

  MakeDraggable(Top, DropShadowHolder)

  -- ══════════════════════════════════════════════════════════════════════
  --  TABS
  -- ══════════════════════════════════════════════════════════════════════
  local Tabs = {}
  local CountTab = 0
  local CountDropdown = 0

  function Tabs:CreateTab(Config)
    local _Name = Config[1] or Config.Name or ""
    local Icon  = Config[2] or Config.Icon or ""

    -- Content scroll page for this tab
    local ScrolLayers = Custom:Create("ScrollingFrame", {
      ScrollBarImageColor3 = Z.border2,
      ScrollBarThickness   = 3,
      Active               = true,
      LayoutOrder          = CountTab,
      BackgroundTransparency = 1,
      BorderSizePixel      = 0,
      Size                 = UDim2.new(1, 0, 1, 0),
      Name                 = "ScrolLayers",
      Parent               = LayersFolder,
    })
    Custom:Create("UIListLayout", {
      Padding   = UDim.new(0, 4),
      SortOrder = Enum.SortOrder.LayoutOrder,
      Parent    = ScrolLayers,
    })
    Custom:Create("UIPadding", {
      PaddingLeft  = UDim.new(0, 10),
      PaddingRight = UDim.new(0, 10),
      PaddingTop   = UDim.new(0, 6),
      Parent       = ScrolLayers,
    })

    -- Tab item in sidebar
    local Tab = Custom:Create("Frame", {
      BackgroundColor3       = CountTab == 0 and Z.elevated or Z.bg,
      BackgroundTransparency = 0,
      BorderSizePixel        = 0,
      LayoutOrder            = CountTab,
      Size                   = UDim2.new(1, 0, 0, 30),
      Name                   = "Tab",
      Parent                 = ScrollTab,
    })
    Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, Tab)

    -- Invisible click button
    local TabButton = Custom:Create("TextButton", {
      Text               = "",
      BackgroundTransparency = 1,
      BorderSizePixel    = 0,
      Size               = UDim2.new(1, 0, 1, 0),
      Name               = "TabButton",
      Parent             = Tab,
    })

    -- Tab icon
    if Icon ~= "" then
      Custom:Create("ImageLabel", {
        Image              = Icon,
        ImageColor3        = Z.fgMuted,
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        AnchorPoint        = Vector2.new(0, 0.5),
        Position           = UDim2.new(0, 8, 0.5, 0),
        Size               = UDim2.new(0, 14, 0, 14),
        Name               = "FeatureImg",
        Parent             = Tab,
      })
    end

    -- Tab name label
    Custom:Create("TextLabel", {
      Font               = Enum.Font.GothamBold,
      Text               = _Name,
      TextColor3         = CountTab == 0 and Z.fg or Z.fgMuted,
      TextSize           = 12,
      TextXAlignment     = Enum.TextXAlignment.Left,
      BackgroundTransparency = 1,
      BorderSizePixel    = 0,
      AnchorPoint        = Vector2.new(0, 0.5),
      Position           = UDim2.new(0, Icon ~= "" and 28 or 10, 0.5, 0),
      Size               = UDim2.new(1, -(Icon ~= "" and 34 or 14), 0, 18),
      Name               = "TabName",
      Parent             = Tab,
    })

    -- Active indicator bar
    if CountTab == 0 then
      LayersPageLayout:JumpToIndex(0)
      NameTab.Text = _Name

      local ChooseFrame = Custom:Create("Frame", {
        BackgroundColor3 = Z.accent,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, -6, 0.5, 0),
        Size             = UDim2.new(0, 2, 0, 14),
        Name             = "ChooseFrame",
        Parent           = Tab,
      })
      Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, ChooseFrame)
      Custom:Create("UIStroke",  { Color = Z.accent, Thickness = 1 }, ChooseFrame)
    end

    TabButton.Activated:Connect(function()
      CircleClick(TabButton, Player:GetMouse().X, Player:GetMouse().Y)
      local FrameChoose = nil
      for _, s in pairs(ScrollTab:GetChildren()) do
        for _, v in pairs(s:GetChildren()) do
          if v.Name == "ChooseFrame" then FrameChoose = v; break end
        end
        if FrameChoose then break end
      end

      if FrameChoose and Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
        -- Reset all tabs
        for _, tf in pairs(ScrollTab:GetChildren()) do
          if tf.Name == "Tab" then
            TweenService:Create(tf, TweenInfo.new(0.15), { BackgroundColor3 = Z.bg }):Play()
            local lbl = tf:FindFirstChild("TabName")
            if lbl then TweenService:Create(lbl, TweenInfo.new(0.15), { TextColor3 = Z.fgMuted }):Play() end
          end
        end

        TweenService:Create(Tab, TweenInfo.new(0.2, Enum.EasingStyle.Quart), { BackgroundColor3 = Z.elevated }):Play()
        local lbl2 = Tab:FindFirstChild("TabName")
        if lbl2 then TweenService:Create(lbl2, TweenInfo.new(0.15), { TextColor3 = Z.fg }):Play() end

        TweenService:Create(FrameChoose, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
          Position = UDim2.new(0, -6, 0, (Tab.LayoutOrder * 32) + 8),
        }):Play()

        LayersPageLayout:JumpToIndex(Tab.LayoutOrder)
        task.wait(0.04)
        NameTab.Text = _Name
      end
    end)

    TabButton.MouseEnter:Connect(function()
      if Tab.BackgroundColor3 ~= Z.elevated then
        TweenService:Create(Tab, TweenInfo.new(0.12), { BackgroundColor3 = Z.border }):Play()
      end
    end)
    TabButton.MouseLeave:Connect(function()
      if Tab.BackgroundColor3 ~= Z.elevated then
        TweenService:Create(Tab, TweenInfo.new(0.12), { BackgroundColor3 = Z.bg }):Play()
      end
    end)

    -- ── SECTIONS ──────────────────────────────────────────────────────────
    local Sections, CountSection = {}, 0

    function Sections:AddSection(Title, OpenSection)
      Title       = Title or ""
      OpenSection = OpenSection or false

      local Section = Custom:Create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        LayoutOrder            = CountSection,
        Size                   = UDim2.new(1, 0, 0, 32),
        Name                   = "Section",
        Parent                 = ScrolLayers,
      })

      -- Section header row
      local SectionReal = Custom:Create("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = Z.bg,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.5, 0, 0, 0),
        Size             = UDim2.new(1, 0, 0, 32),
        Name             = "SectionReal",
        Parent           = Section,
      })
      Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, SectionReal)
      Custom:Create("UIStroke",  { Color = Z.border, Thickness = 1 }, SectionReal)

      local SectionButton = Custom:Create("TextButton", {
        Text               = "",
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Size               = UDim2.new(1, 0, 1, 0),
        Name               = "SectionButton",
        Parent             = SectionReal,
      })

      -- Chevron
      local FeatureFrame = Custom:Create("Frame", {
        AnchorPoint        = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Position           = UDim2.new(1, -8, 0.5, 0),
        Size               = UDim2.new(0, 18, 0, 18),
        Name               = "FeatureFrame",
        Parent             = SectionReal,
      })
      local FeatureImg = Custom:Create("ImageLabel", {
        Image              = "rbxassetid://125609963478878",
        ImageColor3        = Z.muted,
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Position           = UDim2.new(0.5, 0, 0.5, 0),
        Rotation           = -90,
        Size               = UDim2.new(1, 0, 1, 0),
        Name               = "FeatureImg",
        Parent             = FeatureFrame,
      })

      -- Section title
      Custom:Create("TextLabel", {
        Font               = Enum.Font.GothamBold,
        Text               = Title,
        TextColor3         = Z.fgMuted,
        TextSize           = 11,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        AnchorPoint        = Vector2.new(0, 0.5),
        Position           = UDim2.new(0, 12, 0.5, 0),
        Size               = UDim2.new(1, -40, 0, 14),
        Name               = "SectionTitle",
        Parent             = SectionReal,
      })

      -- Accent divider below header
      local SectionDecideFrame = Custom:Create("Frame", {
        BackgroundColor3 = Z.accent,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 0, 0, 35),
        Size             = UDim2.new(0, 0, 0, 1),
        Name             = "SectionDecideFrame",
        Parent           = Section,
      })
      Custom:Create("UICorner", {}, SectionDecideFrame)

      -- Items container
      local SectionAdd = Custom:Create("Frame", {
        AnchorPoint        = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        ClipsDescendants   = true,
        Position           = UDim2.new(0.5, 0, 0, 38),
        Size               = UDim2.new(1, 0, 0, 0),
        Name               = "SectionAdd",
        Parent             = Section,
      })
      Custom:Create("UIListLayout", {
        Padding   = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent    = SectionAdd,
      })

      -- Size helpers
      local function UpdateSizeScroll()
        local h = 0
        for _, child in pairs(ScrolLayers:GetChildren()) do
          if child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
            h = h + 4 + child.Size.Y.Offset
          end
        end
        ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, h)
      end

      local function UpdateSizeSection()
        if OpenSection then
          local h = 38
          for _, v in pairs(SectionAdd:GetChildren()) do
            if v.Name ~= "UIListLayout" then h = h + v.Size.Y.Offset + 4 end
          end
          TweenService:Create(FeatureFrame, TweenInfo.new(0.15), { Rotation = 90 }):Play()
          TweenService:Create(Section,      TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, h) }):Play()
          TweenService:Create(SectionAdd,   TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, h-38) }):Play()
          TweenService:Create(SectionDecideFrame, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, 1) }):Play()
          task.wait(0.4)
          UpdateSizeScroll()
        end
      end

      local function ToggleSection()
        CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)
        if OpenSection then
          TweenService:Create(FeatureFrame, TweenInfo.new(0.15), { Rotation = 0 }):Play()
          TweenService:Create(Section,      TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, 32) }):Play()
          TweenService:Create(SectionDecideFrame, TweenInfo.new(0.15), { Size = UDim2.new(0, 0, 0, 1) }):Play()
          OpenSection = false
          task.wait(0.15)
          UpdateSizeScroll()
        else
          OpenSection = true
          UpdateSizeSection()
        end
      end

      SectionButton.Activated:Connect(ToggleSection)
      SectionAdd.ChildAdded:Connect(UpdateSizeSection)
      SectionAdd.ChildRemoved:Connect(UpdateSizeSection)
      UpdateSizeScroll()

      -- ── ITEMS ────────────────────────────────────────────────────────────
      local Item, ItemCount = {}, 0

      -- Shared row builder
      local function makeRow(h)
        local row = Custom:Create("Frame", {
          BackgroundColor3 = Z.elevated,
          BorderSizePixel  = 0,
          Size             = UDim2.new(1, 0, 0, h),
          LayoutOrder      = ItemCount,
          Parent           = SectionAdd,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
        Custom:Create("UIStroke",  { Color = Z.border, Thickness = 1 }, row)
        return row
      end

      local function rowTitle(parent, text, x, y, w)
        Custom:Create("TextLabel", {
          Font               = Enum.Font.GothamBold,
          Text               = text,
          TextColor3         = Z.fg,
          TextSize           = 12,
          TextXAlignment     = Enum.TextXAlignment.Left,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(0, x, 0, y),
          Size               = UDim2.new(1, w, 0, 14),
          Parent             = parent,
        })
      end

      local function rowSub(parent, text, x, y, w)
        return Custom:Create("TextLabel", {
          Font               = Enum.Font.Gotham,
          Text               = text,
          TextColor3         = Z.muted,
          TextSize           = 11,
          TextXAlignment     = Enum.TextXAlignment.Left,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(0, x, 0, y),
          Size               = UDim2.new(1, w, 0, 13),
          Parent             = parent,
        })
      end

      -- ── AddParagraph ─────────────────────────────────────────────────
      function Item:AddParagraph(Config)
        local _T = Config[1] or Config.Title   or ""
        local _C = Config[2] or Config.Content or ""
        local F  = {}

        local row = makeRow(36)
        rowTitle(row, _T, 10, 8, -20)
        local subL = Custom:Create("TextLabel", {
          Font               = Enum.Font.Gotham,
          Text               = _C,
          TextColor3         = Z.fgMuted,
          TextSize           = 11,
          TextWrapped        = true,
          TextXAlignment     = Enum.TextXAlignment.Left,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(0, 10, 0, 22),
          Size               = UDim2.new(1, -20, 0, 13),
          Parent             = row,
        })

        local function refresh()
          subL.TextWrapped = false
          local lines = math.max(1, math.ceil(subL.TextBounds.X / math.max(1, subL.AbsoluteSize.X)))
          subL.Size = UDim2.new(1, -20, 0, 13*lines)
          row.Size  = UDim2.new(1, 0, 0, subL.AbsoluteSize.Y + 28)
          subL.TextWrapped = true
          UpdateSizeSection()
        end
        refresh()
        subL:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)

        function F:Set(C)
          local t = C[1] or C.Title   or ""
          local c = C[2] or C.Content or ""
          row:FindFirstChildOfClass("TextLabel").Text = t
          subL.Text = c
          refresh()
        end
        ItemCount += 1
        return F
      end

      -- ── AddSeperator ─────────────────────────────────────────────────
      function Item:AddSeperator(Config)
        local _T = Config[1] or Config.Title or ""
        local F  = {}
        local sep = Custom:Create("Frame", {
          BackgroundColor3 = Z.border,
          BorderSizePixel  = 0,
          LayoutOrder      = ItemCount,
          Size             = UDim2.new(1, 0, 0, 28),
          Name             = "Seperator",
          Parent           = SectionAdd,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 6) }, sep)
        local lbl = Custom:Create("TextLabel", {
          Font               = Enum.Font.GothamBold,
          Text               = _T,
          TextColor3         = Z.fgMuted,
          TextSize           = 11,
          TextXAlignment     = Enum.TextXAlignment.Left,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(0, 12, 0, 0),
          Size               = UDim2.new(1, -16, 1, 0),
          Parent             = sep,
        })
        function F:Set(C) lbl.Text = C[1] or C.Title or "" end
        ItemCount += 1
        return F
      end

      -- ── AddLine ──────────────────────────────────────────────────────
      function Item:AddLine()
        Custom:Create("Frame", {
          BackgroundColor3 = Z.border,
          BorderSizePixel  = 0,
          LayoutOrder      = ItemCount,
          Size             = UDim2.new(1, 0, 0, 1),
          Name             = "Line",
          Parent           = SectionAdd,
        })
        ItemCount += 1
        return {}
      end

      -- ── AddButton ────────────────────────────────────────────────────
      function Item:AddButton(Config)
        local _T  = Config[1] or Config.Title    or ""
        local _C  = Config[2] or Config.Content  or ""
        local _I  = Config[3] or Config.Icon     or ""
        local _CB = Config[4] or Config.Callback or function() end
        local F   = {}

        local row = makeRow(38)
        rowTitle(row, _T, 10, 8, -100)
        rowSub(row, _C, 10, 22, -100)

        -- Right icon
        if _I ~= "" then
          Custom:Create("ImageLabel", {
            Image              = _I,
            ImageColor3        = Z.fgMuted,
            AnchorPoint        = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel    = 0,
            Position           = UDim2.new(1, -10, 0.5, 0),
            Size               = UDim2.new(0, 16, 0, 16),
            Parent             = row,
          })
        end

        local btn = Custom:Create("TextButton", {
          Text               = "",
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 1, 0),
          ZIndex             = 5,
          Parent             = row,
        })
        btn.MouseEnter:Connect(function()
          TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Z.border }):Play()
        end)
        btn.MouseLeave:Connect(function()
          TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Z.elevated }):Play()
        end)
        btn.Activated:Connect(function()
          CircleClick(btn, Player:GetMouse().X, Player:GetMouse().Y)
          _CB()
        end)

        ItemCount += 1
        return F
      end

      -- ── AddToggle ────────────────────────────────────────────────────
      function Item:AddToggle(Config)
        local _T   = Config[1] or Config.Title    or ""
        local _C   = Config[2] or Config.Content  or ""
        local _D   = Config[3] or Config.Default  or false
        local _CB  = Config[4] or Config.Callback or function() end
        local FT   = { Value = _D }

        local row = makeRow(38)
        rowTitle(row, _T, 10, 8, -110)
        rowSub(row, _C, 10, 22, -110)

        -- Switch track
        local track = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(1, 0.5),
          BackgroundColor3 = _D and Z.accent or Z.border2,
          BorderSizePixel  = 0,
          Position         = UDim2.new(1, -10, 0.5, 0),
          Size             = UDim2.new(0, 44, 0, 22),
          Parent           = row,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, track)

        local thumb = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(0, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BorderSizePixel  = 0,
          Position         = _D and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 1, 0.5, 0),
          Size             = UDim2.new(0, 18, 0, 18),
          Parent           = track,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, thumb)

        local tbtn = Custom:Create("TextButton", {
          Text               = "",
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 1, 0),
          ZIndex             = 5,
          Parent             = row,
        })

        local function setVisual(on)
          local tw = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
          TweenService:Create(track, tw, { BackgroundColor3 = on and Z.accent or Z.border2 }):Play()
          TweenService:Create(thumb, tw, { Position = on and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 1, 0.5, 0) }):Play()
        end

        function FT:Set(val)
          FT.Value = val
          setVisual(val)
          _CB(val)
        end
        FT:Set(_D)

        tbtn.Activated:Connect(function()
          CircleClick(tbtn, Player:GetMouse().X, Player:GetMouse().Y)
          FT:Set(not FT.Value)
        end)

        ItemCount += 1
        return FT
      end

      -- ── AddSlider ────────────────────────────────────────────────────
      function Item:AddSlider(Config)
        local _T   = Config[1] or Config.Title     or ""
        local _C   = Config[2] or Config.Content   or ""
        local _Inc = Config[3] or Config.Increment or 1
        local _Min = Config[4] or Config.Min       or 0
        local _Max = Config[5] or Config.Max       or 100
        local _D   = Config[6] or Config.Default   or 50
        local _CB  = Config[7] or Config.Callback  or function() end
        local FS   = { Value = _D }

        local row = makeRow(52)
        rowTitle(row, _T, 10, 7, -80)

        -- Value badge
        local valBadge = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(1, 0),
          BackgroundColor3 = Z.border,
          BorderSizePixel  = 0,
          Position         = UDim2.new(1, -8, 0, 6),
          Size             = UDim2.new(0, 44, 0, 20),
          Parent           = row,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, valBadge)
        local valTB = Custom:Create("TextBox", {
          Font               = Enum.Font.GothamBold,
          Text               = tostring(_D),
          TextColor3         = Z.fg,
          TextSize           = 11,
          TextXAlignment     = Enum.TextXAlignment.Center,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 1, 0),
          Parent             = valBadge,
        })

        -- Track
        local track = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(0, 1),
          BackgroundColor3 = Z.border2,
          BorderSizePixel  = 0,
          Position         = UDim2.new(0, 10, 1, -8),
          Size             = UDim2.new(1, -20, 0, 3),
          Parent           = row,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, track)

        -- Fill
        local fill = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(0, 0.5),
          BackgroundColor3 = Z.accent,
          BorderSizePixel  = 0,
          Position         = UDim2.new(0, 0, 0.5, 0),
          Size             = UDim2.new(0, 0, 1, 0),
          Parent           = track,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, fill)

        -- Thumb
        local slThumb = Custom:Create("Frame", {
          AnchorPoint      = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BorderSizePixel  = 0,
          Position         = UDim2.new(0, 0, 0.5, 0),
          Size             = UDim2.new(0, 12, 0, 12),
          Parent           = track,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, slThumb)
        Custom:Create("UIStroke",  { Color = Z.accent, Thickness = 2 }, slThumb)

        local function Round(n, f)
          local r = math.floor(n/f + 0.5*math.sign(n)) * f
          if r < 0 then r = r+f end
          return r
        end

        function FS:Set(v)
          v = math.clamp(Round(v, _Inc), _Min, _Max)
          FS.Value = v
          valTB.Text = tostring(v)
          local pct = (_Max==_Min) and 0 or (v-_Min)/(_Max-_Min)
          TweenService:Create(fill,    TweenInfo.new(0.08), { Size     = UDim2.new(pct, 0, 1, 0) }):Play()
          TweenService:Create(slThumb, TweenInfo.new(0.08), { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
        end

        local draggingSlider = false
        track.InputBegan:Connect(function(inp)
          if inp.UserInputType == Enum.UserInputType.MouseButton1
          or inp.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
          end
        end)
        track.InputEnded:Connect(function(inp)
          if inp.UserInputType == Enum.UserInputType.MouseButton1
          or inp.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
            _CB(FS.Value)
          end
        end)
        UserInputService.InputChanged:Connect(function(inp)
          if draggingSlider then
            local pct = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            FS:Set(_Min + (_Max-_Min)*pct)
          end
        end)

        valTB:GetPropertyChangedSignal("Text"):Connect(function()
          local clean = valTB.Text:gsub("[^%d]", "")
          if clean ~= "" then
            local n = math.min(tonumber(clean) or 0, _Max)
            if tostring(n) ~= valTB.Text then valTB.Text = tostring(n) end
          end
        end)
        valTB.FocusLost:Connect(function()
          FS:Set(tonumber(valTB.Text) or 0)
          _CB(FS.Value)
        end)

        FS:Set(_D)
        _CB(FS.Value)
        ItemCount += 1
        return FS
      end

      -- ── AddInput ─────────────────────────────────────────────────────
      function Item:AddInput(Config)
        local _T  = Config[1] or Config.Title    or ""
        local _C  = Config[2] or Config.Content  or ""
        local _D  = Config[3] or Config.Default  or ""
        local _CB = Config[4] or Config.Callback or function() end
        local FI  = { Value = _D }

        local row = makeRow(38)
        rowTitle(row, _T, 10, 8, -160)
        rowSub(row, _C, 10, 22, -160)

        local inputFrame = Custom:Create("Frame", {
          AnchorPoint        = Vector2.new(1, 0.5),
          BackgroundColor3   = Z.border,
          BorderSizePixel    = 0,
          ClipsDescendants   = true,
          Position           = UDim2.new(1, -8, 0.5, 0),
          Size               = UDim2.new(0, 140, 0, 26),
          Parent             = row,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 5) }, inputFrame)
        Custom:Create("UIStroke",  { Color = Z.border2, Thickness = 1 }, inputFrame)

        local tb = Custom:Create("TextBox", {
          Font               = Enum.Font.Gotham,
          PlaceholderText    = "Type here…",
          PlaceholderColor3  = Z.muted,
          Text               = _D,
          TextColor3         = Z.fg,
          TextSize           = 11,
          TextXAlignment     = Enum.TextXAlignment.Left,
          AnchorPoint        = Vector2.new(0, 0.5),
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(0, 6, 0.5, 0),
          Size               = UDim2.new(1, -10, 1, -6),
          Parent             = inputFrame,
        })

        tb.Focused:Connect(function()
          TweenService:Create(inputFrame, TweenInfo.new(0.12), { BackgroundColor3 = Z.elevated }):Play()
        end)
        tb.FocusLost:Connect(function()
          TweenService:Create(inputFrame, TweenInfo.new(0.12), { BackgroundColor3 = Z.border }):Play()
          FI:Set(tb.Text)
        end)

        function FI:Set(v)
          tb.Text  = v
          FI.Value = v
          _CB(v)
        end
        FI:Set(_D)

        ItemCount += 1
        return FI
      end

      -- ── AddDropdown ──────────────────────────────────────────────────
      function Item:AddDropdown(Config)
        local _T   = Config[1] or Config.Title    or ""
        local _C   = Config[2] or Config.Content  or ""
        local _M   = Config[3] or Config.Multi    or false
        local _Opt = Config[4] or Config.Options  or {}
        local _D   = Config[5] or Config.Default  or {}
        local _CB  = Config[6] or Config.Callback or function() end
        local FD   = { Value = _D, Options = _Opt }

        local row = makeRow(38)
        rowTitle(row, _T, 10, 8, -160)
        rowSub(row, _C, 10, 22, -160)

        -- Select frame (shows current value)
        local selFrame = Custom:Create("Frame", {
          AnchorPoint        = Vector2.new(1, 0.5),
          BackgroundColor3   = Z.border,
          BorderSizePixel    = 0,
          ClipsDescendants   = true,
          Position           = UDim2.new(1, -8, 0.5, 0),
          Size               = UDim2.new(0, 140, 0, 26),
          Name               = "SelectOptionsFrame",
          LayoutOrder        = CountDropdown,
          Parent             = row,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 5) }, selFrame)
        Custom:Create("UIStroke",  { Color = Z.border2, Thickness = 1 }, selFrame)

        local selLabel = Custom:Create("TextLabel", {
          Font               = Enum.Font.Gotham,
          Text               = "Select…",
          TextColor3         = Z.muted,
          TextSize           = 11,
          TextXAlignment     = Enum.TextXAlignment.Left,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          AnchorPoint        = Vector2.new(0, 0.5),
          Position           = UDim2.new(0, 6, 0.5, 0),
          Size               = UDim2.new(1, -28, 1, 0),
          TextTruncate       = Enum.TextTruncate.AtEnd,
          Parent             = selFrame,
        })
        Custom:Create("ImageLabel", {
          Image              = "rbxassetid://90200523188815",
          ImageColor3        = Z.muted,
          AnchorPoint        = Vector2.new(1, 0.5),
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Position           = UDim2.new(1, -2, 0.5, 0),
          Size               = UDim2.new(0, 18, 0, 18),
          Parent             = selFrame,
        })

        -- Open dropdown overlay on click
        local dBtn = Custom:Create("TextButton", {
          Text               = "",
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 1, 0),
          ZIndex             = 5,
          Parent             = selFrame,
        })

        -- Scroll page for this dropdown's options
        local ScrollSelect = Custom:Create("ScrollingFrame", {
          CanvasSize         = UDim2.new(0, 0, 0, 0),
          ScrollBarThickness = 0,
          Active             = true,
          LayoutOrder        = CountDropdown,
          BackgroundTransparency = 1,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 1, 0),
          Name               = "ScrollSelect",
          Parent             = DropdownFolder,
        })
        Custom:Create("UIListLayout", {
          Padding   = UDim.new(0, 3),
          SortOrder = Enum.SortOrder.LayoutOrder,
          Parent    = ScrollSelect,
        })
        Custom:Create("UIPadding", {
          PaddingTop    = UDim.new(0, 4),
          PaddingBottom = UDim.new(0, 4),
          PaddingLeft   = UDim.new(0, 4),
          PaddingRight  = UDim.new(0, 4),
          Parent        = ScrollSelect,
        })

        -- Search box
        local search = Custom:Create("TextBox", {
          Font               = Enum.Font.Gotham,
          PlaceholderText    = "Search…",
          PlaceholderColor3  = Z.muted,
          Text               = "",
          TextColor3         = Z.fg,
          TextSize           = 11,
          BackgroundColor3   = Z.border,
          BorderSizePixel    = 0,
          Size               = UDim2.new(1, 0, 0, 24),
          Name               = "SearchBar",
          Parent             = ScrollSelect,
        })
        Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, search)

        search:GetPropertyChangedSignal("Text"):Connect(function()
          local q = search.Text:lower()
          for _, v in pairs(ScrollSelect:GetChildren()) do
            if v:IsA("Frame") and v.Name == "Option" then
              local ot = v:FindFirstChild("OptionText")
              if ot then v.Visible = string.find(ot.Text:lower(), q) ~= nil end
            end
          end
        end)

        dBtn.Activated:Connect(function()
          if not MoreBlur.Visible then
            MoreBlur.Visible = true
            DropPageLayout:JumpToIndex(selFrame.LayoutOrder)
            TweenService:Create(MoreBlur,       TweenInfo.new(0.15), { BackgroundTransparency = 0.3 }):Play()
            TweenService:Create(DropdownSelect, TweenInfo.new(0.15), { Position = UDim2.new(1, -11, 0.5, 0) }):Play()
          end
        end)

        local DropCount = 0

        function FD:Clear()
          for _, c in pairs(ScrollSelect:GetChildren()) do
            if c.Name == "Option" then c:Destroy() end
          end
          FD.Value   = {}
          FD.Options = {}
          selLabel.Text = "Select…"
        end

        function FD:Set(val)
          FD.Value = val or FD.Value
          for _, Drop in pairs(ScrollSelect:GetChildren()) do
            if Drop.Name == "Option" then
              local found = table.find(FD.Value, Drop.OptionText.Text)
              TweenService:Create(Drop, TweenInfo.new(0.15), {
                BackgroundColor3       = found and Z.elevated or Z.card,
                BackgroundTransparency = found and 0 or 0,
              }):Play()
              local cf = Drop:FindFirstChild("ChooseFrame")
              if cf then
                TweenService:Create(cf, TweenInfo.new(0.15), {
                  BackgroundColor3 = found and Z.accent or Z.border,
                }):Play()
              end
            end
          end
          local joined = table.concat(FD.Value, ", ")
          selLabel.Text      = joined ~= "" and joined or "Select…"
          selLabel.TextColor3 = joined ~= "" and Z.fg or Z.muted
          _CB(FD.Value)
        end

        function FD:AddOption(optName)
          optName = optName or "Option"
          local opt = Custom:Create("Frame", {
            BackgroundColor3 = Z.card,
            BorderSizePixel  = 0,
            LayoutOrder      = DropCount,
            Size             = UDim2.new(1, 0, 0, 28),
            Name             = "Option",
            Parent           = ScrollSelect,
          })
          Custom:Create("UICorner", { CornerRadius = UDim.new(0, 4) }, opt)

          -- Active accent bar
          local cf = Custom:Create("Frame", {
            BackgroundColor3 = Z.border,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, 2, 0.6, 0),
            Name             = "ChooseFrame",
            Parent           = opt,
          })
          Custom:Create("UICorner", { CornerRadius = UDim.new(0, 9999) }, cf)
          Custom:Create("UIStroke",  { Color = Z.border2, Thickness = 0.5 }, cf)

          Custom:Create("TextLabel", {
            Font               = Enum.Font.Gotham,
            Text               = optName,
            TextColor3         = Z.fgMuted,
            TextSize           = 11,
            TextXAlignment     = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel    = 0,
            AnchorPoint        = Vector2.new(0, 0.5),
            Position           = UDim2.new(0, 10, 0.5, 0),
            Size               = UDim2.new(1, -14, 0, 14),
            Name               = "OptionText",
            Parent             = opt,
          })

          local ob = Custom:Create("TextButton", {
            Text               = "",
            BackgroundTransparency = 1,
            BorderSizePixel    = 0,
            Size               = UDim2.new(1, 0, 1, 0),
            ZIndex             = 5,
            Parent             = opt,
          })

          ob.Activated:Connect(function()
            CircleClick(ob, Player:GetMouse().X, Player:GetMouse().Y)
            if _M then
              if table.find(FD.Value, optName) then
                table.remove(FD.Value, table.find(FD.Value, optName))
              else
                table.insert(FD.Value, optName)
              end
            else
              FD.Value = { optName }
            end
            FD:Set(FD.Value)
          end)

          -- Update scroll canvas
          local h = 0
          for _, c in ipairs(ScrollSelect:GetChildren()) do
            if c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" and c.Name ~= "SearchBar" then
              h = h + 4 + c.Size.Y.Offset
            end
          end
          ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, h+32)

          DropCount += 1
        end

        function FD:Refresh(list, sel)
          list = list or {}
          sel  = sel  or {}
          FD:Clear()
          for _, v in ipairs(list) do FD:AddOption(v) end
          FD.Options = list
          FD:Set(sel)
        end

        FD:Refresh(FD.Options, FD.Value)

        ItemCount   += 1
        CountDropdown += 1
        return FD
      end

      ItemCount += 1
      return Item
    end

    CountSection += 1
    return Sections
  end

  CountTab += 1
  return Tabs
end

return Speed_Library
