--[[
    path.lua - visible, colour-coded paths and picture signposts
    ============================================================

    Children find the activities by following COLOURED PATHS that start at
    the crossroads (end of the tutorial). Each activity has its own colour:

        teal   = Lake Crossing      gold = Village Decision
        blue   = Irrigation Channel purple = Hub / home
        pink   = Breathing Garden

    A path is 3 blocks wide: a softly glowing coloured centre line between
    two light stone edges. It follows the ground, cuts gently through
    hills (never steeper than one block up or down per step) and becomes a
    bridge over water. Path blocks are unbreakable.

    At the start of each path stands a SIGNPOST: a wooden post with a
    picture block on top showing where the path leads (a boat, a house...).

    For activity mods:

        sel_core.register_sign("sel_lake:sign", "sel_lake_sign.png")

        sel_core.build_path({ {x=..., z=...}, {x=..., z=...}, ... }, "teal")
            -- waypoints: only x and z; the height is found automatically

        sel_core.build_signpost(pos, "sel_lake:sign")
            -- pos = the ground block the post stands on
]]

-- path colours (also used by sel_core.colors for particles)
local PATH_COLORS = {
	teal   = "#28c8be",
	gold   = "#ffd23f",
	blue   = "#4aa3ff",
	purple = "#c77dff",
	pink   = "#ff6fb5",
}

-- Shared settings of unbreakable SEL blocks.
local function unbreakable(def)
	def.groups = {sel_unbreakable = 1}
	def.diggable = false
	def.on_blast = function() end
	return def
end

for color, hex in pairs(PATH_COLORS) do
	core.register_node("sel_core:path_" .. color, unbreakable({
		description = "SEL path (" .. color .. ")",
		tiles = {"sel_core_path.png^[multiply:" .. hex},
		light_source = 5, -- a soft glow: the line is visible from far away
	}))
end

core.register_node("sel_core:path_edge", unbreakable({
	description = "SEL path edge",
	tiles = {"sel_core_path_edge.png"},
}))

core.register_node("sel_core:post", unbreakable({
	description = "SEL signpost",
	drawtype = "nodebox",
	node_box = {type = "fixed", fixed = {-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}},
	tiles = {"default_wood.png"},
	paramtype = "light",
}))

-- Register a picture block for signposts (same picture on all sides).
function sel_core.register_sign(name, texture)
	core.register_node(name, unbreakable({
		description = "SEL sign",
		tiles = {texture},
		light_source = 6,
	}))
end

-- A signpost: two post blocks with the picture block on top.
function sel_core.build_signpost(pos, sign_node)
	core.set_node(vector.offset(pos, 0, 1, 0), {name = "sel_core:post"})
	core.set_node(vector.offset(pos, 0, 2, 0), {name = "sel_core:post"})
	core.set_node(vector.offset(pos, 0, 3, 0), {name = sign_node})
end

----------------------------------------------------------------------------
-- Finding the ground
----------------------------------------------------------------------------
-- Things a path may replace: air, plants, leaves, tree trunks, snow ...
local function is_soft(name)
	local def = core.registered_nodes[name]
	if name == "air" or not def then
		return true
	end
	local groups = def.groups or {}
	return def.buildable_to and def.liquidtype == "none"
		or groups.leaves ~= nil or groups.tree ~= nil
end

-- Height at which a path block belongs at (x, z):
--   on land:  the top ground block itself (the path is flush with the ground)
--   on water: one above the water surface (the path becomes a bridge)
-- The area must be loaded. Searches downwards from y = 80.
function sel_core.path_height(x, z)
	for y = 80, -20, -1 do
		local name = core.get_node({x = x, y = y, z = z}).name
		local def = core.registered_nodes[name]
		if def and def.liquidtype ~= "none" then
			return y + 1
		elseif not is_soft(name) then
			return y
		end
	end
	return 1
end

----------------------------------------------------------------------------
-- Building a path
----------------------------------------------------------------------------
-- All block positions (x, z) on straight lines between the waypoints.
local function trace(waypoints)
	local points = {}
	for i = 1, #waypoints - 1 do
		local a, b = waypoints[i], waypoints[i + 1]
		local steps = math.max(math.abs(b.x - a.x), math.abs(b.z - a.z))
		for s = 0, steps - 1 do
			table.insert(points, {
				x = math.floor(a.x + (b.x - a.x) * s / steps + 0.5),
				z = math.floor(a.z + (b.z - a.z) * s / steps + 0.5),
			})
		end
	end
	table.insert(points, {x = waypoints[#waypoints].x, z = waypoints[#waypoints].z})
	return points
end

function sel_core.build_path(waypoints, color)
	local points = trace(waypoints)

	-- 1. Ground height under every point of the centre line.
	local h = {}
	for i, p in ipairs(points) do
		h[i] = sel_core.path_height(p.x, p.z)
	end

	-- 2. Make it gentle: never more than one block up or down per step.
	--    Lowering the high side means the path CUTS into a hill instead of
	--    floating in the air.
	for i = 2, #h do
		h[i] = math.min(h[i], h[i - 1] + 1)
	end
	for i = #h - 1, 1, -1 do
		h[i] = math.min(h[i], h[i + 1] + 1)
	end

	-- 3. Decide one height and one block type per column. The centre line
	--    is coloured; the 8 columns around each centre point are edge.
	local columns = {} -- "x,z" -> {x=, y=, z=, centre=bool}
	for i, p in ipairs(points) do
		for dx = -1, 1 do
			for dz = -1, 1 do
				local key = (p.x + dx) .. "," .. (p.z + dz)
				local centre = dx == 0 and dz == 0
				local col = columns[key]
				if not col then
					columns[key] = {x = p.x + dx, y = h[i], z = p.z + dz, centre = centre}
				elseif centre then
					col.centre, col.y = true, h[i] -- the centre line wins
				end
			end
		end
	end

	-- 4. First clear head room above every column, then lay the blocks.
	--    (Two passes, so clearing never removes a neighbour's path block.)
	for _, col in pairs(columns) do
		sel_core.fill({x = col.x, y = col.y + 1, z = col.z},
			{x = col.x, y = col.y + 5, z = col.z}, "air")
	end
	for _, col in pairs(columns) do
		local node = col.centre and ("sel_core:path_" .. color) or "sel_core:path_edge"
		core.set_node({x = col.x, y = col.y, z = col.z}, {name = node})
		-- over water or a dip: support down to the ground
		sel_core.pillar_down({x = col.x, y = col.y - 1, z = col.z}, "default:stone", 30)
	end
	return #points
end
