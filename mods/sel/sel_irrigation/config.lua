--[[
    config.lua - where everything of the Irrigation Channel is
    ==========================================================

    The fields lie on flat ground south-east of the crossroads (map in
    docs/WORLD.md). The ground there is at y = 15; channel blocks are put
    ON the ground, so everything that must touch the channel (source block,
    garden bed) stands one block higher, at y = 16.

        west                                                        east
         brook
           |    (I) [+]           green  ~ ~  dry
        [ pool ][S] . . . . ooo . . . . . . . T . . . . [ garden bed ]
           (calm)           ooo                              (scarecrow)

        S = blue Water Source block      ooo = boulders (in the way!)
        I = Inventor, [+] = spare parts  T = old tree

    The straight way from the source to the garden is 24 blocks long and
    blocked by boulders: the channel has to go around them (or over them).
    The west half of the field is green, the east half is dry and yellow -
    it turns green when the water arrives.

    One child has 15 channel blocks + 1 pump. That is not enough alone:
    two or more children must join their pieces. For very small groups
    (and for trying it out alone) the spare-parts crate next to the
    Inventor hands out a few more blocks to whoever has none left.
]]

-- Bump to rebuild the site on the next start (or /sel irrigation_rebuild).
sel_irrigation.BUILD_VERSION = 2
-- History: 1 = first field (15 blocks between source and garden).
-- 2 = bigger and more varied: 24 blocks, boulders, brook, old tree, dry
--     half that turns green, fence, gate, scarecrow, spare-parts crate.

local Y = 15 -- ground level of the field (children stand at Y + 1)

sel_irrigation.layout = {
	ground_y = Y,

	-- the levelled field; everything else sits inside it. A wooden fence
	-- runs along its edge (openings: see `openings` below).
	field_min = {x = -650, y = Y, z = -846},
	field_max = {x = -606, y = Y, z = -824},

	-- THE ACTIVITY AREA: whoever is inside this box takes part
	area_min = {x = -652, y = Y - 6, z = -848},
	area_max = {x = -604, y = Y + 25, z = -822},

	-- The ground is green (watered) west of this x and dry east of it.
	-- The border is ragged over a few blocks, see build.lua.
	dry_from_x = -634,

	-- little pool (decoration) with a stone rim; the water "comes from here"
	pool_min = {x = -648, y = Y, z = -837},
	pool_max = {x = -644, y = Y, z = -833},

	-- the brook that feeds the pool: one block wide, from the north fence
	-- to the pool, with a plank to walk across
	brook_x = -646,
	brook_z_min = -833,
	brook_z_max = -825,
	brook_plank_z = -829,

	-- the blue Water Source block: the channel must START next to it
	source = {x = -643, y = Y + 1, z = -835},

	-- the garden bed, raised one block: the channel must END next to it
	garden_min = {x = -618, y = Y + 1, z = -838},
	garden_max = {x = -612, y = Y + 1, z = -832},

	-- the Inventor stands north of the pool, east of the brook
	inventor = {x = -644, y = Y + 0.5, z = -830},

	-- the spare-parts crate beside the Inventor (see nodes.lua)
	crate = {x = -642, y = Y + 1, z = -829},

	-- THINGS IN THE WAY (decoration that the channel has to avoid).
	-- Boulders: {x, z, height}. They lie right on the straight line.
	boulders = {
		{x = -636, z = -836, h = 1}, {x = -635, z = -836, h = 2}, {x = -634, z = -836, h = 1},
		{x = -636, z = -835, h = 2}, {x = -635, z = -835, h = 2}, {x = -634, z = -835, h = 1},
		{x = -635, z = -834, h = 1}, {x = -634, z = -837, h = 1},
		-- a second, small group further east
		{x = -623, z = -835, h = 1}, {x = -623, z = -836, h = 1}, {x = -622, z = -836, h = 2},
	},
	-- the old tree (ground block under its trunk) and a fallen log
	tree = {x = -627, y = Y, z = -837},
	log_min = {x = -631, y = Y + 1, z = -841},
	log_max = {x = -629, y = Y + 1, z = -841},

	-- decoration around the garden
	scarecrow = {x = -609, y = Y, z = -829},
	straw = { -- bales of straw: {x, z, height}
		{x = -609, z = -841, h = 2}, {x = -610, z = -841, h = 1}, {x = -609, z = -842, h = 1},
	},

	-- openings in the fence (the fence block is left out where
	-- x and z are inside one of these boxes)
	openings = {
		{x1 = -650, x2 = -650, z1 = -836, z2 = -834}, -- west: the blue path
		{x1 = -606, x2 = -606, z1 = -836, z2 = -834}, -- east: out to the meadow
	},
	-- the blue gate stands over the path just outside the west opening
	gate = {x = -651, y = Y, z = -835},

	-- calm corner in the south-west corner of the field
	calm_corner = {x = -647, y = Y, z = -841},

	-- where the "way back home" pad appears after success (south of the bed)
	home_pad = {x = -615, y = Y, z = -840},

	-- where children arrive with /sel goto irrigation
	arrival = {x = -649, y = Y + 1, z = -835},

	-- the blue path (about 35 blocks) from the SOUTH exit of the
	-- crossroads (see sel_hub/config.lua) to the west edge of the field.
	-- Only x and z; heights are automatic.
	path = {
		{x = -680, z = -807},
		{x = -672, z = -822},
		{x = -660, z = -834},
		{x = -652, z = -835},
	},
}

-- THE KIT every child receives when entering the field
sel_irrigation.KIT_CHANNELS = 15
sel_irrigation.KIT_PUMPS = 1

-- THE SPARE-PARTS CRATE: a right click gives this many channel blocks -
-- but only to a child whose pockets hold no channel block any more.
sel_irrigation.CRATE_CHANNELS = 5

-- THE FLOW
-- Seconds everyone must stand on their own pump together.
sel_irrigation.HOLD_SECONDS = 3
-- Seconds the water needs per channel block (smaller = faster flow).
sel_irrigation.FLOW_STEP_TIME = 0.15
-- If the channel has a gap: seconds the water stays visible before the
-- channel runs dry again (time to look where it stopped).
sel_irrigation.DRY_AGAIN_TIME = 4
-- Safety limit for the number of channel blocks that are followed.
sel_irrigation.MAX_CHANNEL_BLOCKS = 2000

-- Plants on the field. All of them give way when a channel block is put
-- on their spot. The dry ones are swapped for the green ones when the
-- water arrives (and back at a reset).
sel_irrigation.FIELD_PLANTS = {
	green = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4"},
	dry = {"default:dry_grass_1", "default:dry_grass_2", "default:dry_grass_3", "default:dry_shrub"},
}
-- About one of this many ground blocks carries a plant.
sel_irrigation.PLANT_ONE_IN = 5

-- What grows on the garden bed when the water arrives (picked at random).
sel_irrigation.PLANTS = {
	"flowers:tulip", "flowers:dandelion_yellow", "flowers:geranium",
	"flowers:rose", "flowers:viola", "farming:wheat_8", "default:grass_4",
}
