--[[
    launch.lua - the launch: hold, vessel check, sailing, arrival
    =============================================================

    1. HOLD   All children in the activity area stand on the teal launch
              platform together for 3 seconds (big 3-2-1). If anyone steps
              off - or a child of the group is somewhere else in the area -
              the count starts over.
    2. CHECK  The "vessel" is everything the children built that is
              connected to the launch platform (blocks touching each other,
              made of the four materials). It must
                * contain at least one block of EVERY material, and
                * reach at least MIN_REACH blocks out over the water.
              If not: a picture shows what is missing, the crates of the
              missing materials sparkle, and the children keep building.
    3. SAIL   The children are put onto the vessel and the whole thing
              glides west, one block at a time, until it touches the far
              dock at the Hub island.
    4. ARRIVE Fireworks, and a purple HOME PAD appears on the far dock:
              stepping on it brings a child back to the Hub.

    The activity then stays "done" until the teacher types
    /sel lake_reset (cleans the water, forgets the roles, ready for the
    next group).

    Design note (the original design leaves this open): the vessel does NOT have to
    reach the far shore by itself - it sails the rest of the way. If the
    children built all the way across, the sail is simply very short.
]]

local S = sel_lake.S
local L = sel_lake.layout
local WATER_LEVEL = sel_lake.WATER_LEVEL -- blocks at or below this are lake water

-- "building" -> "sailing" -> "done". Remembered across server restarts,
-- so a finished crossing stays finished until the teacher resets it.
local storage = core.get_mod_storage()
sel_lake.state = storage:get_string("state") == "done" and "done" or "building"

local function set_state(state)
	sel_lake.state = state
	storage:set_string("state", state)
end

----------------------------------------------------------------------------
-- Finding the vessel
----------------------------------------------------------------------------
local NEIGHBOURS = {
	{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0},
	{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0},
	{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},
}

-- Returns a description of everything connected to the launch platform:
--   blocks     list of {pos=, name=, param2=}
--   has        role -> true for every material that occurs
--   min_x      westernmost x of the vessel (nil if there is no vessel)
function sel_lake.find_vessel()
	local vessel = {blocks = {}, has = {}}
	local seen, queue = {}, {}

	-- look at a position; if it is a material block we have not seen yet,
	-- add it to the vessel and to the list of blocks to continue from
	local function visit(pos)
		local key = core.hash_node_position(pos)
		if seen[key] or not sel_lake.in_area(pos) then
			return
		end
		seen[key] = true
		local node = core.get_node(pos)
		local role = sel_lake.node_role[node.name]
		if role and #vessel.blocks < sel_lake.MAX_VESSEL_BLOCKS then
			table.insert(vessel.blocks, {pos = pos, name = node.name, param2 = node.param2})
			table.insert(queue, pos)
			vessel.has[role] = true
			vessel.min_x = math.min(vessel.min_x or pos.x, pos.x)
		end
	end

	-- start with everything touching the launch platform ...
	for x = L.launch_min.x, L.launch_max.x do
		for z = L.launch_min.z, L.launch_max.z do
			for _, d in ipairs(NEIGHBOURS) do
				visit(vector.add({x = x, y = L.deck_y, z = z}, d))
			end
		end
	end
	-- ... and follow the blocks that touch those, and so on
	local i = 1
	while queue[i] do
		for _, d in ipairs(NEIGHBOURS) do
			visit(vector.add(queue[i], d))
		end
		i = i + 1
	end
	return vessel
end

-- What is still wrong with the vessel? Returns a list of missing roles
-- and whether it is too short.
local function vessel_problems(vessel)
	local missing = {}
	for _, role in ipairs(sel_lake.ROLES) do
		if not vessel.has[role] then
			table.insert(missing, role)
		end
	end
	local reach = vessel.min_x and (L.launch_min.x - vessel.min_x) or 0
	return missing, reach < sel_lake.MIN_REACH
end

----------------------------------------------------------------------------
-- Sailing
----------------------------------------------------------------------------
-- Move every block of the vessel one step west (x - 1). Done with a
-- VoxelManip: all blocks change in one go, so nothing drops or falls
-- while the vessel is "between two places".
local function shift_west(blocks)
	local minp = vector.copy(blocks[1].pos)
	local maxp = vector.copy(blocks[1].pos)
	for _, b in ipairs(blocks) do
		minp = vector.new(math.min(minp.x, b.pos.x), math.min(minp.y, b.pos.y), math.min(minp.z, b.pos.z))
		maxp = vector.new(math.max(maxp.x, b.pos.x), math.max(maxp.y, b.pos.y), math.max(maxp.z, b.pos.z))
	end
	minp.x = minp.x - 1 -- room for the step

	local vm = core.get_voxel_manip()
	local e1, e2 = vm:read_from_map(minp, maxp)
	local area = VoxelArea:new({MinEdge = e1, MaxEdge = e2})
	local data, param2 = vm:get_data(), vm:get_param2_data()
	local water = core.get_content_id("default:water_source")
	local air = core.get_content_id("air")

	-- 1. lift the vessel out: its old places become water (or air above)
	for _, b in ipairs(blocks) do
		local i = area:indexp(b.pos)
		data[i] = b.pos.y <= WATER_LEVEL and water or air
		param2[i] = 0
	end
	-- 2. put it down one block further west
	for _, b in ipairs(blocks) do
		b.pos.x = b.pos.x - 1
		local i = area:indexp(b.pos)
		data[i] = core.get_content_id(b.name)
		param2[i] = b.param2
	end
	vm:set_data(data)
	vm:set_param2_data(param2)
	vm:write_to_map(true)
