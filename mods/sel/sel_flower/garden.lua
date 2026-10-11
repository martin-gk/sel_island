--[[
    garden.lua - the Breathing Garden and the Gardener
    ==================================================

    A quiet place right beside the crossroads where children LEARN how the
    Breathing Flower works - and where they can always come back to.

    The Gardener tells it in five pictures (no words, sel_core/npc.lua):

      1  when everything is too much: go to a flower
      2  the flower OPENS and is BLUE   -> breathe IN    (count to 4)
      3  the flower is OPEN and GOLD    -> HOLD          (count to 7)
      4  the flower CLOSES, is VIOLET   -> breathe OUT   (count to 8)
      5  calm again - and round it goes, as often as you like

    Then the children try it at once: five flowers breathe in the garden,
    all in the same rhythm, with seats in front of them.

    The garden lies inside the story area (sel_core/story_area.lua):
    nothing can be dug there, but children CAN plant their own flower.
    Its flowers are "fixed" like those of the calm corners: /sel calm
    brings a child to the nearest one.

    All positions: config.lua (sel_flower.garden).
]]

local S = sel_flower.S
local G = sel_flower.garden
local Y = G.ground_y
local fill, set = sel_core.fill, sel_core.set
local storage = core.get_mod_storage()

sel_core.register_npc("gardener", {
	skin = "sel_flower_gardener.png",
	story = {
		"sel_flower_story_1.png",
		"sel_flower_story_2.png",
		"sel_flower_story_3.png",
		"sel_flower_story_4.png",
		"sel_flower_story_5.png",
	},
	radius = 5,
})

local BED_FLOWERS = {"flowers:tulip", "flowers:rose", "flowers:viola", "flowers:geranium",
	"flowers:dandelion_yellow", "flowers:dandelion_white", "flowers:tulip_black",
	"flowers:chrysanthemum_green"}

local function build_ground()
	local a, b = G.min, G.max
	-- head room, earth below (the land slopes: one side is cut into the
	-- hill, the other side is filled up), grass on top
	fill({x = a.x, y = Y + 1, z = a.z}, {x = b.x, y = Y + 10, z = b.z}, "air")
	fill({x = a.x, y = Y - 3, z = a.z}, {x = b.x, y = Y - 1, z = b.z}, "default:dirt")
	fill(a, b, "default:dirt_with_grass")
end

-- A hedge (one block of leaves) around the garden, open at the entrance.
local function build_hedge()
	local a, b = G.min, G.max
	local function leaf(x, z)
		local in_entrance = x == a.x and z >= G.entrance_z_min and z <= G.entrance_z_max
		if not in_entrance then
			-- param2 = 1 marks "placed by hand": such leaves never decay
			set({x = x, y = Y + 1, z = z}, "default:leaves", 1)
		end
	end
	for x = a.x, b.x do
		leaf(x, a.z)
		leaf(x, b.z)
	end
	for z = a.z, b.z do
		leaf(a.x, z)
		leaf(b.x, z)
	end
end

function sel_flower.build_garden(done)
	local p1 = {x = G.min.x - 16, y = 0, z = G.min.z - 16}
	local p2 = {x = G.max.x + 16, y = 60, z = G.max.z + 16}
	for _, p in ipairs(G.path) do
		p1.x, p1.z = math.min(p1.x, p.x - 16), math.min(p1.z, p.z - 16)
		p2.x, p2.z = math.max(p2.x, p.x + 16), math.max(p2.z, p.z + 16)
	end

	core.log("action", "[sel_flower] generating the garden area ...")
	sel_core.when_loaded(p1, p2, function()
		build_ground()
		sel_core.build_path(G.path, "pink")
		local sign = G.signpost
		sel_core.build_signpost({x = sign.x, y = sel_core.path_height(sign.x, sign.z), z = sign.z},
			"sel_flower:sign")
		build_hedge()
		sel_core.build_gate(G.gate, "x", "pink")

		-- the five flowers, each on its patch of Calm Grass; built in the
		-- same moment, so they breathe in the same rhythm
		for _, pos in ipairs(G.flowers) do
			sel_flower.build_calm_corner(pos)
		end
		for _, seat in ipairs(G.seats) do
			set({x = seat.x, y = Y + 1, z = seat.z}, "stairs:slab_wood")
		end
		-- small flowers on about every third free grass block
		sel_core.scatter(vector.offset(G.min, 1, 0, 1), vector.offset(G.max, -1, 0, -1),
			BED_FLOWERS, 3, 60)
		for _, b in ipairs(G.butterflies) do
			set({x = b.x, y = Y + 3, z = b.z}, "butterflies:butterfly_" .. b.kind)
		end
		-- keep the way in free of flowers
		fill({x = G.min.x, y = Y + 1, z = G.entrance_z_min},
			{x = G.min.x + 2, y = Y + 2, z = G.entrance_z_max}, "air")

		sel_core.spawn_npc("gardener", G.gardener, 0)
		storage:set_int("garden_version", sel_flower.GARDEN_VERSION)
		core.log("action", "[sel_flower] garden built (version "
			.. sel_flower.GARDEN_VERSION .. ")")
		if done then
			done()
		end
	end)
end

-- Build on first start / layout change (after the Hub and the activities).
core.after(8, function()
	if storage:get_int("garden_version") < sel_flower.GARDEN_VERSION then
		sel_flower.build_garden()
	end
end)

----------------------------------------------------------------------------
-- Signpost picture, /sel goto site, rebuild command
----------------------------------------------------------------------------
sel_core.register_sign("sel_flower:sign", "sel_flower_sign.png")
sel_core.register_site("garden", G.arrival)

core.register_chatcommand("sel_garden_rebuild", {
	description = S("Rebuild the Breathing Garden"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_flower.build_garden(function()
			core.chat_send_player(name, S("The Breathing Garden has been rebuilt."))
		end)
		return true, S("Rebuilding the Breathing Garden ...")
	end,
})
