--[[
    build.lua - builds the village
    ==============================

    Built on the first server start (and when BUILD_VERSION in config.lua
    is increased, or with /sel village_rebuild):

      1. level ground for the whole village
      2. the gold path from the crossroads (laid after levelling, so it
         runs flat through the village)
      3. the pond and the two ends of the bridge
      4. the square with Decision Stone, pedestals and the picture sign
      5. the houses (each a little different)
      6. decoration: gold gate, well, apple trees, flowers at every
         door, grass tufts, reeds and water lilies at the pond
      7. calm corner, story characters
      8. reset of the activity (decide.lua): deposits full, nothing built

    Protection: the whole area is a zone in which children can only do
    what the activity allows (rules.lua).
]]

local S = sel_village.S
local L = sel_village.layout
local Y = L.ground_y
local fill, set = sel_core.fill, sel_core.set
local storage = core.get_mod_storage()

local MAT = {
	ground = "default:dirt_with_grass",
	square = "default:sandstonebrick",
	floor = "default:wood",
	base = "default:stonebrick",
	window = "default:glass",
	bridge = "default:wood",
	pillar = "default:pine_tree",
	bed = "default:sand",
}

local function build_ground()
	local a, b = L.ground_min, L.ground_max
	fill({x = a.x, y = Y + 1, z = a.z}, {x = b.x, y = Y + 14, z = b.z}, "air")
	fill({x = a.x, y = Y - 2, z = a.z}, {x = b.x, y = Y - 1, z = b.z}, "default:dirt")
	fill(a, b, MAT.ground)
end

-- The pond: one block of air, two blocks of water, a sandy bed.
local function build_pond()
	local a, b = L.pond_min, L.pond_max
	fill({x = a.x, y = Y, z = a.z}, {x = b.x, y = Y, z = b.z}, "air")
	fill({x = a.x, y = Y - 2, z = a.z}, {x = b.x, y = Y - 1, z = b.z}, "default:water_source")
	fill({x = a.x, y = Y - 3, z = a.z}, {x = b.x, y = Y - 3, z = b.z}, MAT.bed)
end

-- The two finished ends of the bridge (two rows each); the gap between
-- them stays open.
local function build_bridge_ends()
	local north = {L.gap_max.z + 1, L.gap_max.z + 2} -- towards the square
	local south = {L.gap_min.z - 1, L.gap_min.z - 2} -- towards the grandparents
	for _, rows in ipairs({north, south}) do
		for _, z in ipairs(rows) do
			fill({x = L.bridge_x_min, y = Y, z = z}, {x = L.bridge_x_max, y = Y, z = z}, MAT.bridge)
		end
		-- a pillar under the outer corners of each end
		for _, x in ipairs({L.bridge_x_min, L.bridge_x_max}) do
			sel_core.pillar_down({x = x, y = Y - 1, z = rows[1]}, MAT.pillar, 4)
		end
	end
	fill(L.gap_min, L.gap_max, "air")
end

local function build_square()
	fill(L.square_min, L.square_max, MAT.square)
	fill(L.stone_min, L.stone_max, "sel_village:decision_stone")
	set(L.pedestal_gold, "sel_village:pedestal_gold")
	set(L.pedestal_blue, "sel_village:pedestal_blue")
	sel_core.build_signpost(L.decision_sign, "sel_village:sign_decision")
end

-- A simple 5 x 5 house: stone-brick floor frame, wooden walls 3 high with
-- a door opening and windows, and a stepped roof. `h` comes from config.
local function build_house(h)
	local x1, z1, x2, z2 = h.x, h.z, h.x + 4, h.z + 4
	fill({x = x1, y = Y, z = z1}, {x = x2, y = Y, z = z2}, MAT.base)
	fill({x = x1 + 1, y = Y, z = z1 + 1}, {x = x2 - 1, y = Y, z = z2 - 1}, MAT.floor)
	-- walls: fill the box, then hollow it out
	fill({x = x1, y = Y + 1, z = z1}, {x = x2, y = Y + 3, z = z2}, h.wall)
	fill({x = x1 + 1, y = Y + 1, z = z1 + 1}, {x = x2 - 1, y = Y + 3, z = z2 - 1}, "air")
	-- a window in the middle of every wall ...
	local mx, mz = x1 + 2, z1 + 2
	local sides = {
		north = {x = mx, z = z2}, south = {x = mx, z = z1},
		east = {x = x2, z = mz}, west = {x = x1, z = mz},
	}
	for _, p in pairs(sides) do
		set({x = p.x, y = Y + 2, z = p.z}, MAT.window)
	end
	-- ... except where the door is: an opening two blocks high
	local door = sides[h.door]
	set({x = door.x, y = Y + 1, z = door.z}, "air")
	set({x = door.x, y = Y + 2, z = door.z}, "air")
	-- stepped roof: 7 x 7, then 5 x 5, then 3 x 3
	for step = 0, 2 do
		fill({x = x1 - 1 + step, y = Y + 4 + step, z = z1 - 1 + step},
			{x = x2 + 1 - step, y = Y + 4 + step, z = z2 + 1 - step}, h.roof)
	end
	-- a lamp under the roof, so it is friendly inside
	set({x = mx, y = Y + 3, z = mz}, "default:meselamp")
