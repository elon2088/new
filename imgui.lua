-- rbimgui.lua
-- Dark ImGui-style UI library for Roblox
-- API-compatible with rbimgui-2 style

local rbimgui = {}

-- ─── THEME ───────────────────────────────────────────────────────────────────
local THEME = {
    BG          = Color3.fromRGB(18, 18, 20),
    TITLEBAR    = Color3.fromRGB(12, 12, 14),
    TAB_IDLE    = Color3.fromRGB(28, 28, 32),
    TAB_ACTIVE  = Color3.fromRGB(200, 170, 40),
    TAB_TEXT_IDLE   = Color3.fromRGB(160, 160, 160),
    TAB_TEXT_ACTIVE = Color3.fromRGB(10, 10, 10),
    WIDGET_BG   = Color3.fromRGB(28, 28, 32),
    WIDGET_BORDER = Color3.fromRGB(48, 48, 56),
    BUTTON      = Color3.fromRGB(40, 40, 50),
    BUTTON_HOVER= Color3.fromRGB(58, 58, 72),
    BUTTON_TEXT = Color3.fromRGB(220, 220, 220),
    LABEL_TEXT  = Color3.fromRGB(200, 200, 200),
    SLIDER_FILL = Color3.fromRGB(200, 170, 40),
    SLIDER_BG   = Color3.fromRGB(40, 40, 50),
    SWITCH_ON   = Color3.fromRGB(80, 200, 80),
    SWITCH_OFF  = Color3.fromRGB(80, 80, 90),
    FOLDER_BG   = Color3.fromRGB(22, 22, 26),
    FOLDER_HEADER = Color3.fromRGB(32, 32, 40),
    DROPDOWN_BG = Color3.fromRGB(22, 22, 26),
    DROPDOWN_ITEM = Color3.fromRGB(30, 30, 38),
    DROPDOWN_HOVER = Color3.fromRGB(48, 48, 60),
    SCROLLBAR   = Color3.fromRGB(60, 60, 70),
    SEPARATOR   = Color3.fromRGB(50, 50, 60),
    TEXT_DIM    = Color3.fromRGB(120, 120, 140),
    ACCENT      = Color3.fromRGB(200, 170, 40),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code
local TEXT_SIZE = 13
local TITLE_SIZE = 13
local TAB_HEIGHT = 30
local WIDGET_HEIGHT = 30
local PADDING = 8
local CORNER = 6

-- ─── UTILITY ─────────────────────────────────────────────────────────────────
local function makeSignal()
    local callbacks = {}
    local signal = {}
    function signal:Connect(fn) callbacks[#callbacks+1] = fn end
    function signal:Fire(...)
        for _, fn in ipairs(callbacks) do
            task.spawn(fn, ...)
        end
    end
    return signal
end

local function applyCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or CORNER)
    c.Parent = inst
    return c
end

local function applyPadding(inst, x, y)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, x or PADDING)
    p.PaddingRight  = UDim.new(0, x or PADDING)
    p.PaddingTop    = UDim.new(0, y or PADDING)
    p.PaddingBottom = UDim.new(0, y or PADDING)
    p.Parent = inst
    return p
end

local function applyListLayout(inst, dir, spacing, halign, valign)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, spacing or 4)
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = valign or Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = inst
    return l
end

local function newFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Name = name or "Frame"
    f.Size = size or UDim2.new(1, 0, 0, 30)
    f.Position = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = color or THEME.WIDGET_BG
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function newLabel(parent, text, color, size, font, name)
    local l = Instance.new("TextLabel")
    l.Name = name or "Label"
    l.Text = text or ""
    l.TextColor3 = color or THEME.LABEL_TEXT
    l.TextSize = size or TEXT_SIZE
    l.Font = font or FONT
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Parent = parent
    return l
end

local function hoverEffect(btn, normal, hover)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = normal end)
end

-- ─── WIDGET BUILDERS ─────────────────────────────────────────────────────────

local widgetBuilders = {}

