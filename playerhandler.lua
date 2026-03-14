-- PlayerHandler.lua
-- Manages tracked players and their ESP state

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerHandler = {}
PlayerHandler.__index = PlayerHandler

export type PlayerData = {
    Player: Player,
    Character: Model?,
    HumanoidRootPart: BasePart?,
    Humanoid: Humanoid?,
    Enabled: boolean,
}

function PlayerHandler.new(): typeof(setmetatable({} :: any, PlayerHandler))
    local self = setmetatable({}, PlayerHandler)
    self._players = {} :: { [Player]: PlayerData }
    self._callbacks = {
        onAdded   = {} :: { (PlayerData) -> () },
        onRemoved = {} :: { (Player) -> () },
        onRespawn = {} :: { (PlayerData) -> () },
    }
    self._connections = {} :: { RBXScriptConnection }
    return self
end

function PlayerHandler:_registerCharacter(player: Player, character: Model)
    local data = self._players[player]
    if not data then return end

    data.Character          = character
    data.HumanoidRootPart   = character:WaitForChild("HumanoidRootPart", 5) :: BasePart
    data.Humanoid           = character:WaitForChild("Humanoid", 5) :: Humanoid

    for _, cb in self._callbacks.onRespawn do
        task.spawn(cb, data)
    end
end

function PlayerHandler:_addPlayer(player: Player)
    if player == LocalPlayer then return end

    local data: PlayerData = {
        Player    = player,
        Character = nil,
        HumanoidRootPart = nil,
        Humanoid  = nil,
        Enabled   = true,
    }
    self._players[player] = data

    if player.Character then
        self:_registerCharacter(player, player.Character)
    end

    table.insert(self._connections,
        player.CharacterAdded:Connect(function(char)
            self:_registerCharacter(player, char)
        end)
    )

    for _, cb in self._callbacks.onAdded do
        task.spawn(cb, data)
    end
end

function PlayerHandler:_removePlayer(player: Player)
    self._players[player] = nil
    for _, cb in self._callbacks.onRemoved do
        task.spawn(cb, player)
    end
end

function PlayerHandler:Start()
    for _, player in Players:GetPlayers() do
        self:_addPlayer(player)
    end

    table.insert(self._connections,
        Players.PlayerAdded:Connect(function(p) self:_addPlayer(p) end)
    )
    table.insert(self._connections,
        Players.PlayerRemoving:Connect(function(p) self:_removePlayer(p) end)
    )
end

function PlayerHandler:Stop()
    for _, conn in self._connections do conn:Disconnect() end
    table.clear(self._connections)
    table.clear(self._players)
end

function PlayerHandler:GetPlayers(): { PlayerData }
    local out = {}
    for _, data in self._players do
        table.insert(out, data)
    end
    return out
end

function PlayerHandler:OnPlayerAdded(cb: (PlayerData) -> ())
    table.insert(self._callbacks.onAdded, cb)
end

function PlayerHandler:OnPlayerRemoved(cb: (Player) -> ())
    table.insert(self._callbacks.onRemoved, cb)
end

function PlayerHandler:OnPlayerRespawn(cb: (PlayerData) -> ())
    table.insert(self._callbacks.onRespawn, cb)
end

return PlayerHandler
