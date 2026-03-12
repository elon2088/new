-- KingVonHook UI Library | By Vlone

local UIS    = game:GetService("UserInputService")
local Players= game:GetService("Players")
local HTTP   = game:GetService("HttpService")
local RUN    = game:GetService("RunService")
local TweenS = game:GetService("TweenService")

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
local function Stroke(p,c,t) return New("UIStroke",{Color=c,Thickness=t},p) end
local function Tween(obj,props,t)
	TweenS:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end
local function Draggable(frame, handle)
	local drag, ds, sp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag, ds, sp = true, i.Position, frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - ds
			frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
	end)
end

-- HSV helpers
local function HSVtoRGB(h,s,v)
	if s == 0 then return Color3.new(v,v,v) end
	local i = math.floor(h*6)%6
	local f = h*6 - math.floor(h*6)
	local p,q,t2 = v*(1-s), v*(1-s*f), v*(1-s*(1-f))
	local lut = {{v,t2,p},{q,v,p},{p,v,t2},{p,q,v},{t2,p,v},{v,p,q}}
	local rgb = lut[i+1]
	return Color3.new(rgb[1],rgb[2],rgb[3])
end
local function RGBtoHSV(c)
	local r,g,b = c.R,c.G,c.B
	local mx = math.max(r,g,b); local mn = math.min(r,g,b); local d = mx-mn
	local h,s,v = 0, 0, mx
	if mx ~= 0 then s = d/mx end
	if d ~= 0 then
		if mx==r then h=(g-b)/d%6 elseif mx==g then h=(b-r)/d+2 else h=(r-g)/d+4 end
		h = h/6
	end
	return h,s,v
end
local function c3ToT(c) return {R=math.floor(c.R*255),G=math.floor(c.G*255),B=math.floor(c.B*255)} end
local function tToC3(t) if type(t)=="table" and t.R then return Color3.fromRGB(t.R,t.G,t.B) end return Color3.new(1,1,1) end

-- ─────────────────────────────────────────────────────────
-- POPUP MANAGER
-- Uses task.defer on outside-click so item clicks always
-- fire BEFORE the close check — fixes dropdown/multidrop.
-- ─────────────────────────────────────────────────────────

local PM = { _open=nil, _gui=nil }

function PM:Setup(sg)
	self._gui = sg
end

function PM:Open(popup, anchor)
	if self._open and self._open ~= popup then
		self._open.Visible = false
	end
	popup.Parent = self._gui

	-- Position below anchor, clamp to screen
	local ax = anchor.AbsolutePosition.X
	local ay = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 3
	local pw = popup.Size.X.Offset
	local ph = popup.Size.Y.Offset
	local sw = self._gui.AbsoluteSize.X
	local sh = self._gui.AbsoluteSize.Y
	if ax + pw > sw - 4 then ax = sw - pw - 4 end
	if ay + ph > sh - 4 then ay = anchor.AbsolutePosition.Y - ph - 3 end
	if ax < 2 then ax = 2 end
	popup.Position = UDim2.new(0, ax, 0, ay)
	popup.Visible  = true
	self._open = popup
end

function PM:Close(popup)
	if popup then
		popup.Visible = false
		if self._open == popup then self._open = nil end
	end
end

function PM:CloseAll()
	if self._open then self:Close(self._open) end
end

-- task.defer so item MouseButton1Click fires FIRST before we decide to close
UIS.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not PM._open or not PM._open.Visible then return end
	local mp = UIS:GetMouseLocation()
	local snap = PM._open
	task.defer(function()
		if not snap or not snap.Visible then return end
		local px = snap.AbsolutePosition.X
		local py = snap.AbsolutePosition.Y
		local pw2 = snap.AbsoluteSize.X
		local ph2 = snap.AbsoluteSize.Y
		if mp.X < px or mp.X > px+pw2 or mp.Y < py or mp.Y > py+ph2 then
			PM:CloseAll()
		end
	end)
end)

-- ─────────────────────────────────────────────────────────
-- CONFIG SYSTEM
-- ─────────────────────────────────────────────────────────

local CS = {Folder="KingVonHook", Ext=".kvh"}
CS.__index = CS
function CS:Init()
	if not isfolder(self.Folder) then makefolder(self.Folder) end
end
function CS:Save(n, d)
	local o = {}
	for k,v in pairs(d) do
		if type(v) == "userdata" then o[k] = c3ToT(v)
		elseif type(v) == "table" then o[k] = v
		else o[k] = v end
	end
	writefile(self.Folder.."/"..n..self.Ext, HTTP:JSONEncode(o))
end
function CS:Load(n)
	local p = self.Folder.."/"..n..self.Ext
	if not isfile(p) then return nil end
	local ok,v = pcall(function() return HTTP:JSONDecode(readfile(p)) end)
	return ok and v or nil
end
function CS:Delete(n)
	local p = self.Folder.."/"..n..self.Ext
	if isfile(p) then delfile(p) end
end
function CS:List()
	local o = {}
	for _,f in ipairs(listfiles(self.Folder)) do
		local n = f:match("([^/\\]+)"..self.Ext.."$")
		if n then table.insert(o,n) end
	end
	return o
end

-- ─────────────────────────────────────────────────────────
-- CONSTRUCTOR
-- ─────────────────────────────────────────────────────────

