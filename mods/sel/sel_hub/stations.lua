--[[
    stations.lua - what happens at each of the six stations
    =======================================================

    Every station follows the same pattern:
      1. detect that the child did the thing
      2. give feedback (sound + sparkles)  -> always, so it feels responsive
      3. sel_hub.mark_done(player, n)      -> lights up icon n

    The FIRST time a station is done the child hears the "chime" sound;
    repeating a station only gives sparkles.

    Finishing the course (crystal) gives the Builder's Tool.
]]

local L = sel_hub.layout
local C = sel_core.colors

-- Common feedback for a completed station.
local function station_done(player, number, pos, color)
	sel_core.sparkle(vector.offset(pos, 0, 0.5, 0), color, 30)
	if sel_hub.mark_done(player, number) then
		sel_core.play("sel_core_chime", player)
	end
end

----------------------------------------------------------------------------
-- 1. WALK - step on the blue marker
----------------------------------------------------------------------------
function sel_hub.on_start_marker(pos, player)
	station_done(player, 1, pos, C.blue)
end

----------------------------------------------------------------------------
-- 2. BREAK - dig the shiny block. A reward pops out, the block comes back.
----------------------------------------------------------------------------
function sel_hub.on_shiny_dug(pos, digger)
	-- The reward jumps out of the hole like a little fountain.
	local item = core.add_item(pos, sel_hub.REWARD_ITEM)
	if item then
		item:set_velocity({x = math.random() - 0.5, y = 4, z = math.random() - 0.5})
	end

	if digger and digger:is_player() then
		station_done(digger, 2, pos, C.gold)
	end

	-- Put the shiny block back after a moment (if nothing else is there).
	core.after(sel_hub.SHINY_RESPAWN_TIME, function()
		if core.get_node(pos).name == "air" then
			core.set_node(pos, {name = "sel_hub:shiny_block"})
			sel_core.sparkle(pos, C.gold, 12)
		end
	end)
end

----------------------------------------------------------------------------
-- 3. PLACE - put any block on top of the green marker
----------------------------------------------------------------------------
-- The block placed on the marker sits one above it.
local place_spot = vector.offset(L.place_marker, 0, 1, 0)

core.register_on_placenode(function(pos, newnode, placer)
	if not vector.equals(pos, place_spot) then
		return
	end
	if placer and placer:is_player() then
		station_done(placer, 3, pos, C.gold)
	end
	-- Clear the marker again after a few seconds for the next child.
	core.after(sel_hub.PLACED_BLOCK_TIME, function()
		if core.get_node(pos).name == newnode.name then
			core.remove_node(pos)
			sel_core.sparkle(pos, C.green, 10)
		end
	end)
end)

----------------------------------------------------------------------------
-- 4. JUMP - land on the yellow markers behind the gap
----------------------------------------------------------------------------
function sel_hub.on_landing(pos, player)
	station_done(player, 4, pos, C.gold)
end

----------------------------------------------------------------------------
-- 5. TOGETHER - two children on the two orange plates at the same time
----------------------------------------------------------------------------
-- How many plates must be occupied? Normally both. If only ONE player is
-- online (e.g. the teacher testing, or a child alone), one plate is enough,
-- following the "small groups" rule of the other activities.
local function plates_needed()
	return math.min(#L.plates, #core.get_connected_players())
end

sel_core.register_hold({
	seconds = sel_hub.TOGETHER_SECONDS,
	countdown = false, -- one second is too short for 3-2-1 numbers

	check = function()
		local on_plates = sel_core.players_on_positions(L.plates)
		-- count DIFFERENT plates that are occupied
		local occupied, players = {}, {}
		for _, entry in ipairs(on_plates) do
			occupied[entry.index] = true
			table.insert(players, entry.player)
		end
		local count = 0
		for _ in pairs(occupied) do
			count = count + 1
		end
		return players, count >= plates_needed() and count > 0
	end,

	on_complete = function(players)
		for _, player in ipairs(players) do
			station_done(player, 5, sel_core.pos_under(player), C.orange)
		end
		-- a little extra cheer for working together
		sel_core.play("sel_core_success", L.plates[1], 0.7)
	end,
})

----------------------------------------------------------------------------
-- 6. FINISH - step on the crystal: fireworks!
----------------------------------------------------------------------------
-- Fireworks at most every few seconds, even if several children arrive
-- one after another (keeps it special and not too noisy).
local FIREWORK_COOLDOWN = 4
local last_firework = -FIREWORK_COOLDOWN

function sel_hub.on_crystal(pos, player)
	local first_time = sel_hub.mark_done(player, 6)
	sel_core.sparkle(vector.offset(pos, 0, 0.5, 0), C.purple, 40)

	local now = core.get_us_time() / 1e6
	if now - last_firework >= FIREWORK_COOLDOWN then
		last_firework = now
		sel_core.fireworks(L.crystal_center)
	end

	if first_time then
		-- Reward for finishing: the Builder's Tool (see sel_core/items.lua).
		-- From now on the child can dig and build freely on the island.
		sel_core.ensure_tool(player)
		-- ... and their own Breathing Flower to plant when they need calm.
		sel_flower.ensure_flower(player)

		-- After finishing, the icon row stays a moment, then disappears.
		local name = player:get_player_name()
		core.after(sel_hub.HUD_LINGER_TIME, function()
			-- the player may have left in the meantime
			local p = core.get_player_by_name(name)
			if p and sel_hub.is_finished(p) then
				sel_hub.hide_hud(p)
			end
		end)
	end
end
