--[[
    world.lua - makes sure every SEL world is the same island
    ==========================================================

    All activities are placed at fixed coordinates (see docs/WORLD.md), so
    the terrain MUST always be generated from the same seed and settings.

    The text seed "sel_island" is turned into a number by Luanti
    (murmur hash, see read_seed() in the engine). We store the resulting
    number directly because core.set_mapgen_setting() only accepts numbers.
    Verified by creating a world with seed "sel_island" (docs/WORLD.md).

    `true` as the 3rd argument means "override whatever the world's
    map_meta.txt says", so even a world created with a random seed is fixed
    on its first start. (Only do this with NEW worlds: changing the seed of a
    world that already has generated land would create seams.)
]]

local SEED_SEL_ISLAND = "6302475988778189316" -- = text seed "sel_island"

core.set_mapgen_setting("mg_name", "v7", true)
core.set_mapgen_setting("seed", SEED_SEL_ISLAND, true)
-- Same as the engine defaults, except "nodungeons".
core.set_mapgen_setting("mg_flags",
	"caves,nodungeons,light,decorations,biomes,ores", true)
core.set_mapgen_setting("mgv7_spflags",
	"mountains,ridges,nofloatlands,caverns", true)

-- Mods of Minetest Game that SEL Island does not ship (see docs/ARCHITECTURE.md)
-- may have left blocks in worlds created with an older version: the map
-- generator scattered fireflies in the grass. They simply turn into air.
core.register_alias("fireflies:firefly", "air")
core.register_alias("fireflies:hidden_firefly", "air")

-- Always daytime: game minetest.conf sets time_speed = 0 (time stands still),
-- and here we put the sun at noon once the server is running.
core.after(0, function()
	core.set_timeofday(0.5)
end)
