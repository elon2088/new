-- KingVonHook UI Library | By elon

local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HTTP    = game:GetService("HttpService")
local RUN     = game:GetService("RunService")
local TweenS  = game:GetService("TweenService")

local Library = {}
Library.__index = Library

-- ─────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────

local function New(class, props, parent)
	local i = Instance.new(class)
	for k,v in pairs(props) do i[k]=v end
	if parent then i.Parent=parent end
	return i
end
local function Corner(p,r) New("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function Stroke(p,c,t) New("UIStroke",{Color=c,Thickness=t},p) end

local function Tween(obj, props, t)
	TweenS:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function Draggable(frame, handle)
	local drag,ds,sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag,ds,sp=true,i.Position,frame.Position end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-ds
			frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)
end

-- HSV helpers
local function HSVtoRGB(h,s,v)
	if s==0 then return Color3.new(v,v,v) end
	local i=math.floor(h*6)%6; local f=h*6-math.floor(h*6)
	local p,q,t2=v*(1-s),v*(1-s*f),v*(1-s*(1-f))
	local r,g,b
	if i==0 then r,g,b=v,t2,p elseif i==1 then r,g,b=q,v,p
	elseif i==2 then r,g,b=p,v,t2 elseif i==3 then r,g,b=p,q,v
	elseif i==4 then r,g,b=t2,p,v elseif i==5 then r,g,b=v,p,q end
	return Color3.new(r,g,b)
end
local function RGBtoHSV(c)
	local r,g,b=c.R,c.G,c.B
	local mx=math.max(r,g,b); local mn=math.min(r,g,b); local d=mx-mn
	local h,s,v=0,0,mx
	if mx~=0 then s=d/mx end
	if d~=0 then
		if mx==r then h=(g-b)/d%6
		elseif mx==g then h=(b-r)/d+2
		else h=(r-g)/d+4 end
		h=h/6
	end
	return h,s,v
end
local function colorToTable(c) return {R=math.floor(c.R*255),G=math.floor(c.G*255),B=math.floor(c.B*255)} end
local function tableToColor(t)
	if type(t)=="table" and t.R then return Color3.fromRGB(t.R,t.G,t.B) end
	return Color3.new(1,1,1)
end

-- ─────────────────────────────────────────────────────────
-- CONFIG SYSTEM
-- ─────────────────────────────────────────────────────────

local ConfigSystem = {Folder="KingVonHook", Ext=".kvh"}
ConfigSystem.__index = ConfigSystem

function ConfigSystem:Init()
	if not isfolder(self.Folder) then makefolder(self.Folder) end
end
function ConfigSystem:Save(name, data)
	local out={}
	for k,v in pairs(data) do
		if type(v)=="userdata" then out[k]=colorToTable(v)
		else out[k]=v end
	end
	writefile(self.Folder.."/"..name..self.Ext, HTTP:JSONEncode(out))
end
function ConfigSystem:Load(name)
	local path=self.Folder.."/"..name..self.Ext
	if not isfile(path) then return nil end
	local ok,v=pcall(function() return HTTP:JSONDecode(readfile(path)) end)
	return ok and v or nil
end
function ConfigSystem:Delete(name)
	local path=self.Folder.."/"..name..self.Ext
	if isfile(path) then delfile(path) end
end
function ConfigSystem:List()
	local out={}
	for _,f in ipairs(listfiles(self.Folder)) do
		local n=f:match("([^/\\]+)"..self.Ext.."$")
		if n then table.insert(out,n) end
	end
	return out
end

-- ─────────────────────────────────────────────────────────
-- POPUP MANAGER
-- Popups live in a full-screen overlay above everything.
-- Only one popup can be open at a time.
-- Clicking outside closes all popups.
-- ─────────────────────────────────────────────────────────

local PopupManager = {}
PopupManager._open = nil
PopupManager._overlay = nil

function PopupManager:Init(sg)
	if self._overlay and self._overlay.Parent then return end
	self._overlay = New("Frame",{
		Name="KVH_Overlay", Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1, ZIndex=500,
	}, sg)
	-- Invisible full screen button to catch outside clicks
	local bg = New("TextButton",{
		Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Text="", ZIndex=499,
	}, sg)
	bg.MouseButton1Click:Connect(function()
		self:CloseAll()
	end)
end

function PopupManager:Open(popup, anchorFrame)
	-- Close previous
	if self._open and self._open ~= popup then
		self._open.Visible = false
		self._open = nil
	end

	-- Reparent to overlay so it's never clipped
	popup.Parent = self._overlay

	-- Position below anchor
	local ax = anchorFrame.AbsolutePosition.X
	local ay = anchorFrame.AbsolutePosition.Y + anchorFrame.AbsoluteSize.Y + 3
	local pw = popup.Size.X.Offset
	local ph = popup.Size.Y.Offset
	local sw = self._overlay.AbsoluteSize.X
	local sh = self._overlay.AbsoluteSize.Y
	if ax + pw > sw then ax = sw - pw - 4 end
	if ay + ph > sh then ay = anchorFrame.AbsolutePosition.Y - ph - 3 end
	popup.Position = UDim2.new(0, ax, 0, ay)

	-- Smooth open
	popup.Visible = true
	popup.BackgroundTransparency = 1
	Tween(popup, {BackgroundTransparency=0}, 0.12)
	local children = popup:GetDescendants()
	for _,c in ipairs(children) do
		if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("Frame") then
			if c.BackgroundTransparency < 1 then
				local target = c.BackgroundTransparency
				c.BackgroundTransparency = 1
				Tween(c, {BackgroundTransparency=target}, 0.12)
			end
		end
	end

	self._open = popup
end

function PopupManager:Close(popup)
	if popup then
		popup.Visible = false
		if self._open == popup then self._open = nil end
	end
