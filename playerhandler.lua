-- PlayerHandler.lua
-- Host on GitHub and loadstring() from your ESP loader

local PlayerHandler = {}
PlayerHandler.__index = PlayerHandler

-- Config
PlayerHandler.Config = {
    Enabled = true,
    BoxColor = Color3.fromRGB(0, 170, 255),       -- cyan-blue from image
    OutlineColor = Color3.fromRGB(0, 0, 0),
    HealthBarColor = Color3.fromRGB(0, 255, 80),
    HealthBarBGColor = Color3.fromRGB(180, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(200, 200, 200),
    ToolColor = Color3.fromRGB(200, 200, 200),
    TextSize = 13,
    BoxThickness = 1.5,
    OutlineThickness = 3,
    HealthBarWidth = 3,
    HealthBarOffset = 5,
    MaxDistance = 1000,
    TeamCheck = false,
}

function PlayerHandler.new()
    return setmetatable({ Players = {} }, PlayerHandler)
end

function PlayerHandler:Add(player)
    if not self.Players[player] then
        self.Players[player] = true
    end
end

function PlayerHandler:Remove(player)
    self.Players[player] = nil
end

function PlayerHandler:GetAll()
    local list = {}
    for p in pairs(self.Players) do
        list[#list + 1] = p
    end
    return list
end

function PlayerHandler:Clear()
    self.Players = {}
end

return PlayerHandler
