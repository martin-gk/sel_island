--[[
    build.lua - builds the Hub plaza and the tutorial course
    ========================================================

    The Hub is built by code the first time the server starts (and again
    whenever sel_hub.BUILD_VERSION in config.lua is increased, or a teacher
    types /sel_hub_rebuild). All positions come from config.lua.

    Build order:
      1. clear the space above the plaza and walkway (terrain, trees)
      2. plaza: stone floor with a solid stone base down to the ground
      3. plaza railing with lamp posts on the corners
      4. walkway: wooden floor, pillars down to the ground, fences
      5. the gap (station 4) and the parkour between the stations
      6. the station blocks
      7. the calm corner (Breathing Flower on calm grass)
      8. the crossroads with its signposts
    Finally the protection zone is registered (see bottom of this file).
]]

local L = sel_hub.layout
local O = L.origin
local R = L.plaza_radius
local W = L.walk_half_width
local fill, set = sel_core.fill, sel_core.set

local storage = core.get_mod_storage()

-- Blocks used for the structure (change here to restyle the Hub).
local MAT = {
	plaza_floor = "default:stone_block",
	plaza_base  = "default:stone",
	plaza_post  = "default:stonebrick",
	lamp        = "default:meselamp",
	plaza_fence = "default:fence_wood",
	walk_floor  = "default:pine_wood",
	walk_pillar = "default:pine_tree",
	walk_fence  = "default:fence_pine_wood",
	pit_wall    = "sel_core:shield_glass", -- unbreakable, see sel_core/items.lua
	stone       = "default:stone_block",   -- stepping stones
	wall        = "default:stonebrick",    -- climbing wall
	ladder      = "default:ladder_wood",
	beam        = "default:tree",          -- balance beam (a log)
}

local function build_plaza()
	-- 2. Floor on top of a solid base reaching down to the ground.
	for x = O.x - R, O.x + R do
		for z = O.z - R, O.z + R do
			sel_core.pillar_down({x = x, y = O.y - 1, z = z}, MAT.plaza_base)
		end
	end
	fill({x = O.x - R, y = O.y, z = O.z - R},
		{x = O.x + R, y = O.y, z = O.z + R}, MAT.plaza_floor)

	-- 3. Fence around the edge, with an opening to the walkway (south).
	for i = -R, R do
		for _, p in ipairs({
			{x = O.x + i, y = O.y + 1, z = O.z + R},  -- north edge
			{x = O.x + i, y = O.y + 1, z = O.z - R},  -- south edge
			{x = O.x + R, y = O.y + 1, z = O.z + i},  -- east edge
			{x = O.x - R, y = O.y + 1, z = O.z + i},  -- west edge
		}) do
			local in_opening = p.z == O.z - R and math.abs(p.x - O.x) <= W - 1
			if not in_opening then
				set(p, MAT.plaza_fence)
			end
		end
	end

	-- Lamp posts on the four corners.
	for _, dx in ipairs({-R, R}) do
		for _, dz in ipairs({-R, R}) do
			set({x = O.x + dx, y = O.y + 1, z = O.z + dz}, MAT.plaza_post)
			set({x = O.x + dx, y = O.y + 2, z = O.z + dz}, MAT.lamp)
		end
	end
end

local function build_walkway()
	local z1, z2 = L.walk_first_z, L.walk_last_z

	-- 4. Floor (7 wide: 5 to walk on + 1 under each fence).
	fill({x = O.x - W, y = O.y, z = z1}, {x = O.x + W, y = O.y, z = z2},
		MAT.walk_floor)

	-- Fences along both sides.
	fill({x = O.x - W, y = O.y + 1, z = z1}, {x = O.x - W, y = O.y + 1, z = z2},
		MAT.walk_fence)
	fill({x = O.x + W, y = O.y + 1, z = z1}, {x = O.x + W, y = O.y + 1, z = z2},
		MAT.walk_fence)

	-- Pillars down to the ground every 6 rows, under both fence lines.
	for z = z1, z2, -6 do
		sel_core.pillar_down({x = O.x - W, y = O.y - 1, z = z}, MAT.walk_pillar)
		sel_core.pillar_down({x = O.x + W, y = O.y - 1, z = z}, MAT.walk_pillar)
	end
	-- ... and one at the very end.
	sel_core.pillar_down({x = O.x - W, y = O.y - 1, z = z2}, MAT.walk_pillar)
	sel_core.pillar_down({x = O.x + W, y = O.y - 1, z = z2}, MAT.walk_pillar)
