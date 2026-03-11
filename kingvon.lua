-- KingVonHook UI Library | by elon

local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HTTP    = game:GetService("HttpService")
local RUN     = game:GetService("RunService")

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

-- HSV → Color3
local function HSVtoRGB(h,s,v)
	if s==0 then return Color3.new(v,v,v) end
	local i=math.floor(h*6)
	local f=h*6-i; local p=v*(1-s); local q=v*(1-s*f); local t2=v*(1-s*(1-f))
	local r,g,b
	i=i%6
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

-- Serialize Color3 for JSON
local function colorToTable(c) return {R=math.floor(c.R*255),G=math.floor(c.G*255),B=math.floor(c.B*255)} end
local function tableToColor(t)
	if type(t)=="table" and t.R then return Color3.fromRGB(t.R,t.G,t.B) end
	return Color3.new(1,1,1)
end

-- ─────────────────────────────────────────────────────────
-- OVERLAY LAYER  (dropdowns/pickers render here, never clip)
-- ─────────────────────────────────────────────────────────
-- We attach popups to a full-screen Frame above everything.
-- This completely fixes the clipping/overlap problem.

local _overlayGui = nil
local function GetOverlay(sg)
	if not _overlayGui or not _overlayGui.Parent then
		_overlayGui = New("Frame",{
			Name="KVH_Overlay", Size=UDim2.new(1,0,1,0),
			BackgroundTransparency=1, ZIndex=100,
		}, sg)
	end
	return _overlayGui
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
	-- Deep-copy, convert Color3 tables to serializable form
	local function clean(t)
		local out={}
		for k,v in pairs(t) do
			if type(v)=="table" and v.R and v.G and v.B then out[k]=v
			elseif type(v)=="userdata" then out[k]=colorToTable(v)
			else out[k]=v end
		end
		return out
	end
	writefile(self.Folder.."/"..name..self.Ext, HTTP:JSONEncode(clean(data)))
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
-- LIBRARY CONSTRUCTOR
-- ─────────────────────────────────────────────────────────

function Library.new(config)
	config=config or {}
	local self=setmetatable({},Library)
	self.Tabs={};self.TabMap={};self.ActiveTab=nil;self.ActiveBtn=nil
	self.Flags={};self._flagApis={};self.BindList={};self._openPopup=nil
	self.Config=setmetatable({},ConfigSystem);self.Config:Init()

	local sg=New("ScreenGui",{Name="KingVonHook",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	pcall(function() sg.Parent=game:GetService("CoreGui") end)
	if not sg.Parent then sg.Parent=Players.LocalPlayer:WaitForChild("PlayerGui") end
	self.ScreenGui=sg
	self.Overlay=GetOverlay(sg)

	-- Main frame
	local main=New("Frame",{
		Name="MainFrame",Size=UDim2.new(0,900,0,620),
		Position=UDim2.new(0.5,-450,0.5,-310),
		BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0,Active=true,
	},sg)
	Corner(main,4);Stroke(main,Color3.fromRGB(35,35,35),1)
	self.MainFrame=main

	-- Title bar
	local tbar=New("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},main)
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(32,32,32),BorderSizePixel=0},tbar)
	New("TextLabel",{
		Size=UDim2.new(0.7,0,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
		Text=config.Title or "KINGVONHOOK (Bypass) By Vlone",
		TextColor3=Color3.fromRGB(160,160,160),TextSize=12,Font=Enum.Font.Code,
		TextXAlignment=Enum.TextXAlignment.Left,
	},tbar)
	Draggable(main,tbar)

	-- Watermark (top-right of title bar)
	if config.Watermark~=false then
		self.WatermarkLabel=New("TextLabel",{
			Size=UDim2.new(0.3,-10,1,0),Position=UDim2.new(0.7,0,0,0),
			BackgroundTransparency=1,
			Text=config.WatermarkText or ("KVH | "..Players.LocalPlayer.Name),
			TextColor3=Color3.fromRGB(120,120,120),TextSize=11,Font=Enum.Font.Code,
			TextXAlignment=Enum.TextXAlignment.Right,
		},tbar)
		New("UIPadding",{PaddingRight=UDim.new(0,10)},self.WatermarkLabel)
	end

	-- Tab wrapper
	local tw=New("Frame",{Size=UDim2.new(1,-16,0,34),Position=UDim2.new(0,8,0,32),BackgroundTransparency=1},main)
	local tc=New("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},tw)
	New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)},tc)
	self.TabContainer=tc

	local utrack=New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0},tw)
	self.TabUnderline=New("Frame",{Size=UDim2.new(0,60,0,1),BackgroundColor3=Color3.fromRGB(210,210,210),BorderSizePixel=0,ZIndex=2},utrack)

	-- Content frame
	local cf=New("Frame",{
		Size=UDim2.new(1,-16,1,-82),Position=UDim2.new(0,8,0,74),
		BackgroundColor3=Color3.fromRGB(10,10,10),BorderSizePixel=0,ClipsDescendants=true,
	},main)
	Corner(cf,4);Stroke(cf,Color3.fromRGB(32,32,32),1)
	self.ContentFrame=cf

	if config.BackgroundId then
		New("ImageLabel",{
			Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
			Image="rbxassetid://"..tostring(config.BackgroundId),
			ScaleType=Enum.ScaleType.Stretch,
			ImageTransparency=config.ImageTransparency or 0.3,ZIndex=1,
		},cf)
	end

	-- Close any open popup when clicking outside
	UIS.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			if self._openPopup then
				task.defer(function()
					if self._openPopup then
						self._openPopup.Visible=false
						self._openPopup=nil
					end
				end)
			end
		end
	end)

	self:_AddRipTab()
	return self
