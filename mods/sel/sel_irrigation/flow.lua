--[[
    flow.lua - the pumps, tracing the channel, the water, reset
    ===========================================================

    1. HOLD   Every child in the field stands on their OWN pump for 3
              seconds (big 3-2-1). If anyone steps off, or one child is not
              on a pump, the count starts over.
    2. TRACE  Starting at the blue Water Source block, follow all channel
              blocks and pumps that touch each other. Remember how many
              steps from the source each one is.
    3. FLOW   The water runs through exactly those blocks, block after
              block (they change to their "wet" look).
    4. RESULT - The traced channel touches the garden bed AND every child's
                pump is part of it: the garden blooms, the dry half of the
                field turns green, fireworks, home pad.
              - Otherwise: the water simply stops where the channel stops.
                After a few seconds the channel runs dry again. The children
                see where the water ended and look for the gap.

    States: "building" -> "flowing" -> back to "building" (gap) or "done".
    "done" is remembered across server restarts until the teacher types
    /sel irrigation_reset.
]]

local S = sel_irrigation.S
local L = sel_irrigation.layout
local storage = core.get_mod_storage()

sel_irrigation.state = storage:get_string("state") == "done" and "done" or "building"

local function set_state(state)
	sel_irrigation.state = state
	storage:set_string("state", state)
end

local WET = {
	["sel_irrigation:channel"] = "sel_irrigation:channel_wet",
	["sel_irrigation:pump"] = "sel_irrigation:pump_wet",
}
local DRY = {
	["sel_irrigation:channel_wet"] = "sel_irrigation:channel",
	["sel_irrigation:pump_wet"] = "sel_irrigation:pump",
}

local NEIGHBOURS = {
	{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0},
	{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0},
	{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},
}

----------------------------------------------------------------------------
-- Tracing the channel
----------------------------------------------------------------------------
-- Follows the channel from the Water Source. Returns
--   blocks         list of {pos=, steps=} in the order the water reaches them
--   contains(pos)  is this position part of the traced channel?
--   reaches_garden true if a traced block touches the garden bed
function sel_irrigation.trace()
	local result = {blocks = {}, reaches_garden = false}
	local seen = {}
	local queue = {}

	local function visit(pos, steps)
		local key = core.hash_node_position(pos)
		if seen[key] or not sel_irrigation.in_area(pos) then
			return
		end
		local name = core.get_node(pos).name
		if core.get_item_group(name, "sel_garden") > 0 then
			-- (only called for neighbours of channel blocks, see below)
			result.reaches_garden = true
		elseif core.get_item_group(name, "sel_channel") > 0
				and #result.blocks < sel_irrigation.MAX_CHANNEL_BLOCKS then
			seen[key] = true
			local entry = {pos = pos, steps = steps}
			table.insert(result.blocks, entry)
			table.insert(queue, entry)
		end
	end

	-- the first channel blocks are the ones touching the source ...
	for _, d in ipairs(NEIGHBOURS) do
		local pos = vector.add(L.source, d)
		-- (the source does not count as "touching the garden")
		if core.get_item_group(core.get_node(pos).name, "sel_channel") > 0 then
			visit(pos, 1)
		end
	end
	-- ... then follow block by block (breadth first = shortest way first)
	local i = 1
	while queue[i] do
		for _, d in ipairs(NEIGHBOURS) do
			visit(vector.add(queue[i].pos, d), queue[i].steps + 1)
		end
		i = i + 1
	end

	function result.contains(pos)
		return seen[core.hash_node_position(pos)] == true
	end
	return result
end