end

-- Turn one row of the walkway into a pit, 1 block deep: the floor is one
-- block lower and the side walls are Shield Glass, so a child who falls in
-- can simply jump out again.
local function pit_row(z)
	fill({x = O.x - W + 1, y = O.y, z = z}, {x = O.x + W - 1, y = O.y, z = z}, "air")
	fill({x = O.x - W + 1, y = O.y - 1, z = z}, {x = O.x + W - 1, y = O.y - 1, z = z},
		MAT.walk_floor)
	set({x = O.x - W, y = O.y, z = z}, MAT.pit_wall)
	set({x = O.x + W, y = O.y, z = z}, MAT.pit_wall)
end

local function build_gap()
	-- 5. Station 4: two rows of pit to jump over.
	for _, z in ipairs(L.gap_z) do
		pit_row(z)
	end
end

-- 5b. Parkour between the stations: more practice for the controls.
local function build_parkour()
	local P = L.parkour

	-- Stepping stones: a pit with single blocks to hop across.
	for z = P.stones_first_z, P.stones_last_z, -1 do
		pit_row(z)
	end
	for _, pos in ipairs(P.stones) do
		set(pos, MAT.stone)
	end

	-- Climbing wall: 2 blocks high across the walkway. Ladders on the
	-- north side (param2 = 5: the ladder hangs on the block to its south),
	-- one step on the south side to hop down.
	fill({x = O.x - W + 1, y = O.y + 1, z = P.wall_z},
		{x = O.x + W - 1, y = O.y + 2, z = P.wall_z}, MAT.wall)
	fill({x = O.x - 1, y = O.y + 1, z = P.ladder_z},
		{x = O.x + 1, y = O.y + 2, z = P.ladder_z}, MAT.ladder, 5)
	fill({x = O.x - W + 1, y = O.y + 1, z = P.step_z},
		{x = O.x + W - 1, y = O.y + 1, z = P.step_z}, MAT.wall)
	-- higher side rails here, so nobody steps off the bridge from the wall
	for _, x in ipairs({O.x - W, O.x + W}) do
		fill({x = x, y = O.y + 2, z = P.ladder_z}, {x = x, y = O.y + 3, z = P.step_z},
			MAT.pit_wall)
	end

	-- Balance beam: a pit with a beam one block wide in the middle.
	for z = P.beam_first_z, P.beam_last_z, -1 do
		pit_row(z)
		set({x = O.x, y = O.y, z = z}, MAT.beam)
	end
end

local function build_stations()
	-- 6. The station blocks (see nodes.lua / stations.lua).
	set(L.start_marker, "sel_hub:marker_start")
	set(L.shiny, "sel_hub:shiny_block")
	set(L.place_marker, "sel_hub:marker_place")
	fill({x = O.x - W + 1, y = O.y, z = L.landing_z},
		{x = O.x + W - 1, y = O.y, z = L.landing_z}, "sel_hub:marker_landing")
	for _, p in ipairs(L.plates) do
		set(p, "sel_hub:plate")
	end
	fill(L.crystal_min, L.crystal_max, "sel_hub:crystal")
end

-- 8. The crossroads: a paved square on the south shore where the walkway
--    ends. Every activity that registered a destination gets a signpost.
local function build_crossroads()
	local C, r = L.crossroads, L.crossroads_radius
	fill({x = C.x - r - 1, y = C.y + 1, z = C.z - r - 1},
		{x = C.x + r + 1, y = C.y + 8, z = C.z + r + 1}, "air")
	for x = C.x - r, C.x + r do
		for z = C.z - r, C.z + r do
			sel_core.pillar_down({x = x, y = C.y - 1, z = z}, "default:stone", 20)
		end
	end
	fill({x = C.x - r, y = C.y, z = C.z - r}, {x = C.x + r, y = C.y, z = C.z + r},
		"sel_core:path_edge")
	-- purple (= Hub colour) square in the middle
	fill({x = C.x - 1, y = C.y, z = C.z - 1}, {x = C.x + 1, y = C.y, z = C.z + 1},
		"sel_core:path_purple")

	sel_core.build_signpost(L.signs.north, "sel_hub:sign")
	for side, sign_node in pairs(sel_hub.destinations) do
		sel_core.build_signpost(L.signs[side], sign_node)
	end
end

-- 9. Decoration: flower planters on the plaza, a flower meadow and two
--    apple trees around the crossroads. Not needed to play.
local FLOWERS = {"flowers:tulip", "flowers:rose", "flowers:viola", "flowers:geranium",
	"flowers:dandelion_yellow", "flowers:dandelion_white", "flowers:chrysanthemum_green"}