function Library.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Library)
	self.Tabs={}; self.TabMap={}; self.ActiveTab=nil; self.ActiveBtn=nil
	self.Flags={}; self._apis={}; self._binds={}
	self.Config = setmetatable({}, CS); self.Config:Init()

	-- ScreenGui
	local sg = New("ScreenGui",{Name="KingVonHook",ResetOnSpawn=false,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	pcall(function() sg.Parent=game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end
	self.ScreenGui = sg
	PM:Setup(sg)

	-- Main window
	local main = New("Frame",{
		Name="Main",Size=UDim2.new(0,900,0,620),
		Position=UDim2.new(0.5,-450,0.5,-310),
		BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0,Active=true,
	},sg)
	Corner(main,4); Stroke(main,Color3.fromRGB(35,35,35),1)
	self.MainFrame = main

	-- Title bar
	local tbar = New("Frame",{Size=UDim2.new(1,0,0,30),
		BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},main)
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(32,32,32),BorderSizePixel=0},tbar)
	New("TextLabel",{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),
		BackgroundTransparency=1,
		Text=cfg.Title or "KINGVONHOOK (Bypass) By Vlone",
		TextColor3=Color3.fromRGB(160,160,160),TextSize=12,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left},tbar)
	Draggable(main,tbar)

	-- Tab bar
	local tw = New("Frame",{Size=UDim2.new(1,-16,0,34),Position=UDim2.new(0,8,0,32),BackgroundTransparency=1},main)
	local tc = New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},tw)
	New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},tc)
	self.TabContainer = tc
	local utrack = New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0},tw)
	self.Underline = New("Frame",{Size=UDim2.new(0,60,0,1),
		BackgroundColor3=Color3.fromRGB(210,210,210),BorderSizePixel=0,ZIndex=2},utrack)

	-- Content frame
	local cf = New("Frame",{
		Size=UDim2.new(1,-16,1,-82),Position=UDim2.new(0,8,0,74),
		BackgroundColor3=Color3.fromRGB(10,10,10),BorderSizePixel=0,ClipsDescendants=true},main)
	Corner(cf,4); Stroke(cf,Color3.fromRGB(32,32,32),1)
	self.ContentFrame = cf
	if cfg.BackgroundId then
		New("ImageLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Image="rbxassetid://"..tostring(cfg.BackgroundId),
			ScaleType=Enum.ScaleType.Stretch,
			ImageTransparency=cfg.ImageTransparency or 0.3,ZIndex=1},cf)
	end

	-- Watermark (separate draggable bar)
	local wm = New("Frame",{
		Name="KVH_Watermark",Size=UDim2.new(0,400,0,26),
		Position=UDim2.new(0.5,-200,0,6),
		BackgroundColor3=Color3.fromRGB(6,6,6),BorderSizePixel=0,Active=true,ZIndex=10,
	},sg)
	Corner(wm,4)
	local wmSt = Stroke(wm,Color3.fromRGB(160,0,0),1)
	local wmGr = New("UIGradient",{Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(200,0,0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30,0,0)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(200,0,0)),
	}),Rotation=0},wmSt)
	local wmLbl = New("TextLabel",{
		Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,
		Text="KingVonHook  |  fps: --  |  ping: --ms  |  time: --:--:--",
		TextColor3=Color3.fromRGB(200,200,200),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11},wm)
	self.WatermarkLabel  = wmLbl
	self.WatermarkWindow = wm
	Draggable(wm,wm)

	local wmRot = 0
	RUN.Heartbeat:Connect(function(dt)
		wmRot = (wmRot + dt*50)%360
		wmGr.Rotation = wmRot
		local fps  = math.floor(1/math.max(dt,0.001))
		local ping = math.floor(Players.LocalPlayer:GetNetworkPing()*1000)
		local t    = os.date("*t")
		wmLbl.Text = string.format(
			"KingVonHook  |  fps: %d  |  ping: %dms  |  time: %02d:%02d:%02d",
			fps,ping,t.hour,t.min,t.sec)
	end)

	self:_AddRipTab()
	return self
end

-- ─────────────────────────────────────────────────────────
-- R.I.P. VON
-- ─────────────────────────────────────────────────────────

function Library:_AddRipTab()
	local tab = self:_CreateTab("R.I.P. VON",true)
	local function L(txt,col,sz,y)
		New("TextLabel",{Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,12,0,y),
			BackgroundTransparency=1,Text=txt,TextColor3=col,TextSize=sz,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=3},tab.Page)
	end
	L("R.I.P. KING VON",Color3.fromRGB(195,0,0),13,12)
	L("Rest in Peace to the legendary rapper King Von.",Color3.fromRGB(155,155,155),12,38)
	L("This cheat is dedicated to his memory.",Color3.fromRGB(155,155,155),12,58)
	L("2020 - Forever",Color3.fromRGB(90,90,90),12,90)
end

-- ─────────────────────────────────────────────────────────
-- TABS
-- ─────────────────────────────────────────────────────────

function Library:_CreateTab(name,noPanels)
	local btn = New("TextButton",{
		Name=name,Size=UDim2.new(0,64,1,0),
		BackgroundTransparency=1,BorderSizePixel=0,
		Text=name,TextColor3=Color3.fromRGB(120,120,120),
		TextSize=11,Font=Enum.Font.Code,
		LayoutOrder=#self.Tabs+1,AutoButtonColor=false,
	},self.TabContainer)
	local page = New("Frame",{
		Name=name,Size=UDim2.new(1,0,1,0),
		BackgroundTransparency=1,Visible=false,ZIndex=2},self.ContentFrame)
	local tab = {Name=name,Button=btn,Page=page,LeftPanel=nil,RightPanel=nil}
	if not noPanels then
		New("Frame",{Size=UDim2.new(0,1,1,-10),Position=UDim2.new(0.5,0,0,5),
			BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0,ZIndex=2},page)
		tab.LeftPanel  = New("Frame",{Size=UDim2.new(0.5,-8,1,0),BackgroundTransparency=1,ZIndex=2},page)
		tab.RightPanel = New("Frame",{Size=UDim2.new(0.5,-8,1,0),Position=UDim2.new(0.5,8,0,0),BackgroundTransparency=1,ZIndex=2},page)
	end
	table.insert(self.Tabs,tab); self.TabMap[name]=tab
	btn.MouseButton1Click:Connect(function() self:SetActiveTab(name) end)
	btn.MouseEnter:Connect(function() if self.ActiveTab~=name then btn.TextColor3=Color3.fromRGB(165,165,165) end end)
	btn.MouseLeave:Connect(function() if self.ActiveTab~=name then btn.TextColor3=Color3.fromRGB(120,120,120) end end)
	return tab