----------------------------------------------------------------------------
-- Water in, water out
----------------------------------------------------------------------------
-- Change one block to its wet / dry look (keeps the pump's owner).
local function set_look(pos, map)
	local node = core.get_node(pos)
	if map[node.name] then
		core.swap_node(pos, {name = map[node.name], param2 = node.param2})
	end
end

-- Every wet block in the field becomes dry again.
local function dry_everything()
	local wet = core.find_nodes_in_area(L.area_min, L.area_max,
		{"sel_irrigation:channel_wet", "sel_irrigation:pump_wet"})
	for _, pos in ipairs(wet) do
		set_look(pos, DRY)
	end
end

-- The garden bed turns dark and wet, and plants grow on it.
local function bloom()
	for x = L.garden_min.x, L.garden_max.x do
		for z = L.garden_min.z, L.garden_max.z do
			local bed = {x = x, y = L.garden_min.y, z = z}
			core.set_node(bed, {name = "sel_irrigation:garden_wet"})
			local above = vector.offset(bed, 0, 1, 0)
			-- leave channel blocks standing on the bed alone
			if core.get_node(above).name == "air" then
				local plants = sel_irrigation.PLANTS
				core.set_node(above, {name = plants[math.random(#plants)]})
			end
		end
	end
	sel_core.sparkle(vector.offset(L.garden_min, 3, 1, 3), sel_core.colors.green, 60)
end

local function succeed()
	set_state("done")
	bloom()
	sel_irrigation.paint_ground(true) -- the dry half of the field turns green
	core.set_node(L.home_pad, {name = "sel_core:home_pad"})
	sel_core.fireworks(vector.offset(L.garden_min, 3, 1, 3), 8)
	core.log("action", "[sel_irrigation] the water reached the garden")
end

-- Let the water run through the traced blocks; then call `finished`.
local function run_water(trace, finished)
	local last = 0
	for _, block in ipairs(trace.blocks) do
		last = math.max(last, block.steps)
		core.after(block.steps * sel_irrigation.FLOW_STEP_TIME, function()
			set_look(block.pos, WET)
			sel_core.ambient_sparkle(block.pos, sel_core.colors.blue)
		end)
	end
	sel_core.play("sel_core_tick", L.source)
	core.after((last + 1) * sel_irrigation.FLOW_STEP_TIME, finished)
end

----------------------------------------------------------------------------
-- The group hold: everyone on their own pump
----------------------------------------------------------------------------
-- The position of the pump this player stands on, if it is their own.
local function own_pump_under(player)
	local pos = sel_core.pos_under(player)
	if core.get_item_group(core.get_node(pos).name, "sel_pump") > 0
			and core.get_meta(pos):get_string("owner") == player:get_player_name() then
		return pos
	end
end

sel_core.register_hold({
	seconds = sel_irrigation.HOLD_SECONDS,
	countdown = true,

	check = function()
		if sel_irrigation.state == "done" then
			return {}, false
		end
		-- (While the water is running we keep answering normally. The hold
		-- only fires again after everybody has stepped off once, so children
		-- who simply stay on their pumps do not restart the water.)
		local everyone = sel_irrigation.participants()
		local on_pumps = {}
		for _, player in ipairs(everyone) do
			if own_pump_under(player) then
				table.insert(on_pumps, player)
			end
		end
		-- ALL children in the field must stand on their own pump
		return on_pumps, #everyone > 0 and #on_pumps == #everyone
	end,

	on_complete = function(players)
		if sel_irrigation.state ~= "building" then
			return -- the water is still running from the last try
		end
		local trace = sel_irrigation.trace()

		-- is every child's pump part of the channel that the water reaches?
		local pumps_connected = true
		for _, player in ipairs(players) do
			local pump = own_pump_under(player)
			if not (pump and trace.contains(pump)) then
				pumps_connected = false
			end
		end
		local success = trace.reaches_garden and pumps_connected

		set_state("flowing")
		run_water(trace, function()
			if success then
				succeed()
				return
			end
			-- A gap somewhere: the water stays for a moment so everyone can
			-- see where it stopped, then the channel runs dry again.
			for _, player in ipairs(players) do
				if core.get_player_by_name(player:get_player_name()) then
					sel_core.play("sel_core_reset", player)
				end
			end
			core.after(sel_irrigation.DRY_AGAIN_TIME, function()
				dry_everything()
				set_state("building")
			end)
		end)
	end,
})

----------------------------------------------------------------------------
-- Reset for the next group
----------------------------------------------------------------------------
-- Removes every channel block and pump from the field, dries the garden
-- and the east half of the field, removes the plants and the home pad,
-- and starts a new round (so every
-- child gets a fresh kit).
function sel_irrigation.reset()
	local pieces = core.find_nodes_in_area(L.area_min, L.area_max, {"group:sel_channel"})
	for _, pos in ipairs(pieces) do
		core.remove_node(pos)
	end
	sel_core.fill(L.garden_min, L.garden_max, "sel_irrigation:garden_dry")
	sel_core.fill(vector.offset(L.garden_min, 0, 1, 0), vector.offset(L.garden_max, 0, 1, 0), "air")
	core.set_node(L.home_pad, {name = "default:dirt_with_grass"})
	sel_irrigation.paint_ground(false) -- green in the west, dry in the east

	-- take left-over kit pieces out of the pockets of everyone online
	for _, player in ipairs(core.get_connected_players()) do
		local inv = player:get_inventory()
		inv:remove_item("main", "sel_irrigation:channel 999")
		inv:remove_item("main", "sel_irrigation:pump 99")
	end
	sel_irrigation.next_round()
	set_state("building")
end

core.register_chatcommand("sel_irrigation_reset", {
	description = S("Irrigation Channel: clean up and start again with new kits"),
	privs = {sel_teacher = true},
	func = function()
		sel_irrigation.reset()
		return true, S("The Irrigation Channel is ready for the next group.")
	end,
})
