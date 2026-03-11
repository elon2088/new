-- KingVonHook UI Library | By Vlone
-- Returns: Library API
-- loadstring(game:HttpGet("RAW_URL"))()

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Library = {}
Library.__index = Library

-- ─────────────────────────────────────────────────────────
-- INTERNAL HELPERS
-- ─────────────────────────────────────────────────────────

local function New(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function Corner(p, r) return New("UICorner", {CornerRadius=UDim.new(0,r)}, p) end
local function Stroke(p, c, t) return New("UIStroke", {Color=c, Thickness=t}, p) end

local function Draggable(frame, handle)
	local dragging, ds, sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, ds, sp = true, i.Position, frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- ─────────────────────────────────────────────────────────
-- CONFIG SYSTEM
-- ─────────────────────────────────────────────────────────

local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem
ConfigSystem.Folder = "KingVonHook"
ConfigSystem.Ext = ".kvh"

function ConfigSystem:Init()
	if not isfolder(self.Folder) then makefolder(self.Folder) end
end

function ConfigSystem:Save(name, data)
	local encoded = game:GetService("HttpService"):JSONEncode(data)
	writefile(self.Folder .. "/" .. name .. self.Ext, encoded)
end

function ConfigSystem:Load(name)
	local path = self.Folder .. "/" .. name .. self.Ext
	if isfile(path) then
		local ok, decoded = pcall(function()
			return game:GetService("HttpService"):JSONDecode(readfile(path))
		end)
		return ok and decoded or nil
	end
	return nil
end

function ConfigSystem:Delete(name)
	local path = self.Folder .. "/" .. name .. self.Ext
	if isfile(path) then delfile(path) end
end

function ConfigSystem:List()
	local files = listfiles(self.Folder)
	local names = {}
	for _, f in ipairs(files) do
		local name = f:match("([^/\\]+)" .. self.Ext .. "$")
		if name then table.insert(names, name) end
	end
	return names
end

-- ─────────────────────────────────────────────────────────
-- LIBRARY CONSTRUCTOR
-- ─────────────────────────────────────────────────────────

function Library.new(config)
	config = config or {}
	local self = setmetatable({}, Library)
	self.Tabs       = {}
	self.TabMap     = {}
	self.ActiveTab  = nil
	self.ActiveBtn  = nil
	self.Flags      = {}    -- stores all toggle/slider/dropdown values by key
	self.Config     = ConfigSystem
	self.Config:Init()

	local sg = New("ScreenGui", {
		Name="KingVonHook", ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
	})
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then
		sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	self.ScreenGui = sg

	local main = New("Frame", {
		Name="MainFrame",
		Size=UDim2.new(0,900,0,620),
		Position=UDim2.new(0.5,-450,0.5,-310),
		BackgroundColor3=Color3.fromRGB(8,8,8),
		BorderSizePixel=0, Active=true,
	}, sg)
	Corner(main,4); Stroke(main, Color3.fromRGB(35,35,35), 1)
	self.MainFrame = main

	-- Title bar
	local tbar = New("Frame", {
		Size=UDim2.new(1,0,0,30),
		BackgroundColor3=Color3.fromRGB(8,8,8),
		BorderSizePixel=0,
	}, main)
	New("Frame", {
		Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(32,32,32), BorderSizePixel=0,
	}, tbar)
	New("TextLabel", {
		Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,10,0,0),
		BackgroundTransparency=1,
		Text=config.Title or "KINGVONHOOK (Bypass) By Vlone",
		TextColor3=Color3.fromRGB(160,160,160), TextSize=12,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left,
	}, tbar)
	Draggable(main, tbar)

	-- Tab wrapper
	local tw = New("Frame", {
		Size=UDim2.new(1,-16,0,34), Position=UDim2.new(0,8,0,32),
		BackgroundTransparency=1,
	}, main)
	local tc = New("Frame", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1}, tw)
	New("UIListLayout", {
		FillDirection=Enum.FillDirection.Horizontal,
		SortOrder=Enum.SortOrder.LayoutOrder,
		Padding=UDim.new(0,6),
	}, tc)
	self.TabContainer = tc

	local utrack = New("Frame", {
		Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(30,30,30), BorderSizePixel=0,
	}, tw)
	local uline = New("Frame", {
		Size=UDim2.new(0,60,0,1),
		BackgroundColor3=Color3.fromRGB(210,210,210),
		BorderSizePixel=0, ZIndex=2,
	}, utrack)
	self.TabUnderline  = uline
	self.UnderlineTrack = utrack

	-- Content frame
	local cf = New("Frame", {
		Size=UDim2.new(1,-16,1,-82), Position=UDim2.new(0,8,0,74),
		BackgroundColor3=Color3.fromRGB(10,10,10),
		BorderSizePixel=0, ClipsDescendants=true,
	}, main)
	Corner(cf,4); Stroke(cf, Color3.fromRGB(32,32,32), 1)
	self.ContentFrame = cf

	if config.BackgroundId then
		New("ImageLabel", {
			Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
			Image="rbxassetid://"..tostring(config.BackgroundId),
			ScaleType=Enum.ScaleType.Stretch,
			ImageTransparency=config.ImageTransparency or 0.3,
			ZIndex=1,
		}, cf)
	end

	-- Auto-add R.I.P. VON tab
	self:_AddRipTab()

	return self