end

-- ─────────────────────────────────────────────────────────
-- WATERMARK UPDATE
-- ─────────────────────────────────────────────────────────

function Library:SetWatermark(text)
	if self.WatermarkLabel then self.WatermarkLabel.Text=text end
end

-- ─────────────────────────────────────────────────────────
-- R.I.P. VON TAB
-- ─────────────────────────────────────────────────────────

function Library:_AddRipTab()
	local tab=self:_CreateTabFrame("R.I.P. VON",true)
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
	local btn=New("TextButton",{
		Name=tabName,Size=UDim2.new(0,64,1,0),BackgroundTransparency=1,BorderSizePixel=0,
		Text=tabName,TextColor3=Color3.fromRGB(120,120,120),TextSize=11,Font=Enum.Font.Code,
		LayoutOrder=#self.Tabs+1,AutoButtonColor=false,
	},self.TabContainer)

	local page=New("Frame",{
		Name=tabName,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=2,
	},self.ContentFrame)

	local tab={Name=tabName,Button=btn,Page=page,LeftPanel=nil,RightPanel=nil}

	if not noPanels then
		New("Frame",{Size=UDim2.new(0,1,1,-10),Position=UDim2.new(0.5,0,0,5),BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0,ZIndex=2},page)
		tab.LeftPanel=New("Frame",{Size=UDim2.new(0.5,-8,1,0),BackgroundTransparency=1,ZIndex=2,ClipsDescendants=false},page)
		tab.RightPanel=New("Frame",{Size=UDim2.new(0.5,-8,1,0),Position=UDim2.new(0.5,8,0,0),BackgroundTransparency=1,ZIndex=2,ClipsDescendants=false},page)
	end

	table.insert(self.Tabs,tab);self.TabMap[tabName]=tab

	btn.MouseButton1Click:Connect(function() self:SetActiveTab(tabName) end)
	btn.MouseEnter:Connect(function() if self.ActiveTab~=tabName then btn.TextColor3=Color3.fromRGB(165,165,165) end end)
	btn.MouseLeave:Connect(function() if self.ActiveTab~=tabName then btn.TextColor3=Color3.fromRGB(120,120,120) end end)

	return tab
end

-- ─────────────────────────────────────────────────────────
-- ADD TAB  (R.I.P. VON always stays last)
-- ─────────────────────────────────────────────────────────

function Library:AddTab(tabName)
	local rip=self.TabMap["R.I.P. VON"]
	if rip then rip.Button.LayoutOrder=999 end
	local tab=self:_CreateTabFrame(tabName,false)
	tab.Button.LayoutOrder=#self.Tabs-1
	return tab
end

-- ─────────────────────────────────────────────────────────
-- SET ACTIVE TAB
-- ─────────────────────────────────────────────────────────

function Library:SetActiveTab(tabName)
	if self.ActiveBtn then self.ActiveBtn.TextColor3=Color3.fromRGB(120,120,120) end
	local tab=self.TabMap[tabName]; if not tab then return end
	tab.Button.TextColor3=tabName=="R.I.P. VON" and Color3.fromRGB(200,60,60) or Color3.fromRGB(220,220,220)
	self.ActiveTab=tabName;self.ActiveBtn=tab.Button
	task.defer(function()
		self.TabUnderline.Size=UDim2.new(0,tab.Button.AbsoluteSize.X,0,1)
		self.TabUnderline.Position=UDim2.new(0,tab.Button.AbsolutePosition.X-self.TabContainer.AbsolutePosition.X,0,0)
	end)
	for _,t in ipairs(self.Tabs) do t.Page.Visible=t.Name==tabName end
