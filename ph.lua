-- PlayerHandler.lua
-- Responsible only for managing players

local Players = game:GetService("Players")

export type PlayerData = {
	Player: Player,
	Character: Model?,
	Humanoid: Humanoid?,
	Root: BasePart?
}

local Handler = {}
Handler.__index = Handler

function Handler.new()
	local self = setmetatable({}, Handler)
	self.Players = {}
	return self
end

function Handler:Track(player: Player)
	if player == Players.LocalPlayer then
		return
	end

	local data: PlayerData = {
		Player = player,
		Character = nil,
		Humanoid = nil,
		Root = nil
	}

	self.Players[player] = data

	local function characterAdded(char: Model)
		data.Character = char
		data.Humanoid = char:WaitForChild("Humanoid",5)
		data.Root = char:WaitForChild("HumanoidRootPart",5)
	end

	if player.Character then
		characterAdded(player.Character)
	end

	player.CharacterAdded:Connect(characterAdded)

	player.CharacterRemoving:Connect(function()
		data.Character = nil
		data.Humanoid = nil
		data.Root = nil
	end)
end

function Handler:Remove(player: Player)
	self.Players[player] = nil
end

function Handler:GetPlayers()
	return self.Players
end

return Handler