end

function PopupManager:CloseAll()
	if self._open then
		self._open.Visible = false
		self._open = nil
	end
end

-- ─────────────────────────────────────────────────────────
-- LIBRARY CONSTRUCTOR
-- ─────────────────────────────────────────────────────────

function Library.new(config)
	config = config or {}
	local self = setmetatable({}, Library)
	self.Tabs={}; self.TabMap={}; self.ActiveTab=nil; self.ActiveBtn=nil
	self.Flags={}; self._flagApis={}
	-- BindList stores {label, keyRef, toggleRef, enabled}
	self._binds = {}
	self.Config = setmetatable({}, ConfigSystem)
	self.Config:Init()

	local sg = New("ScreenGui",{Name="KingVonHook",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	pcall(function() sg.Parent = game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	self.ScreenGui = sg

	PopupManager:Init(sg)
	self.Popup = PopupManager

	-- Main frame
	local main = New("Frame",{
		Name="MainFrame", Size=UDim2.new(0,900,0,620),
		Position=UDim2.new(0.5,-450,0.5,-310),
		BackgroundColor3=Color3.fromRGB(8,8,8), BorderSizePixel=0, Active=true,
	}, sg)
	Corner(main,4); Stroke(main, Color3.fromRGB(35,35,35), 1)
	self.MainFrame = main

	-- Title bar
	local tbar = New("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},main)
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(32,32,32),BorderSizePixel=0},tbar)
	New("TextLabel",{
		Size=UDim2.new(0.6,0,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
		Text=config.Title or "KINGVONHOOK (Bypass) By Vlone",
		TextColor3=Color3.fromRGB(160,160,160),TextSize=12,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,
	},tbar)
	Draggable(main, tbar)

	-- ── Watermark (right side of title bar) ──
	-- Floating bar inspired by reference: "KingVonHook | fps | ping | time"
	local wmFrame = New("Frame",{
		Size=UDim2.new(0,360,0,22),
		Position=UDim2.new(1,-370,0.5,-11),
		BackgroundColor3=Color3.fromRGB(5,5,5),
		BorderSizePixel=0,
	},tbar)
	Corner(wmFrame,3)
	-- Red border stroke on watermark
	local wmStroke = New("UIStroke",{Color=Color3.fromRGB(160,0,0),Thickness=1},wmFrame)
	self.WatermarkFrame = wmFrame
	self.WatermarkStroke = wmStroke

	self.WatermarkLabel = New("TextLabel",{
		Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,6,0,0),
		BackgroundTransparency=1,
		Text="KingVonHook | fps: -- | ping: -- | time: --:--:--",
		TextColor3=Color3.fromRGB(200,200,200),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,
	},wmFrame)

	-- Rotating black→red gradient on watermark border
	local wmGrad = New("UIGradient",{
		Color=ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(160,0,0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30,0,0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160,0,0)),
		}),
		Rotation=0,
	}, wmStroke)
	self._wmRot = 0
	RUN.Heartbeat:Connect(function(dt)
		self._wmRot = (self._wmRot + dt*40)%360
		wmGrad.Rotation = self._wmRot
		-- Update FPS / ping / time in watermark
		local fps = math.floor(1/dt)
		local ping = math.floor(Players.LocalPlayer:GetNetworkPing()*1000)
		local t = os.date("*t")
		local timeStr = string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
		self.WatermarkLabel.Text = string.format(
			"KingVonHook | fps: %d | ping: %dms | time: %s",
			fps, ping, timeStr
		)
	end)

	-- Tab wrapper
	local tw = New("Frame",{Size=UDim2.new(1,-16,0,34),Position=UDim2.new(0,8,0,32),BackgroundTransparency=1},main)
	local tc = New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},tw)
	New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},tc)
	self.TabContainer = tc

	local utrack = New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0},tw)
	self.TabUnderline = New("Frame",{Size=UDim2.new(0,60,0,1),BackgroundColor3=Color3.fromRGB(210,210,210),BorderSizePixel=0,ZIndex=2},utrack)

	-- Content frame
	local cf = New("Frame",{
		Size=UDim2.new(1,-16,1,-82),Position=UDim2.new(0,8,0,74),
		BackgroundColor3=Color3.fromRGB(10,10,10),BorderSizePixel=0,ClipsDescendants=true,
	},main)
	Corner(cf,4); Stroke(cf,Color3.fromRGB(32,32,32),1)
	self.ContentFrame = cf

	if config.BackgroundId then
		New("ImageLabel",{
			Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Image="rbxassetid://"..tostring(config.BackgroundId),
			ScaleType=Enum.ScaleType.Stretch,
			ImageTransparency=config.ImageTransparency or 0.3,ZIndex=1,
		},cf)
	end

	self:_AddRipTab()
	return self
end

function Library:SetWatermark(text) if self.WatermarkLabel then self.WatermarkLabel.Text=text end end

-- ─────────────────────────────────────────────────────────
-- R.I.P. VON TAB
-- ─────────────────────────────────────────────────────────

function Library:_AddRipTab()
	local tab = self:_CreateTabFrame("R.I.P. VON",true)
	local function L(txt,col,sz,y)
		New("TextLabel",{Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,12,0,y),BackgroundTransparency=1,
			Text=txt,TextColor3=col,TextSize=sz,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=3},tab.Page)
	end
	L("R.I.P. KING VON",                                 Color3.fromRGB(195,0,0),    13,12)
	L("Rest in Peace to the legendary rapper King Von.", Color3.fromRGB(155,155,155),12,38)
	L("This cheat is dedicated to his memory.",          Color3.fromRGB(155,155,155),12,58)
	L("2020 - Forever",                                  Color3.fromRGB(90,90,90),   12,90)
end