end

function Library:AddTab(name)
	local rip = self.TabMap["R.I.P. VON"]
	if rip then rip.Button.LayoutOrder=999 end
	local tab = self:_CreateTab(name,false)
	tab.Button.LayoutOrder = #self.Tabs-1
	return tab
end

function Library:SetActiveTab(name)
	if self.ActiveBtn then self.ActiveBtn.TextColor3=Color3.fromRGB(120,120,120) end
	local tab = self.TabMap[name]; if not tab then return end
	tab.Button.TextColor3 = name=="R.I.P. VON" and Color3.fromRGB(200,60,60) or Color3.fromRGB(220,220,220)
	self.ActiveTab=name; self.ActiveBtn=tab.Button
	task.defer(function()
		self.Underline.Size     = UDim2.new(0,tab.Button.AbsoluteSize.X,0,1)
		self.Underline.Position = UDim2.new(0,tab.Button.AbsolutePosition.X-self.TabContainer.AbsolutePosition.X,0,0)
	end)
	for _,t in ipairs(self.Tabs) do t.Page.Visible=(t.Name==name) end
end

-- ─────────────────────────────────────────────────────────
-- SECTION HEADER
-- ─────────────────────────────────────────────────────────

function Library:MakeSectionHeader(p,left,right,y,z)
	local h = New("Frame",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},p)
	New("TextLabel",{Size=UDim2.new(0.65,0,1,0),BackgroundTransparency=1,Text=left,
		TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},h)
	if right and right~="" then
		New("TextLabel",{Size=UDim2.new(0.35,0,1,0),Position=UDim2.new(0.65,0,0,0),BackgroundTransparency=1,
			Text=right,TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Right,ZIndex=z},h)
	end
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(45,45,45),BorderSizePixel=0,ZIndex=z},h)
end

-- ─────────────────────────────────────────────────────────
-- COLOR PICKER POPUP (shared builder)
-- ─────────────────────────────────────────────────────────

local function BuildColorPickerPopup(hR,sR,vR,aR,defColor,fk,flags,cb)
	local hue,sat,val,alpha = hR[1],sR[1],vR[1],aR[1]

	local picker = New("Frame",{
		Size=UDim2.new(0,224,0,232),BackgroundColor3=Color3.fromRGB(14,14,14),
		BorderSizePixel=0,Visible=false,ZIndex=10})
	Corner(picker,5); Stroke(picker,Color3.fromRGB(50,50,50),1)

	local satBox = New("ImageButton",{
		Size=UDim2.new(1,-16,0,110),Position=UDim2.new(0,8,0,8),
		BackgroundColor3=HSVtoRGB(hue,1,1),BorderSizePixel=0,
		Image="rbxassetid://13037988805",AutoButtonColor=false,ZIndex=11},picker)
	Corner(satBox,3)
	local cur = New("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundTransparency=1,BorderSizePixel=0,ZIndex=13},satBox)
	New("UIStroke",{Color=Color3.new(1,1,1),Thickness=2},cur); Corner(cur,5)

	local vTrack = New("Frame",{Size=UDim2.new(1,-16,0,10),Position=UDim2.new(0,8,0,126),
		BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=11},picker); Corner(vTrack,3)
	New("UIGradient",{Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(1,1,1))},vTrack)
	local vKnob = New("Frame",{Size=UDim2.new(0,10,1,4),AnchorPoint=Vector2.new(0.5,0),
		Position=UDim2.new(val,0,0,-2),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=12},vTrack)
	Corner(vKnob,2); Stroke(vKnob,Color3.new(0,0,0),1)
	local vHit = New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-4),
		BackgroundTransparency=1,Text="",ZIndex=14},vTrack)

	local aTrack = New("Frame",{Size=UDim2.new(1,-16,0,10),Position=UDim2.new(0,8,0,146),
		BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=11},picker); Corner(aTrack,3)
	New("UIGradient",{
		Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)),
		Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},aTrack)
	local aKnob = New("Frame",{Size=UDim2.new(0,10,1,4),AnchorPoint=Vector2.new(0.5,0),
		Position=UDim2.new(alpha,0,0,-2),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=12},aTrack)
	Corner(aKnob,2); Stroke(aKnob,Color3.new(0,0,0),1)
	local aHit = New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-4),
		BackgroundTransparency=1,Text="",ZIndex=14},aTrack)

	New("TextLabel",{Size=UDim2.new(0.5,0,0,11),Position=UDim2.new(0,8,0,158),BackgroundTransparency=1,
		Text="Brightness",TextColor3=Color3.fromRGB(80,80,80),TextSize=9,Font=Enum.Font.Code,ZIndex=11},picker)
	New("TextLabel",{Size=UDim2.new(0.5,0,0,11),Position=UDim2.new(0.5,0,0,158),BackgroundTransparency=1,
		Text="Opacity",TextColor3=Color3.fromRGB(80,80,80),TextSize=9,Font=Enum.Font.Code,ZIndex=11},picker)

	local hexBox = New("TextBox",{
		Size=UDim2.new(1,-48,0,22),Position=UDim2.new(0,8,0,171),
		BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0,
		Text=string.format("%02X%02X%02X",math.floor(defColor.R*255),math.floor(defColor.G*255),math.floor(defColor.B*255)),
		TextColor3=Color3.fromRGB(200,200,200),PlaceholderText="RRGGBB",
		PlaceholderColor3=Color3.fromRGB(80,80,80),TextSize=11,Font=Enum.Font.Code,
		ClearTextOnFocus=false,ZIndex=11},picker)
	Corner(hexBox,3); Stroke(hexBox,Color3.fromRGB(50,50,50),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,6)},hexBox)
	local swInner = New("Frame",{Size=UDim2.new(0,32,0,22),Position=UDim2.new(1,-40,0,171),
		BackgroundColor3=defColor,BorderSizePixel=0,ZIndex=11},picker)
	Corner(swInner,3); Stroke(swInner,Color3.fromRGB(50,50,50),1)

	local previewRef = {}
	local function getColor() return HSVtoRGB(hue,sat,val) end
	local function updateAll()
		local c = getColor()
		swInner.BackgroundColor3 = c
		if previewRef[1] then previewRef[1].BackgroundColor3 = c end
		satBox.BackgroundColor3  = HSVtoRGB(hue,1,1)
		cur.Position             = UDim2.new(hue,0,1-sat,0)
		vKnob.Position           = UDim2.new(val,0,0,-2)
		aKnob.Position           = UDim2.new(alpha,0,0,-2)
		hexBox.Text = string.format("%02X%02X%02X",
			math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
		hR[1]=hue; sR[1]=sat; vR[1]=val; aR[1]=alpha
		if fk and flags then flags[fk]=c3ToT(c) end
		if cb then cb(c,alpha) end
	end

	local sD,vD,aD = false,false,false
	satBox.MouseButton1Down:Connect(function() sD=true end)
	vHit.MouseButton1Down:Connect(function() vD=true end)
	aHit.MouseButton1Down:Connect(function() aD=true end)
	UIS.InputChanged:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if sD then
			hue = math.clamp((i.Position.X-satBox.AbsolutePosition.X)/satBox.AbsoluteSize.X,0,0.9999)
			sat = 1-math.clamp((i.Position.Y-satBox.AbsolutePosition.Y)/satBox.AbsoluteSize.Y,0,1)
			updateAll()
		elseif vD then
			val = math.clamp((i.Position.X-vTrack.AbsolutePosition.X)/vTrack.AbsoluteSize.X,0,1)
			updateAll()
		elseif aD then
			alpha = math.clamp((i.Position.X-aTrack.AbsolutePosition.X)/aTrack.AbsoluteSize.X,0,1)
			updateAll()
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then sD=false;vD=false;aD=false end
	end)
	hexBox.FocusLost:Connect(function()
		local h = hexBox.Text:gsub("[^%x]",""):sub(1,6)
		if #h==6 then
			hue,sat,val=RGBtoHSV(Color3.new(
				tonumber(h:sub(1,2),16)/255,
				tonumber(h:sub(3,4),16)/255,
				tonumber(h:sub(5,6),16)/255))
			updateAll()
		end
	end)

	updateAll()
	return picker, previewRef, updateAll, getColor