local function build_decor()
	for i, p in ipairs(L.planters) do
		set(p, "default:dirt_with_grass")
		set(vector.offset(p, 0, 1, 0), FLOWERS[i])
	end
	local C, r = L.crossroads, L.meadow_radius
	-- flowers on one of 7 grass blocks, grass tufts on one of 5
	sel_core.scatter({x = C.x - r, y = C.y, z = C.z - r}, {x = C.x + r, y = C.y, z = C.z + r},
		FLOWERS, 7, 40)
	sel_core.scatter({x = C.x - r, y = C.y, z = C.z - r}, {x = C.x + r, y = C.y, z = C.z + r},
		{"default:grass_2", "default:grass_3", "default:grass_4"}, 5, 41)
	for _, t in ipairs(L.trees) do
		local y = sel_core.path_height(t.x, t.z)
		-- only on land (path_height answers "above the water" over water)
		if core.get_item_group(core.get_node({x = t.x, y = y, z = t.z}).name, "soil") > 0 then
			sel_core.plant_tree({x = t.x, y = y, z = t.z}, "apple")
		end
	end
end

-- Build everything. `done` (optional) is called when finished.
function sel_hub.build(done)
	-- Load/generate the whole area first (a bit bigger than the zone, so the
	-- map generator never overwrites our work later).
	local p1 = vector.offset(L.zone_min, -16, 0, -32) -- includes the crossroads
	local p2 = vector.offset(L.zone_max, 16, 0, 16)
	core.log("action", "[sel_hub] generating Hub area ...")

	sel_core.when_loaded(p1, p2, function()
		-- 1. Clear the air space above the Hub (hilltop, trees, ...).
		fill({x = O.x - R - 2, y = O.y + 1, z = L.walk_last_z - 2},
			{x = O.x + R + 2, y = O.y + 16, z = O.z + R + 2}, "air")

		build_plaza()
		build_walkway()
		build_gap()
		build_parkour()
		build_stations()
		sel_flower.build_calm_corner(L.calm_corner)
		set(L.wardrobe, "sel_looks:wardrobe")
		set(vector.offset(L.wardrobe, 0, 1, 0), "sel_looks:wardrobe")
		build_crossroads()
		build_decor()

		storage:set_int("built_version", sel_hub.BUILD_VERSION)
		core.log("action", "[sel_hub] Hub built (version "
			.. sel_hub.BUILD_VERSION .. ")")
		if done then
			done()
		end
	end)
end

-- A short text listing all registered destinations, e.g.
-- "east=sel_lake:sign;south=sel_irrigation:sign;". If it differs from the
-- one stored at the last build, a new activity has been added (or removed)
-- and the crossroads needs its signposts refreshed.
local function destinations_signature()
	local sides = {}
	for side in pairs(sel_hub.destinations) do
		table.insert(sides, side)
	end
	table.sort(sides)
	local text = ""
	for _, side in ipairs(sides) do
		text = text .. side .. "=" .. sel_hub.destinations[side] .. ";"
	end
	return text
end

-- Build automatically on the first start (or when the layout changed).
-- If only the list of activities changed, just rebuild the crossroads.
core.after(1, function()
	if storage:get_int("built_version") < sel_hub.BUILD_VERSION then
		sel_hub.build(function()
			storage:set_string("destinations", destinations_signature())
		end)
	elseif storage:get_string("destinations") ~= destinations_signature() then
		local C, r = L.crossroads, L.crossroads_radius + 2
		sel_core.when_loaded(vector.offset(C, -r, -4, -r), vector.offset(C, r, 10, r), function()
			build_crossroads()
			storage:set_string("destinations", destinations_signature())
			core.log("action", "[sel_hub] crossroads signposts updated")
		end)
	end
end)

----------------------------------------------------------------------------
-- Protection: children cannot change the Hub, except for the two places
-- where the tutorial asks them to dig (shiny block) or place (green marker).
----------------------------------------------------------------------------
local place_spot = vector.offset(L.place_marker, 0, 1, 0)

sel_core.protect_zone({
	name = "hub",
	minp = L.zone_min,
	maxp = L.zone_max,
	allow = function(pos, name)
		if vector.equals(pos, L.shiny) then
			return true -- station 2: dig the shiny block
		end
		if vector.equals(pos, place_spot) then
			return true -- station 3: place a block on the green marker
		end
		return false
	end,
})