end

-- Put the children onto the vessel: on top of blocks that have two free
-- blocks of air above them, as close to the launch platform as possible.
local function board(players, vessel)
	local is_vessel = {}
	for _, b in ipairs(vessel.blocks) do
		is_vessel[core.hash_node_position(b.pos)] = true
	end
	local spots = {}
	for _, b in ipairs(vessel.blocks) do
		local above1 = vector.offset(b.pos, 0, 1, 0)
		local above2 = vector.offset(b.pos, 0, 2, 0)
		local walkable = core.registered_nodes[b.name].walkable
		if walkable and core.get_node(above1).name == "air"
				and core.get_node(above2).name == "air" then
			table.insert(spots, b.pos)
		end
	end
	if #spots == 0 then
		return -- nowhere to stand (very odd vessel): they stay on the dock
	end
	table.sort(spots, function(a, b)
		return vector.distance(a, L.launch_min) < vector.distance(b, L.launch_min)
	end)
	for i, player in ipairs(players) do
		local spot = spots[(i - 1) % #spots + 1]
		player:set_pos({x = spot.x, y = spot.y + 0.5, z = spot.z})
	end
end

local function arrive()
	set_state("done")
	core.set_node(L.home_pad, {name = "sel_core:home_pad"})
	sel_core.fireworks(vector.offset(L.home_pad, 0, 1, 0), 8)
	core.log("action", "[sel_lake] the vessel reached the far dock")
end

local function sail(players, vessel)
	set_state("sailing")
	board(players, vessel)
	sel_core.play("sel_core_success", L.launch_min)

	-- the far dock ends at far_max.x; the vessel stops right next to it
	local steps = vessel.min_x - (L.far_max.x + 1)
	local function step()
		if steps <= 0 then
			arrive()
			return
		end
		steps = steps - 1
		shift_west(vessel.blocks)
		for _, player in ipairs(players) do
			-- the player may have left the game in the meantime
			if core.get_player_by_name(player:get_player_name()) then
				player:set_pos(vector.offset(player:get_pos(), -1, 0, 0))
			end
		end
		core.after(sel_lake.SAIL_STEP_TIME, step)
	end
	core.after(1, step) -- a short moment to realise "we are on board"
end

----------------------------------------------------------------------------
-- The group hold on the launch platform
----------------------------------------------------------------------------
local function on_launch_platform(player)
	local p = sel_core.pos_under(player)
	return p.y == L.deck_y
		and p.x >= L.launch_min.x and p.x <= L.launch_max.x
		and p.z >= L.launch_min.z and p.z <= L.launch_max.z
end

sel_core.register_hold({
	seconds = sel_lake.HOLD_SECONDS,
	countdown = true,

	check = function()
		if sel_lake.state ~= "building" then
			return {}, false
		end
		local everyone = sel_lake.participants()
		local on_platform = {}
		for _, player in ipairs(everyone) do
			if on_launch_platform(player) then
				table.insert(on_platform, player)
			end
		end
		-- ALL children in the area must be on the platform
		return on_platform, #everyone > 0 and #on_platform == #everyone
	end,

	on_complete = function(players)
		local vessel = sel_lake.find_vessel()
		local missing, too_short = vessel_problems(vessel)

		if #missing == 0 and not too_short then
			sail(players, vessel)
			return
		end

		-- Not ready yet: show WHAT is missing, without words.
		--   picture 2 = "you need all four materials" (+ sparkling crates)
		--   picture 4 = "build further out over the water"
		local picture = #missing > 0 and "sel_lake_story_2.png" or "sel_lake_story_4.png"
		for _, player in ipairs(players) do
			sel_core.show_hint(player, picture, 4)
			sel_core.play("sel_core_reset", player)
		end
		for _, role in ipairs(missing) do
			sel_core.sparkle(vector.offset(L.crates[role], 0, 0.5, 0), sel_core.colors.gold, 40)
		end
	end,
})

----------------------------------------------------------------------------
-- Reset for the next group
----------------------------------------------------------------------------
-- Removes everything the children built on and between the docks, takes
-- the home pad away again and forgets the roles.
function sel_lake.reset()
	local minp = {x = L.area_min.x, y = L.area_min.y, z = L.start_min.z - 2}
	local maxp = {x = L.start_max.x, y = L.area_max.y, z = L.start_max.z + 2}
	local materials = {}
	for node in pairs(sel_lake.node_role) do
		table.insert(materials, node)
	end
	for _, pos in ipairs(core.find_nodes_in_area(minp, maxp, materials)) do
		core.set_node(pos, {name = pos.y <= WATER_LEVEL and "default:water_source" or "air"})
	end
	core.set_node(L.home_pad, {name = "default:pine_wood"})
	sel_lake.clear_roles()
	set_state("building")
end

core.register_chatcommand("sel_lake_reset", {
	description = S("Lake Crossing: clean up and start again with new roles"),
	privs = {sel_teacher = true},
	func = function()
		sel_lake.reset()
		return true, S("The Lake Crossing is ready for the next group.")
	end,
})
