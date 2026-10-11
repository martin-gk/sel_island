--[[
    sel_hub - Activity 1: Tutorial & Hub
    ====================================

    The Hub is a stone plaza on the island in the lake. Children spawn in
    its middle (static_spawnpoint in the game's minetest.conf) and walk a
    wooden course - which is also the bridge to the shore - with six
    stations, each teaching one thing:

      1. Walk     - step on the BLUE marker to start
      2. Break    - dig the SHINY block; a reward pops out, the block returns
      3. Place    - put any block on the GREEN marker (sound + gold sparkles)
      4. Jump     - leap over the gap and land on the YELLOW markers
      5. Together - two children stand on the two ORANGE plates at once
      6. Finish   - step on the PURPLE crystal: fireworks! The child
                    receives the Builder's Tool (sel_core) as a reward.

    Between the stations there is some PARKOUR to practise the controls:
    stepping stones, a climbing wall with ladders and a balance beam.

    A row of six icons at the top of the screen lights up as stations are
    done (no reading needed). The walkway ends at the CROSSROADS on the
    shore, where picture signposts and coloured paths lead to the other
    activities (see config.lua and sel_core/path.lua).

    Files:
      config.lua   - ALL coordinates and tunable values (start here)
      nodes.lua    - the station blocks (markers, plates, crystal, ...)
      progress.lua - remembers each child's done stations + the icon row
      stations.lua - what happens at each station
      build.lua    - builds the plaza and course into the world
      commands.lua - teacher chat commands (/sel_hub, /sel_tutorial, ...)

    Docs: docs/modules/01_hub_tutorial.md
]]

sel_hub = {}
sel_hub.S = core.get_translator("sel_hub")

local path = core.get_modpath("sel_hub")
for _, file in ipairs({
	"config", "nodes", "progress", "stations", "build", "commands",
}) do
	dofile(path .. "/" .. file .. ".lua")
end
