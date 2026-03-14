
local PlayerHandler = {}
PlayerHandler.__index = PlayerHandler

local Players = game:GetService("Players")

function PlayerHandler.new()
    local self = setmetatable({}, PlayerHandler)
    self._list        = {}
    self._onAdd       = {}
    self._onRemove    = {}
    self._connections = {}

    -- Populate existing players
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            self._list[p] = true
        end
    end

    local addConn = Players.PlayerAdded:Connect(function(p)
        if p == Players.LocalPlayer then return end
        self._list[p] = true
        for _, cb in next, self._onAdd do task.spawn(cb, p) end
    end)

    local removeConn = Players.PlayerRemoving:Connect(function(p)
        if not self._list[p] then return end
        self._list[p] = nil
        for _, cb in next, self._onRemove do task.spawn(cb, p) end
    end)

    self._connections = { addConn, removeConn }
    return self
end

-- Register add callback; also fires immediately for all current players
function PlayerHandler:OnAdded(cb)
    self._onAdd[#self._onAdd + 1] = cb
    for p in next, self._list do task.spawn(cb, p) end
end

function PlayerHandler:OnRemoved(cb)
    self._onRemove[#self._onRemove + 1] = cb
end

function PlayerHandler:GetPlayers()
    local t = {}
    for p in next, self._list do t[#t + 1] = p end
    return t
end

function PlayerHandler:Destroy()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    table.clear(self._list)
    table.clear(self._onAdd)
    table.clear(self._onRemove)
end

return PlayerHandler
