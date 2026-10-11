--[[
    config.lua - tunable values of the Breathing Flower
]]

-- The breathing rhythm in seconds (4-7-8 breathing).
sel_flower.IN_TIME   = 4  -- flower opens       -> breathe in
sel_flower.HOLD_TIME = 7  -- flower stays open  -> hold
sel_flower.OUT_TIME  = 8  -- flower closes      -> breathe out

-- One full breath. Derived - do not edit.
sel_flower.CYCLE = sel_flower.IN_TIME + sel_flower.HOLD_TIME + sel_flower.OUT_TIME

-- Number of looks between bud and wide open (textures
-- sel_flower_<phase>_0.png ... sel_flower_<phase>_4.png).
sel_flower.STAGES = 5

-- How often the flower updates itself (seconds). Smaller = smoother but
-- more work for the server; 0.25 is plenty for 5 stages.
sel_flower.TICK = 0.25

-- The flower is drawn this many blocks tall and wide, so a whole group of
-- children can stand around it and see it.
sel_flower.SIZE = 3

-- Height of the flower head above the block the flower stands in
-- (from the texture: the head sits at about 56 % of the picture height).
sel_flower.HEAD_HEIGHT = -0.5 + 0.56 * sel_flower.SIZE

----------------------------------------------------------------------------
-- THE BREATHING GARDEN (garden.lua)
----------------------------------------------------------------------------
-- A quiet garden a few steps south-east of the crossroads (map in
-- docs/WORLD.md): five Breathing Flowers, flower beds, places to sit, and
-- the Gardener, who shows in pictures how to breathe with a flower.
--
--        north
--     # # # # # # # # #        # = hedge       F = Breathing Flower
--     # F     s     F #        s = seats       G = Gardener
--   ==>   G           #        ==> the pink path from the crossroads
--     # s     F     s #            comes in through the pink gate
--     #               #
--     # F     s     F #
--     # # # # # # # # #

-- Bump to rebuild the garden on the next start (or /sel garden_rebuild).
sel_flower.GARDEN_VERSION = 1

local GY = 19                          -- ground level of the garden
local GC = {x = -658, y = GY, z = -811} -- its centre
local GR = 7                           -- "radius": the garden is 15 x 15

sel_flower.garden = {
	ground_y = GY,
	center = GC,
	min = {x = GC.x - GR, y = GY, z = GC.z - GR},
	max = {x = GC.x + GR, y = GY, z = GC.z + GR},

	-- the Breathing Flowers: centre of each 3 x 3 patch of Calm Grass
	flowers = {
		{x = GC.x, y = GY, z = GC.z},
		{x = GC.x - 4, y = GY, z = GC.z - 4}, {x = GC.x + 4, y = GY, z = GC.z - 4},
		{x = GC.x - 4, y = GY, z = GC.z + 4}, {x = GC.x + 4, y = GY, z = GC.z + 4},
	},

	-- seats (wooden slabs, two side by side), each looking at a flower
	seats = {
		{x = GC.x, z = GC.z + 4}, {x = GC.x + 1, z = GC.z + 4},  -- north
		{x = GC.x, z = GC.z - 4}, {x = GC.x - 1, z = GC.z - 4},  -- south
		{x = GC.x + 4, z = GC.z}, {x = GC.x + 4, z = GC.z + 1},  -- east
		{x = GC.x - 3, z = GC.z - 1},                            -- west (one)
	},

	-- the entrance: a gap in the west hedge (z from .. to), the pink gate
	-- stands in it
	entrance_z_min = GC.z - 1,
	entrance_z_max = GC.z + 1,
	gate = {x = GC.x - GR, y = GY, z = GC.z},

	-- the Gardener stands just inside, beside the way in
	gardener = {x = GC.x - 5, y = GY + 0.5, z = GC.z + 2},

	-- butterflies (blocks that flutter in place), two blocks above the ground
	butterflies = {
		{x = GC.x - 2, z = GC.z + 5, kind = "white"}, {x = GC.x + 5, z = GC.z + 2, kind = "red"},
		{x = GC.x + 2, z = GC.z - 5, kind = "violet"}, {x = GC.x - 5, z = GC.z - 3, kind = "white"},
	},

	-- where children arrive with /sel goto garden (in the entrance)
	arrival = {x = GC.x - GR + 1, y = GY + 1, z = GC.z},

	-- the pink path (about 12 blocks) from the south-east corner of the
	-- crossroads to the entrance, and the signpost beside its start.
	-- Only x and z; heights are automatic.
	path = {
		{x = -675, z = -807},
		{x = GC.x - GR - 2, z = GC.z},
	},
	signpost = {x = -673, z = -805},
}