-- ─────────────────────────────────────────────────────────
-- TAB FRAME FACTORY
-- ─────────────────────────────────────────────────────────

function Library:_CreateTabFrame(tabName, noPanels)
	local btn = New("TextButton",{
		Name=tabName, Size=UDim2.new(0,64,1,0), BackgroundTransparency=1, BorderSizePixel=0,
		Text=tabName, TextColor3=Color3.fromRGB(120,120,120), TextSize=11, Font=Enum.Font.Code,
		LayoutOrder=#self.Tabs+1, AutoButtonColor=false,
	},self.TabContainer)

	local page = New("Frame",{
		Name=tabName, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=2,
	},self.ContentFrame)

	local tab = {Name=tabName, Button=btn, Page=page, LeftPanel=nil, RightPanel=nil}

	if not noPanels then
		New("Frame",{Size=UDim2.new(0,1,1,-10),Position=UDim2.new(0.5,0,0,5),
			BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0,ZIndex=2},page)
		tab.LeftPanel  = New("Frame",{Size=UDim2.new(0.5,-8,1,0),
			BackgroundTransparency=1,ZIndex=2,ClipsDescendants=false},page)
		tab.RightPanel = New("Frame",{Size=UDim2.new(0.5,-8,1,0),Position=UDim2.new(0.5,8,0,0),
			BackgroundTransparency=1,ZIndex=2,ClipsDescendants=false},page)
	end

	table.insert(self.Tabs,tab); self.TabMap[tabName]=tab
	btn.MouseButton1Click:Connect(function() self:SetActiveTab(tabName) end)
	btn.MouseEnter:Connect(function() if self.ActiveTab~=tabName then btn.TextColor3=Color3.fromRGB(165,165,165) end end)
	btn.MouseLeave:Connect(function() if self.ActiveTab~=tabName then btn.TextColor3=Color3.fromRGB(120,120,120) end end)
	return tab
end

function Library:AddTab(tabName)
	local rip = self.TabMap["R.I.P. VON"]
	if rip then rip.Button.LayoutOrder=999 end
	local tab = self:_CreateTabFrame(tabName, false)
	tab.Button.LayoutOrder = #self.Tabs-1
	return tab
end

function Library:SetActiveTab(tabName)
	if self.ActiveBtn then self.ActiveBtn.TextColor3=Color3.fromRGB(120,120,120) end
	local tab = self.TabMap[tabName]; if not tab then return end
	tab.Button.TextColor3 = tabName=="R.I.P. VON" and Color3.fromRGB(200,60,60) or Color3.fromRGB(220,220,220)
	self.ActiveTab=tabName; self.ActiveBtn=tab.Button
	task.defer(function()
		self.TabUnderline.Size     = UDim2.new(0,tab.Button.AbsoluteSize.X,0,1)
		self.TabUnderline.Position = UDim2.new(0,tab.Button.AbsolutePosition.X-self.TabContainer.AbsolutePosition.X,0,0)
	end)
	for _,t in ipairs(self.Tabs) do t.Page.Visible = t.Name==tabName end
end

-- ─────────────────────────────────────────────────────────
-- SECTION HEADER
-- ─────────────────────────────────────────────────────────

function Library:MakeSectionHeader(parent,leftText,rightText,yPos,zIdx)
	local h=New("Frame",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(0.6,0,1,0),BackgroundTransparency=1,Text=leftText,TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},h)
	if rightText and rightText~="" then
		New("TextLabel",{Size=UDim2.new(0.4,0,1,0),Position=UDim2.new(0.6,0,0,0),BackgroundTransparency=1,Text=rightText,TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=zIdx},h)
	end
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(45,45,45),BorderSizePixel=0,ZIndex=zIdx},h)
end

-- ─────────────────────────────────────────────────────────
-- TOGGLE  (with optional key bind shown inline)
-- ─────────────────────────────────────────────────────────

function Library:MakeToggle(parent,labelText,yPos,zIdx,flagKey,callback)
	local row = New("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	local box = New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=zIdx},row)
	Corner(box,2); Stroke(box,Color3.fromRGB(70,70,70),1)
	local check = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(100,200,100),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1},box)
	local lbl = New("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)

	-- Key bind display (right side, shown if key is set)
	local keyTag = New("TextLabel",{
		Size=UDim2.new(0,50,0,16),Position=UDim2.new(1,-54,0.5,-8),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,
		Text="",TextColor3=Color3.fromRGB(200,200,100),TextSize=9,Font=Enum.Font.Code,
		Visible=false,ZIndex=zIdx+1,
	},row)
	Corner(keyTag,2); Stroke(keyTag,Color3.fromRGB(50,50,50),1)

	local enabled=false
	if flagKey then self.Flags[flagKey]=false end

	local hitbox=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=zIdx+2},row)
	hitbox.MouseButton1Click:Connect(function()
		enabled=not enabled
		check.Text=enabled and "✓" or ""
		if flagKey then self.Flags[flagKey]=enabled end
		if callback then callback(enabled) end
	end)

	local api={}
	function api:Set(v)
		enabled=v; check.Text=enabled and "✓" or ""
		if flagKey then self.Flags[flagKey]=enabled end
		if callback then callback(enabled) end
	end
	function api:Get() return enabled end
	function api:SetKey(keyName)
		keyTag.Text="["..keyName.."]"; keyTag.Visible=true
		-- shrink label to not overlap
		lbl.Size=UDim2.new(1,-80,1,0)
	end
	return row,api
end

-- ─────────────────────────────────────────────────────────
-- SLIDER
-- ─────────────────────────────────────────────────────────

