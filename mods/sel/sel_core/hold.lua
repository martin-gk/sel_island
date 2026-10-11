--[[
    hold.lua - "everyone stand here together for N seconds"
    =======================================================

    Several activities end with a group hold: all children stand on a
    platform / plates / pumps at the same time for 3 seconds. If anyone
    steps off, the count starts over. This file implements that once.

    Usage:

        local hold = sel_core.register_hold({
            seconds   = 3,      -- how long the group must hold
            countdown = true,   -- show big 3, 2, 1 numbers + tick sounds

            -- Called twice per second. Return the list of player objects
            -- that are currently taking part, and true/false for "is the
            -- condition fulfilled right now?".
            check = function()
                local players = ...
                return players, #players >= 2
            end,

            -- Called once when the hold succeeds.
            on_complete = function(players) ... end,
        })

        hold.enabled = false   -- pause it (e.g. activity already finished)

    After a success the hold re-arms only when the condition stops being
    true (everybody stepped off), so it does not fire again and again.
]]

local TICK = 0.5 -- seconds between checks

local holds = {} -- all registered holds

function sel_core.register_hold(def)
	local hold = {
		def = def,
		enabled = true,
		elapsed = 0,       -- seconds the condition has been true so far
		armed = true,      -- false right after a success, until people step off
		shown_to = {},     -- player name -> true while countdown is shown
	}
	table.insert(holds, hold)
	return hold
end

-- Remove the countdown from everybody who currently sees it.
local function hide_countdown(hold)
	for name in pairs(hold.shown_to) do
		local player = core.get_player_by_name(name)
		if player then
			sel_core.hide_big_text(player)
		end
	end
	hold.shown_to = {}
end

-- Show "3", "2", "1" to the participating players and hide it from players
-- who are no longer participating.
local function show_countdown(hold, players, number)
	local now = {}
	for _, player in ipairs(players) do
		local name = player:get_player_name()
		now[name] = true
		sel_core.show_big_text(player, tostring(number), 0xFFE066)
	end
	for name in pairs(hold.shown_to) do
		if not now[name] then
			local player = core.get_player_by_name(name)
			if player then
				sel_core.hide_big_text(player)
			end
		end
	end
	hold.shown_to = now
end

local function update(hold, dtime)
	local def = hold.def
	local players, ok = def.check()
	players = players or {}

	-- Just succeeded: wait until the condition is false once, then re-arm.
	if not hold.armed then
		if not ok then
			hold.armed = true
		end
		return
	end

	if ok then
		local before = hold.elapsed
		hold.elapsed = hold.elapsed + dtime

		if hold.elapsed >= def.seconds then
			-- Success!
			hide_countdown(hold)
			hold.elapsed = 0
			hold.armed = false
			def.on_complete(players)
		elseif def.countdown then
			-- Seconds left, rounded up: 3 -> 2 -> 1
			local left = math.ceil(def.seconds - hold.elapsed)
			show_countdown(hold, players, left)
			-- One tick sound whenever a new second starts.
			if math.ceil(def.seconds - before) ~= left or before == 0 then
				for _, player in ipairs(players) do
					sel_core.play("sel_core_tick", player, 0.8)
				end
			end
		end
	elseif hold.elapsed > 0 then
		-- Somebody stepped off: start over from zero.
		hold.elapsed = 0
		if def.countdown then
			for name in pairs(hold.shown_to) do
				local player = core.get_player_by_name(name)
				if player then
					sel_core.play("sel_core_reset", player, 0.8)
				end
			end
		end
		hide_countdown(hold)
	end
end

local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < TICK then
		return
	end
	local step = timer
	timer = 0
	for _, hold in ipairs(holds) do
		if hold.enabled then
			update(hold, step)
		end
	end
end)
