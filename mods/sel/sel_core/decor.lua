--[[
    decor.lua - small decorations shared by all sites
    =================================================

    Nothing in here is needed to PLAY. These helpers only make the sites
    nicer to look at and easier to recognise:

        sel_core.build_gate(pos, along, color)
            An arch over a path where it enters a site: two posts and a
            glowing beam in the colour of the path (teal / gold / blue /
            purple). pos = the path block under the middle of the arch,
            along = "x" or "z": the direction in which the path RUNS.

        sel_core.scatter(minp, maxp, plants, one_in, salt)
            Plants on about one of `one_in` free ground blocks in a
            rectangle (only x and z of minp/maxp are used). A plant is only
            put on soil with air above, so paths, floors and buildings stay
            free. `plants` is a list of node names.

        sel_core.plant_tree(pos, kind)
            A tree from Minetest Game ("apple", "acacia", "aspen", "pine",
            "bush", "acacia_bush"). pos = the GROUND block it stands on.
            Only fills air: it never grows into a building.

        sel_core.build_reeds(pos, height)
            A stalk of reed (papyrus) standing on pos.

        sel_core.build_water_plants(minp, maxp, water_y, one_in, salt)
            Reeds in shallow water (one block deep) and water lilies on
            deeper water, inside a rectangle of a lake whose top water
            block is at height water_y.

        sel_core.pick(list, x, z, salt)
            Chooses an entry of `list` for the column (x, z).

    IMPORTANT: everything is decided by a fixed formula from the
    coordinates (sel_core.noise), NOT by chance. So a site looks exactly
    the same every time it is built, in every world - teachers and tests
    can rely on what is where.
]]

-- A number 0 .. 0.9999 that depends only on (x, z, salt). Looks random,
-- but is always the same for the same input.
function sel_core.noise(x, z, salt)
	local n = math.sin(x * 12.9898 + z * 78.233 + (salt or 0) * 37.719) * 43758.5453
	return n - math.floor(n)
end

-- The entry of `list` that belongs to column (x, z).
function sel_core.pick(list, x, z, salt)
	return list[math.floor(sel_core.noise(x, z, salt) * #list) + 1]
end

----------------------------------------------------------------------------
-- Gate
----------------------------------------------------------------------------
local GATE_HEIGHT = 4     -- the beam is this many blocks above the path
local GATE_HALF_WIDTH = 2 -- posts stand this far left and right of the middle

function sel_core.build_gate(pos, along, color)
	-- the posts stand ACROSS the path
	local side = along == "x" and {x = 0, y = 0, z = 1} or {x = 1, y = 0, z = 0}
	for _, sign in ipairs({-1, 1}) do
		local foot = vector.add(pos, vector.multiply(side, sign * GATE_HALF_WIDTH))
		-- stand firmly even if the ground slopes away beside the path
		sel_core.pillar_down(vector.offset(foot, 0, 0, 0), "sel_core:path_edge", 6)
		for dy = 1, GATE_HEIGHT - 1 do
			core.set_node(vector.offset(foot, 0, dy, 0), {name = "sel_core:post"})
		end
	end
	for i = -GATE_HALF_WIDTH, GATE_HALF_WIDTH do
		local beam = vector.add(vector.offset(pos, 0, GATE_HEIGHT, 0), vector.multiply(side, i))
		core.set_node(beam, {name = "sel_core:path_" .. color})
	end
end

----------------------------------------------------------------------------
-- Plants
----------------------------------------------------------------------------
-- The highest block that is not air or a plant, searching down from y_top.
local function ground_at(x, z, y_top, y_bottom)
	for y = y_top, y_bottom, -1 do
		local name = core.get_node({x = x, y = y, z = z}).name
		local def = core.registered_nodes[name]
		if name ~= "air" and def and not def.buildable_to then
			return {x = x, y = y, z = z}, name
		end
	end
end

function sel_core.scatter(minp, maxp, plants, one_in, salt)
	local y_top = math.max(minp.y or 0, maxp.y or 0) + 12
	local y_bottom = math.min(minp.y or 0, maxp.y or 0) - 12
	local count = 0
	for x = math.min(minp.x, maxp.x), math.max(minp.x, maxp.x) do
		for z = math.min(minp.z, maxp.z), math.max(minp.z, maxp.z) do
			if sel_core.noise(x, z, salt) < 1 / one_in then
				local ground, name = ground_at(x, z, y_top, y_bottom)
				local above = ground and vector.offset(ground, 0, 1, 0)
				if ground and core.get_item_group(name, "soil") > 0
						and core.get_node(above).name == "air" then
					core.set_node(above, {name = sel_core.pick(plants, x, z, (salt or 0) + 1)})
					count = count + 1
				end
			end
		end
	end
	return count
end

function sel_core.build_reeds(pos, height)
	for dy = 1, height do
		core.set_node(vector.offset(pos, 0, dy, 0), {name = "default:papyrus"})
	end
end

local function is_water(pos)
	return core.get_item_group(core.get_node(pos).name, "water") > 0
end

function sel_core.build_water_plants(minp, maxp, water_y, one_in, salt)
	for x = math.min(minp.x, maxp.x), math.max(minp.x, maxp.x) do
		for z = math.min(minp.z, maxp.z), math.max(minp.z, maxp.z) do
			local surface = {x = x, y = water_y, z = z}
			if sel_core.noise(x, z, salt) < 1 / one_in and is_water(surface)
					and core.get_node(vector.offset(surface, 0, 1, 0)).name == "air" then
				if is_water(vector.offset(surface, 0, -1, 0)) then
					-- deep water: a lily pad floating on top
					core.set_node(vector.offset(surface, 0, 1, 0), {name = "flowers:waterlily"})
				else
					-- shallow water: reeds standing in it, 2 or 3 blocks tall
					sel_core.build_reeds(vector.offset(surface, 0, -1, 0),
						2 + math.floor(sel_core.noise(x, z, (salt or 0) + 1) * 2))
				end
			end
		end
	end
end

----------------------------------------------------------------------------
-- Trees
----------------------------------------------------------------------------
local SCHEMATICS = core.get_modpath("default") .. "/schematics/"
local TREES = {
	apple = "apple_tree.mts",
	acacia = "acacia_tree.mts",
	aspen = "aspen_tree.mts",
	pine = "small_pine_tree.mts",
	bush = "bush.mts",
	acacia_bush = "acacia_bush.mts",
}

function sel_core.plant_tree(pos, kind)
	-- (the lowest layer of these schematics is the first block ABOVE ground)
	core.place_schematic(vector.offset(pos, 0, 1, 0), SCHEMATICS .. TREES[kind], "0", nil, false,
		"place_center_x, place_center_z")
end