function Library:MakeSlider(parent,labelText,minVal,maxVal,defaultVal,yPos,zIdx,flagKey,callback)
	local cont=New("Frame",{Size=UDim2.new(1,-16,0,38),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(0.6,0,0,16),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(140,140,140),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},cont)
	local valLbl=New("TextLabel",{Size=UDim2.new(0.4,0,0,16),Position=UDim2.new(0.6,0,0,0),BackgroundTransparency=1,Text=tostring(defaultVal),TextColor3=Color3.fromRGB(140,140,140),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=zIdx},cont)
	local track=New("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,0,20),BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,ZIndex=zIdx},cont)
	Corner(track,4); Stroke(track,Color3.fromRGB(55,55,55),1)
	local p0=(defaultVal-minVal)/(maxVal-minVal)
	local fill=New("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=Color3.fromRGB(180,180,180),BorderSizePixel=0,ZIndex=zIdx+1},track); Corner(fill,4)
	local knob=New("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(p0,0,0.5,-5),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.fromRGB(220,220,220),BorderSizePixel=0,ZIndex=zIdx+2},track); Corner(knob,5)
	local hitbox=New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-7),BackgroundTransparency=1,Text="",ZIndex=zIdx+3},track)
	local current=defaultVal; if flagKey then self.Flags[flagKey]=current end
	local drag=false
	local function upd(x)
		local p=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
		fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,-5)
		current=math.floor((minVal+(maxVal-minVal)*p)*10+0.5)/10
		valLbl.Text=tostring(current)
		if flagKey then self.Flags[flagKey]=current end
		if callback then callback(current) end
	end
	hitbox.MouseButton1Down:Connect(function() drag=true end)
	UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	local api={}
	function api:Set(v)
		current=math.clamp(v,minVal,maxVal); local p=(current-minVal)/(maxVal-minVal)
		fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,-5); valLbl.Text=tostring(current)
		if flagKey then self.Flags[flagKey]=current end; if callback then callback(current) end
	end
	function api:Get() return current end
	return cont,api
end

-- ─────────────────────────────────────────────────────────
-- DROPDOWN  (fixed: popup in overlay, correct selection)
-- ─────────────────────────────────────────────────────────

function Library:MakeDropdown(parent,labelText,options,yPos,zIdx,flagKey,callback)
	local ITEM_H=22

	local wrapper=New("Frame",{
		Size=UDim2.new(1,-16,0,26), Position=UDim2.new(0,8,0,yPos),
		BackgroundTransparency=1, ZIndex=zIdx,
	},parent)

	if labelText and labelText~="" then
		New("TextLabel",{
			Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,-14),
			BackgroundTransparency=1,Text=labelText,
			TextColor3=Color3.fromRGB(120,120,120),TextSize=10,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx,
		},wrapper)
	end

	local selected = options[1] or ""
	if flagKey then self.Flags[flagKey]=selected end

	local mainBtn=New("TextButton",{
		Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),
		BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx,
	},wrapper)
	Corner(mainBtn,3); Stroke(mainBtn,Color3.fromRGB(55,55,55),1)

	local selLbl=New("TextLabel",{
		Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
		Text=selected,TextColor3=Color3.fromRGB(185,185,185),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx+1,
	},mainBtn)
	local arrow=New("TextLabel",{
		Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,
		Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1,
	},mainBtn)

	-- List popup lives in overlay (built once, repositioned on open)
	local listFrame=New("Frame",{
		Size=UDim2.new(0,200,0,#options*ITEM_H+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=502,
	}, PopupManager._overlay or self.ScreenGui)
	Corner(listFrame,3); Stroke(listFrame,Color3.fromRGB(55,55,55),1)

	local function buildItems(opts)
		for _,c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
		end
		listFrame.Size = UDim2.new(0, 200, 0, #opts*ITEM_H+4)
		for idx,opt in ipairs(opts) do
			local item=New("TextButton",{
				Size=UDim2.new(1,0,0,ITEM_H),
				Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),
				BackgroundTransparency=1,BorderSizePixel=0,
				Text=opt,TextColor3=Color3.fromRGB(165,165,165),
				TextSize=11,Font=Enum.Font.Code,
				TextXAlignment=Enum.TextXAlignment.Left,
				AutoButtonColor=false,ZIndex=503,
			},listFrame)
			New("UIPadding",{PaddingLeft=UDim.new(0,8)},item)
			item.MouseEnter:Connect(function()
				item.BackgroundTransparency=0
				item.BackgroundColor3=Color3.fromRGB(28,28,28)
			end)
			item.MouseLeave:Connect(function()
				item.BackgroundTransparency=1
			end)
			-- FIX: use a closure that captures `opt` correctly
			local capturedOpt = opt
			item.MouseButton1Click:Connect(function()
				selected=capturedOpt
				selLbl.Text=capturedOpt
				if flagKey then self.Flags[flagKey]=capturedOpt end
				if callback then callback(capturedOpt) end
				PopupManager:Close(listFrame)
				arrow.Text="▾"
			end)
		end
	end
	buildItems(options)

	mainBtn.MouseButton1Click:Connect(function()
		if listFrame.Visible then
			PopupManager:Close(listFrame)
			arrow.Text="▾"
		else
			listFrame.Size=UDim2.new(0,mainBtn.AbsoluteSize.X>10 and mainBtn.AbsoluteSize.X or 200,0,listFrame.Size.Y.Offset)
			PopupManager:Open(listFrame, mainBtn)
			arrow.Text="▴"
		end
	end)

	-- Arrow sync when popup is closed externally
	RUN.Heartbeat:Connect(function()
		if not listFrame.Visible and arrow.Text=="▴" then arrow.Text="▾" end
	end)

	local api={}
	function api:Get() return selected end
	function api:Set(v) selected=v; selLbl.Text=v; if flagKey then self.Flags[flagKey]=v end; if callback then callback(v) end end
	function api:Refresh(newOpts) buildItems(newOpts) end
	return wrapper,api
end

-- ─────────────────────────────────────────────────────────
-- MULTI-DROPDOWN
-- ─────────────────────────────────────────────────────────

function Library:MakeMultiDropdown(parent,labelText,options,yPos,zIdx,flagKey,callback)
	local ITEM_H=22
	local wrapper=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	if labelText and labelText~="" then
		New("TextLabel",{Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,-14),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(120,120,120),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},wrapper)
	end
	local selected={}; if flagKey then self.Flags[flagKey]={} end
	local mainBtn=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx},wrapper)
	Corner(mainBtn,3); Stroke(mainBtn,Color3.fromRGB(55,55,55),1)
	local selLbl=New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="None",TextColor3=Color3.fromRGB(185,185,185),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx+1},mainBtn)
	local arrow=New("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1},mainBtn)

	local function updateLabel()
		local keys={}; for k in pairs(selected) do table.insert(keys,k) end
		selLbl.Text=#keys==0 and "None" or table.concat(keys,", ")
	end

	local listFrame=New("Frame",{
		Size=UDim2.new(0,200,0,#options*ITEM_H+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=502,
	}, PopupManager._overlay or self.ScreenGui)
	Corner(listFrame,3); Stroke(listFrame,Color3.fromRGB(55,55,55),1)

	local checkMarks={}
	for idx,opt in ipairs(options) do
		local item=New("Frame",{Size=UDim2.new(1,0,0,ITEM_H),Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),BackgroundTransparency=1,ZIndex=502},listFrame)
		local chk=New("TextLabel",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,6,0.5,-7),BackgroundColor3=Color3.fromRGB(18,18,18),Text="",TextColor3=Color3.fromRGB(100,200,100),TextSize=10,Font=Enum.Font.Code,BorderSizePixel=0,ZIndex=503},item)
		Corner(chk,2); Stroke(chk,Color3.fromRGB(70,70,70),1)
		New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,26,0,0),BackgroundTransparency=1,Text=opt,TextColor3=Color3.fromRGB(165,165,165),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=502},item)
		local hitbox=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=504},item)
		checkMarks[opt]=chk
		hitbox.MouseEnter:Connect(function() item.BackgroundTransparency=0; item.BackgroundColor3=Color3.fromRGB(22,22,22) end)
		hitbox.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
		local capturedOpt=opt
		hitbox.MouseButton1Click:Connect(function()
			if selected[capturedOpt] then selected[capturedOpt]=nil; chk.Text=""
			else selected[capturedOpt]=true; chk.Text="✓" end
			updateLabel()
			local arr={}; for k in pairs(selected) do table.insert(arr,k) end
			if flagKey then self.Flags[flagKey]=arr end
			if callback then callback(arr) end
		end)
	end

	mainBtn.MouseButton1Click:Connect(function()
		if listFrame.Visible then PopupManager:Close(listFrame); arrow.Text="▾"
		else listFrame.Size=UDim2.new(0,mainBtn.AbsoluteSize.X>10 and mainBtn.AbsoluteSize.X or 200,0,listFrame.Size.Y.Offset); PopupManager:Open(listFrame,mainBtn); arrow.Text="▴" end
	end)
	RUN.Heartbeat:Connect(function() if not listFrame.Visible and arrow.Text=="▴" then arrow.Text="▾" end end)

	local api={}
	function api:Get() local a={}; for k in pairs(selected) do table.insert(a,k) end return a end
	function api:Set(arr) selected={}; for _,v in ipairs(arr) do selected[v]=true; if checkMarks[v] then checkMarks[v].Text="✓" end end; updateLabel() end
	return wrapper,api
