--[[
    build.lua - builds the Lake Crossing site
    =========================================

    Built on the first server start (and when BUILD_VERSION in config.lua
    is increased, or with /sel_lake_rebuild):

      1. start dock on the beach: pine deck on pillars, launch platform,
         Shield Glass railing (open only in front of the launch platform
         and towards the beach)
      2. crates, calm corner, Ferrymaster
      3. far dock at the Hub island
      4. the broken ferry (decoration)
      5. the teal path from the crossroads to the start dock, with a
         teal gate at its end; reeds and water lilies beside the dock
      6. reset of the activity (launch.lua): water cleaned, roles forgotten

    Protection: the dock decks and the ferry are protected zones (children
    cannot dig them). The water in between is NOT protected - that is where
    the children build. Crates, launch platform, railing, calm corner and
    path are unbreakable blocks.
]]

local S = sel_lake.S
local L = sel_lake.layout
local Y = L.deck_y
local fill, set = sel_core.fill, sel_core.set
local storage = core.get_mod_storage()

local MAT = {
	deck = "default:pine_wood",
	pillar = "default:pine_tree",
	railing = "sel_core:shield_glass",
	hull = "default:wood",
	mast = "default:pine_tree",
	sail = "wool:white",
}

-- A wooden deck from minp to maxp (y = deck height) with pillars down to
-- the lake bed every 3 blocks along its north and south edges.
local function build_deck(minp, maxp)
	fill(vector.offset(minp, -1, 1, -1), vector.offset(maxp, 1, 12, 1), "air")
	fill(minp, maxp, MAT.deck)
	for x = minp.x, maxp.x, 3 do
		for _, z in ipairs({minp.z, maxp.z}) do
			sel_core.pillar_down({x = x, y = Y - 1, z = z}, MAT.pillar, 20)
		end
	end
end

local function build_start_dock()
	local a, b = L.start_min, L.start_max
	build_deck(a, b)
	fill(L.launch_min, L.launch_max, "sel_lake:launch")

	-- railing one block above the deck: north and south edges ...
	fill({x = a.x - 1, y = Y + 1, z = b.z + 1}, {x = b.x, y = Y + 1, z = b.z + 1}, MAT.railing)
	fill({x = a.x - 1, y = Y + 1, z = a.z - 1}, {x = b.x, y = Y + 1, z = a.z - 1}, MAT.railing)
	-- ... and the west edge (towards the water), open only in front of
	-- the launch platform. The east edge stays open: that is the beach.
	for z = a.z, b.z do
		local in_front_of_launch = z >= L.launch_min.z and z <= L.launch_max.z
		if not in_front_of_launch then
			set({x = a.x - 1, y = Y + 1, z = z}, MAT.railing)
		end
	end

	for role, pos in pairs(L.crates) do
		set(pos, "sel_lake:crate_" .. role)
	end
	sel_flower.build_calm_corner(L.calm_corner)
end

local function build_ferry()
	local a, b = L.ferry_min, L.ferry_max
	-- hull: a wooden box outline, the floor at y=0 (half under water)
	fill({x = a.x, y = 0, z = a.z}, {x = b.x, y = 0, z = b.z}, MAT.hull)
	fill({x = a.x, y = 1, z = a.z}, {x = b.x, y = 1, z = a.z}, MAT.hull)
	fill({x = a.x, y = 1, z = b.z}, {x = b.x, y = 1, z = b.z}, MAT.hull)
	-- the "broken" part: a hole in the floor and side at the west end
	set({x = a.x, y = 0, z = a.z + 1}, "default:water_source")
	set({x = a.x, y = 0, z = a.z + 2}, "default:water_source")
	set({x = a.x + 1, y = 1, z = b.z}, "air")
	-- mast with a torn sail
	local mx, mz = a.x + 3, a.z + 2
	fill({x = mx, y = 1, z = mz}, {x = mx, y = 4, z = mz}, MAT.mast)
	set({x = mx + 1, y = 4, z = mz}, MAT.sail)
	set({x = mx + 1, y = 3, z = mz}, MAT.sail)
end

-- The smallest box (with a margin) that contains all given x/z points.
local function bounds(points, margin)
	local minp = {x = math.huge, y = -16, z = math.huge}
	local maxp = {x = -math.huge, y = 60, z = -math.huge}
	for _, p in ipairs(points) do
		minp.x, minp.z = math.min(minp.x, p.x), math.min(minp.z, p.z)
		maxp.x, maxp.z = math.max(maxp.x, p.x), math.max(maxp.z, p.z)
	end
	return vector.offset(minp, -margin, 0, -margin), vector.offset(maxp, margin, 0, margin)
end

function sel_lake.build(done)
	-- everything we touch: both docks, the ferry and the whole path
	local points = {L.start_min, L.start_max, L.far_min, L.far_max, L.ferry_min, L.ferry_max}
	for _, p in ipairs(L.path) do
		table.insert(points, p)
	end
	local p1, p2 = bounds(points, 16)

	core.log("action", "[sel_lake] generating Lake area ...")
	sel_core.when_loaded(p1, p2, function()
		sel_core.build_path(L.path, "teal") -- first, so the dock is laid over its end
		build_start_dock()
		build_deck(L.far_min, L.far_max)
		build_ferry()
		-- decoration (see sel_core/decor.lua)
		sel_core.build_gate({x = L.gate.x, y = sel_core.path_height(L.gate.x, L.gate.z),
			z = L.gate.z}, "z", "teal")
		for i, box in ipairs(L.water_plants) do
			sel_core.build_water_plants(box.min, box.max, sel_lake.WATER_LEVEL, 4, 30 + i)
		end
		sel_lake.reset() -- no left-over vessel, no home pad, fresh roles
		sel_core.spawn_npc("ferrymaster", L.ferrymaster, 0)
		storage:set_int("built_version", sel_lake.BUILD_VERSION)
		core.log("action", "[sel_lake] Lake site built (version "
			.. sel_lake.BUILD_VERSION .. ")")
		if done then
			done()
		end
	end)
end

-- Build on first start / layout change. Wait for the Hub to start first
-- (both emerge areas at the same time is slower, not faster).
core.after(3, function()
	if storage:get_int("built_version") < sel_lake.BUILD_VERSION then
		sel_lake.build()
	end
end)

----------------------------------------------------------------------------
-- Signpost at the crossroads, protection zones, /sel_goto site, rebuild
----------------------------------------------------------------------------
sel_core.register_sign("sel_lake:sign", "sel_lake_sign.png")
sel_hub.register_destination("east", "sel_lake:sign")

sel_core.protect_zone({
	name = "lake start dock",
	minp = {x = L.start_min.x, y = -16, z = L.start_min.z},
	maxp = L.start_max,
})
sel_core.protect_zone({
	name = "lake far dock",
	minp = {x = L.far_min.x, y = -16, z = L.far_min.z},
	maxp = L.far_max,
})
sel_core.protect_zone({
	name = "lake ferry",
	minp = L.ferry_min,
	maxp = vector.offset(L.ferry_max, 0, 4, 0),
})

sel_core.register_site("lake", L.arrival)

core.register_chatcommand("sel_lake_rebuild", {
	description = S("Rebuild the Lake Crossing site"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_lake.build(function()
			core.chat_send_player(name, S("The Lake Crossing site has been rebuilt."))
		end)
		return true, S("Rebuilding the Lake Crossing site ...")
	end,
})
