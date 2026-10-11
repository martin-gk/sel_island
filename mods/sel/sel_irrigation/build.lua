--[[
    build.lua - builds the Irrigation Channel site
    ==============================================

    Built on the first server start (and when BUILD_VERSION in config.lua
    is increased, or with /sel irrigation_rebuild):

      1. the blue path from the crossroads, with a blue gate at the field
      2. the field: a level rectangle (air above, earth below) with a
         wooden fence around it
      3. the brook, the pool with its stone rim, the blue Water Source
      4. the raised garden bed (dry)
      5. things in the way and decoration: boulders, old tree, fallen log,
         scarecrow, straw bales
      6. calm corner, Inventor, spare-parts crate
      7. reset of the activity (flow.lua) - this also paints the ground:
         green in the west, dry in the east (paint_ground below)

    Protection: the whole activity area is a zone where only channel blocks
    and pumps can be placed or dug (kit.lua). So boulders, fence and tree
    cannot be removed by children - the channel has to go around them.
]]

local S = sel_irrigation.S
local L = sel_irrigation.layout
local Y = L.ground_y
local fill, set = sel_core.fill, sel_core.set
local storage = core.get_mod_storage()

local GREEN, DRY = "default:dirt_with_grass", "default:dry_dirt_with_dry_grass"

----------------------------------------------------------------------------
-- Green and dry ground
----------------------------------------------------------------------------
-- Is this one of the little plants we put on the field ourselves?
local is_field_plant = {}
for _, list in pairs(sel_irrigation.FIELD_PLANTS) do
	for _, name in ipairs(list) do
		is_field_plant[name] = true
	end
end

-- Paint the ground of the field and put grass tufts / dry shrubs on it.
--   all_green = false: green in the west, dry and yellow in the east
--                      (the border is ragged, not a straight line)
--   all_green = true:  everything green - the water has arrived
-- Only grass blocks and our own little plants are touched: pool, garden,
-- boulders and everything the children built stay as they are.
function sel_irrigation.paint_ground(all_green)
	for x = L.field_min.x, L.field_max.x do
		for z = L.field_min.z, L.field_max.z do
			local ragged = math.floor(sel_core.noise(x, z, 3) * 5) - 2 -- -2 .. 2
			local dry = not all_green and x + ragged >= L.dry_from_x
			local ground = {x = x, y = Y, z = z}
			local name = core.get_node(ground).name
			if name == GREEN or name == DRY then
				core.set_node(ground, {name = dry and DRY or GREEN})
				local above = {x = x, y = Y + 1, z = z}
				local on_top = core.get_node(above).name
				if on_top == "air" or is_field_plant[on_top] then
					local plant = "air"
					if sel_core.noise(x, z, 7) < 1 / sel_irrigation.PLANT_ONE_IN then
						local list = sel_irrigation.FIELD_PLANTS[dry and "dry" or "green"]
						plant = sel_core.pick(list, x, z, 8)
					end
					core.set_node(above, {name = plant})
				end
			end
		end
	end
end

----------------------------------------------------------------------------
-- The parts of the site
----------------------------------------------------------------------------
local function build_field()
	local a, b = L.field_min, L.field_max
	-- head room (bushes, trees, small bumps), earth below, grass on top
	fill({x = a.x, y = Y + 1, z = a.z}, {x = b.x, y = Y + 12, z = b.z}, "air")
	fill({x = a.x, y = Y - 2, z = a.z}, {x = b.x, y = Y - 1, z = b.z}, "default:dirt")
	fill(a, b, GREEN)
end

-- A wooden fence along the edge of the field, except at the openings.
local function build_fence()
	local a, b = L.field_min, L.field_max
	local function post(x, z)
		for _, o in ipairs(L.openings) do
			if x >= o.x1 and x <= o.x2 and z >= o.z1 and z <= o.z2 then
				return
			end
		end
		set({x = x, y = Y + 1, z = z}, "default:fence_wood")
	end
	for x = a.x, b.x do
		post(x, a.z)
		post(x, b.z)
	end
	for z = a.z, b.z do
		post(a.x, z)
		post(b.x, z)
	end
end

