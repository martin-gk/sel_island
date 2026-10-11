--[[
    config.lua - where everything of the Village Decision is
    ========================================================

    The village lies on flat ground (y = 19) south-west of the crossroads,
    at the foot of the big mountain (map in docs/WORLD.md).

    Top view (north is up, not to scale):

          [house A]   [house B]      [house D]
                                                    <- gold path from
          [house C]  +--- square ---+    Mayor         the crossroads
                     | (G)          |                  (enters from the east)
                     | sign  STONE  |
                     | (B)          |
                     +--------------+     calm corner
                           child
          ~~~~~~~~~~~ |bridge| ~~~~~~~~~~~   pond
          ~~~~~~~~~~~ | gap  | ~~~~~~~~~~~
          ~~~~~~~~~~~ |bridge| ~~~~~~~~~~~
                  [grandparents' house]

    (G) = gold pedestal, (B) = blue pedestal, STONE = Decision Stone.
]]

-- Bump to rebuild the site on the next start (or /sel village_rebuild).
sel_village.BUILD_VERSION = 2
-- History: 1 = first village. 2 = decoration: gold gate, well, trees,
-- flowers at the doors, reeds and water lilies at the pond.

local Y = 19 -- ground level (children stand at Y + 1)

sel_village.layout = {
	ground_y = Y,

	-- the levelled ground of the whole village
	ground_min = {x = -722, y = Y, z = -868},
	ground_max = {x = -688, y = Y, z = -826},

	-- THE ACTIVITY AREA: whoever is inside this box takes part
	area_min = {x = -724, y = Y - 7, z = -870},
	area_max = {x = -686, y = Y + 26, z = -824},

	-- the paved village square
	square_min = {x = -710, y = Y, z = -845},
	square_max = {x = -698, y = Y, z = -833},

	-- the Decision Stone (3 x 3) in the middle of the square
	stone_min = {x = -705, y = Y, z = -840},
	stone_max = {x = -703, y = Y, z = -838},

	-- the two pedestals on the west side of the square, and between them
	-- the signpost with the "everyone on the stone" picture
	pedestal_gold = {x = -708, y = Y + 1, z = -837},
	pedestal_blue = {x = -708, y = Y + 1, z = -841},
	decision_sign = {x = -708, y = Y, z = -839},

	-- the story characters
	mayor = {x = -699, y = Y + 0.5, z = -836},        -- where the path arrives
	child = {x = -701, y = Y + 0.5, z = -848},        -- at the broken bridge
	grandma = {x = -706, y = Y + 0.5, z = -861},      -- in front of their house
	grandpa = {x = -702, y = Y + 0.5, z = -861},

	-- houses: south-west corner (x, z) of a 5 x 5 house, which side the
	-- door is on, and what it is built of. Different on purpose: a village
	-- of all kinds of houses.
	houses = {
		{x = -719, z = -832, door = "south", wall = "default:wood",        roof = "default:brick"},
		{x = -707, z = -831, door = "south", wall = "default:aspen_wood",  roof = "default:desert_stonebrick"},
		{x = -721, z = -843, door = "east",  wall = "default:junglewood",  roof = "default:sandstonebrick"},
		{x = -696, z = -832, door = "south", wall = "default:acacia_wood", roof = "default:pine_wood"},
		-- the grandparents' house, on the far side of the pond
		{x = -706, z = -867, door = "north", wall = "default:pine_wood",   roof = "default:brick"},
	},

	-- the pond ("the lake" of the story) south of the square:
	-- the water surface is one block below the ground
	pond_min = {x = -716, z = -858},
	pond_max = {x = -692, z = -850},

	-- the bridge over the pond, 3 wide. The two ends exist, the middle
	-- is missing: the GAP the children close if they choose blue.
	bridge_x_min = -705,
	bridge_x_max = -703,
	gap_min = {x = -705, y = Y, z = -856},
	gap_max = {x = -703, y = Y, z = -852},

	-- where decorations count (the square plus two blocks around it)
	decor_min = {x = -712, y = Y + 1, z = -847},
	decor_max = {x = -696, y = Y + 8, z = -831},

	-- gemstone deposits, hidden around the houses (blocks standing on the ground)
	gems = {
		{x = -721, z = -830}, {x = -713, z = -828}, {x = -709, z = -828},
		{x = -701, z = -827}, {x = -698, z = -830}, {x = -690, z = -830},
		{x = -722, z = -845}, {x = -715, z = -838}, {x = -712, z = -848},
		{x = -696, z = -848}, {x = -690, z = -843}, {x = -718, z = -852},
	},

	-- DECORATION (build.lua, build_decor). None of it is needed to play.
	-- the gold gate where the path enters the village (the path runs
	-- north-south there)
	gate = {x = -690, z = -826},
	-- the well (centre block), between the square and the west houses
	well = {x = -714, y = Y, z = -835},
	-- apple trees (the ground block each one stands on)
	trees = {
		{x = -720, y = Y, z = -836}, {x = -690, y = Y, z = -856},
		{x = -712, y = Y, z = -864}, {x = -695, y = Y, z = -864},
	},
	-- reeds on the bank of the pond (at its corners, so the north bank
	-- stays free), and water lilies (never where the bridge will be)
	reeds = {
		{x = -717, z = -851}, {x = -717, z = -854}, {x = -717, z = -857},
		{x = -691, z = -852}, {x = -691, z = -857}, {x = -714, z = -859},
	},
	lilies = {
		{x = -713, z = -853}, {x = -710, z = -856}, {x = -709, z = -851},
		{x = -698, z = -852}, {x = -695, z = -855}, {x = -700, z = -857},
	},

	-- calm corner south-east of the square
	calm_corner = {x = -692, y = Y, z = -846},

	-- where the "way back home" pad appears after the celebration
	home_pad = {x = -704, y = Y, z = -843},

	-- where children arrive with /sel goto village
	arrival = {x = -696, y = Y + 1, z = -839},

	-- the gold path (about 45 blocks, over the hill) from the WEST exit
	-- of the crossroads to the east side of the square.
	path = {
		{x = -685, z = -802},
		{x = -690, z = -815},
		{x = -690, z = -833},
		{x = -695, z = -839},
	},
}

-- Seconds everyone must stand on the Decision Stone together.
sel_village.HOLD_SECONDS = 3

-- Seconds until a mined gemstone deposit has grown back.
sel_village.GEM_REGROW_TIME = 20

-- GOLD: this many gem lamps must be placed on and around the square.
sel_village.DECOR_GOAL = 12

-- The gem lamps children receive for decorating (three colours).
sel_village.LAMPS = {"gold", "teal", "pink"}
