--[[
    config.lua - where everything of the Hub is
    ===========================================

    All positions are computed from ONE point, the ORIGIN = the centre
    block of the plaza floor. Move the origin and the whole Hub moves.

    The origin (-680, 21, -750) is the middle of the flat-topped island in
    the lake that Martin Guevara-Kunerth picked (see docs/WORLD.md for the map).
    !! If you change it, also change static_spawnpoint in minetest.conf !!

    Map directions: +x = east, +z = north. The course leaves the plaza to
    the SOUTH (towards -z) as a wooden walkway. It crosses the water like
    a bridge and ends level with the ground on the lake's south shore, at
    the CROSSROADS: a small paved square where the coloured paths to the
    activities start, each marked by a picture signpost.

    Top view (not to scale), "row" = distance south of the plaza edge:

        plaza (15 x 15, stone)          spawn in the middle,
                                        calm corner (flower) north-west,
                                        wardrobe (looks) north-east
        |  |  walkway (5 wide + fence on each side)
        row  2   [B]        blue start marker
        row  3-7  . o . o . STEPPING STONES: hop from stone to stone
        row  8   [S]        shiny block (stands on the walkway)
        row 10-12 |#|       CLIMBING WALL: up the ladders, down the step
        row 14   [G]        green place marker
        row 19-20  ~gap~    1 block deep pit
        row 21   [YYYYY]    yellow landing markers (full width)
        row 23-26  --|--    BALANCE BEAM: one block wide
        row 28   [O] . [O]  two orange "together" plates
        row 35-37 [CCC]     3x3 purple crystal floor
        row 39   end of walkway
        rows 40-48  crossroads (9 x 9): signposts + start of the paths
]]

-- Bump this number whenever the layout below changes. On the next server
-- start the Hub is rebuilt automatically (or use /sel_hub_rebuild).
sel_hub.BUILD_VERSION = 8
-- History: 1 = first Hub. 2 = pit side walls made of unbreakable Shield Glass.
-- 3 = calm corner (Breathing Flower) on the plaza.
-- 4 = moved to the lake island at (-680, 21, -750); crossroads added.
-- 5 = parkour between the stations: stepping stones, climbing wall,
--     balance beam.
-- 6 = the calm corner's flower is marked "fixed" (children cannot pick it
--     up, now that they carry their own flowers).
-- 7 = wardrobe on the plaza (sel_looks: children choose their look).
-- 8 = decoration: flower planters on the plaza, flowers and two trees at
--     the crossroads.

-- Bump this number whenever the Hub MOVES to another place. Players who
-- were last seen at an older location (e.g. in a world created before the
-- move) are brought to the new Hub when they join. See progress.lua.
-- History: 1 = hill near (31, 68, 18). 2 = lake island (-680, 21, -750).
sel_hub.LOCATION_VERSION = 2

local O = {x = -680, y = 21, z = -750} -- origin: centre of the plaza floor
local R = 7                         -- plaza "radius": plaza is 15 x 15
local E = O.z - R - 1               -- z of the first walkway row (row 0)
local LENGTH = 40                   -- walkway rows: row 0 .. row 39

-- z of a walkway row (row 0 touches the plaza, rows go south)
local function row(n)
	return E - n
end