-- LABEL
widgetBuilders["label"] = function(parent, props)
    props = props or {}
    local row = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, Color3.fromRGB(0,0,0), "LabelRow")
    row.BackgroundTransparency = 1

    local lbl = newLabel(row, props.text or "label", props.color or THEME.LABEL_TEXT)
    lbl.TextSize = props.size or TEXT_SIZE

    local obj = { event = makeSignal() }
    function obj.set(v) lbl.Text = tostring(v) end
    return obj
end

-- BUTTON
widgetBuilders["button"] = function(parent, props)
    props = props or {}
    local row = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, Color3.fromRGB(0,0,0), "ButtonRow")
    row.BackgroundTransparency = 1

    local btn = Instance.new("TextButton")
    btn.Name = "Button"
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = THEME.BUTTON
    btn.BorderSizePixel = 0
    btn.Text = props.text or "Button"
    btn.TextColor3 = THEME.BUTTON_TEXT
    btn.TextSize = TEXT_SIZE
    btn.Font = FONT
    btn.AutoButtonColor = false
    btn.Parent = row
    applyCorner(btn, 4)
    hoverEffect(btn, THEME.BUTTON, THEME.BUTTON_HOVER)

    -- border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.WIDGET_BORDER
    stroke.Thickness = 1
    stroke.Parent = btn

    local event = makeSignal()
    btn.MouseButton1Click:Connect(function() event:Fire() end)

    local obj = { event = event }
    function obj.set(t) btn.Text = tostring(t) end
    return obj
end

-- SWITCH
widgetBuilders["switch"] = function(parent, props)
    props = props or {}
    local row = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, Color3.fromRGB(0,0,0), "SwitchRow")
    row.BackgroundTransparency = 1

    local lbl = newLabel(row, props.text or "Switch", THEME.LABEL_TEXT)
    lbl.Size = UDim2.new(1, -54, 1, 0)

    local track = newFrame(row, UDim2.new(0, 44, 0, 22), UDim2.new(1, -48, 0.5, -11), THEME.SWITCH_OFF, "Track")
    applyCorner(track, 11)

    local knob = newFrame(track, UDim2.new(0, 18, 0, 18), UDim2.new(0, 2, 0.5, -9), Color3.fromRGB(230,230,230), "Knob")
    applyCorner(knob, 9)

    local state = false
    local event = makeSignal()

    local function setState(v)
        state = v
        track.BackgroundColor3 = state and THEME.SWITCH_ON or THEME.SWITCH_OFF
        knob.Position = state
            and UDim2.new(0, 24, 0.5, -9)
            or  UDim2.new(0, 2,  0.5, -9)
    end

    -- clickable area over track
    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = track
    clickBtn.MouseButton1Click:Connect(function()
        setState(not state)
        event:Fire(state)
    end)

    local obj = { event = event }
    function obj.set(v)
        setState(v == true)
    end

    setState(props.value == true)
    return obj
end