end

-- ─────────────────────────────────────────────────────────
-- COLOR PICKER  (fixed: stopPropagation so clicks inside don't close)
-- ─────────────────────────────────────────────────────────

function Library:MakeColorPicker(parent,labelText,defaultColor,yPos,zIdx,flagKey,callback)
	defaultColor = defaultColor or Color3.new(1,0,0)
	local hue,sat,val = RGBtoHSV(defaultColor)
	local alpha = 1
	if flagKey then self.Flags[flagKey]=colorToTable(defaultColor) end

	local row=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,-36,1,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)
	local preview=New("TextButton",{Size=UDim2.new(0,24,0,18),Position=UDim2.new(1,-28,0.5,-9),BackgroundColor3=defaultColor,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx+1},row)
	Corner(preview,3); Stroke(preview,Color3.fromRGB(70,70,70),1)

	local PW,PH = 224,236

	-- Picker panel (lives in overlay permanently — only visibility toggles)
	local picker=New("Frame",{
		Size=UDim2.new(0,PW,0,PH),
		BackgroundColor3=Color3.fromRGB(14,14,14),
		BorderSizePixel=0, Visible=false, ZIndex=502,
	}, PopupManager._overlay or self.ScreenGui)
	Corner(picker,5); Stroke(picker,Color3.fromRGB(50,50,50),1)

	-- CRITICAL FIX: Stop clicks inside picker from propagating to the overlay bg button
	local blocker=New("TextButton",{
		Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=501,
	},picker)
	blocker.MouseButton1Click:Connect(function() end) -- consume click

	-- Hue+Sat gradient (the uploaded color wheel image)
	local satBox=New("ImageButton",{
		Size=UDim2.new(1,-16,0,110),Position=UDim2.new(0,8,0,8),
		BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,
		Image="rbxassetid://2529273",AutoButtonColor=false,ZIndex=503,
	},picker)
	Corner(satBox,3)

	local satCursor=New("Frame",{
		Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=505,
	},satBox); Corner(satCursor,5); Stroke(satCursor,Color3.fromRGB(0,0,0),1)

	-- Value slider
	local valTrack=New("Frame",{Size=UDim2.new(1,-16,0,10),Position=UDim2.new(0,8,0,126),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=503},picker)
	Corner(valTrack,3)
	New("UIGradient",{Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(1,1,1)),Rotation=0},valTrack)
	local valKnob=New("Frame",{Size=UDim2.new(0,10,1,4),Position=UDim2.new(val,0,0,-2),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=504},valTrack)
	Corner(valKnob,2); Stroke(valKnob,Color3.fromRGB(0,0,0),1)
	local valHitbox=New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-4),BackgroundTransparency=1,Text="",ZIndex=506},valTrack)

	-- Alpha slider
	local alphaTrack=New("Frame",{Size=UDim2.new(1,-16,0,10),Position=UDim2.new(0,8,0,146),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=503},picker)
	Corner(alphaTrack,3)
	New("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=0},alphaTrack)
	local alphaKnob=New("Frame",{Size=UDim2.new(0,10,1,4),Position=UDim2.new(1,0,0,-2),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=504},alphaTrack)
	Corner(alphaKnob,2); Stroke(alphaKnob,Color3.fromRGB(0,0,0),1)
	local alphaHitbox=New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-4),BackgroundTransparency=1,Text="",ZIndex=506},alphaTrack)

	-- Labels
	New("TextLabel",{Size=UDim2.new(0.5,0,0,12),Position=UDim2.new(0,8,0,158),BackgroundTransparency=1,Text="Brightness",TextColor3=Color3.fromRGB(90,90,90),TextSize=9,Font=Enum.Font.Code,ZIndex=503},picker)
	New("TextLabel",{Size=UDim2.new(0.5,0,0,12),Position=UDim2.new(0.5,0,0,158),BackgroundTransparency=1,Text="Opacity",TextColor3=Color3.fromRGB(90,90,90),TextSize=9,Font=Enum.Font.Code,ZIndex=503},picker)

	-- Hex input
	local hexBox=New("TextBox",{
		Size=UDim2.new(1,-48,0,22),Position=UDim2.new(0,8,0,172),
		BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0,
		Text=string.format("%02X%02X%02X",math.floor(defaultColor.R*255),math.floor(defaultColor.G*255),math.floor(defaultColor.B*255)),
		PlaceholderText="RRGGBB",TextColor3=Color3.fromRGB(200,200,200),
		PlaceholderColor3=Color3.fromRGB(80,80,80),TextSize=11,Font=Enum.Font.Code,
		ClearTextOnFocus=false,ZIndex=503,
	},picker)
	Corner(hexBox,3); Stroke(hexBox,Color3.fromRGB(50,50,50),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,6)},hexBox)

	-- Swatch inside picker
	local swatch=New("Frame",{Size=UDim2.new(0,32,0,22),Position=UDim2.new(1,-40,0,172),BackgroundColor3=defaultColor,BorderSizePixel=0,ZIndex=503},picker)
	Corner(swatch,3); Stroke(swatch,Color3.fromRGB(50,50,50),1)

	local function getColor() return HSVtoRGB(hue,sat,val) end
	local function updateUI()
		local c=getColor()
		preview.BackgroundColor3=c; swatch.BackgroundColor3=c
		hexBox.Text=string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
		valKnob.Position=UDim2.new(val,0,0,-2)
		alphaKnob.Position=UDim2.new(alpha,0,0,-2)
		satCursor.Position=UDim2.new(hue,0,1-sat,0)
		-- Tint satBox background to show current hue column
		satBox.BackgroundColor3=HSVtoRGB(hue,1,1)
		if flagKey then self.Flags[flagKey]=colorToTable(c) end
		if callback then callback(c,alpha) end
	end

	-- Drags
	local satDrag,valDrag,alphaDrag=false,false,false
	satBox.MouseButton1Down:Connect(function() satDrag=true end)
	valHitbox.MouseButton1Down:Connect(function() valDrag=true end)
	alphaHitbox.MouseButton1Down:Connect(function() alphaDrag=true end)

	UIS.InputChanged:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
		if satDrag then
			hue=math.clamp((i.Position.X-satBox.AbsolutePosition.X)/satBox.AbsoluteSize.X,0,0.9999)
			sat=1-math.clamp((i.Position.Y-satBox.AbsolutePosition.Y)/satBox.AbsoluteSize.Y,0,1)
			updateUI()
		elseif valDrag then
			val=math.clamp((i.Position.X-valTrack.AbsolutePosition.X)/valTrack.AbsoluteSize.X,0,1)
			updateUI()
		elseif alphaDrag then
			alpha=math.clamp((i.Position.X-alphaTrack.AbsolutePosition.X)/alphaTrack.AbsoluteSize.X,0,1)
			updateUI()
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then satDrag=false; valDrag=false; alphaDrag=false end
	end)

	hexBox.FocusLost:Connect(function()
		local hex=hexBox.Text:gsub("[^%x]",""):sub(1,6)
		if #hex==6 then
			hue,sat,val=RGBtoHSV(Color3.new(tonumber(hex:sub(1,2),16)/255,tonumber(hex:sub(3,4),16)/255,tonumber(hex:sub(5,6),16)/255))
			updateUI()
		end
	end)

	preview.MouseButton1Click:Connect(function()
		if picker.Visible then
			PopupManager:Close(picker)
		else
			PopupManager:Open(picker, preview)
		end
	end)

	updateUI()

	local api={}
	function api:Get() return getColor(),alpha end
	function api:Set(c,a)
		hue,sat,val=RGBtoHSV(c); alpha=a or 1; updateUI()
	end
	return row,api
