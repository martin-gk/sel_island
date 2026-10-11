--[[
    sel_flower - Activity 2: Breathing Flower
    =========================================

    Anyone can plant a big flower: the teacher for the whole group, and
    every child has their own flower in the pocket (given after the
    tutorial) for a calm moment of their own. Children gather around it and
    breathe with it - no buttons, no commands. The flower opens and closes
    on its own, forever, until the teacher removes it:

        4 s  opening   (breathe IN)   BLUE flower,   sparkles drift OUTWARD
        7 s  open      (HOLD)         GOLD flower,   sparkles HOVER
        8 s  closing   (breathe OUT)  VIOLET flower, sparkles SETTLE BACK

    It closes into a bud - it never wilts - ready to open again.

    Besides the flowers the teacher places, every activity site has a
    permanent "calm corner" with a flower (calm.lua), so a child who feels
    overwhelmed always has something grounding nearby.

    How it works (KISS): the flower is a block with 5 looks ("stages",
    0 = bud ... 4 = wide open). A node timer ticks 4 times per second,
    adds the time to the flower's own clock, works out how open the flower
    should be at that moment of the 19-second cycle and swaps to the
    matching stage. See flower.lua.

    Files:
      config.lua - timings and size (start here)
      flower.lua - the flower blocks, the breathing cycle, the sparkles
      calm.lua   - CALM CORNERS: grass patch + flower at every activity,
                   list of all flowers, /sel_calm
      commands.lua - /sel_flower (teacher gets a flower)
      garden.lua - the BREATHING GARDEN beside the crossroads, where the
                   Gardener shows in pictures how to breathe with a flower

    Docs: docs/modules/02_breathing_flower.md
]]

sel_flower = {}
sel_flower.S = core.get_translator("sel_flower")

local path = core.get_modpath("sel_flower")
for _, file in ipairs({"config", "flower", "calm", "commands", "garden"}) do
	dofile(path .. "/" .. file .. ".lua")
end