-- SLIDER
widgetBuilders["slider"] = function(parent, props)
    props = props or {}
    local minV   = props.min     or 0
    local maxV   = props.max     or 100
    local initV  = props.value   or minV
    local round  = props.rounding or 0
    local fillColor = props.color or THEME.SLIDER_FILL
    local width  = props.size    or nil  -- nil = full width

    local rowH = WIDGET_HEIGHT + 6
    local row = newFrame(parent, UDim2.new(1, 0, 0, rowH), nil, Color3.fromRGB(0,0,0), "SliderRow")
    row.BackgroundTransparency = 1

    -- label + value display
    local topRow = newFrame(row, UDim2.new(1, 0, 0, 16), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0), "TopRow")
    topRow.BackgroundTransparency = 1

    local lbl = newLabel(topRow, props.text or "Slider", THEME.LABEL_TEXT)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)

    local valLbl = newLabel(topRow, tostring(initV), THEME.ACCENT, TEXT_SIZE, FONT_BOLD, "ValLabel")
    valLbl.Size = UDim2.new(0.4, 0, 1, 0)
    valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    -- track
    local trackW = width and UDim2.new(0, width, 0, 6) or UDim2.new(1, 0, 0, 6)
    local track = newFrame(row, trackW, UDim2.new(0, 0, 0, rowH - 10), THEME.SLIDER_BG, "SliderTrack")
    applyCorner(track, 3)

    local fill = newFrame(track, UDim2.new(0, 0, 1, 0), UDim2.new(0,0,0,0), fillColor, "Fill")
    applyCorner(fill, 3)

    local knob = newFrame(track, UDim2.new(0, 12, 0, 12), UDim2.new(0, 0, 0.5, -6), Color3.fromRGB(240,240,240), "SliderKnob")
    applyCorner(knob, 6)

    local event = makeSignal()
    local currentVal = initV

    local function roundVal(v)
        local factor = 10 ^ round
        return math.floor(v * factor + 0.5) / factor
    end

    local function setVal(v)
        v = math.clamp(v, minV, maxV)
        currentVal = roundVal(v)
        local pct = (currentVal - minV) / (maxV - minV)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -6, 0.5, -6)
        valLbl.Text = tostring(currentVal)
    end

    setVal(initV)

    -- drag logic
    local dragging = false
    local dragBtn = Instance.new("TextButton")
    dragBtn.Size = UDim2.new(1,0,1,0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text = ""
    dragBtn.Parent = track

    local function updateFromInput(input)
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
        local newVal = minV + rel * (maxV - minV)
        setVal(newVal)
        event:Fire(currentVal)
    end

    dragBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    dragBtn.MouseButton1Click:Connect(function() end) -- catch clicks on track

    local obj = { event = event }
    function obj.set(v)
        setVal(v)
    end
    return obj
end

-- COLOR PICKER (RGB sliders)
widgetBuilders["color"] = function(parent, props)
    props = props or {}
    local initColor = props.color or Color3.new(1, 1, 1)
    local r, g, b = initColor.R, initColor.G, initColor.B

    local rowH = WIDGET_HEIGHT * 4 + 16
    local row = newFrame(parent, UDim2.new(1, 0, 0, rowH), nil, THEME.FOLDER_BG, "ColorRow")
    applyCorner(row, 4)

    local topRow = newFrame(row, UDim2.new(1, 0, 0, WIDGET_HEIGHT), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0), "ColorTop")
    topRow.BackgroundTransparency = 1

    local lbl = newLabel(topRow, props.text or "Color", THEME.LABEL_TEXT)
    lbl.Size = UDim2.new(0.7,0,1,0)

    local preview = newFrame(topRow, UDim2.new(0,24,0,24), UDim2.new(1,-28,0.5,-12), initColor, "ColorPreview")
    applyCorner(preview, 4)

    local event = makeSignal()
    local currentColor = initColor

    local channels = {
        {label="R", key="R", color=Color3.fromRGB(200,60,60)},
        {label="G", key="G", color=Color3.fromRGB(60,200,60)},
        {label="B", key="B", color=Color3.fromRGB(60,100,220)},
    }
    local vals = {R = r, G = g, B = b}

    local function updateColor()
        currentColor = Color3.new(vals.R, vals.G, vals.B)
        preview.BackgroundColor3 = currentColor
        event:Fire(currentColor)
    end

    for i, ch in ipairs(channels) do
        local subProps = {
            text = ch.label,
            color = ch.color,
            min = 0, max = 1,
            value = vals[ch.key],
            rounding = 2,
        }
        local subRow = newFrame(row, UDim2.new(1,-PADDING*2, 0, WIDGET_HEIGHT), UDim2.new(0,PADDING,0, WIDGET_HEIGHT * i + 4), Color3.fromRGB(0,0,0), ch.label.."Row")
        subRow.BackgroundTransparency = 1

        -- mini slider per channel
        local slider = widgetBuilders["slider"](subRow, subProps)
        slider.event:Connect(function(v)
            vals[ch.key] = v
            updateColor()
        end)
    end

    local obj = { event = event }
    function obj.set(c)
        vals.R, vals.G, vals.B = c.R, c.G, c.B
        updateColor()
    end
    return obj