sel_hub.layout = {
	origin = O,
	plaza_radius = R,

	-- where children appear (one block above the floor)
	spawn = {x = O.x, y = O.y + 1, z = O.z},

	-- calm corner: centre of its 3x3 grass patch, in the north-west part
	-- of the plaza floor (see sel_flower/calm.lua)
	calm_corner = {x = O.x - 4, y = O.y, z = O.z + 4},

	-- wardrobe (two blocks high) in the north-east part of the plaza:
	-- right click = change your look (see sel_looks)
	wardrobe = {x = O.x + 4, y = O.y + 1, z = O.z + 4},

	-- walkway: x from -3..+3 around the centre line (the outer two columns
	-- carry the fences), from row 0 to row LENGTH-1
	walk_first_z = row(0),
	walk_last_z = row(LENGTH - 1),
	walk_half_width = 3,

	-- Station 1: blue start marker (in the floor)
	start_marker = {x = O.x, y = O.y, z = row(2)},

	-- Station 2: shiny block (standing ON the walkway)
	shiny = {x = O.x, y = O.y + 1, z = row(8)},

	-- Station 3: green place marker (in the floor)
	place_marker = {x = O.x, y = O.y, z = row(14)},

	-- Station 4: the gap (two rows) and the landing row after it
	gap_z = {row(19), row(20)},
	landing_z = row(21),

	-- Parkour between the stations (no icons - just practice for the
	-- controls). All pits are 1 block deep: falling in is harmless.
	parkour = {
		-- stepping stones: a pit over these rows with single blocks to hop on
		stones_first_z = row(3),
		stones_last_z = row(7),
		stones = {
			{x = O.x - 1, y = O.y, z = row(4)},
			{x = O.x + 1, y = O.y, z = row(6)},
		},
		-- climbing wall: ladders on its north side, 2 blocks high,
		-- one step down on the south side
		ladder_z = row(10),
		wall_z = row(11),
		step_z = row(12),
		-- balance beam: a pit over these rows with a 1-wide beam in the middle
		beam_first_z = row(23),
		beam_last_z = row(26),
	},

	-- Station 5: the two plates, on the left and right side of the walkway
	plates = {
		{x = O.x - 2, y = O.y, z = row(28)},
		{x = O.x + 2, y = O.y, z = row(28)},
	},

	-- Station 6: 3 x 3 crystal floor
	crystal_min = {x = O.x - 1, y = O.y, z = row(37)},
	crystal_max = {x = O.x + 1, y = O.y, z = row(35)},
	crystal_center = {x = O.x, y = O.y, z = row(36)},

	-- The crossroads: a 9 x 9 paved square right after the walkway.
	-- `exits` are the blocks just outside its edges where paths begin;
	-- `signs` are where the signposts of those paths stand.
	crossroads = {x = O.x, y = O.y, z = row(LENGTH + 4)},
	crossroads_radius = 4,
	exits = {
		east  = {x = O.x + 5, z = row(LENGTH + 4)},
		south = {x = O.x,     z = row(LENGTH + 9)},
		west  = {x = O.x - 5, z = row(LENGTH + 4)},
	},
	signs = {
		north = {x = O.x - 4, y = O.y, z = row(LENGTH)},     -- back to the Hub
		east  = {x = O.x + 4, y = O.y, z = row(LENGTH + 2)},
		south = {x = O.x + 2, y = O.y, z = row(LENGTH + 8)},
		-- (north of the west exit: a path leaving there turns south and
		-- would otherwise run over its own signpost)
		west  = {x = O.x - 4, y = O.y, z = row(LENGTH + 2)},
	},

	-- DECORATION (build.lua, build_decor)
	-- flower planters: single grass blocks in the plaza floor, just
	-- inside the four corners
	planters = {
		{x = O.x - 6, y = O.y, z = O.z - 6}, {x = O.x + 6, y = O.y, z = O.z - 6},
		{x = O.x - 6, y = O.y, z = O.z + 6}, {x = O.x + 6, y = O.y, z = O.z + 6},
	},
	-- two apple trees near the crossroads (x and z; they stand on the
	-- ground as it is), away from the three paths
	trees = {
		{x = O.x + 8, z = row(LENGTH + 14)},
		{x = O.x - 14, z = row(LENGTH + 8)},
	},
	-- flowers are scattered on the meadow this far around the crossroads
	meadow_radius = 11,

	-- Protected zone: the whole Hub plus a margin, from deep below (the
	-- supporting pillars) to well above the floor.
	zone_min = {x = O.x - R - 2, y = O.y - 60, z = row(LENGTH + 1)},
	zone_max = {x = O.x + R + 2, y = O.y + 20, z = O.z + R + 2},
}

-- What pops out of the shiny block (station 2). It should be a placeable
-- block, because the next station asks the child to place a block.
sel_hub.REWARD_ITEM = "default:goldblock"

-- How long (seconds) the shiny block stays away before it comes back.
sel_hub.SHINY_RESPAWN_TIME = 1.5

-- How long (seconds) a block placed on the green marker stays there before
-- it disappears again (so the next child has a free marker).
sel_hub.PLACED_BLOCK_TIME = 3

-- Seconds two children must stand on the plates together (station 5).
-- Kept short: this station is about "at the same time", not endurance.
sel_hub.TOGETHER_SECONDS = 1

-- Seconds the icon row stays on screen after finishing the course.
sel_hub.HUD_LINGER_TIME = 8

-- Activities announce themselves here so the crossroads gets a signpost
-- for them (the crossroads is refreshed automatically when this list
-- changes, see build.lua). Call at load time, e.g. from sel_lake:
--     sel_hub.register_destination("east", "sel_lake:sign")
-- side = "east", "south" or "west" (the side of the crossroads where the
-- activity's path starts, see layout.exits).
sel_hub.destinations = {}
function sel_hub.register_destination(side, sign_node)
	sel_hub.destinations[side] = sign_node
end