end

-- ─────────────────────────────────────────────────────────
-- KEY PICKER  (fixed: toggles state, updates BindList correctly)
-- ─────────────────────────────────────────────────────────

function Library:MakeKeyPicker(parent,labelText,defaultKey,yPos,zIdx,flagKey,callback)
	defaultKey = defaultKey or Enum.KeyCode.Unknown
	local current=defaultKey; local listening=false
	-- Find or create entry in bind list
	local bindEntry = {Label=labelText, Key=defaultKey==Enum.KeyCode.Unknown and "NONE" or defaultKey.Name, Enabled=false}
	table.insert(self._binds, bindEntry)

	if flagKey then self.Flags[flagKey]=bindEntry.Key end

	local row=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,-80,1,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)
	local keyBtn=New("TextButton",{
		Size=UDim2.new(0,72,0,20),Position=UDim2.new(1,-76,0.5,-10),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,
		Text=bindEntry.Key,TextColor3=Color3.fromRGB(180,180,180),
		TextSize=10,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=zIdx+1,
	},row)
	Corner(keyBtn,3); Stroke(keyBtn,Color3.fromRGB(55,55,55),1)

	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening=true; keyBtn.Text="..."; keyBtn.TextColor3=Color3.fromRGB(200,200,100)
	end)

	UIS.InputBegan:Connect(function(i)
		if not listening then return end
		if i.UserInputType==Enum.UserInputType.Keyboard then
			listening=false; current=i.KeyCode
			local keyName=current.Name
			keyBtn.Text=keyName; keyBtn.TextColor3=Color3.fromRGB(180,180,180)
			bindEntry.Key=keyName
			if flagKey then self.Flags[flagKey]=keyName end
			if callback then callback(current) end
		end
	end)

	-- Toggle fire: press the key to toggle the toggle it's linked to
	local linkedToggle=nil
	UIS.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==current then
			if linkedToggle then linkedToggle:Set(not linkedToggle:Get()) end
		end
	end)

	local api={}
	function api:Get() return current end
	function api:Set(k)
		if type(k)=="string" then
			current=Enum.KeyCode[k] or Enum.KeyCode.Unknown
		else current=k end
		bindEntry.Key=current.Name; keyBtn.Text=current.Name
		if flagKey then self.Flags[flagKey]=current.Name end
	end
	function api:LinkToggle(toggleApi) linkedToggle=toggleApi end
	return row,api