end

-- ─────────────────────────────────────────────────────────
-- TOGGLE  (plain)
-- ─────────────────────────────────────────────────────────

function Library:MakeToggle(parent,label,y,z,fk,cb)
	local row = New("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	local box = New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=z},row)
	Corner(box,2); Stroke(box,Color3.fromRGB(70,70,70),1)
	local chk = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",
		TextColor3=Color3.fromRGB(100,200,100),TextSize=12,Font=Enum.Font.Code,ZIndex=z+1},box)
	New("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,
		Text=label,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},row)
	local on = false
	if fk then self.Flags[fk]=false end
	local hit = New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=z+2},row)
	hit.MouseButton1Click:Connect(function()
		on=not on; chk.Text=on and "✓" or ""
		if fk then self.Flags[fk]=on end; if cb then cb(on) end
	end)
	local api={}
	function api:Set(v) on=v; chk.Text=on and "✓" or ""; if fk then self.Flags[fk]=on end; if cb then cb(on) end end
	function api:Get() return on end
	return row, api
end

-- ─────────────────────────────────────────────────────────
-- TOGGLE + KEYBIND
-- ─────────────────────────────────────────────────────────

function Library:MakeToggleKey(parent,label,defKey,y,z,fk,fkKey,cb)
	defKey = defKey or Enum.KeyCode.Unknown
	local on,listen = false,false
	local cur    = defKey
	local kName  = cur==Enum.KeyCode.Unknown and "NONE" or cur.Name

	-- _binds entry: use a table so Key updates live
	local entry = {Label=label,Key=kName}
	table.insert(self._binds,entry)

	if fk    then self.Flags[fk]=false  end
	if fkKey then self.Flags[fkKey]=kName end

	local row = New("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	local box = New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=z},row)
	Corner(box,2); Stroke(box,Color3.fromRGB(70,70,70),1)
	local chk = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",
		TextColor3=Color3.fromRGB(100,200,100),TextSize=12,Font=Enum.Font.Code,ZIndex=z+1},box)
	New("TextLabel",{Size=UDim2.new(1,-82,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,
		Text=label,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},row)

	local keyBtn = New("TextButton",{
		Size=UDim2.new(0,56,0,18),Position=UDim2.new(1,-58,0.5,-9),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,
		Text="["..kName.."]",TextColor3=Color3.fromRGB(200,200,100),
		TextSize=9,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=z+2},row)
	Corner(keyBtn,2); Stroke(keyBtn,Color3.fromRGB(55,55,55),1)

	-- toggle hitbox (left portion, avoids key button)
	local hit = New("TextButton",{Size=UDim2.new(1,-62,1,0),BackgroundTransparency=1,Text="",ZIndex=z+2},row)
	hit.MouseButton1Click:Connect(function()
		on=not on; chk.Text=on and "✓" or ""
		if fk then self.Flags[fk]=on end; if cb then cb(on,cur) end
	end)

	keyBtn.MouseButton1Click:Connect(function()
		if listen then return end
		listen=true; keyBtn.Text="[...]"; keyBtn.TextColor3=Color3.fromRGB(255,255,80)
	end)
	UIS.InputBegan:Connect(function(i)
		if not listen then return end
		if i.UserInputType==Enum.UserInputType.Keyboard then
			listen=false; cur=i.KeyCode; kName=cur.Name
			keyBtn.Text="["..kName.."]"; keyBtn.TextColor3=Color3.fromRGB(200,200,100)
			entry.Key=kName  -- update live in _binds
			if fkKey then self.Flags[fkKey]=kName end
			if cb then cb(on,cur) end
		end
	end)
	-- pressing the key triggers the toggle
	UIS.InputBegan:Connect(function(i)
		if listen then return end
		if i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==cur then
			on=not on; chk.Text=on and "✓" or ""
			if fk then self.Flags[fk]=on end; if cb then cb(on,cur) end
		end
	end)

	local api={}
	function api:Set(v) on=v; chk.Text=on and "✓" or ""; if fk then self.Flags[fk]=on end end
	function api:Get() return on end
	function api:GetKey() return cur end
	function api:SetKey(k)
		cur = type(k)=="string" and (Enum.KeyCode[k] or Enum.KeyCode.Unknown) or k
		kName=cur.Name; keyBtn.Text="["..kName.."]"; entry.Key=kName
		if fkKey then self.Flags[fkKey]=kName end
	end
	return row, api
end

-- ─────────────────────────────────────────────────────────
-- TOGGLE + COLOR
-- ─────────────────────────────────────────────────────────

function Library:MakeToggleColor(parent,label,defColor,y,z,fk,fkCol,cb)
	defColor = defColor or Color3.new(1,1,1)
	local on = false
	local h0,s0,v0 = RGBtoHSV(defColor)
	local hR,sR,vR,aR = {h0},{s0},{v0},{1}
	if fk    then self.Flags[fk]=false end
	if fkCol then self.Flags[fkCol]=c3ToT(defColor) end

	local row = New("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	local box = New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=z},row)
	Corner(box,2); Stroke(box,Color3.fromRGB(70,70,70),1)
	local chk = New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",
		TextColor3=Color3.fromRGB(100,200,100),TextSize=12,Font=Enum.Font.Code,ZIndex=z+1},box)
	New("TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,
		Text=label,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},row)

	local swatch = New("TextButton",{
		Size=UDim2.new(0,38,0,18),Position=UDim2.new(1,-42,0.5,-9),
		BackgroundColor3=defColor,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=z+2},row)
	Corner(swatch,3); Stroke(swatch,Color3.fromRGB(70,70,70),1)

	local hit = New("TextButton",{Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,Text="",ZIndex=z+2},row)
	hit.MouseButton1Click:Connect(function()
		on=not on; chk.Text=on and "✓" or ""
		if fk then self.Flags[fk]=on end
		if cb then cb(on,HSVtoRGB(hR[1],sR[1],vR[1]),aR[1]) end
	end)

	local picker,pRef,updUI,getCol = BuildColorPickerPopup(
		hR,sR,vR,aR,defColor,fkCol,self.Flags,
		function(c,a)
			if fkCol then self.Flags[fkCol]=c3ToT(c) end
			if cb then cb(on,c,a) end
		end)
	pRef[1]=swatch

	swatch.MouseButton1Click:Connect(function()
		if picker.Visible then PM:Close(picker) else PM:Open(picker,swatch) end
	end)

	local api={}
	function api:Set(v) on=v; chk.Text=on and "✓" or ""; if fk then self.Flags[fk]=on end end
	function api:Get() return on end
	function api:GetColor() return getCol(),aR[1] end
	function api:SetColor(c,a) local nh,ns,nv=RGBtoHSV(c); hR[1]=nh;sR[1]=ns;vR[1]=nv; aR[1]=a or 1; updUI() end
	return row, api