end

-- DROPDOWN
widgetBuilders["dropdown"] = function(parent, props)
    props = props or {}
    local items = {}
    local selected = nil
    local isOpen = false

    local row = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, Color3.fromRGB(0,0,0), "DropdownRow")
    row.BackgroundTransparency = 1
    row.ClipsDescendants = false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = THEME.BUTTON
    btn.BorderSizePixel = 0
    btn.Text = props.text or "Dropdown"
    btn.TextColor3 = THEME.BUTTON_TEXT
    btn.TextSize = TEXT_SIZE
    btn.Font = FONT
    btn.AutoButtonColor = false
    btn.Parent = row
    applyCorner(btn, 4)
    hoverEffect(btn, THEME.BUTTON, THEME.BUTTON_HOVER)

    local arrow = newLabel(btn, "▼", THEME.TEXT_DIM, 10, FONT_BOLD, "Arrow")
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local stroke = Instance.new("UIStroke")
    stroke.Color = THEME.WIDGET_BORDER
    stroke.Thickness = 1
    stroke.Parent = btn

    -- dropdown panel (rendered above siblings via z-index trick)
    local panel = newFrame(row, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 1, 2), THEME.DROPDOWN_BG, "DropPanel")
    applyCorner(panel, 4)
    panel.ZIndex = 50
    panel.Visible = false
    panel.ClipsDescendants = true

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = THEME.SCROLLBAR
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = panel

    local layout = applyListLayout(scroll, Enum.FillDirection.Vertical, 0)

    local event = makeSignal()

    local function close()
        isOpen = false
        panel.Visible = false
        arrow.Text = "▼"
    end

    local function refreshPanel()
        scroll.CanvasSize = UDim2.new(0, 0, 0, #items * WIDGET_HEIGHT)
        local maxH = math.min(#items * WIDGET_HEIGHT + 4, 140)
        panel.Size = UDim2.new(1, 0, 0, maxH)
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        panel.Visible = isOpen
        arrow.Text = isOpen and "▲" or "▼"
        if isOpen then refreshPanel() end
    end)

    local obj = { event = event }

    function obj.new(name)
        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(1, 0, 0, WIDGET_HEIGHT)
        itemBtn.BackgroundColor3 = THEME.DROPDOWN_ITEM
        itemBtn.BorderSizePixel = 0
        itemBtn.Text = "  " .. tostring(name)
        itemBtn.TextColor3 = THEME.BUTTON_TEXT
        itemBtn.TextSize = TEXT_SIZE
        itemBtn.Font = FONT
        itemBtn.AutoButtonColor = false
        itemBtn.TextXAlignment = Enum.TextXAlignment.Left
        itemBtn.ZIndex = 51
        itemBtn.Parent = scroll
        hoverEffect(itemBtn, THEME.DROPDOWN_ITEM, THEME.DROPDOWN_HOVER)
        itemBtn.MouseButton1Click:Connect(function()
            selected = name
            btn.Text = tostring(name)
            close()
            event:Fire(name)
        end)
        items[#items+1] = name
        if isOpen then refreshPanel() end
    end

    function obj.set(name)
        btn.Text = tostring(name)
        selected = name
    end

    return obj
end

-- DOCK (horizontal row)
widgetBuilders["dock"] = function(parent, props)
    props = props or {}
    local row = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, Color3.fromRGB(0,0,0), "DockRow")
    row.BackgroundTransparency = 1

    local layout = applyListLayout(row, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local sizeHint = UDim2.new(0, 0, 1, 0)

    local obj = {}
    function obj.new(widgetType, wProps)
        wProps = wProps or {}
        -- dock children use fixed or fraction width
        local childSize = wProps.size and UDim2.new(0, wProps.size, 1, 0) or UDim2.new(0, 90, 1, 0)
        local container = newFrame(row, childSize, nil, Color3.fromRGB(0,0,0), "DockChild")
        container.BackgroundTransparency = 1
        local child = widgetBuilders[widgetType](container, wProps)
        return child
    end
    return obj
end

-- FOLDER (collapsible group)
widgetBuilders["folder"] = function(parent, props)
    props = props or {}
    local isOpen = false
    local children = {}

    local container = newFrame(parent, UDim2.new(1, 0, 0, WIDGET_HEIGHT), nil, THEME.FOLDER_BG, "FolderContainer")
    applyCorner(container, 4)
    container.ClipsDescendants = true

    -- header button
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, WIDGET_HEIGHT)
    header.BackgroundColor3 = THEME.FOLDER_HEADER
    header.BorderSizePixel = 0
    header.Text = ""
    header.AutoButtonColor = false
    header.Parent = container
    applyCorner(header, 4)

    local tri = newLabel(header, "▶", THEME.ACCENT, 10, FONT_BOLD, "Triangle")
    tri.Size = UDim2.new(0, 20, 1, 0)
    tri.Position = UDim2.new(0, 4, 0, 0)
    tri.TextXAlignment = Enum.TextXAlignment.Center

    local folderLbl = newLabel(header, props.text or "Folder", THEME.LABEL_TEXT)
    folderLbl.Size = UDim2.new(1, -28, 1, 0)
    folderLbl.Position = UDim2.new(0, 24, 0, 0)

    -- content area
    local content = newFrame(container, UDim2.new(1, -PADDING*2, 0, 0), UDim2.new(0, PADDING, 0, WIDGET_HEIGHT+2), THEME.FOLDER_BG, "FolderContent")
    content.BackgroundTransparency = 1
    local layout = applyListLayout(content, Enum.FillDirection.Vertical, 4)

    local function calcContentH()
        local h = 0
        for _, c in ipairs(content:GetChildren()) do
            if c:IsA("GuiObject") and c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
                h = h + c.AbsoluteSize.Y + 4
            end
        end
        return h
    end

    local function setOpen(v)
        isOpen = v
        tri.Text = isOpen and "▼" or "▶"
        if isOpen then
            local ch = calcContentH() + WIDGET_HEIGHT + 8
            container.Size = UDim2.new(1, 0, 0, ch)
            content.Size = UDim2.new(1, -PADDING*2, 0, ch - WIDGET_HEIGHT - 8)
        else
            container.Size = UDim2.new(1, 0, 0, WIDGET_HEIGHT)
        end
    end

    header.MouseButton1Click:Connect(function()
        setOpen(not isOpen)
    end)

    local obj = {}

    function obj.new(widgetType, wProps)
        local child = widgetBuilders[widgetType](content, wProps)
        -- reflow after add
        task.defer(function()
            if isOpen then setOpen(true) end
        end)
        return child
    end

    function obj.open()
        setOpen(true)
    end

    function obj.close()
        setOpen(false)
    end

    return obj
end

-- ─── SEPARATOR ───────────────────────────────────────────────────────────────
widgetBuilders["separator"] = function(parent, props)
    local row = newFrame(parent, UDim2.new(1, 0, 0, 1), nil, THEME.SEPARATOR, "Separator")
    return {}
end

-- ─── TAB SYSTEM ──────────────────────────────────────────────────────────────
local function createTab(tabBar, contentArea, tabProps)
    local tabName = tabProps.text or "Tab"

    -- tab button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 0, 1, 0)
    tabBtn.AutomaticSize = Enum.AutomaticSize.X
    tabBtn.BackgroundColor3 = THEME.TAB_IDLE
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = "  " .. tabName .. "  "
    tabBtn.TextColor3 = THEME.TAB_TEXT_IDLE
    tabBtn.TextSize = TEXT_SIZE
    tabBtn.Font = FONT_BOLD
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = tabBar
    applyCorner(tabBtn, 4)

    -- content scroll frame for this tab
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = THEME.SCROLLBAR
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = contentArea

    applyListLayout(scroll, Enum.FillDirection.Vertical, 4)
    applyPadding(scroll, PADDING, PADDING)

    local tab = {}

    function tab.new(widgetType, wProps)
        if not widgetBuilders[widgetType] then
            warn("rbimgui: unknown widget type '" .. tostring(widgetType) .. "'")
            return {}
        end
        return widgetBuilders[widgetType](scroll, wProps)
    end

    tab._btn = tabBtn
    tab._content = scroll
    return tab