end

-- ─────────────────────────────────────────────────────────
-- KEYBIND LIST  (fixed: smooth expand/collapse, no duplicates)
-- ─────────────────────────────────────────────────────────

function Library:CreateKeybindList()
	local win=New("Frame",{
		Name="KeybindList", Size=UDim2.new(0,190,0,24),
		Position=UDim2.new(1,-200,1,-50),
		BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0, ZIndex=50,
	},self.ScreenGui)
	Corner(win,4); Stroke(win,Color3.fromRGB(40,40,40),1)

	-- Red-black gradient border (matches watermark style)
	local winGrad=New("UIGradient",{
		Color=ColorSequence.new({
			ColorSequenceKeypoint.new(0,Color3.fromRGB(140,0,0)),
			ColorSequenceKeypoint.new(0.5,Color3.fromRGB(25,0,0)),
			ColorSequenceKeypoint.new(1,Color3.fromRGB(140,0,0)),
		}),Rotation=0,
	},win:FindFirstChildOfClass("UIStroke") or Stroke(win,Color3.fromRGB(140,0,0),1))

	-- Header
	local header=New("Frame",{
		Size=UDim2.new(1,0,0,20),BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0,ZIndex=51,
	},win)
	Corner(header,4)
	-- Fix bottom corners
	New("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0,ZIndex=51},header)
	New("TextLabel",{
		Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
		Text="[X] Keybinds",TextColor3=Color3.fromRGB(180,180,180),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52,
	},header)

	local list=New("Frame",{
		Size=UDim2.new(1,0,1,-22),Position=UDim2.new(0,0,0,22),
		BackgroundTransparency=1,ZIndex=51,ClipsDescendants=true,
	},win)
	local layout=New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},list)

	Draggable(win,header)
	self._bindListWindow=win
	self._bindListRows={}

	-- Update on Heartbeat but only rebuild when bind count changes
	local lastCount=-1
	local rot=0
	RUN.Heartbeat:Connect(function(dt)
		-- Rotate border gradient
		rot=(rot+dt*35)%360
		local s=win:FindFirstChildOfClass("UIStroke")
		if s then
			local g=s:FindFirstChildOfClass("UIGradient")
			if g then g.Rotation=rot end
		end

		local binds=self._binds
		if #binds==lastCount then return end
		lastCount=#binds

		-- Clear old rows
		for _,c in ipairs(list:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end

		-- Build rows
		for i,b in ipairs(binds) do
			local row=New("Frame",{
				Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,ZIndex=52,LayoutOrder=i,
			},list)
			New("TextLabel",{
				Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,
				Text="["..b.Key.."] "..b.Label,TextColor3=Color3.fromRGB(160,160,160),
				TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52,
			},row)
		end

		-- Smooth size tween
		local targetH=22+#binds*19+4
		Tween(win,{Size=UDim2.new(0,190,0,targetH)},0.15)
	end)

	return win
end

-- ─────────────────────────────────────────────────────────
-- CONFIG TAB  (redesigned to match reference screenshot)
-- Shows: Config Name input, file list, Create/Save/Load/Delete buttons
-- ─────────────────────────────────────────────────────────

function Library:_BuildConfigTab(tab)
	-- Use full page (not split panels) for config
	tab.LeftPanel.Size=UDim2.new(1,0,1,0)
	tab.RightPanel.Visible=false
	-- Hide divider
	for _,c in ipairs(tab.Page:GetChildren()) do
		if c:IsA("Frame") and c.Size.X.Offset==1 then c.Visible=false end
	end

	local p=tab.LeftPanel

	-- Title header
	self:MakeSectionHeader(p,"Config Management","",8,3)

	-- Config name input
	New("TextLabel",{
		Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,36),
		BackgroundTransparency=1,Text="Config Name",
		TextColor3=Color3.fromRGB(120,120,120),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3,
	},p)
	local inputBox=New("TextBox",{
		Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,52),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,
		Text="",PlaceholderText="Enter config name...",
		TextColor3=Color3.fromRGB(185,185,185),PlaceholderColor3=Color3.fromRGB(70,70,70),
		TextSize=11,Font=Enum.Font.Code,ClearTextOnFocus=false,ZIndex=3,
	},p)
	Corner(inputBox,3); Stroke(inputBox,Color3.fromRGB(45,45,45),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,8)},inputBox)

	-- Config file list display
	local listBox=New("Frame",{
		Size=UDim2.new(1,-16,0,140),Position=UDim2.new(0,8,0,84),
		BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0,ZIndex=3,
		ClipsDescendants=true,
	},p)
	Corner(listBox,3); Stroke(listBox,Color3.fromRGB(40,40,40),1)

	local listLayout=New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},listBox)
	local selectedConfig=nil
	local configRowMap={}

	local statusLbl=New("TextLabel",{
		Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,374),
		BackgroundTransparency=1,Text="Manage configs above",
		TextColor3=Color3.fromRGB(80,80,80),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3,
	},p)

	local function setStatus(msg,col)
		statusLbl.Text=msg; statusLbl.TextColor3=col or Color3.fromRGB(100,200,100)
		task.delay(3,function() if statusLbl.Parent then statusLbl.Text="Manage configs above"; statusLbl.TextColor3=Color3.fromRGB(80,80,80) end end)
	end

	local function refreshList()
		-- Clear
		for _,c in ipairs(listBox:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		configRowMap={}
		selectedConfig=nil
		local names=self.Config:List()
		for i,name in ipairs(names) do
			local row=New("TextButton",{
				Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,BorderSizePixel=0,
				Text=name..".cfg",TextColor3=Color3.fromRGB(110,110,220),TextSize=11,Font=Enum.Font.Code,
				TextXAlignment=Enum.TextXAlignment.Center,AutoButtonColor=false,ZIndex=4,LayoutOrder=i,
			},listBox)
			configRowMap[name]=row
			row.MouseButton1Click:Connect(function()
				-- Deselect all
				for _,r in pairs(configRowMap) do r.BackgroundTransparency=1; r.TextColor3=Color3.fromRGB(110,110,220) end
				-- Select this
				selectedConfig=name
				row.BackgroundTransparency=0; row.BackgroundColor3=Color3.fromRGB(22,22,35)
				row.TextColor3=Color3.fromRGB(140,140,255)
				inputBox.Text=name
			end)
			row.MouseEnter:Connect(function() if selectedConfig~=name then row.BackgroundTransparency=0; row.BackgroundColor3=Color3.fromRGB(18,18,28) end end)
			row.MouseLeave:Connect(function() if selectedConfig~=name then row.BackgroundTransparency=1 end end)
		end
	end
	refreshList()

	-- Buttons
	local btnData={
		{y=232, text="Create Config", col=Color3.fromRGB(35,35,35), action=function()
			local name=inputBox.Text
			if name=="" then setStatus("Enter a config name.",Color3.fromRGB(200,80,80)) return end
			if self.Config:Load(name) then setStatus("Config already exists.",Color3.fromRGB(200,80,80)) return end
			self.Config:Save(name,{})
			refreshList(); setStatus("Created: "..name)
		end},
		{y=264, text="Save Config", col=Color3.fromRGB(35,35,35), action=function()
			local name=inputBox.Text
			if name=="" then setStatus("Enter a config name.",Color3.fromRGB(200,80,80)) return end
			self.Config:Save(name,self.Flags)
			refreshList(); setStatus("Saved: "..name)
		end},
		{y=296, text="Load Config", col=Color3.fromRGB(35,35,35), action=function()
			local name=selectedConfig or inputBox.Text
			if not name or name=="" then setStatus("Select or enter a config name.",Color3.fromRGB(200,80,80)) return end
			local data=self.Config:Load(name)
			if not data then setStatus("Config not found.",Color3.fromRGB(200,80,80)) return end
			for k,v in pairs(data) do
				self.Flags[k]=v
				if self._flagApis[k] then
					if type(v)=="table" and v.R then self._flagApis[k]:Set(tableToColor(v))
					else pcall(function() self._flagApis[k]:Set(v) end) end
				end
			end
			setStatus("Loaded: "..name)
		end},
		{y=328, text="Delete Config", col=Color3.fromRGB(35,22,22), action=function()
			local name=selectedConfig or inputBox.Text
			if not name or name=="" then setStatus("Select a config to delete.",Color3.fromRGB(200,80,80)) return end
			self.Config:Delete(name)
			refreshList(); setStatus("Deleted: "..name,Color3.fromRGB(200,80,80))
		end},
	}

	for _,bd in ipairs(btnData) do
		local btn=New("TextButton",{
			Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,bd.y),
			BackgroundColor3=bd.col,BorderSizePixel=0,
			Text=bd.text,TextColor3=Color3.fromRGB(175,175,175),
			TextSize=11,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=3,
		},p)
		Corner(btn,3); Stroke(btn,Color3.fromRGB(50,50,50),1)
		btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=Color3.fromRGB(bd.col.R*255+12,bd.col.G*255+10,bd.col.B*255+12)},0.1) end)
		btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=bd.col},0.1) end)
		btn.MouseButton1Click:Connect(bd.action)
	end
end

function Library:AddConfigTab()
	local tab=self:AddTab("Config")
	self:_BuildConfigTab(tab)
	return tab
end

function Library:RegisterFlag(key,api)
	self._flagApis[key]=api
end

function Library:Destroy()
	self.ScreenGui:Destroy()
end

return Library
