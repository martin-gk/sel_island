--[[
    sel_irrigation - Activity 5: Irrigation Channel
    ===============================================

    Story (told by the Inventor in 5 PICTURES, see npc.lua):
      1. The garden is dry.
      2. I made channel blocks and pump stations.
      3. Build a channel from the blue water source to the brown garden.
      4. Everyone stand on your OWN pump, together (3 s).
      5. The water flows and the garden blooms.

    How it plays:
      * Every child who enters the field gets 15 channel blocks and ONE
        pump station (kit.lua).
      * One kit does not reach all the way: the children pool their
        pieces. Who has none left gets a few more at the spare-parts
        crate (nodes.lua). Boulders lie in the straight way.
      * They build a channel, any shape, from the blue Water Source block
        to the Garden bed. Blocks are connected when they touch
        (side by side, or on top of each other - so it may go up on posts).
      * Each child places their own pump somewhere along the channel.
      * When ALL children stand on their own pumps for 3 seconds, the
        water starts at the source and runs through the channel, block
        after block (flow.lua).
          - It reaches the garden and every pump is on the channel:
            the garden blooms. Fireworks, a home pad appears.
          - There is a gap: the water stops there, and after a moment the
            channel runs dry again. The children SEE where it stopped, find
            the gap and fix it together. This is meant to happen.

    Files:
      config.lua - ALL coordinates and numbers (start here)
      nodes.lua  - channel, pump, source and garden blocks
      kit.lua    - who takes part, the kit, what may be dug/placed here
      flow.lua   - the 3-second hold, tracing the channel, the water, reset
      npc.lua    - the Inventor and his picture story
      build.lua  - builds the site + blue path, signpost, protection

    Docs: docs/modules/05_irrigation_channel.md
]]

sel_irrigation = {}
sel_irrigation.S = core.get_translator("sel_irrigation")

local path = core.get_modpath("sel_irrigation")
for _, file in ipairs({"config", "nodes", "kit", "flow", "npc", "build"}) do
	dofile(path .. "/" .. file .. ".lua")
end