end

-- ─────────────────────────────────────────────────────────
-- SLIDER
-- ─────────────────────────────────────────────────────────

function Library:MakeSlider(parent,label,mn,mx,def,y,z,fk,cb)
	local cont = New("Frame",{Size=UDim2.new(1,-16,0,38),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	New("TextLabel",{Size=UDim2.new(0.6,0,0,16),BackgroundTransparency=1,Text=label,
		TextColor3=Color3.fromRGB(140,140,140),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},cont)
	local vl = New("TextLabel",{Size=UDim2.new(0.4,0,0,16),Position=UDim2.new(0.6,0,0,0),
		BackgroundTransparency=1,Text=tostring(def),
		TextColor3=Color3.fromRGB(140,140,140),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Right,ZIndex=z},cont)
	local track = New("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,0,20),
		BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,ZIndex=z},cont)
	Corner(track,4); Stroke(track,Color3.fromRGB(55,55,55),1)
	local p0 = (def-mn)/(mx-mn)
	local fill = New("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=Color3.fromRGB(180,180,180),BorderSizePixel=0,ZIndex=z+1},track); Corner(fill,4)
	local knob = New("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(p0,0,0.5,-5),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.fromRGB(220,220,220),BorderSizePixel=0,ZIndex=z+2},track); Corner(knob,5)
	local hit  = New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-7),BackgroundTransparency=1,Text="",ZIndex=z+3},track)
	local cur  = def; if fk then self.Flags[fk]=cur end
	local drag = false
	local function upd(x)
		local p = math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
		fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,-5)
		cur = math.floor((mn+(mx-mn)*p)*10+0.5)/10
		vl.Text=tostring(cur)
		if fk then self.Flags[fk]=cur end; if cb then cb(cur) end
	end
	hit.MouseButton1Down:Connect(function() drag=true end)
	UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	local api={}
	function api:Set(v)
		cur=math.clamp(tonumber(v) or mn,mn,mx)
		local p=(cur-mn)/(mx-mn)
		fill.Size=UDim2.new(p,0,1,0); knob.Position=UDim2.new(p,0,0.5,-5)
		vl.Text=tostring(cur)
		if fk then self.Flags[fk]=cur end; if cb then cb(cur) end
	end
	function api:Get() return cur end
	return cont, api
end

-- ─────────────────────────────────────────────────────────
-- DROPDOWN
-- FIX: item click happens inside the popup bounds so the
-- task.defer outside-check never triggers while it's open.
-- ─────────────────────────────────────────────────────────