end

-- ─────────────────────────────────────────────────────────
-- INTERNAL: RIP TAB (always present, always last)
-- ─────────────────────────────────────────────────────────

function Library:_AddRipTab()
	local tab = self:_CreateTabFrame("R.I.P. VON", true)

	local function Lbl(text, color, size, y)
		New("TextLabel", {
			Size=UDim2.new(1,-20,0,22), Position=UDim2.new(0,12,0,y),
			BackgroundTransparency=1, Text=text,
			TextColor3=color, TextSize=size, Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,
			TextWrapped=true, ZIndex=3,
		}, tab.Page)
	end

	Lbl("R.I.P. KING VON",                                    Color3.fromRGB(195,0,0),    13, 12)
	Lbl("Rest in Peace to the legendary rapper King Von.",     Color3.fromRGB(155,155,155),12, 38)
	Lbl("This cheat is dedicated to his memory.",              Color3.fromRGB(155,155,155),12, 58)
	Lbl("2020 - Forever",                                      Color3.fromRGB(90,90,90),   12, 90)
end

-- ─────────────────────────────────────────────────────────
-- INTERNAL: TAB FRAME FACTORY
-- ─────────────────────────────────────────────────────────

function Library:_CreateTabFrame(tabName, noPanels)
	local btn = New("TextButton", {
		Name=tabName,
		Size=UDim2.new(0,64,1,0),
		BackgroundTransparency=1, BorderSizePixel=0,
		Text=tabName,
		TextColor3=Color3.fromRGB(120,120,120),
		TextSize=11, Font=Enum.Font.Code,
		LayoutOrder=#self.Tabs+1,
		AutoButtonColor=false,
	}, self.TabContainer)

	local page = New("Frame", {
		Name=tabName, Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1, Visible=false, ZIndex=2,
	}, self.ContentFrame)

	local tab = {Name=tabName, Button=btn, Page=page, LeftPanel=nil, RightPanel=nil}

	if not noPanels then
		New("Frame", {
			Size=UDim2.new(0,1,1,-10), Position=UDim2.new(0.5,0,0,5),
			BackgroundColor3=Color3.fromRGB(35,35,35), BorderSizePixel=0, ZIndex=2,
		}, page)
		tab.LeftPanel = New("Frame", {
			Size=UDim2.new(0.5,-8,1,0),
			BackgroundTransparency=1, ZIndex=2, ClipsDescendants=true,
		}, page)
		tab.RightPanel = New("Frame", {
			Size=UDim2.new(0.5,-8,1,0), Position=UDim2.new(0.5,8,0,0),
			BackgroundTransparency=1, ZIndex=2, ClipsDescendants=true,
		}, page)
	end

	table.insert(self.Tabs, tab)
	self.TabMap[tabName] = tab

	btn.MouseButton1Click:Connect(function() self:SetActiveTab(tabName) end)
	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tabName then
			btn.TextColor3 = Color3.fromRGB(165,165,165)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tabName then
			btn.TextColor3 = Color3.fromRGB(120,120,120)
		end
	end)

	return tab
end

-- ─────────────────────────────────────────────────────────
-- PUBLIC: ADD TAB  (inserts before R.I.P. VON)
-- ─────────────────────────────────────────────────────────

