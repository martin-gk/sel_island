--[[
    sel_core - the shared library of SEL Island
    ============================================

    Every activity mod (sel_hub, later sel_flower, sel_lake, ...) depends on
    this mod and uses its helpers instead of re-inventing them. Keeping all
    the "plumbing" in one place keeps each activity mod short and readable.

    Public API (all functions live in the global table `sel_core`):

      world.lua    - forces seed "sel_island", mapgen v7, no dungeons, daytime
      teacher.lua  - the "sel_teacher" privilege, sel_core.is_teacher(name)
      util.lua     - small helpers (node under a player, box checks, ...)
      effects.lua  - sel_core.play(), sparkle(), fireworks()
      hud.lua      - big centre text for countdowns (3, 2, 1)
      step.lua     - "a player stepped on this block" callbacks
      hold.lua     - "everyone stand here together for N seconds" timers
      protect.lua  - protected zones children cannot dig or build in
      build.lua    - tiny helpers to build structures out of blocks
      items.lua    - Builder's Tool, Teacher's Wand, unbreakable Shield Glass
      npc.lua      - story characters that "speak" with picture panels
      sites.lua    - named activity places + /sel_goto
      path.lua     - colour-coded paths that follow the ground + signposts
      decor.lua    - decorations: gates over paths, plants, trees, reeds
      story_area.lua - the story area (no digging) and the fence around it

    See docs/ARCHITECTURE.md for the big picture.
]]

sel_core = {}

-- Translator for this mod. Strings are written in English and translated to
-- German in locale/sel_core.de.tr (Luanti picks the player's language).
sel_core.S = core.get_translator("sel_core")

-- Load the parts in dependency order. Each file adds functions to sel_core.
local path = core.get_modpath("sel_core")
for _, file in ipairs({
	"world", "teacher", "util", "effects", "hud",
	"step", "hold", "protect", "build", "items", "npc", "sites", "path", "decor", "story_area",
}) do
	dofile(path .. "/" .. file .. ".lua")
end

core.log("action", "[sel_core] loaded")