function Library:MakeDropdown(parent,labelText,opts,y,z,fk,cb)
	local IH = 22
	local wrap = New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	if labelText and labelText~="" then
		New("TextLabel",{Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,-14),BackgroundTransparency=1,
			Text=labelText,TextColor3=Color3.fromRGB(120,120,120),TextSize=10,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},wrap)
	end
	local sel = opts[1] or ""
	if fk then self.Flags[fk]=sel end

	local btn = New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),
		BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=z},wrap)
	Corner(btn,3); Stroke(btn,Color3.fromRGB(55,55,55),1)
	local selLbl = New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text=sel,TextColor3=Color3.fromRGB(185,185,185),
		TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z+1},btn)
	local arrow = New("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),
		BackgroundTransparency=1,Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=z+1},btn)

	-- popup list – parented to nil until PM:Open moves it into the ScreenGui
	local list = New("Frame",{
		Size=UDim2.new(0,200,0,#opts*IH+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=50})
	Corner(list,3); Stroke(list,Color3.fromRGB(55,55,55),1)

	local function buildItems(o)
		for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		list.Size = UDim2.new(0,200,0,#o*IH+4)
		for i,v in ipairs(o) do
			local cv = v
			local item = New("TextButton",{
				Size=UDim2.new(1,0,0,IH),Position=UDim2.new(0,0,0,(i-1)*IH+2),
				BackgroundTransparency=1,BorderSizePixel=0,Text=v,
				TextColor3=Color3.fromRGB(165,165,165),TextSize=11,Font=Enum.Font.Code,
				TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=51},list)
			New("UIPadding",{PaddingLeft=UDim.new(0,8)},item)
			item.MouseEnter:Connect(function() item.BackgroundTransparency=0; item.BackgroundColor3=Color3.fromRGB(28,28,28) end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
			item.MouseButton1Click:Connect(function()
				sel=cv; selLbl.Text=cv
				if fk then self.Flags[fk]=cv end
				if cb then cb(cv) end
				PM:Close(list); arrow.Text="▾"
			end)
		end
	end
	buildItems(opts)

	btn.MouseButton1Click:Connect(function()
		if list.Visible then
			PM:Close(list); arrow.Text="▾"
		else
			list.Size=UDim2.new(0,math.max(btn.AbsoluteSize.X,200),0,list.Size.Y.Offset)
			PM:Open(list,btn); arrow.Text="▴"
		end
	end)
	-- sync arrow when closed externally
	RUN.Heartbeat:Connect(function() if not list.Visible and arrow.Text=="▴" then arrow.Text="▾" end end)

	local api={}
	function api:Get() return sel end
	function api:Set(v) sel=v; selLbl.Text=v; if fk then self.Flags[fk]=v end; if cb then cb(v) end end
	function api:Refresh(no) buildItems(no); if no[1] then sel=no[1]; selLbl.Text=no[1] end end
	return wrap, api
end

-- ─────────────────────────────────────────────────────────
-- MULTI-DROPDOWN
-- FIX: items are at ZIndex=51 so they're inside the popup
-- bounding box – outside-click check leaves them alone.
-- ─────────────────────────────────────────────────────────

function Library:MakeMultiDropdown(parent,labelText,opts,y,z,fk,cb)
	local IH = 22
	local wrap = New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	if labelText and labelText~="" then
		New("TextLabel",{Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,-14),BackgroundTransparency=1,
			Text=labelText,TextColor3=Color3.fromRGB(120,120,120),TextSize=10,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},wrap)
	end
	local sel = {}
	if fk then self.Flags[fk]={} end

	local btn = New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),
		BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=z},wrap)
	Corner(btn,3); Stroke(btn,Color3.fromRGB(55,55,55),1)
	local lbl = New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),
		BackgroundTransparency=1,Text="None",TextColor3=Color3.fromRGB(185,185,185),
		TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z+1},btn)
	local arrow = New("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),
		BackgroundTransparency=1,Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=z+1},btn)

	local function updLbl()
		local k={}; for v in pairs(sel) do table.insert(k,v) end
		lbl.Text = #k==0 and "None" or table.concat(k,", ")
	end

	local list = New("Frame",{
		Size=UDim2.new(0,200,0,#opts*IH+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=50})
	Corner(list,3); Stroke(list,Color3.fromRGB(55,55,55),1)

	local chkMap = {}
	for i,v in ipairs(opts) do
		local cv = v
		local item = New("Frame",{
			Size=UDim2.new(1,0,0,IH),Position=UDim2.new(0,0,0,(i-1)*IH+2),
			BackgroundTransparency=1,ZIndex=50},list)
		local chk = New("TextLabel",{
			Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,6,0.5,-7),
			BackgroundColor3=Color3.fromRGB(18,18,18),Text="",
			TextColor3=Color3.fromRGB(100,200,100),TextSize=10,Font=Enum.Font.Code,
			BorderSizePixel=0,ZIndex=51},item)
		Corner(chk,2); Stroke(chk,Color3.fromRGB(70,70,70),1)
		New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,26,0,0),
			BackgroundTransparency=1,Text=v,TextColor3=Color3.fromRGB(165,165,165),
			TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51},item)
		local hit = New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=52},item)
		chkMap[v] = chk
		hit.MouseEnter:Connect(function() item.BackgroundTransparency=0; item.BackgroundColor3=Color3.fromRGB(22,22,22) end)
		hit.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
		hit.MouseButton1Click:Connect(function()
			if sel[cv] then sel[cv]=nil; chk.Text=""
			else sel[cv]=true; chk.Text="✓" end
			updLbl()
			local a={}; for k in pairs(sel) do table.insert(a,k) end
			if fk then self.Flags[fk]=a end
			if cb then cb(a) end
			-- do NOT close – multi-drop stays open until outside click
		end)
	end

	btn.MouseButton1Click:Connect(function()
		if list.Visible then
			PM:Close(list); arrow.Text="▾"
		else
			list.Size=UDim2.new(0,math.max(btn.AbsoluteSize.X,200),0,list.Size.Y.Offset)
			PM:Open(list,btn); arrow.Text="▴"
		end
	end)
	RUN.Heartbeat:Connect(function() if not list.Visible and arrow.Text=="▴" then arrow.Text="▾" end end)

	local api={}
	function api:Get() local a={}; for k in pairs(sel) do table.insert(a,k) end return a end
	function api:Set(arr)
		sel={}
		for _,v in ipairs(arr) do sel[v]=true; if chkMap[v] then chkMap[v].Text="✓" end end
		updLbl()
	end
	return wrap, api
