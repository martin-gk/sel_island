--[[
    build.lua - tiny helpers to build structures from code
    ======================================================

    Activity sites (Hub, ferry dock, village square, ...) are built by code
    the first time the server starts. Writing them as plain loops keeps them
    readable and easy to change - no external schematic files needed.
]]

-- Fill the box from p1 to p2 (inclusive, any corner order) with one block.
--   sel_core.fill({x=0,y=0,z=0}, {x=4,y=0,z=4}, "default:stone")
--   sel_core.fill(p1, p2, "air")   -- clears the box
function sel_core.fill(p1, p2, nodename, param2)
	local minp, maxp = vector.sort(p1, p2)
	local positions = {}
	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				table.insert(positions, {x = x, y = y, z = z})
			end
		end
	end
	core.bulk_set_node(positions, {name = nodename, param2 = param2 or 0})
end

-- Set a single block.
function sel_core.set(pos, nodename, param2)
	core.set_node(pos, {name = nodename, param2 = param2 or 0})
end

-- Can this block be replaced by a structure? (air, water, grass, flowers,
-- leaves, snow layer, ...). Used to find the ground below a pillar.
local function replaceable(name)
	if name == "air" or name == "ignore" then
		return true
	end
	local def = core.registered_nodes[name]
	if not def then
		return true
	end
	local groups = def.groups or {}
	return def.buildable_to or def.liquidtype ~= "none"
		or groups.leaves ~= nil or groups.tree ~= nil
end

-- Build a pillar of `nodename` from `top` straight down until it reaches
-- solid ground (at most `max_depth` blocks, default 80).
function sel_core.pillar_down(top, nodename, max_depth)
	local pos = vector.copy(top)
	for _ = 1, (max_depth or 80) do
		if not replaceable(core.get_node(pos).name) then
			return
		end
		core.set_node(pos, {name = nodename})
		pos.y = pos.y - 1
	end
end

-- Make sure the map between p1 and p2 is generated and loaded, then call
-- callback(). Building into ungenerated land would be overwritten later.
function sel_core.when_loaded(p1, p2, callback)
	core.emerge_area(p1, p2, function(_, _, remaining)
		if remaining == 0 then
			callback()
		end
	end)
end
