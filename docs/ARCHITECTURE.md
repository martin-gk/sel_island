# Architecture

How SEL Island is put together, and the rules every new piece of code
follows. Read this before changing anything.

## 1. Guiding principles

* **For every child.** Read the Inclusion section of the README before
  adding characters, pictures or activities.
* **KISS.** The simplest thing that works. Plain Lua, no frameworks, no
  external dependencies besides Minetest Game. Structures are built by
  short, readable loops, not by binary schematic files.
* **One activity = one mod.** Each of the five activities lives in its own
  mod under `mods/sel/`. Activities never call each other; they only use
  `sel_core`.
* **Shared plumbing lives in `sel_core`.** If two activities need the same
  thing (group holds, step triggers, sparkles, protection …), it goes into
  `sel_core` — written once, tested once.
* **Configuration at the top.** Every activity has a `config.lua` with all
  coordinates and tunable numbers. Nothing else hard-codes positions.
* **No reading required.** Children get feedback through colour, light,
  particles, sound and big numbers. Text is only for the teacher (commands)
  and for item tooltips.
* **Minetest Game stays untouched.** `mods/mtg/` holds only the Minetest
  Game mods SEL Island needs, with their files unmodified (only the German
  translations are kept). To update: copy these mod folders from a newer
  Minetest Game over them.

  | Kept | Why |
  |---|---|
  | `default` | All basic blocks, trees, water, map generation |
  | `player_api` | The player model and skins (children's looks, story characters) |
  | `sfinv` | The inventory screen |
  | `stairs` | Slabs (seats, straw hat, well roof) |
  | `flowers` | Flowers and water lilies |
  | `butterflies` | Butterflies in the Breathing Garden |
  | `wool`, `dye` | Wool (sail, scarecrow); `wool` needs `dye` |
  | `farming` | Straw bales, wheat in the garden bed |

  Removed because nothing in the game uses them (and some
  would only distract or need reading): beds, binoculars, boats, bones,
  bucket, carts, creative, doors, dungeon_loot, env_sounds, fire,
  fireflies, game_commands, give_initial_stuff, keys, map, mtg_craftguide,
  screwdriver, sethome, spawn, tnt, vessels, walls, weather, xpanes.
  Fireflies placed by the map generator in older worlds become air
  (alias in `sel_core/world.lua`). Without the `map` mod the minimap
  (key V) is available to everyone.

## 2. Layers

```
┌───────────────────────────────────────────────────────────────┐
│ Activities: sel_hub, sel_flower, sel_lake, sel_village,        │
│             sel_irrigation          · sel_looks (avatars)      │
│   config.lua · nodes.lua · stations/logic · build.lua · commands│
├───────────────────────────────────────────────────────────────┤
│ sel_core: world · teacher · util · effects · hud · step · hold │
│           · protect · build · items · npc · sites · path · decor│
│           · story_area (no digging inside the fence)           │
├───────────────────────────────────────────────────────────────┤
│ Minetest Game mods (mods/mtg): default, player_api, sfinv, …   │
├───────────────────────────────────────────────────────────────┤
│ Luanti engine (5.9+)                                           │
└───────────────────────────────────────────────────────────────┘
```

## 3. The game folder

| File | Purpose |
|---|---|
| `game.conf` | Name, only mapgen v7 allowed, hides seed/flags in "New world", forces damage + creative off |
| `minetest.conf` | Defaults: spawn point = Hub, no fire/TNT, no starter items, time stands still |
| `mods/sel/modpack.conf` | Groups our mods |
| `mods/mtg/modpack.conf` | Groups the Minetest Game mods |

## 4. `sel_core` API reference

All functions are in the global table `sel_core`.

### world.lua
Forces mapgen v7, seed `sel_island` (stored as its numeric hash
`6302475988778189316`), mg_flags without dungeons, and noon. Runs at load
time; nothing to call.

### teacher.lua
| Function | Description |
|---|---|
| privilege `sel_teacher` | Teacher: commands + build in protected zones |
| `sel_core.is_teacher(name)` | `true` if the player has `sel_teacher` **and is not in child mode** |
| `sel_core.in_child_mode(name)` | Teacher is pretending to be a child (player meta `sel_core:child_mode`), toggled with `/sel child` |
| `/sel <command> …` | Dispatcher: runs the chat command `sel_<command>`; `/sel` alone lists all commands. New commands are still registered as `sel_<name>` and appear automatically |

### util.lua
| Function | Description |
|---|---|
| `pos_under(player)` | Block position the player stands on |
| `node_under(player)` | Name of that block |
| `in_box(pos, minp, maxp)` | Is pos inside the box (inclusive)? |
| `players_on_positions(list)` | `{ {player=, index=}, … }` of players standing on any of the positions |
| `give(player, itemstring)` | Add to inventory, drop the rest at their feet |

### effects.lua
| Function | Description |
|---|---|
| `colors` | Named particle colours: blue, green, gold, purple, orange, white, pink |
| `play(sound, where, gain)` | `where` = pos (positional), player (only them) or nil (everyone) |
| `sparkle(pos, color, amount)` | Short burst of glowing sparkles |
| `ambient_sparkle(pos, color)` | 3 gentle sparkles rising from a block (for ABMs) |
| `fireworks(pos, bursts)` | Success melody + several firework bursts above pos |

Sounds: `sel_core_chime`, `sel_core_success`, `sel_core_tick`,
`sel_core_reset`, `sel_core_firework`.

### hud.lua
| Function | Description |
|---|---|
| `show_big_text(player, text, color)` | Big number/symbol in the screen centre |
| `show_hint(player, texture, seconds)` | One picture in the screen centre for a few seconds (wordless feedback) |
| `hide_big_text(player)` | Remove it |

### step.lua
Add `_sel_on_step = function(pos, player)` to a node definition; it is
called when a player steps onto that **kind** of block (fires once when the
block type under the feet changes; jumping does not count as stepping off).

### hold.lua — group holds ("everyone stand here for 3 seconds")
```lua
local hold = sel_core.register_hold({
    seconds = 3,
    countdown = true,                       -- big 3-2-1 + tick sounds
    check = function() return players, ok end,
    on_complete = function(players) ... end,
})
hold.enabled = false  -- pause
```
Checked twice per second. If `ok` becomes false the count restarts (reset
sound). After a success it re-arms only after the condition was false once.

### protect.lua
```lua
sel_core.protect_zone({name=, minp=, maxp=, allow=function(pos, name) end})
```
Children cannot dig/place inside the box unless `allow` returns true.
Teachers are never blocked. Wraps `core.is_protected`.
`in_other_zone(pos, zone)` tells whether another zone covers a spot.

### story_area.lua — the story area and its fence
The whole built part of the world is one big zone, the **story area**
(x −727…−598, z −873…−724, all heights). Children cannot dig or place
there, with two exceptions: their own Breathing Flower, and every spot
that lies inside ANOTHER zone — there the activity's own `allow` decides.
**So an activity that lets children build must register its building
place as a zone of its own.** Outside the box nothing is restricted.

| Function / node | Description |
|---|---|
| `sel_core.story_area` | `{minp, maxp, openings, fence_built}` |
| `in_story_area(pos)` | Is this position inside the box? |
| `sel_core:fence` | White, unbreakable fence block (joins like a normal fence) |
| `build_story_fence(done)` | Fence along the border on normal land; none over water or above y 60 (cliff); openings marked by posts with lamps. Built once (`fence_version` in mod storage), `/sel fence_rebuild` |

### build.lua
| Function | Description |
|---|---|
| `fill(p1, p2, node, param2)` | Fill a box (use `"air"` to clear) |
| `set(pos, node, param2)` | Set one block |
| `pillar_down(top, node, max)` | Column down to solid ground |
| `when_loaded(p1, p2, fn)` | Generate/load the area, then call fn |

### items.lua — tools and unbreakable glass
| Item / function | Description |
|---|---|
| `sel_core:tool` | Builder's Tool: digs cracky/choppy/crumbly/snappy/hand groups, never wears out (`uses = 0`), cannot be dropped (`on_drop` returns the stack) |
| `sel_core:teacher_wand` | `on_use` removes the pointed block if the user is a teacher |
| `sel_core:shield_glass` | No dig groups + `diggable = false` + `on_blast` no-op → unbreakable. Group `sel_unbreakable` |
| `has_tool(player)` | Does the player own a Builder's Tool? |
| `ensure_tool(player)` | Give one if missing; returns true if given |
| `/sel_tools <name\|all>`, `/sel_wand` | Teacher commands |

**Which protection to use?** A *protected zone* when nobody may change an
area at all (the Hub course). *Shield Glass* when children build right
next to a structure that must survive (bridges, edges of building areas).

### npc.lua — story characters with picture stories
```lua
sel_core.register_npc("ferrymaster", {
    skin = "sel_lake_ferrymaster.png",           -- 64x32 player skin
    story = {"sel_lake_story_1.png", ...},        -- 64x64 picture panels
    radius = 6,
    on_heard = function(player) end,              -- optional
})
sel_core.spawn_npc("ferrymaster", pos, yaw)       -- from build.lua
sel_core.has_heard(player, id) / forget_heard(player, id)
sel_core.show_story(player, id)                   -- replay from panel 1
```
The NPC is an immortal entity using Minetest Game's `character.b3d` model;
it turns to the nearest player. Near it (≤ radius), panels appear one per
1.2 s at the top of the screen; leaving (> radius + 2) hides them. After the
last panel the story counts as *heard* (player meta `sel_core:heard_<id>`).
Each spawn stores a new token in mod storage; outdated copies of the
entity remove themselves when loaded, so rebuilding never duplicates NPCs.
**No text and no speech** — pictures are generated by a script
(skins are recoloured from the Minetest Game player skin).

### sites.lua — named places
`sel_core.register_site(name, pos)`, `get_site(name)`,
`send_to_site(player, name)`, command `/sel_goto <site> [all|<name>]`.

### path.lua — colour-coded paths and signposts
| Function / node | Description |
|---|---|
| `sel_core:path_teal / _gold / _blue / _purple / _pink` | Glowing centre-line blocks (unbreakable) |
| `sel_core:path_edge`, `sel_core:post` | Paving edge and signpost pole (unbreakable) |
| `register_sign(name, texture)` | Picture block for a signpost |
| `build_signpost(pos, sign_node)` | Two poles + picture block on the ground block `pos` |
| `path_height(x, z)` | Ground height for a path block (water → one above the surface) |
| `build_path(waypoints, color)` | 3-wide path through `{x=, z=}` waypoints: follows the ground, slope ≤ 1 block per step (cuts into hills), bridges water |

### decor.lua — decoration shared by all sites
Nothing here is needed to play; it makes the sites nicer and easier to
recognise. Everything is placed by a fixed formula from the coordinates
(`noise`), never by chance: a site looks the same in every world and
after every rebuild.

| Function | Description |
|---|---|
| `noise(x, z, salt)` / `pick(list, x, z, salt)` | A repeatable "random" number 0…1 for a column / an entry of a list |
| `build_gate(pos, along, color)` | Arch over a path in the path's colour (`along` = "x" or "z", the direction the path runs) |
| `scatter(minp, maxp, plants, one_in, salt)` | Plants on about one of `one_in` free soil blocks in a rectangle |
| `plant_tree(pos, kind)` | A Minetest Game tree on ground block `pos` ("apple", "acacia", "aspen", "pine", "bush", "acacia_bush"); only fills air |
| `build_reeds(pos, height)` / `build_water_plants(minp, maxp, water_y, one_in, salt)` | Reeds; reeds in shallow and lilies on deep water of a rectangle |

Rule for decoration inside an activity area: plants that children may
build over must be `buildable_to` (grass tufts, dry shrubs) so they give
way; anything solid there is an obstacle on purpose.

Shared pattern of the group activities (`sel_lake`, `sel_irrigation`):
an **area box** defines who takes part (non-teachers inside it); a
protected zone over the same box with an `allow` function plus an
`on_placenode` undo implement "you may only dig/place X here"; a
`sel_core.register_hold` checks "all participants stand on …"; the state
(`building`/`done`) is kept in mod storage; `/sel <activity>_reset`
prepares the next group.

`sel_looks` (not an activity): eight generated player skins,
`sel_looks.get/set/next(player)`, the wardrobe block. NPC skins, the
children in the story pictures and the looks all come from the same
colour palette.
`sel_core.register_npc` accepts `size` (e.g. 0.75 for a child).

The **crossroads** (in `sel_hub`) is where paths start. Its signposts are
refreshed automatically when the list of registered destinations changes. An activity calls
`sel_hub.register_destination(side, sign_node)` at load time (side =
`east`/`south`/`west`) to get its signpost there, and starts its path at
`sel_hub.layout.exits[side]`.

**Home pad** (`sel_core:home_pad`, in sites.lua): glowing purple block;
stepping on it sends the player to the site `hub`. Activities place it
where an adventure ends.

### Calm corners (in `sel_flower/calm.lua`)
`sel_flower.build_calm_corner(pos)` — every activity's `build.lua` calls
it once, so each site has a Breathing Flower on unbreakable Calm Grass.
`sel_flower.nearest(pos)` finds the closest flower (for `/sel_calm`).

## 5. Anatomy of an activity mod (template: `sel_hub`)

```
sel_xxx/
├── mod.conf          name, description, depends = sel_core, default
├── init.lua          header comment explaining the activity + dofile list
├── config.lua        ALL coordinates and numbers; BUILD_VERSION
├── nodes.lua         blocks/items of the activity (look only)
├── <logic>.lua       what happens (callbacks, holds)
├── build.lua         builds the site on first start + protection zone
├── commands.lua      teacher commands  /sel_xxx...
├── locale/sel_xxx.de.tr   German translations
└── textures/ sounds/ generated by a script
```

Conventions:

* Code is in English; every player-visible string goes through `S()` and
  is translated in `locale/<mod>.de.tr` (format: `English=Deutsch`).
* Node names: `sel_<activity>:<thing>`. Texture names: `sel_<activity>_<thing>.png`.
* Custom node fields start with `_sel_` (`_sel_on_step`, `_sel_color`).
* Build-once logic: store `built_version` in mod storage; bump
  `BUILD_VERSION` in `config.lua` when the layout changes.
* Teacher commands start with `/sel_` and require `sel_teacher`.
* Use `core.*` (not the old `minetest.*` alias). Tabs for indentation.
* Comment generously: each file starts with a block explaining what it is
  for; each function says what it does and why.

## 6. Data that is saved

| What | Where | Key |
|---|---|---|
| Tutorial progress per child | player metadata | `sel_hub:progress` (`"110000"`) |
| Hub built? | sel_hub mod storage | `built_version` |
| Breathing Flower clock | node metadata of each flower | `t` (seconds into the 19 s breath) |
| List of all flowers | sel_flower mod storage | `flowers` (serialized position set) |
| "Heard the story of NPC x" | player metadata | `sel_core:heard_<id>` |
| NPC spawn token | sel_core mod storage | `npc_token_<id>` |
| Lake site built? | sel_lake mod storage | `built_version` |
| Lake activity state (`building`/`done`) | sel_lake mod storage | `state` |
| Irrigation: built?, round, state | sel_irrigation mod storage | `built_version`, `round`, `state` |
| Irrigation: last round a kit was received | player metadata | `sel_irrigation:round` |
| Owner of a pump | node metadata | `owner` |
| Crossroads signposts up to date? | sel_hub mod storage | `destinations` |
| Village: built?, state, round, who chose | sel_village mod storage | `built_version`, `state`, `round`, `chosen_by` |
| Village: last round a kit was received | player metadata | `sel_village:kit_round` |
| A child's look (1–8) | player metadata | `sel_looks:look` |
| Calm-corner flower may not be picked up | node metadata | `fixed = 1` |
| Teacher is in child mode | player metadata | `sel_core:child_mode` |