end

-- ─────────────────────────────────────────────────────────
-- STANDALONE COLOR PICKER
-- ─────────────────────────────────────────────────────────

function Library:MakeColorPicker(parent,label,defColor,y,z,fk,cb)
	defColor = defColor or Color3.new(1,1,1)
	local h0,s0,v0 = RGBtoHSV(defColor)
	local hR,sR,vR,aR = {h0},{s0},{v0},{1}
	if fk then self.Flags[fk]=c3ToT(defColor) end

	local row = New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,y),BackgroundTransparency=1,ZIndex=z},parent)
	New("TextLabel",{Size=UDim2.new(1,-36,1,0),BackgroundTransparency=1,Text=label,
		TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z},row)
	local preview = New("TextButton",{Size=UDim2.new(0,24,0,18),Position=UDim2.new(1,-28,0.5,-9),
		BackgroundColor3=defColor,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=z+1},row)
	Corner(preview,3); Stroke(preview,Color3.fromRGB(70,70,70),1)

	local picker,pRef,updUI,getCol = BuildColorPickerPopup(hR,sR,vR,aR,defColor,fk,self.Flags,cb)
	pRef[1] = preview

	preview.MouseButton1Click:Connect(function()
		if picker.Visible then PM:Close(picker) else PM:Open(picker,preview) end
	end)

	local api={}
	function api:Get() return getCol(),aR[1] end
	function api:Set(c,a) local nh,ns,nv=RGBtoHSV(c); hR[1]=nh;sR[1]=ns;vR[1]=nv; aR[1]=a or 1; updUI() end
	return row, api
end

-- ─────────────────────────────────────────────────────────
-- VON LIST  (keybind/toggle list)
-- Title bar "VON list", middle-left, draggable.
-- Rows fade in smoothly when added; only active binds shown.
-- ─────────────────────────────────────────────────────────

function Library:CreateKeybindList()
	local WIN_W = 200

	local win = New("Frame",{
		Name="KVH_BindList",Size=UDim2.new(0,WIN_W,0,28),
		Position=UDim2.new(0,8,0.5,-50),
		BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0,Active=true,ZIndex=50,
		ClipsDescendants=false,
	},self.ScreenGui)
	Corner(win,4)
	local wStroke = Stroke(win,Color3.fromRGB(140,0,0),1)
	local wGrad   = New("UIGradient",{Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(200,0,0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25,0,0)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(200,0,0)),
	}),Rotation=0},wStroke)

	-- Title bar
	local HDR_H = 26
	local hdr = New("Frame",{
		Size=UDim2.new(1,0,0,HDR_H),
		BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0,ZIndex=51},win)
	Corner(hdr,4)
	-- fill bottom of header so it looks flat-bottomed against the body
	New("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),
		BackgroundColor3=Color3.fromRGB(12,12,12),BorderSizePixel=0,ZIndex=51},hdr)
	-- 1px separator under header
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
		BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0,ZIndex=52},hdr)
	New("TextLabel",{
		Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,10,0,0),
		BackgroundTransparency=1,Text="VON list",
		TextColor3=Color3.fromRGB(185,185,185),TextSize=11,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52},hdr)
	Draggable(win,hdr)

	-- Rows container
	local body = New("Frame",{
		Size=UDim2.new(1,0,1,-HDR_H),Position=UDim2.new(0,0,0,HDR_H),
		BackgroundTransparency=1,ZIndex=51,ClipsDescendants=false},win)

	-- Track what's currently rendered
	local rendered = {}  -- array of {entry, rowFrame}
	local ROW_H = 20
	local PAD   = 4

	local function rebuildRows()
		-- destroy removed
		for i=#rendered,1,-1 do
			local found=false
			for _,b in ipairs(self._binds) do if b==rendered[i].entry then found=true; break end end
			if not found then
				rendered[i].row:Destroy()
				table.remove(rendered,i)
			end
		end
		-- add new
		for _,b in ipairs(self._binds) do
			local exists=false
			for _,r in ipairs(rendered) do if r.entry==b then exists=true; break end end
			if not exists then
				local r = New("Frame",{
					Size=UDim2.new(1,-8,0,ROW_H),
					Position=UDim2.new(0,4,0,0), -- will be updated below
					BackgroundTransparency=1,ZIndex=51},body)
				New("TextLabel",{
					Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
					Text="",  -- filled each frame
					TextColor3=Color3.fromRGB(155,155,155),TextSize=9,Font=Enum.Font.Code,
					TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52},r)
				-- fade in
				r.BackgroundTransparency=1
				local lbl2=r:FindFirstChildWhichIsA("TextLabel")
				if lbl2 then lbl2.TextTransparency=1; Tween(lbl2,{TextTransparency=0},0.2) end
				table.insert(rendered,{entry=b,row=r})
			end
		end
		-- reposition all rows
		for idx,rv in ipairs(rendered) do
			rv.row.Position = UDim2.new(0,4,0,(idx-1)*ROW_H+PAD)
			local lbl2=rv.row:FindFirstChildWhichIsA("TextLabel")
			if lbl2 then
				lbl2.Text = "["..rv.entry.Key.."]  "..rv.entry.Label
			end
		end
		-- resize window
		local newH = HDR_H + #rendered*ROW_H + PAD*2
		Tween(win,{Size=UDim2.new(0,WIN_W,0,newH)},0.15)
	end

	local rot = 0
	local lastN = -1
	local lastKeys = ""

	RUN.Heartbeat:Connect(function(dt)
		rot = (rot+dt*40)%360; wGrad.Rotation=rot

		-- detect any change (count or key names)
		local ks = ""
		for _,b in ipairs(self._binds) do ks=ks..b.Key end
		if #self._binds~=lastN or ks~=lastKeys then
			lastN=   #self._binds
			lastKeys=ks
			rebuildRows()
		end
	end)

	return win