end

-- ─────────────────────────────────────────────────────────
-- SECTION HEADER
-- ─────────────────────────────────────────────────────────

function Library:MakeSectionHeader(parent,leftText,rightText,yPos,zIdx)
	local h=New("Frame",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(0.5,0,1,0),BackgroundTransparency=1,Text=leftText,TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},h)
	if rightText and rightText~="" then
		New("TextLabel",{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0.5,0,0,0),BackgroundTransparency=1,Text=rightText,TextColor3=Color3.fromRGB(160,160,160),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=zIdx},h)
	end
	New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(45,45,45),BorderSizePixel=0,ZIndex=zIdx},h)
end

-- ─────────────────────────────────────────────────────────
-- TOGGLE
-- ─────────────────────────────────────────────────────────

function Library:MakeToggle(parent,labelText,yPos,zIdx,flagKey,callback)
	local row=New("Frame",{Size=UDim2.new(1,-16,0,28),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	local box=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,ZIndex=zIdx},row)
	Corner(box,2);Stroke(box,Color3.fromRGB(70,70,70),1)
	local check=New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(100,200,100),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1},box)
	New("TextLabel",{Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,24,0,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)
	local enabled=false
	if flagKey then self.Flags[flagKey]=false end
	local hitbox=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=zIdx+2},row)
	hitbox.MouseButton1Click:Connect(function()
		enabled=not enabled;check.Text=enabled and "✓" or ""
		if flagKey then self.Flags[flagKey]=enabled end
		if callback then callback(enabled) end
	end)
	local api={}
	function api:Set(v) enabled=v;check.Text=enabled and "✓" or "";if flagKey then self.Flags[flagKey]=enabled end;if callback then callback(enabled) end end
	function api:Get() return enabled end
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
	Corner(track,4);Stroke(track,Color3.fromRGB(55,55,55),1)
	local p0=(defaultVal-minVal)/(maxVal-minVal)
	local fill=New("Frame",{Size=UDim2.new(p0,0,1,0),BackgroundColor3=Color3.fromRGB(180,180,180),BorderSizePixel=0,ZIndex=zIdx+1},track);Corner(fill,4)
	local knob=New("Frame",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(p0,0,0.5,-5),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.fromRGB(220,220,220),BorderSizePixel=0,ZIndex=zIdx+2},track);Corner(knob,5)
	local hitbox=New("TextButton",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,-7),BackgroundTransparency=1,Text="",ZIndex=zIdx+3},track)
	local current=defaultVal;if flagKey then self.Flags[flagKey]=current end
	local drag=false
	local function upd(x)
		local p=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
		fill.Size=UDim2.new(p,0,1,0);knob.Position=UDim2.new(p,0,0.5,-5)
		current=math.floor((minVal+(maxVal-minVal)*p)*10+0.5)/10
		valLbl.Text=tostring(current);if flagKey then self.Flags[flagKey]=current end;if callback then callback(current) end
	end
	hitbox.MouseButton1Down:Connect(function() drag=true end)
	UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	local api={}
	function api:Set(v)
		current=math.clamp(v,minVal,maxVal);local p=(current-minVal)/(maxVal-minVal)
		fill.Size=UDim2.new(p,0,1,0);knob.Position=UDim2.new(p,0,0.5,-5);valLbl.Text=tostring(current)
		if flagKey then self.Flags[flagKey]=current end;if callback then callback(current) end
	end
	function api:Get() return current end
	return cont,api
end

-- ─────────────────────────────────────────────────────────
-- INTERNAL POPUP HELPER  (positions popup in overlay space)
-- ─────────────────────────────────────────────────────────

function Library:_PositionPopup(popup, anchor)
	-- anchor = the button/widget AbsolutePosition & AbsoluteSize
	local screenSize = self.ScreenGui.AbsoluteSize
	local ax = anchor.AbsolutePosition.X
	local ay = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 2
	local pw = popup.AbsoluteSize.X == 0 and 200 or popup.AbsoluteSize.X
	local ph = popup.Size.Y.Offset

	-- Clamp to screen
	if ax+pw > screenSize.X then ax = screenSize.X - pw - 4 end
	if ay+ph > screenSize.Y then ay = anchor.AbsolutePosition.Y - ph - 2 end

	popup.Position = UDim2.new(0, ax, 0, ay)
end