function Library:AddTab(tabName)
	-- Remove & re-add RIP btn so it stays last
	local ripTab = self.TabMap["R.I.P. VON"]
	if ripTab then
		ripTab.Button.LayoutOrder = 999
	end

	local tab = self:_CreateTabFrame(tabName, false)
	tab.Button.LayoutOrder = #self.Tabs - 1 -- before RIP

	return tab
end

-- ─────────────────────────────────────────────────────────
-- PUBLIC: SET ACTIVE TAB
-- ─────────────────────────────────────────────────────────

function Library:SetActiveTab(tabName)
	if self.ActiveBtn then
		self.ActiveBtn.TextColor3 = Color3.fromRGB(120,120,120)
	end
	local tab = self.TabMap[tabName]
	if not tab then return end

	tab.Button.TextColor3 = tabName == "R.I.P. VON"
		and Color3.fromRGB(200,60,60)
		or  Color3.fromRGB(220,220,220)

	self.ActiveTab = tabName
	self.ActiveBtn = tab.Button

	task.defer(function()
		self.TabUnderline.Size     = UDim2.new(0, tab.Button.AbsoluteSize.X, 0, 1)
		self.TabUnderline.Position = UDim2.new(0,
			tab.Button.AbsolutePosition.X - self.TabContainer.AbsolutePosition.X, 0, 0)
	end)

	for _, t in ipairs(self.Tabs) do
		t.Page.Visible = t.Name == tabName
	end
end

-- ─────────────────────────────────────────────────────────
-- WIDGETS
-- ─────────────────────────────────────────────────────────

function Library:MakeSectionHeader(parent, leftText, rightText, yPos, zIdx)
	local h = New("Frame", {
		Size=UDim2.new(1,-16,0,22), Position=UDim2.new(0,8,0,yPos),
		BackgroundTransparency=1, ZIndex=zIdx,
	}, parent)
	New("TextLabel", {
		Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1,
		Text=leftText, TextColor3=Color3.fromRGB(160,160,160),
		TextSize=11, Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zIdx,
	}, h)
	if rightText and rightText ~= "" then
		New("TextLabel", {
			Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
			BackgroundTransparency=1, Text=rightText,
			TextColor3=Color3.fromRGB(160,160,160), TextSize=11,
			Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=zIdx,
		}, h)
	end
	New("Frame", {
		Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(45,45,45), BorderSizePixel=0, ZIndex=zIdx,
	}, h)
end

function Library:MakeToggle(parent, labelText, yPos, zIdx, flagKey, callback)
	local row = New("Frame", {
		Size=UDim2.new(1,-16,0,28), Position=UDim2.new(0,8,0,yPos),
		BackgroundTransparency=1, ZIndex=zIdx,
	}, parent)
	local box = New("Frame", {
		Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,0,0.5,-8),
		BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0, ZIndex=zIdx,
	}, row)
	Corner(box,2); Stroke(box, Color3.fromRGB(70,70,70), 1)
	local check = New("TextLabel", {
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Text="", TextColor3=Color3.fromRGB(100,200,100),
		TextSize=12, Font=Enum.Font.Code, ZIndex=zIdx+1,
	}, box)
	New("TextLabel", {
		Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,24,0,0),
		BackgroundTransparency=1, Text=labelText,
		TextColor3=Color3.fromRGB(175,175,175), TextSize=11,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zIdx,
	}, row)

	local enabled = false
	if flagKey then self.Flags[flagKey] = false end

	local btn = New("TextButton", {
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Text="", ZIndex=zIdx+2,
	}, row)
	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		check.Text = enabled and "✓" or ""
		if flagKey then self.Flags[flagKey] = enabled end
		if callback then callback(enabled) end
	end)

	local api = {}
	function api:Set(v)
		enabled = v
		check.Text = enabled and "✓" or ""
		if flagKey then self.Flags[flagKey] = enabled end
		if callback then callback(enabled) end
	end
	function api:Get() return enabled end

	return row, api
end

