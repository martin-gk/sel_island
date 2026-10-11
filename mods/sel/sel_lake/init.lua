--[[
    sel_lake - Activity 3: Lake Crossing
    ====================================

    Story (told by the Ferrymaster in 5 PICTURES, see npc.lua):
      1. The ferry is broken.
      2. Here are materials: wood, stone, glass, leaves.
      3. Each of you has some of them - talk and share.
      4. Build something that reaches across the water. Any shape.
      5. All stand on the launch platform together (3 s) -> it sails.

    This activity is built in steps (see docs/modules/03_lake_crossing.md):

      Step 1 (done)  the site: start dock on the east beach with launch
                     platform, material crates, the Ferrymaster, a broken
                     ferry, the far dock at the Hub island, a calm corner,
                     and the teal path + signpost from the crossroads.
      Step 2 (done)  material roles: each child may only dig/place and take
                     their own material; free roles for small groups.
      Step 3 (done)  the launch: group hold, check the vessel (connected,
                     all four materials, out over the water), sail it
                     across, fireworks, way back.

    Files:
      config.lua - ALL coordinates and materials (start here)
      roles.lua  - who gets which material, the role icons, the rules
      nodes.lua  - crates and launch platform blocks
      launch.lua - the 3-second hold, the vessel check and the sailing
      npc.lua    - the Ferrymaster and his picture story
      build.lua  - builds the site on first start + protection zones
]]

sel_lake = {}
sel_lake.S = core.get_translator("sel_lake")

local path = core.get_modpath("sel_lake")
for _, file in ipairs({"config", "roles", "nodes", "npc", "build", "launch"}) do
	dofile(path .. "/" .. file .. ".lua")
end