end

-- ─────────────────────────────────────────────────────────
-- CONFIG TAB
-- ─────────────────────────────────────────────────────────

function Library:_BuildConfigTab(tab)
	if tab.LeftPanel  then tab.LeftPanel.Size=UDim2.new(0.5,0,1,0) end
	if tab.RightPanel then tab.RightPanel.Visible=false end
	for _,c in ipairs(tab.Page:GetChildren()) do
		if c:IsA("Frame") and c.Size.X.Offset==1 then c.Visible=false end
	end
	local p = tab.LeftPanel

	self:MakeSectionHeader(p,"Config Management","",8,3)
	New("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,36),
		BackgroundTransparency=1,Text="Config Name",
		TextColor3=Color3.fromRGB(110,110,110),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},p)
	local inp = New("TextBox",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,52),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,
		Text="",PlaceholderText="Enter config name...",
		TextColor3=Color3.fromRGB(185,185,185),PlaceholderColor3=Color3.fromRGB(65,65,65),
		TextSize=11,Font=Enum.Font.Code,ClearTextOnFocus=false,ZIndex=3},p)
	Corner(inp,3); Stroke(inp,Color3.fromRGB(45,45,45),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,8)},inp)

	local lb = New("Frame",{Size=UDim2.new(1,-16,0,138),Position=UDim2.new(0,8,0,84),
		BackgroundColor3=Color3.fromRGB(11,11,11),BorderSizePixel=0,ZIndex=3,ClipsDescendants=true},p)
	Corner(lb,3); Stroke(lb,Color3.fromRGB(38,38,38),1)
	New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},lb)

	local selName=nil; local rowMap={}
	local status = New("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,376),
		BackgroundTransparency=1,Text="Manage configs above",
		TextColor3=Color3.fromRGB(75,75,75),TextSize=10,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},p)

	local function setStat(msg,col)
		status.Text=msg; status.TextColor3=col or Color3.fromRGB(100,200,100)
		task.delay(3,function()
			if status and status.Parent then
				status.Text="Manage configs above"
				status.TextColor3=Color3.fromRGB(75,75,75)
			end
		end)
	end

	local function refresh()
		for _,c in ipairs(lb:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		rowMap={}; selName=nil
		for i,n in ipairs(self.Config:List()) do
			local rw = New("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,
				BorderSizePixel=0,Text=n..".kvh",TextColor3=Color3.fromRGB(110,110,220),
				TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Center,
				AutoButtonColor=false,ZIndex=4,LayoutOrder=i},lb)
			rowMap[n]=rw
			rw.MouseButton1Click:Connect(function()
				for _,r in pairs(rowMap) do r.BackgroundTransparency=1; r.TextColor3=Color3.fromRGB(110,110,220) end
				selName=n; rw.BackgroundTransparency=0; rw.BackgroundColor3=Color3.fromRGB(20,20,38)
				rw.TextColor3=Color3.fromRGB(140,140,255); inp.Text=n
			end)
			rw.MouseEnter:Connect(function() if selName~=n then rw.BackgroundTransparency=0; rw.BackgroundColor3=Color3.fromRGB(16,16,28) end end)
			rw.MouseLeave:Connect(function() if selName~=n then rw.BackgroundTransparency=1 end end)
		end
	end
	refresh()

	local btns = {
		{y=230,t="Create Config",fn=function()
			local n=inp.Text; if n=="" then setStat("Enter a name.",Color3.fromRGB(200,80,80)) return end
			if self.Config:Load(n) then setStat("Already exists.",Color3.fromRGB(200,80,80)) return end
			self.Config:Save(n,{}); refresh(); setStat("Created: "..n)
		end},
		{y=262,t="Save Config",fn=function()
			local n=inp.Text; if n=="" then setStat("Enter a name.",Color3.fromRGB(200,80,80)) return end
			self.Config:Save(n,self.Flags); refresh(); setStat("Saved: "..n)
		end},
		{y=294,t="Load Config",fn=function()
			local n=selName or inp.Text
			if not n or n=="" then setStat("Select a config.",Color3.fromRGB(200,80,80)) return end
			local d=self.Config:Load(n)
			if not d then setStat("Not found.",Color3.fromRGB(200,80,80)) return end
			for k,v in pairs(d) do
				self.Flags[k]=v
				if self._apis[k] then
					pcall(function()
						local api=self._apis[k]
						if type(v)=="table" and v.R then
							api:Set(tToC3(v))
						else
							api:Set(v)
						end
					end)
				end
			end
			setStat("Loaded: "..n)
		end},
		{y=326,t="Delete Config",fn=function()
			local n=selName or inp.Text
			if not n or n=="" then setStat("Select a config.",Color3.fromRGB(200,80,80)) return end
			self.Config:Delete(n); refresh(); setStat("Deleted: "..n,Color3.fromRGB(200,80,80))
		end},
	}
	for _,bd in ipairs(btns) do
		local bg = bd.t=="Delete Config" and Color3.fromRGB(32,18,18) or Color3.fromRGB(28,28,28)
		local b = New("TextButton",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,bd.y),
			BackgroundColor3=bg,BorderSizePixel=0,Text=bd.t,
			TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,
			AutoButtonColor=false,ZIndex=3},p)
		Corner(b,3); Stroke(b,Color3.fromRGB(48,48,48),1)
		b.MouseEnter:Connect(function() Tween(b,{BackgroundColor3=Color3.fromRGB(42,42,42)},0.1) end)
		b.MouseLeave:Connect(function() Tween(b,{BackgroundColor3=bg},0.1) end)
		b.MouseButton1Click:Connect(bd.fn)
	end
end

function Library:AddConfigTab()
	local tab = self:AddTab("Config")
	self:_BuildConfigTab(tab)
	return tab
end

-- RegisterFlag: call after creating each widget so Load Config can set values
function Library:RegisterFlag(key,api)
	self._apis[key]=api
end

function Library:Destroy()
	self.ScreenGui:Destroy()
end

return Library
