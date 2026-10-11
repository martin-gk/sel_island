--[[
    sel_village - Activity 4: Village Decision
    ==========================================

    A village with sparkling gemstone deposits. Two people want the
    gemstones for two different, equally good things - told in PICTURES:

      The Mayor (at the square):          "Let us decorate our village
                                           square with them!"  -> GOLD
      A child from the village (at the    "With them I can finish the
      broken bridge):                      bridge to my grandparents!" -> BLUE

    There is no right answer. The point is how the group decides.

    How it plays (decide.lua):
      1. GATHER  Children find and mine gemstones around the houses, and
                 listen to the Mayor and to the child. Two little faces in
                 the corner of the screen light up when a child has heard
                 each of them.
      2. AGREE   They talk it out (in real life, with the teacher). Then
                 ALL of them stand on the white Decision Stone for 3
                 seconds. One child who is not convinced can simply stay
                 off the stone - the group cannot go around them.
                 (It only counts if everyone has heard both sides.)
      3. DECIDE  The two pedestals wake up. The first gemstone put on a
                 pedestal (right click) fixes the choice: gold = village,
                 blue = bridge.
      4. BUILD   Everyone receives the matching blocks: gem lamps to
                 decorate the square, or planks to close the gap in the
                 bridge. A row of gems on the screen fills up.
      5. DONE    The square shines / the grandparents can be visited.
                 Fireworks either way, and a home pad appears.

    Files:
      config.lua - ALL coordinates and numbers (start here)
      nodes.lua  - gem ore, gemstone, Decision Stone, pedestals, lamps, planks
      rules.lua  - who takes part, what may be dug/placed, the screen icons
      decide.lua - the five steps above, celebration, reset
      npc.lua    - Mayor, village child, grandparents
      build.lua  - builds the village, pond, bridge, gold path, signposts

    Docs: docs/modules/04_village_decision.md
]]

sel_village = {}
sel_village.S = core.get_translator("sel_village")

local path = core.get_modpath("sel_village")
for _, file in ipairs({"config", "nodes", "rules", "decide", "npc", "build"}) do
	dofile(path .. "/" .. file .. ".lua")
end