function Library:_OpenPopup(popup, anchor)
	if self._openPopup and self._openPopup ~= popup then
		self._openPopup.Visible = false
	end
	popup.Parent = self.Overlay
	self:_PositionPopup(popup, anchor)
	popup.Visible = true
	self._openPopup = popup
end

function Library:_ClosePopup(popup)
	popup.Visible = false
	if self._openPopup == popup then self._openPopup = nil end
end

-- ─────────────────────────────────────────────────────────
-- DROPDOWN  (fixed overlap — uses overlay layer)
-- ─────────────────────────────────────────────────────────

function Library:MakeDropdown(parent,labelText,options,yPos,zIdx,flagKey,callback)
	local ITEM_H=22
	local wrapper=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,-15),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(130,130,130),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},wrapper)
	local selected=options[1] or "";if flagKey then self.Flags[flagKey]=selected end
	local mainBtn=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx},wrapper)
	Corner(mainBtn,3);Stroke(mainBtn,Color3.fromRGB(55,55,55),1)
	local selLbl=New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text=selected,TextColor3=Color3.fromRGB(185,185,185),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx+1},mainBtn)
	local arrow=New("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1},mainBtn)

	-- List lives in overlay
	local listFrame=New("Frame",{
		Size=UDim2.new(0,200,0,#options*ITEM_H+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=200,
	},self.Overlay)
	Corner(listFrame,3);Stroke(listFrame,Color3.fromRGB(55,55,55),1)

	local function buildItems(opts)
		for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		listFrame.Size=UDim2.new(0,mainBtn.AbsoluteSize.X>0 and mainBtn.AbsoluteSize.X or 200,0,#opts*ITEM_H+4)
		for idx,opt in ipairs(opts) do
			local item=New("TextButton",{
				Size=UDim2.new(1,0,0,ITEM_H),Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),
				BackgroundTransparency=1,BorderSizePixel=0,Text=opt,
				TextColor3=Color3.fromRGB(165,165,165),TextSize=11,Font=Enum.Font.Code,
				TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=201,
			},listFrame)
			New("UIPadding",{PaddingLeft=UDim.new(0,8)},item)
			item.MouseEnter:Connect(function() item.BackgroundTransparency=0;item.BackgroundColor3=Color3.fromRGB(28,28,28) end)
			item.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
			item.MouseButton1Click:Connect(function()
				selected=opt;selLbl.Text=opt;if flagKey then self.Flags[flagKey]=opt end
				if callback then callback(opt) end
				self:_ClosePopup(listFrame);arrow.Text="▾"
			end)
		end
	end
	buildItems(options)

	mainBtn.MouseButton1Click:Connect(function()
		if listFrame.Visible then
			self:_ClosePopup(listFrame);arrow.Text="▾"
		else
			listFrame.Size=UDim2.new(0,mainBtn.AbsoluteSize.X,0,listFrame.Size.Y.Offset)
			self:_OpenPopup(listFrame,mainBtn);arrow.Text="▴"
		end
	end)

	local api={}
	function api:Get() return selected end
	function api:Set(v) selected=v;selLbl.Text=v;if flagKey then self.Flags[flagKey]=v end;if callback then callback(v) end end
	function api:Refresh(newOpts) buildItems(newOpts) end
	return wrapper,api
end

-- ─────────────────────────────────────────────────────────
-- MULTI-DROPDOWN
-- ─────────────────────────────────────────────────────────

function Library:MakeMultiDropdown(parent,labelText,options,yPos,zIdx,flagKey,callback)
	local ITEM_H=22
	local wrapper=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,-15),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(130,130,130),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},wrapper)
	local selected={};if flagKey then self.Flags[flagKey]={} end
	local mainBtn=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx},wrapper)
	Corner(mainBtn,3);Stroke(mainBtn,Color3.fromRGB(55,55,55),1)
	local selLbl=New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="None",TextColor3=Color3.fromRGB(185,185,185),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx+1},mainBtn)
	local arrow=New("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-22,0,0),BackgroundTransparency=1,Text="▾",TextColor3=Color3.fromRGB(120,120,120),TextSize=12,Font=Enum.Font.Code,ZIndex=zIdx+1},mainBtn)

	local function updateLabel()
		local keys={}; for k in pairs(selected) do table.insert(keys,k) end
		selLbl.Text=#keys==0 and "None" or table.concat(keys,", ")
	end

	local listFrame=New("Frame",{
		Size=UDim2.new(0,200,0,#options*ITEM_H+4),
		BackgroundColor3=Color3.fromRGB(16,16,16),BorderSizePixel=0,Visible=false,ZIndex=200,
	},self.Overlay)
	Corner(listFrame,3);Stroke(listFrame,Color3.fromRGB(55,55,55),1)

	for idx,opt in ipairs(options) do
		local item=New("Frame",{Size=UDim2.new(1,0,0,ITEM_H),Position=UDim2.new(0,0,0,(idx-1)*ITEM_H+2),BackgroundTransparency=1,ZIndex=201},listFrame)
		local chk=New("TextLabel",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,6,0.5,-7),BackgroundColor3=Color3.fromRGB(18,18,18),Text="",TextColor3=Color3.fromRGB(100,200,100),TextSize=10,Font=Enum.Font.Code,BorderSizePixel=0,ZIndex=202},item)
		Corner(chk,2);Stroke(chk,Color3.fromRGB(70,70,70),1)
		New("TextLabel",{Size=UDim2.new(1,-26,1,0),Position=UDim2.new(0,26,0,0),BackgroundTransparency=1,Text=opt,TextColor3=Color3.fromRGB(165,165,165),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},item)
		local hitbox=New("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=203},item)
		hitbox.MouseEnter:Connect(function() item.BackgroundTransparency=0;item.BackgroundColor3=Color3.fromRGB(22,22,22) end)
		hitbox.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
		hitbox.MouseButton1Click:Connect(function()
			if selected[opt] then selected[opt]=nil;chk.Text=""
			else selected[opt]=true;chk.Text="✓" end
			updateLabel()
			local arr={}; for k in pairs(selected) do table.insert(arr,k) end
			if flagKey then self.Flags[flagKey]=arr end
			if callback then callback(arr) end
		end)
	end

	mainBtn.MouseButton1Click:Connect(function()
		if listFrame.Visible then self:_ClosePopup(listFrame);arrow.Text="▾"
		else listFrame.Size=UDim2.new(0,mainBtn.AbsoluteSize.X,0,listFrame.Size.Y.Offset);self:_OpenPopup(listFrame,mainBtn);arrow.Text="▴" end
	end)

	local api={}
	function api:Get() local a={};for k in pairs(selected) do table.insert(a,k) end return a end
	function api:Set(arr) selected={};for _,v in ipairs(arr) do selected[v]=true end;updateLabel() end
	return wrapper,api
end

-- ─────────────────────────────────────────────────────────
-- COLOR PICKER
-- ─────────────────────────────────────────────────────────

function Library:MakeColorPicker(parent,labelText,defaultColor,yPos,zIdx,flagKey,callback)
	defaultColor=defaultColor or Color3.new(1,0,0)
	local h0,s0,v0=RGBtoHSV(defaultColor)
	local hue,sat,val=h0,s0,v0
	if flagKey then self.Flags[flagKey]=colorToTable(defaultColor) end

	local row=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,-36,1,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)

	local preview=New("TextButton",{Size=UDim2.new(0,24,0,18),Position=UDim2.new(1,-28,0.5,-9),BackgroundColor3=defaultColor,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=zIdx+1},row)
	Corner(preview,3);Stroke(preview,Color3.fromRGB(70,70,70),1)

	-- Picker popup
	local PW,PH=220,230
	local picker=New("Frame",{
		Size=UDim2.new(0,PW,0,PH),BackgroundColor3=Color3.fromRGB(14,14,14),
		BorderSizePixel=0,Visible=false,ZIndex=200,
	},self.Overlay)
	Corner(picker,5);Stroke(picker,Color3.fromRGB(50,50,50),1)

	-- Hue/Saturation gradient (the uploaded image asset)
	local satBox=New("ImageButton",{
		Size=UDim2.new(1,-16,0,120),Position=UDim2.new(0,8,0,8),
		BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,
		Image="rbxassetid://2529273",AutoButtonColor=false,ZIndex=201,
	},picker)
	Corner(satBox,3)
	-- White→transparent overlay for saturation
	New("UIGradient",{Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
	}),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),Rotation=90},satBox)

	local satCursor=New("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=203},satBox)
	Corner(satCursor,5);Stroke(satCursor,Color3.fromRGB(0,0,0),1)

	-- Value (brightness) slider
	local valTrack=New("Frame",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,136),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=201},picker)
	Corner(valTrack,3)
	New("UIGradient",{Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(1,1,1)),Rotation=0},valTrack)
	local valKnob=New("Frame",{Size=UDim2.new(0,10,1,2),Position=UDim2.new(1,0,0,-1),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=202},valTrack)
	Corner(valKnob,2);Stroke(valKnob,Color3.fromRGB(0,0,0),1)

	-- Alpha (opacity) slider
	New("TextLabel",{Size=UDim2.new(1,-16,0,12),Position=UDim2.new(0,8,0,154),BackgroundTransparency=1,Text="Opacity",TextColor3=Color3.fromRGB(100,100,100),TextSize=9,Font=Enum.Font.Code,ZIndex=201},picker)
	local alphaTrack=New("Frame",{Size=UDim2.new(1,-16,0,10),Position=UDim2.new(0,8,0,166),BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=201},picker)
	Corner(alphaTrack,3)
	New("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}),Rotation=0},alphaTrack)
	local alphaKnob=New("Frame",{Size=UDim2.new(0,10,1,2),Position=UDim2.new(1,0,0,-1),AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=202},alphaTrack)
	Corner(alphaKnob,2);Stroke(alphaKnob,Color3.fromRGB(0,0,0),1)
	local alpha=1

	-- RGB hex display
	local hexBox=New("TextBox",{
		Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,182),
		BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0,
		Text=string.format("%02X%02X%02X",math.floor(defaultColor.R*255),math.floor(defaultColor.G*255),math.floor(defaultColor.B*255)),
		PlaceholderText="RRGGBB",TextColor3=Color3.fromRGB(200,200,200),
		PlaceholderColor3=Color3.fromRGB(80,80,80),TextSize=11,Font=Enum.Font.Code,
		ClearTextOnFocus=false,ZIndex=201,
	},picker)
	Corner(hexBox,3);Stroke(hexBox,Color3.fromRGB(50,50,50),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,8)},hexBox)

	-- Color preview swatch inside picker
	local swatchInner=New("Frame",{Size=UDim2.new(0,24,0,22),Position=UDim2.new(1,-32,0,182),BackgroundColor3=defaultColor,BorderSizePixel=0,ZIndex=201},picker)
	Corner(swatchInner,3);Stroke(swatchInner,Color3.fromRGB(50,50,50),1)

	local function getColor() return HSVtoRGB(hue,sat,val) end

	local function updateUI()
		local c=getColor()
		preview.BackgroundColor3=c;swatchInner.BackgroundColor3=c
		satCursor.BackgroundColor3=c
		hexBox.Text=string.format("%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
		valKnob.Position=UDim2.new(val,0,0,-1)
		-- Update satBox tint to show current hue
		satBox.BackgroundColor3=HSVtoRGB(hue,1,1)
		satCursor.Position=UDim2.new(hue,0,1-sat,0)
		if flagKey then self.Flags[flagKey]=colorToTable(c) end
		if callback then callback(c,alpha) end
	end

	-- Drag on satBox for hue+saturation
	local satDrag=false
	satBox.MouseButton1Down:Connect(function() satDrag=true end)
	UIS.InputChanged:Connect(function(i)
		if satDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
			hue=math.clamp((i.Position.X-satBox.AbsolutePosition.X)/satBox.AbsoluteSize.X,0,0.9999)
			sat=1-math.clamp((i.Position.Y-satBox.AbsolutePosition.Y)/satBox.AbsoluteSize.Y,0,1)
			updateUI()
		end
	end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then satDrag=false end end)

	-- Drag on value slider
	local valDrag=false
	local valHitbox=New("TextButton",{Size=UDim2.new(1,0,1,4),Position=UDim2.new(0,0,0,-2),BackgroundTransparency=1,Text="",ZIndex=203},valTrack)
	valHitbox.MouseButton1Down:Connect(function() valDrag=true end)
	UIS.InputChanged:Connect(function(i)
		if valDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
			val=math.clamp((i.Position.X-valTrack.AbsolutePosition.X)/valTrack.AbsoluteSize.X,0,1)
			updateUI()
		end
	end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then valDrag=false end end)

	-- Drag on alpha slider
	local alphaDrag=false
	local alphaHitbox=New("TextButton",{Size=UDim2.new(1,0,1,4),Position=UDim2.new(0,0,0,-2),BackgroundTransparency=1,Text="",ZIndex=203},alphaTrack)
	alphaHitbox.MouseButton1Down:Connect(function() alphaDrag=true end)
	UIS.InputChanged:Connect(function(i)
		if alphaDrag and i.UserInputType==Enum.UserInputType.MouseMovement then
			alpha=math.clamp((i.Position.X-alphaTrack.AbsolutePosition.X)/alphaTrack.AbsoluteSize.X,0,1)
			alphaKnob.Position=UDim2.new(alpha,0,0,-1)
			if callback then callback(getColor(),alpha) end
		end
	end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then alphaDrag=false end end)

	-- Hex input
	hexBox.FocusLost:Connect(function()
		local hex=hexBox.Text:gsub("[^%x]",""):sub(1,6)
		if #hex==6 then
			local r=tonumber(hex:sub(1,2),16)/255
			local g=tonumber(hex:sub(3,4),16)/255
			local b=tonumber(hex:sub(5,6),16)/255
			local c=Color3.new(r,g,b)
			hue,sat,val=RGBtoHSV(c);updateUI()
		end
	end)

	preview.MouseButton1Click:Connect(function()
		if picker.Visible then self:_ClosePopup(picker)
		else self:_OpenPopup(picker,preview) end
	end)

	updateUI()

	local api={}
	function api:Get() return getColor(),alpha end
	function api:Set(c,a)
		hue,sat,val=RGBtoHSV(c);alpha=a or 1;updateUI()
		alphaKnob.Position=UDim2.new(alpha,0,0,-1)
	end
	return row,api
end

-- ─────────────────────────────────────────────────────────
-- KEY PICKER  (binds a key, shows in button)
-- ─────────────────────────────────────────────────────────

function Library:MakeKeyPicker(parent,labelText,defaultKey,yPos,zIdx,flagKey,callback)
	defaultKey=defaultKey or Enum.KeyCode.Unknown
	local current=defaultKey;local listening=false
	if flagKey then self.Flags[flagKey]=defaultKey.Name end

	local row=New("Frame",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,yPos),BackgroundTransparency=1,ZIndex=zIdx},parent)
	New("TextLabel",{Size=UDim2.new(1,-80,1,0),BackgroundTransparency=1,Text=labelText,TextColor3=Color3.fromRGB(175,175,175),TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=zIdx},row)
	local keyBtn=New("TextButton",{Size=UDim2.new(0,70,0,20),Position=UDim2.new(1,-74,0.5,-10),BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,Text=defaultKey==Enum.KeyCode.Unknown and "NONE" or defaultKey.Name,TextColor3=Color3.fromRGB(180,180,180),TextSize=10,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=zIdx+1},row)
	Corner(keyBtn,3);Stroke(keyBtn,Color3.fromRGB(55,55,55),1)

	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening=true;keyBtn.Text="...";keyBtn.TextColor3=Color3.fromRGB(200,200,100)
	end)

	UIS.InputBegan:Connect(function(i,gp)
		if not listening then return end
		if i.UserInputType==Enum.UserInputType.Keyboard then
			listening=false;current=i.KeyCode
			keyBtn.Text=current.Name;keyBtn.TextColor3=Color3.fromRGB(180,180,180)
			if flagKey then self.Flags[flagKey]=current.Name end
			if callback then callback(current) end
			-- Register in bind list
			table.insert(self.BindList,{Label=labelText,Key=current.Name})
		end
	end)

	local api={}
	function api:Get() return current end
	function api:Set(k) current=k;keyBtn.Text=k.Name;if flagKey then self.Flags[flagKey]=k.Name end end
	return row,api
