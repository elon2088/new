
local PlayerHandler = {}
local Players = game:GetService("Players")

-- Add names or UserIds to ignore specific players
PlayerHandler.Blacklist = {
    -- ["PlayerName"] = true,
    -- [12345678] = true,
}

-- If populated, ONLY these players are tracked (leave empty for all)
PlayerHandler.Whitelist = {
    -- ["PlayerName"] = true,
    -- [12345678] = true,
}

-- Returns filtered list of valid target players
function PlayerHandler:GetPlayers()
    local list = {}
    local lp = Players.LocalPlayer

    for _, p in ipairs(Players:GetPlayers()) do
        if p == lp then continue end
        if self.Blacklist[p.Name] or self.Blacklist[p.UserId] then continue end
        if next(self.Whitelist) and not (self.Whitelist[p.Name] or self.Whitelist[p.UserId]) then continue end
        table.insert(list, p)
    end

    return list
end

-- Checks if a specific player should be tracked
function PlayerHandler:IsTracked(player)
    if player == Players.LocalPlayer then return false end
    if self.Blacklist[player.Name] or self.Blacklist[player.UserId] then return false end
    if next(self.Whitelist) and not (self.Whitelist[player.Name] or self.Whitelist[player.UserId]) then return false end
    return true
end

return PlayerHandler