local function build_pool()
	local a, b = L.pool_min, L.pool_max
	fill(a, b, "default:stone_block")                                  -- rim
	fill({x = a.x, y = Y - 1, z = a.z}, {x = b.x, y = Y - 1, z = b.z}, "default:stone_block") -- bottom
	fill(vector.offset(a, 1, 0, 1), vector.offset(b, -1, 0, -1), "default:water_source")
	-- the brook: a one-block-wide ditch full of water from the north
	-- fence into the pool (it is shut in by the ground on both sides, so
	-- the water stays where it is), with a plank to walk across
	for z = L.brook_z_min, L.brook_z_max do
		set({x = L.brook_x, y = Y, z = z}, "default:water_source")
	end
	set({x = L.brook_x, y = Y, z = L.brook_plank_z}, "default:wood")
	set(L.source, "sel_irrigation:source")
end

-- Boulders, the old tree, the fallen log: the channel must go around.
local function build_obstacles()
	local stones = {"default:mossycobble", "default:cobble", "default:stone"}
	for _, bo in ipairs(L.boulders) do
		for dy = 1, bo.h do
			set({x = bo.x, y = Y + dy, z = bo.z}, sel_core.pick(stones, bo.x + dy, bo.z, 5))
		end
	end
	sel_core.plant_tree(L.tree, "acacia")
	fill(L.log_min, L.log_max, "default:acacia_tree", 12) -- 12 = lying along x
end

-- A scarecrow (fence posts, a yellow head, a straw hat) and straw bales.
local function build_farm_things()
	local p = L.scarecrow
	set(vector.offset(p, 0, 1, 0), "default:fence_wood")
	set(vector.offset(p, 0, 2, 0), "default:fence_wood")
	set(vector.offset(p, -1, 2, 0), "default:fence_wood") -- arms
	set(vector.offset(p, 1, 2, 0), "default:fence_wood")
	set(vector.offset(p, 0, 3, 0), "wool:yellow")
	set(vector.offset(p, 0, 4, 0), "stairs:slab_straw")
	for _, bale in ipairs(L.straw) do
		for dy = 1, bale.h do
			set({x = bale.x, y = Y + dy, z = bale.z}, "farming:straw")
		end
	end
end

function sel_irrigation.build(done)
	local points = {L.area_min, L.area_max}
	for _, p in ipairs(L.path) do
		table.insert(points, p)
	end
	-- the smallest box around everything we touch, plus a margin
	local p1 = {x = math.huge, y = -8, z = math.huge}
	local p2 = {x = -math.huge, y = 60, z = -math.huge}
	for _, p in ipairs(points) do
		p1.x, p1.z = math.min(p1.x, p.x - 16), math.min(p1.z, p.z - 16)
		p2.x, p2.z = math.max(p2.x, p.x + 16), math.max(p2.z, p.z + 16)
	end

	core.log("action", "[sel_irrigation] generating the field area ...")
	sel_core.when_loaded(p1, p2, function()
		sel_core.build_path(L.path, "blue")
		sel_core.build_gate({x = L.gate.x, y = sel_core.path_height(L.gate.x, L.gate.z),
			z = L.gate.z}, "x", "blue")
		build_field()
		build_fence()
		build_pool()
		fill(L.garden_min, L.garden_max, "sel_irrigation:garden_dry")
		build_obstacles()
		build_farm_things()
		sel_flower.build_calm_corner(L.calm_corner)
		sel_core.spawn_npc("inventor", L.inventor, 0)
		set(L.crate, "sel_irrigation:crate")
		sel_irrigation.reset() -- no left-over channel, dry garden, new round
		storage:set_int("built_version", sel_irrigation.BUILD_VERSION)
		core.log("action", "[sel_irrigation] site built (version "
			.. sel_irrigation.BUILD_VERSION .. ")")
		if done then
			done()
		end
	end)
end

-- Build on first start / layout change (after the Hub and the Lake).
core.after(5, function()
	if storage:get_int("built_version") < sel_irrigation.BUILD_VERSION then
		sel_irrigation.build()
	end
end)

----------------------------------------------------------------------------
-- Signpost at the crossroads, /sel goto site, rebuild command
----------------------------------------------------------------------------
sel_core.register_sign("sel_irrigation:sign", "sel_irrigation_sign.png")
sel_hub.register_destination("south", "sel_irrigation:sign")

sel_core.register_site("irrigation", L.arrival)

core.register_chatcommand("sel_irrigation_rebuild", {
	description = S("Rebuild the Irrigation Channel site"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_irrigation.build(function()
			core.chat_send_player(name, S("The Irrigation Channel site has been rebuilt."))
		end)
		return true, S("Rebuilding the Irrigation Channel site ...")
	end,
})