end

----------------------------------------------------------------------------
-- Decoration (nothing here is needed to play)
----------------------------------------------------------------------------
local DOOR_FLOWERS = {"flowers:tulip", "flowers:rose", "flowers:viola",
	"flowers:geranium", "flowers:dandelion_yellow", "flowers:chrysanthemum_green"}

-- Two flowers in front of a house, left and right of its door.
local function build_door_flowers(h, number)
	local mx, mz = h.x + 2, h.z + 2
	local spots = {
		north = {{x = mx - 1, z = h.z + 5}, {x = mx + 1, z = h.z + 5}},
		south = {{x = mx - 1, z = h.z - 1}, {x = mx + 1, z = h.z - 1}},
		east = {{x = h.x + 5, z = mz - 1}, {x = h.x + 5, z = mz + 1}},
		west = {{x = h.x - 1, z = mz - 1}, {x = h.x - 1, z = mz + 1}},
	}
	for i, p in ipairs(spots[h.door]) do
		-- every house has its own two kinds of flowers
		set({x = p.x, y = Y + 1, z = p.z}, DOOR_FLOWERS[(number * 2 + i - 3) % #DOOR_FLOWERS + 1])
	end
end

-- The well: a ring of stone brick around water, two posts, a little roof.
local function build_well()
	local c = L.well
	fill(vector.offset(c, -1, 1, -1), vector.offset(c, 1, 1, 1), "default:stonebrick")
	set(c, "default:water_source")
	set(vector.offset(c, 0, 1, 0), "default:water_source")
	for _, dx in ipairs({-1, 1}) do
		set(vector.offset(c, dx, 2, 0), "default:fence_wood")
		set(vector.offset(c, dx, 3, 0), "default:fence_wood")
	end
	fill(vector.offset(c, -1, 4, 0), vector.offset(c, 1, 4, 0), "stairs:slab_wood")
end

local function build_decor()
	local gate = L.gate
	sel_core.build_gate({x = gate.x, y = sel_core.path_height(gate.x, gate.z), z = gate.z},
		"z", "gold")
	build_well()
	for i, house in ipairs(L.houses) do
		build_door_flowers(house, i)
	end
	for _, tree in ipairs(L.trees) do
		sel_core.plant_tree(tree, "apple")
	end
	for _, p in ipairs(L.reeds) do
		sel_core.build_reeds({x = p.x, y = Y, z = p.z},
			2 + math.floor(sel_core.noise(p.x, p.z, 1) * 2))
	end
	for _, p in ipairs(L.lilies) do
		-- the water surface is one block below the ground
		set({x = p.x, y = Y, z = p.z}, "flowers:waterlily")
	end
	-- grass tufts here and there (they give way to anything placed on them)
	sel_core.scatter(L.ground_min, L.ground_max,
		{"default:grass_1", "default:grass_2", "default:grass_3"}, 9, 21)
end

function sel_village.build(done)
	local p1 = {x = L.area_min.x - 16, y = 0, z = L.area_min.z - 16}
	local p2 = {x = L.area_max.x + 16, y = 60, z = L.area_max.z + 16}
	for _, p in ipairs(L.path) do
		p1.x, p1.z = math.min(p1.x, p.x - 16), math.min(p1.z, p.z - 16)
		p2.x, p2.z = math.max(p2.x, p.x + 16), math.max(p2.z, p.z + 16)
	end

	core.log("action", "[sel_village] generating the village area ...")
	sel_core.when_loaded(p1, p2, function()
		build_ground()
		sel_core.build_path(L.path, "gold")
		build_pond()
		build_bridge_ends()
		build_square()
		for _, house in ipairs(L.houses) do
			build_house(house)
		end
		build_decor()
		sel_flower.build_calm_corner(L.calm_corner)
		sel_core.spawn_npc("mayor", L.mayor, 0)
		sel_core.spawn_npc("village_child", L.child, 0)
		sel_core.spawn_npc("grandma", L.grandma, 0)
		sel_core.spawn_npc("grandpa", L.grandpa, 0)
		sel_village.reset() -- deposits full, nothing built, pedestals empty
		storage:set_int("built_version", sel_village.BUILD_VERSION)
		core.log("action", "[sel_village] village built (version "
			.. sel_village.BUILD_VERSION .. ")")
		if done then
			done()
		end
	end)
end

-- Build on first start / layout change (after Hub, Lake and Irrigation).
core.after(7, function()
	if storage:get_int("built_version") < sel_village.BUILD_VERSION then
		sel_village.build()
	end
end)

----------------------------------------------------------------------------
-- Signpost at the crossroads, /sel goto site, rebuild command
----------------------------------------------------------------------------
sel_core.register_sign("sel_village:sign", "sel_village_sign.png")
sel_hub.register_destination("west", "sel_village:sign")

sel_core.register_site("village", L.arrival)

core.register_chatcommand("sel_village_rebuild", {
	description = S("Rebuild the village"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_village.build(function()
			core.chat_send_player(name, S("The village has been rebuilt."))
		end)
		return true, S("Rebuilding the village ...")
	end,
})