end

-- ─────────────────────────────────────────────────────────
-- KEYBIND LIST  (floating window showing all active binds)
-- ─────────────────────────────────────────────────────────

function Library:CreateKeybindList()
	local win=New("Frame",{
		Name="KeybindList",Size=UDim2.new(0,160,0,30),
		Position=UDim2.new(1,-170,1,-40),
		BackgroundColor3=Color3.fromRGB(10,10,10),BorderSizePixel=0,ZIndex=50,
	},self.ScreenGui)
	Corner(win,4);Stroke(win,Color3.fromRGB(40,40,40),1)

	New("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundColor3=Color3.fromRGB(14,14,14),BorderSizePixel=0,Text=" KEYBINDS",TextColor3=Color3.fromRGB(140,140,140),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51},win)
	New("UICorner",{CornerRadius=UDim.new(0,4)},win:FindFirstChildOfClass("TextLabel"))

	local list=New("Frame",{Size=UDim2.new(1,0,1,-20),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,ZIndex=51},win)
	New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)},list)

	Draggable(win, win:FindFirstChildOfClass("TextLabel"))
	self.BindListWindow=win;self.BindListContainer=list

	RUN.Heartbeat:Connect(function()
		for _,c in ipairs(list:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local count=0
		for _,b in ipairs(self.BindList) do
			count=count+1
			local row=New("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,ZIndex=52,LayoutOrder=count},list)
			New("TextLabel",{Size=UDim2.new(0.65,0,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text=b.Label,TextColor3=Color3.fromRGB(155,155,155),TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=52},row)
			New("TextLabel",{Size=UDim2.new(0.35,-4,1,0),Position=UDim2.new(0.65,0,0,0),BackgroundTransparency=1,Text=b.Key,TextColor3=Color3.fromRGB(200,200,100),TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=52},row)
		end
		win.Size=UDim2.new(0,160,0,20+count*18+2)
	end)

	return win
end

-- ─────────────────────────────────────────────────────────
-- CONFIG TAB (built-in)
-- ─────────────────────────────────────────────────────────

function Library:_BuildConfigTab(tab)
	local lp,rp=tab.LeftPanel,tab.RightPanel

	self:MakeSectionHeader(lp,"SAVE CONFIG","",8,3)
	local inputBox=New("TextBox",{
		Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,36),
		BackgroundColor3=Color3.fromRGB(18,18,18),BorderSizePixel=0,
		Text="",PlaceholderText="Config name...",
		TextColor3=Color3.fromRGB(185,185,185),PlaceholderColor3=Color3.fromRGB(80,80,80),
		TextSize=11,Font=Enum.Font.Code,ClearTextOnFocus=false,ZIndex=3,
	},lp)
	Corner(inputBox,3);Stroke(inputBox,Color3.fromRGB(55,55,55),1)
	New("UIPadding",{PaddingLeft=UDim.new(0,8)},inputBox)

	local saveBtn=New("TextButton",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,68),BackgroundColor3=Color3.fromRGB(22,22,22),BorderSizePixel=0,Text="SAVE CONFIG",TextColor3=Color3.fromRGB(180,180,180),TextSize=11,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=3},lp)
	Corner(saveBtn,3);Stroke(saveBtn,Color3.fromRGB(55,55,55),1)

	self:MakeSectionHeader(rp,"LOAD / DELETE","",8,3)

	local _, ddApi=self:MakeDropdown(rp,"Select Config",self.Config:List(),40,3,nil,nil)
	self._configDropdown=ddApi

	local loadBtn=New("TextButton",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,84),BackgroundColor3=Color3.fromRGB(22,22,22),BorderSizePixel=0,Text="LOAD CONFIG",TextColor3=Color3.fromRGB(180,180,180),TextSize=11,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=3},rp)
	Corner(loadBtn,3);Stroke(loadBtn,Color3.fromRGB(55,55,55),1)

	local delBtn=New("TextButton",{Size=UDim2.new(1,-16,0,26),Position=UDim2.new(0,8,0,116),BackgroundColor3=Color3.fromRGB(22,22,22),BorderSizePixel=0,Text="DELETE CONFIG",TextColor3=Color3.fromRGB(180,80,80),TextSize=11,Font=Enum.Font.Code,AutoButtonColor=false,ZIndex=3},rp)
	Corner(delBtn,3);Stroke(delBtn,Color3.fromRGB(80,40,40),1)

	local statusLbl=New("TextLabel",{Size=UDim2.new(1,-16,0,18),Position=UDim2.new(0,8,0,148),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(100,200,100),TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},rp)

	local function setStatus(msg,col)
		statusLbl.Text=msg;statusLbl.TextColor3=col or Color3.fromRGB(100,200,100)
		task.delay(3,function() if statusLbl.Parent then statusLbl.Text="" end end)
	end
	for _,b in ipairs({saveBtn,loadBtn,delBtn}) do
		b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(28,28,28) end)
		b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(22,22,22) end)
	end

	saveBtn.MouseButton1Click:Connect(function()
		local name=inputBox.Text
		if name=="" then setStatus("Enter a name.",Color3.fromRGB(200,80,80)) return end
		self.Config:Save(name,self.Flags)
		ddApi:Refresh(self.Config:List())
		setStatus("Saved: "..name)
	end)

	loadBtn.MouseButton1Click:Connect(function()
		local name=ddApi:Get()
		if not name or name=="" then setStatus("No config selected.",Color3.fromRGB(200,80,80)) return end
		local data=self.Config:Load(name)
		if not data then setStatus("Failed to load.",Color3.fromRGB(200,80,80)) return end
		for k,v in pairs(data) do
			self.Flags[k]=v
			if self._flagApis[k] then
				-- Handle Color3 tables
				if type(v)=="table" and v.R then
					self._flagApis[k]:Set(tableToColor(v))
				else
					self._flagApis[k]:Set(v)
				end
			end
		end
		setStatus("Loaded: "..name)
	end)

	delBtn.MouseButton1Click:Connect(function()
		local name=ddApi:Get()
		if not name or name=="" then setStatus("No config selected.",Color3.fromRGB(200,80,80)) return end
		self.Config:Delete(name)
		ddApi:Refresh(self.Config:List())
		setStatus("Deleted: "..name,Color3.fromRGB(200,80,80))
	end)
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