end

-- ─── WINDOW ──────────────────────────────────────────────────────────────────
function rbimgui.new(windowProps)
    windowProps = windowProps or {}
    local title = windowProps.text or "Window"
    local winSize = windowProps.size or UDim2.new(0, 420, 0, 500)

    -- make absolute if UDim2 has scale-only or mixed
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "rbimgui_" .. title
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = game:GetService("CoreGui")

    -- main window frame
    local win = newFrame(screenGui, winSize, UDim2.new(0.5, -winSize.X.Offset/2, 0.5, -winSize.Y.Offset/2), THEME.BG, "Window")
    applyCorner(win, CORNER)
    win.ClipsDescendants = true

    -- drop shadow
    local shadow = newFrame(screenGui, UDim2.new(1,8,1,8), UDim2.new(0,-4,0,-4), Color3.fromRGB(0,0,0), "Shadow")
    shadow.BackgroundTransparency = 0.6
    applyCorner(shadow, CORNER + 2)
    shadow.ZIndex = win.ZIndex - 1
    shadow.Parent = win.Parent -- already parented above

    -- title bar
    local titleBar = newFrame(win, UDim2.new(1, 0, 0, 36), UDim2.new(0,0,0,0), THEME.TITLEBAR, "TitleBar")

    local titleLbl = newLabel(titleBar, title, Color3.fromRGB(220,220,220), TITLE_SIZE, FONT_BOLD, "Title")
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Position = UDim2.new(0, PADDING, 0, 0)

    -- close btn
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.TextSize = 12
    closeBtn.Font = FONT_BOLD
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    applyCorner(closeBtn, 14)
    hoverEffect(closeBtn, Color3.fromRGB(180,50,50), Color3.fromRGB(220,60,60))
    closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- tab bar
    local tabBarContainer = newFrame(win, UDim2.new(1, 0, 0, TAB_HEIGHT), UDim2.new(0,0,0,36), THEME.TITLEBAR, "TabBarContainer")
    local tabBar = newFrame(tabBarContainer, UDim2.new(1, -PADDING*2, 1, -8), UDim2.new(0,PADDING,0,4), Color3.fromRGB(0,0,0), "TabBar")
    tabBar.BackgroundTransparency = 1
    applyListLayout(tabBar, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    -- separator line
    local sep = newFrame(win, UDim2.new(1,0,0,1), UDim2.new(0,0,0,36+TAB_HEIGHT), THEME.SEPARATOR, "Sep")

    -- content area
    local contentArea = newFrame(win, UDim2.new(1,0,1,-(36+TAB_HEIGHT+1)), UDim2.new(0,0,0,36+TAB_HEIGHT+1), THEME.BG, "ContentArea")

    local tabs = {}
    local activeTab = nil

    local function activateTab(tab)
        if activeTab then
            activeTab._btn.BackgroundColor3 = THEME.TAB_IDLE
            activeTab._btn.TextColor3 = THEME.TAB_TEXT_IDLE
            activeTab._content.Visible = false
        end
        activeTab = tab
        tab._btn.BackgroundColor3 = THEME.TAB_ACTIVE
        tab._btn.TextColor3 = THEME.TAB_TEXT_ACTIVE
        tab._content.Visible = true
    end

    local window = {}

    function window.new(tabProps)
        local tab = createTab(tabBar, contentArea, tabProps)
        tab._btn.MouseButton1Click:Connect(function()
            activateTab(tab)
        end)
        tabs[#tabs+1] = tab
        if #tabs == 1 then activateTab(tab) end
        return tab
    end

    function window.open()
        win.Visible = true
    end

    function window.close()
        win.Visible = false
    end

    function window.destroy()
        screenGui:Destroy()
    end

    win.Visible = false
    return window
end

return rbimgui