function Library:MakeSlider(parent, labelText, minVal, maxVal, defaultVal, yPos, zIdx, flagKey, callback)
	local cont = New("Frame", {
		Size=UDim2.new(1,-16,0,38), Position=UDim2.new(0,8,0,yPos),
		BackgroundTransparency=1, ZIndex=zIdx,
	}, parent)
	New("TextLabel", {
		Size=UDim2.new(0.6,0,0,16), BackgroundTransparency=1,
		Text=labelText, TextColor3=Color3.fromRGB(140,140,140),
		TextSize=10, Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zIdx,
	}, cont)
	local valLbl = New("TextLabel", {
		Size=UDim2.new(0.4,0,0,16), Position=UDim2.new(0.6,0,0,0),
		BackgroundTransparency=1, Text=tostring(defaultVal),
		TextColor3=Color3.fromRGB(140,140,140), TextSize=10,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=zIdx,
	}, cont)
	local track = New("Frame", {
		Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,20),
		BackgroundColor3=Color3.fromRGB(30,30,30), BorderSizePixel=0, ZIndex=zIdx,
	}, cont)
	Corner(track,4); Stroke(track, Color3.fromRGB(55,55,55), 1)

	local pct0 = (defaultVal-minVal)/(maxVal-minVal)
	local fill = New("Frame", {
		Size=UDim2.new(pct0,0,1,0),
		BackgroundColor3=Color3.fromRGB(180,180,180), BorderSizePixel=0, ZIndex=zIdx+1,
	}, track)
	Corner(fill,4)
	local knob = New("Frame", {
		Size=UDim2.new(0,10,0,10), Position=UDim2.new(pct0,0,0.5,-5),
		AnchorPoint=Vector2.new(0.5,0),
		BackgroundColor3=Color3.fromRGB(220,220,220), BorderSizePixel=0, ZIndex=zIdx+2,
	}, track)
	Corner(knob,5)
	local hitbox = New("TextButton", {
		Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,-7),
		BackgroundTransparency=1, Text="", ZIndex=zIdx+3,
	}, track)

	local current = defaultVal
	if flagKey then self.Flags[flagKey] = current end

	local dragging = false
	local function update(x)
		local p = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(p,0,1,0)
		knob.Position = UDim2.new(p,0,0.5,-5)
		current = math.floor((minVal+(maxVal-minVal)*p)*10+0.5)/10
		valLbl.Text = tostring(current)
		if flagKey then self.Flags[flagKey] = current end
		if callback then callback(current) end
	end

	hitbox.MouseButton1Down:Connect(function() dragging = true end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	local api = {}
	function api:Set(v)
		current = math.clamp(v, minVal, maxVal)
		local p = (current-minVal)/(maxVal-minVal)
		fill.Size = UDim2.new(p,0,1,0)
		knob.Position = UDim2.new(p,0,0.5,-5)
		valLbl.Text = tostring(current)
		if flagKey then self.Flags[flagKey] = current end
		if callback then callback(current) end
	end
	function api:Get() return current end

	return cont, api
end

-- ─────────────────────────────────────────────────────────
-- DROPDOWN
-- ─────────────────────────────────────────────────────────

function Library:MakeDropdown(parent, labelText, options, yPos, zIdx, flagKey, callback)
	local HEIGHT   = 26
	local ITEM_H   = 22
	local openRef  = {value = false}

	local wrapper = New("Frame", {
		Size=UDim2.new(1,-16,0,HEIGHT), Position=UDim2.new(0,8,0,yPos),
		BackgroundTransparency=1, ZIndex=zIdx, ClipsDescendants=false,
	}, parent)

	-- Label above
	New("TextLabel", {
		Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,-15),
		BackgroundTransparency=1, Text=labelText,
		TextColor3=Color3.fromRGB(130,130,130), TextSize=10,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zIdx,
	}, wrapper)

	local selected = options[1] or ""
	if flagKey then self.Flags[flagKey] = selected end

	-- Main button
	local mainBtn = New("TextButton", {
		Size=UDim2.new(1,0,0,HEIGHT),
		BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0,
		Text="", AutoButtonColor=false, ZIndex=zIdx,
	}, wrapper)
	Corner(mainBtn,3); Stroke(mainBtn, Color3.fromRGB(55,55,55), 1)

	local selLbl = New("TextLabel", {
		Size=UDim2.new(1,-26,1,0), Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1, Text=selected,
		TextColor3=Color3.fromRGB(185,185,185), TextSize=11,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zIdx+1,
	}, mainBtn)
	local arrow = New("TextLabel", {
		Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-22,0,0),
		BackgroundTransparency=1, Text="▾",
		TextColor3=Color3.fromRGB(120,120,120), TextSize=12,
		Font=Enum.Font.Code, ZIndex=zIdx+1,
	}, mainBtn)

	-- Dropdown list (rendered above siblings via high ZIndex)
	local listFrame = New("Frame", {
		Size=UDim2.new(1,0,0,#options*ITEM_H+4),
		Position=UDim2.new(0,0,1,2),
		BackgroundColor3=Color3.fromRGB(16,16,16),
		BorderSizePixel=0, Visible=false, ZIndex=zIdx+10,
	}, wrapper)
	Corner(listFrame,3); Stroke(listFrame, Color3.fromRGB(55,55,55), 1)

	for idx, opt in ipairs(options) do
		local item = New("TextButton", {
			Size=UDim2.new(1,0,0,ITEM_H),
			Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),
			BackgroundTransparency=1, BorderSizePixel=0,
			Text=opt, TextColor3=Color3.fromRGB(165,165,165),
			TextSize=11, Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,
			AutoButtonColor=false, ZIndex=zIdx+11,
		}, listFrame)
		New("UIPadding", {PaddingLeft=UDim.new(0,8)}, item)

		item.MouseEnter:Connect(function() item.BackgroundTransparency = 0; item.BackgroundColor3 = Color3.fromRGB(28,28,28) end)
		item.MouseLeave:Connect(function() item.BackgroundTransparency = 1 end)
		item.MouseButton1Click:Connect(function()
			selected = opt
			selLbl.Text = opt
			if flagKey then self.Flags[flagKey] = opt end
			if callback then callback(opt) end
			listFrame.Visible = false
			openRef.value = false
			arrow.Text = "▾"
		end)
	end

	mainBtn.MouseButton1Click:Connect(function()
		openRef.value = not openRef.value
		listFrame.Visible = openRef.value
		arrow.Text = openRef.value and "▴" or "▾"
	end)

	local api = {}
	function api:Get() return selected end
	function api:Set(v)
		selected = v; selLbl.Text = v
		if flagKey then self.Flags[flagKey] = v end
		if callback then callback(v) end
	end
	function api:Refresh(newOptions)
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		listFrame.Size = UDim2.new(1,0,0,#newOptions*ITEM_H+4)
		for idx, opt in ipairs(newOptions) do
			local item = New("TextButton", {
				Size=UDim2.new(1,0,0,ITEM_H),
				Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),
				BackgroundTransparency=1, BorderSizePixel=0,
				Text=opt, TextColor3=Color3.fromRGB(165,165,165),
				TextSize=11, Font=Enum.Font.Code,
				TextXAlignment=Enum.TextXAlignment.Left,
				AutoButtonColor=false, ZIndex=zIdx+11,
			}, listFrame)
			New("UIPadding", {PaddingLeft=UDim.new(0,8)}, item)
			item.MouseEnter:Connect(function() item.BackgroundTransparency=0; item.BackgroundColor3=Color3.fromRGB(28,28,28) end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
			item.MouseButton1Click:Connect(function()
				selected=opt; selLbl.Text=opt
				if flagKey then self.Flags[flagKey]=opt end
				if callback then callback(opt) end
				listFrame.Visible=false; openRef.value=false; arrow.Text="▾"
			end)
		end
	end

	return wrapper, api
end

-- ─────────────────────────────────────────────────────────
-- CONFIG TAB (built-in)
-- ─────────────────────────────────────────────────────────

function Library:_BuildConfigTab(tab)
	local lp = tab.LeftPanel
	local rp = tab.RightPanel

	self:MakeSectionHeader(lp, "SAVE CONFIG", "", 8, 3)

	-- Config name input box
	local inputBox = New("TextBox", {
		Size=UDim2.new(1,-16,0,26), Position=UDim2.new(0,8,0,36),
		BackgroundColor3=Color3.fromRGB(18,18,18), BorderSizePixel=0,
		Text="", PlaceholderText="Config name...",
		TextColor3=Color3.fromRGB(185,185,185),
		PlaceholderColor3=Color3.fromRGB(80,80,80),
		TextSize=11, Font=Enum.Font.Code,
		ClearTextOnFocus=false, ZIndex=3,
	}, lp)
	Corner(inputBox,3); Stroke(inputBox, Color3.fromRGB(55,55,55), 1)
	New("UIPadding", {PaddingLeft=UDim.new(0,8)}, inputBox)

	-- Save button
	local saveBtn = New("TextButton", {
		Size=UDim2.new(1,-16,0,26), Position=UDim2.new(0,8,0,68),
		BackgroundColor3=Color3.fromRGB(22,22,22), BorderSizePixel=0,
		Text="SAVE CONFIG", TextColor3=Color3.fromRGB(180,180,180),
		TextSize=11, Font=Enum.Font.Code, AutoButtonColor=false, ZIndex=3,
	}, lp)
	Corner(saveBtn,3); Stroke(saveBtn, Color3.fromRGB(55,55,55), 1)

	self:MakeSectionHeader(rp, "LOAD / DELETE", "", 8, 3)

	-- Config list dropdown
	local _, ddApi = self:MakeDropdown(rp, "Select Config", self.Config:List(), 40, 3, nil, nil)
	self._configDropdown = ddApi

	-- Refresh list helper
	local function refreshList()
		ddApi:Refresh(self.Config:List())
	end

	-- Load button
	local loadBtn = New("TextButton", {
		Size=UDim2.new(1,-16,0,26), Position=UDim2.new(0,8,0,84),
		BackgroundColor3=Color3.fromRGB(22,22,22), BorderSizePixel=0,
		Text="LOAD CONFIG", TextColor3=Color3.fromRGB(180,180,180),
		TextSize=11, Font=Enum.Font.Code, AutoButtonColor=false, ZIndex=3,
	}, rp)
	Corner(loadBtn,3); Stroke(loadBtn, Color3.fromRGB(55,55,55), 1)

	-- Delete button
	local delBtn = New("TextButton", {
		Size=UDim2.new(1,-16,0,26), Position=UDim2.new(0,8,0,116),
		BackgroundColor3=Color3.fromRGB(22,22,22), BorderSizePixel=0,
		Text="DELETE CONFIG", TextColor3=Color3.fromRGB(180,80,80),
		TextSize=11, Font=Enum.Font.Code, AutoButtonColor=false, ZIndex=3,
	}, rp)
	Corner(delBtn,3); Stroke(delBtn, Color3.fromRGB(80,40,40), 1)

	-- Status label
	local statusLbl = New("TextLabel", {
		Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,8,0,148),
		BackgroundTransparency=1, Text="",
		TextColor3=Color3.fromRGB(100,200,100), TextSize=10,
		Font=Enum.Font.Code, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
	}, rp)

	local function setStatus(msg, color)
		statusLbl.Text = msg
		statusLbl.TextColor3 = color or Color3.fromRGB(100,200,100)
		task.delay(3, function() statusLbl.Text = "" end)
	end

	-- Hover effects
	for _, b in ipairs({saveBtn, loadBtn, delBtn}) do
		b.MouseEnter:Connect(function() b.BackgroundColor3 = Color3.fromRGB(28,28,28) end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = Color3.fromRGB(22,22,22) end)
	end

	saveBtn.MouseButton1Click:Connect(function()
		local name = inputBox.Text
		if name == "" then setStatus("Enter a config name.", Color3.fromRGB(200,80,80)) return end
		self.Config:Save(name, self.Flags)
		refreshList()
		setStatus("Saved: " .. name)
	end)

	loadBtn.MouseButton1Click:Connect(function()
		local name = ddApi:Get()
		if not name or name == "" then setStatus("No config selected.", Color3.fromRGB(200,80,80)) return end
		local data = self.Config:Load(name)
		if not data then setStatus("Failed to load.", Color3.fromRGB(200,80,80)) return end
		for k, v in pairs(data) do
			self.Flags[k] = v
			if self._flagApis and self._flagApis[k] then
				self._flagApis[k]:Set(v)
			end
		end
		setStatus("Loaded: " .. name)
	end)

	delBtn.MouseButton1Click:Connect(function()
		local name = ddApi:Get()
		if not name or name == "" then setStatus("No config selected.", Color3.fromRGB(200,80,80)) return end
		self.Config:Delete(name)
		refreshList()
		setStatus("Deleted: " .. name, Color3.fromRGB(200,80,80))
	end)
end

-- ─────────────────────────────────────────────────────────
-- PUBLIC: ADD CONFIG TAB
-- ─────────────────────────────────────────────────────────

function Library:AddConfigTab()
	local tab = self:AddTab("Config")
	self._flagApis = self._flagApis or {}
	self:_BuildConfigTab(tab)
	return tab
end

-- Register a widget API so config load can call :Set()
function Library:RegisterFlag(key, api)
	self._flagApis = self._flagApis or {}
	self._flagApis[key] = api
end

function Library:Destroy()
	self.ScreenGui:Destroy()
end

return Library
