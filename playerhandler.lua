-- ==================== PLAYER HANDLER (GitHub-stable) ====================
local function initPlayerHandler()
	-- Add existing players
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			espCache[plr] = createESP()
		end
	end
	
	-- PlayerAdded
	Players.PlayerAdded:Connect(function(plr)
		if plr ~= LocalPlayer then
			espCache[plr] = createESP()
		end
	end)
	
	-- PlayerRemoving + cleanup
	Players.PlayerRemoving:Connect(function(plr)
		if espCache[plr] then
			local obj = espCache[plr]
			for _, v in pairs(obj) do
				if typeof(v) == "table" then
					for __, line in ipairs(v) do
						if line and line.Destroy then line:Destroy() end
					end
				elseif v and v.Destroy then
					v:Destroy()
				end
			end
			espCache[plr] = nil
		end
	end)
end

-- ==================== MAIN LOOP ====================
initPlayerHandler()

RunService.RenderStepped:Connect(function()
	for player, objects in pairs(espCache) do
		updateESP(player, objects)
	end
end)
