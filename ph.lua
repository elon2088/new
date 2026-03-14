local Players = game:GetService("Players")

local PlayerHandler = {}
PlayerHandler.__index = PlayerHandler

PlayerHandler.PlayerAdded = Instance.new("BindableEvent")
PlayerHandler.PlayerRemoving = Instance.new("BindableEvent")

function PlayerHandler:GetPlayers()
    return Players:GetPlayers()
end


Players.PlayerAdded:Connect(function(player)
    PlayerHandler.PlayerAdded:Fire(player)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerHandler.PlayerRemoving:Fire(player)
end)

return PlayerHandler
