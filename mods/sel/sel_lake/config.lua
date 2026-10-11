--[[
    config.lua - where everything of the Lake Crossing is
    =====================================================

    The crossing goes over the lake around the Hub island, from the sandy
    EAST BEACH westwards to the foot of the Hub island (map in
    docs/WORLD.md). Two wooden docks leave 15 blocks of open water:

        west (Hub island)                                east (beach)
        -x                                                        +x
        x -660..-656        x -655..-641          x -640..-629
        [ far dock ]  ~ ~ ~ open water ~ ~ ~  [L][ start dock ] beach
                       children build here     ^
                                               launch platform (teal)

    The water surface is at y = 1, so both decks are at y = 2 (level with
    the beach) and the children stand at y = 3.

    Children reach the start dock by following the TEAL path from the
    crossroads (see `path` below) or with /sel_goto lake.
]]

-- Bump to rebuild the site on the next start (or /sel_lake_rebuild).
sel_lake.BUILD_VERSION = 4
-- History: 1 = first site (north of the old Hub).
-- 2 = moved to the east beach of the Hub lake; teal path from the crossroads.
-- 3 = calm corner flower marked "fixed"; building area cleaned on rebuild.
-- 4 = decoration: teal gate at the dock, reeds and water lilies.

local Y = 2 -- deck height

-- Height of the top block of lake water (the mapgen's sea level).
sel_lake.WATER_LEVEL = 1

sel_lake.layout = {
	deck_y = Y,

	-- start dock (on the beach side), and the launch platform at its
	-- west edge
	start_min = {x = -640, y = Y, z = -753},
	start_max = {x = -629, y = Y, z = -739},
	launch_min = {x = -640, y = Y, z = -748},
	launch_max = {x = -639, y = Y, z = -744},

	-- far dock (goal), at the foot of the Hub island's east cliff
	far_min = {x = -660, y = Y, z = -750},
	far_max = {x = -656, y = Y, z = -742},

	-- THE ACTIVITY AREA: whoever is inside this box takes part (gets a
	-- material role, counts for the launch). It covers both docks, the
	-- water between them and a bit of beach.
	area_min = {x = -664, y = -12, z = -758},
	area_max = {x = -622, y = 40,  z = -730},

	-- where the "way back home" pad appears after a successful crossing
	-- (middle of the far dock)
	home_pad = {x = -658, y = Y, z = -746},

	-- where children arrive with /sel_goto lake (on the start dock)
	arrival = {x = -636, y = Y + 1, z = -746},

	-- material crates, standing in a row on the south part of the start
	-- dock (one per role)
	crates = {
		wood   = {x = -639, y = Y + 1, z = -752},
		stone  = {x = -637, y = Y + 1, z = -752},
		glass  = {x = -635, y = Y + 1, z = -752},
		garden = {x = -633, y = Y + 1, z = -752},
	},

	-- the Ferrymaster stands in front of the crates
	ferrymaster = {x = -634, y = Y + 0.5, z = -750},

	-- calm corner on the north end of the start dock
	calm_corner = {x = -635, y = Y, z = -741},

	-- the broken ferry, washed up north of the dock (decoration)
	ferry_min = {x = -630, y = 0, z = -734},
	ferry_max = {x = -625, y = 1, z = -731},

	-- DECORATION: the teal gate over the last, straight part of the path
	-- (it runs north-south there), and two stretches of shore with reeds
	-- and water lilies. Both lie beside the docks, NOT between them:
	-- the water where the children build stays empty.
	gate = {x = -625, z = -750},
	water_plants = {
		{min = {x = -642, z = -737}, max = {x = -623, z = -731}}, -- north of the dock
		{min = {x = -642, z = -762}, max = {x = -628, z = -756}}, -- south of the dock
	},

	-- the teal path (about 65 blocks): from the east exit of the
	-- crossroads (see sel_hub/config.lua) north-east along the lake shore
	-- and down the bank to the beach, ending beside the dock.
	-- Only x and z; heights are automatic.
	path = {
		{x = -675, z = -802},
		{x = -655, z = -790},
		{x = -642, z = -772},
		{x = -627, z = -758},
		{x = -625, z = -750},
		{x = -625, z = -746},
	},
}

-- The four material roles, in a fixed order.
--   texture = picture of the material (crate, role icons)
--   background = colour behind the picture (glass and leaves are partly
--             see-through)
--   items   = what the crate hands out per right click
--   nodes   = blocks that count as this material (for "may I dig/place
--             this?" and for "does the vessel contain every material?")
sel_lake.ROLES = {"wood", "stone", "glass", "garden"}
sel_lake.MATERIALS = {
	wood = {
		texture = "default_wood.png",
		background = "#8c6432",
		items = {"default:wood 10"},
		nodes = {"default:wood"},
	},
	stone = {
		texture = "default_cobble.png",
		background = "#6e6e6e",
		items = {"default:cobble 10"},
		nodes = {"default:cobble"},
	},
	glass = {
		texture = "default_glass.png",
		background = "#aad2f0",
		items = {"default:glass 10"},
		nodes = {"default:glass"},
	},
	garden = {
		texture = "default_leaves.png",
		background = "#3c7832",
		items = {"default:leaves 10", "flowers:rose 2"},
		nodes = {"default:leaves", "flowers:rose"},
	},
}

-- THE LAUNCH
-- Seconds everyone must stand on the launch platform together.
sel_lake.HOLD_SECONDS = 3
-- The vessel must reach at least this many blocks out over the water
-- (measured from the launch platform) before it can sail.
sel_lake.MIN_REACH = 5
-- Seconds between two steps (1 block each) while the vessel sails.
sel_lake.SAIL_STEP_TIME = 0.35
-- Safety limit: a vessel bigger than this many blocks is not followed
-- any further (keeps the server fast).
sel_lake.MAX_VESSEL_BLOCKS = 3000
