# Activity 1 — Tutorial & Hub (`sel_hub`)

**Status:** implemented, automated tests pass. Needs a real
playtest with children's computers.

## Goal

Children spawn on the Hub on the mountain peak and see the whole island.
They walk a short course with six stations, each teaching one control.
Done when they reach the crystal; then they can go anywhere.

## Design decisions

| Decision | Why |
|---|---|
| Hub on the flat-topped island in the lake at (−680, 21, −750) — the spot Martin Guevara-Kunerth picked. The course runs south on a wooden walkway that is also the **bridge** to the shore | Children see the whole lake; finishing the tutorial literally brings them "into the world" |
| The walkway ends level with the ground at the **crossroads**: a paved square with picture signposts where the coloured paths to the activities start | Children find the activities on their own, without reading |
| All station blocks are **floor tiles** (full blocks in the walkway) | Easy and reliable to detect "standing on it"; very visible |
| Progress shown as a row of 6 station pictures, dark → bright | No reading needed |
| Stations can be done in any order; the crystal always celebrates | KISS; the teacher sees gaps with `/sel_tutorial` |
| Reward of the shiny block = **gold block** | It is a placeable block, so station 3 can be done with it |
| Block placed on the green marker disappears after 3 s | The marker is free again for the next child |
| Gap = 2 rows wide, 1 block deep pit with glass sides | Falling in is harmless, jumping out is easy |
| Station 5 needs `min(2, players online)` plates for **1 second** | Two children normally; one child alone can still finish (same rule as other activities) |
| Fireworks at most every 4 s | Several children arriving together don't create noise chaos |
| End of the walkway opens onto the crossroads | "Then they can go anywhere" |
| Finishing (crystal) gives the **Builder's Tool**; it is given back on rejoin if missing | Children only get to dig/build freely after they learned the controls |
| Pit side walls are **Shield Glass** (unbreakable) | Visible example of "this cannot be broken" (BUILD_VERSION 2) |
| A calm corner on the plaza (BUILD_VERSION 3) | Children who feel overwhelmed find a Breathing Flower right where they start |
| Parkour between the stations (stepping stones, climbing wall, balance beam), without icons (BUILD_VERSION 5) | Martin Guevara-Kunerth's playtest: more practice for the controls. Six stations stay as in the original design; the parkour is extra |
| A **wardrobe** on the plaza lets children choose one of eight looks (BUILD_VERSION 7) | So that everyone can play as someone they like to be — see the Inclusion section of the README |
| Flower planters in the plaza corners; a flower meadow and two apple trees around the crossroads (BUILD_VERSION 8) | The first place children see should feel friendly, and the crossroads should be recognisable from far away |
| Whole Hub area is protected; only the shiny block (dig) and the spot on the green marker (place) are allowed | Children cannot destroy the course |

## Files

| File | Content |
|---|---|
| `config.lua` | Origin, every station position (computed from the origin), timings, reward item, BUILD_VERSION |
| `nodes.lua` | 6 station blocks + ambient sparkle ABM |
| `progress.lua` | Saved progress (`player meta sel_hub:progress`), icon row HUD |
| `stations.lua` | Logic of each station |
| `build.lua` | Builds plaza + walkway on first start; protection zone |
| `commands.lua` | `/sel_hub`, `/sel_tutorial`, `/sel_tutorial_reset`, `/sel_hub_rebuild` |
| `locale/sel_hub.de.tr` | German strings |

## Layout

Rows are counted southwards from the plaza edge (row 0 = z −758).

| Row | z | Content |
|---|---|---|
| — | −757…−743 | Plaza 15×15, stone, fence, 4 lamp posts, spawn in the centre, calm corner (Breathing Flower) north-west at (−684, 21, −746) |
| 2 | −760 | Blue start marker (centre) |
| 3–7 | −761…−765 | **Parkour:** stepping stones (pit; stones at x −681/row 4 and x −679/row 6) |
| 8 | −766 | Shiny block standing on the walkway (centre) |
| 10–12 | −768…−770 | **Parkour:** climbing wall (ladders row 10, wall 2 high row 11, step row 12), higher Shield Glass rails |
| 14 | −772 | Green place marker (centre) |
| 19–20 | −777, −778 | Gap / pit |
| 21 | −779 | Yellow landing markers (full width) |
| 23–26 | −781…−784 | **Parkour:** balance beam (pit with a 1-wide log in the middle) |
| 28 | −786 | Orange plates at x −682 and x −678 |
| 35–37 | −793…−795 | 3×3 purple crystal |
| 39 | −797 | Walkway end |
| 40–48 | −798…−806 | Crossroads 9×9: purple centre, signposts (Hub: crystal, Lake: boat), path exits east / south / west |

## Changing the Hub

1. Edit `config.lua` (positions are relative to the origin).
2. Increase `sel_hub.BUILD_VERSION`.
3. Restart the server (or `/sel_hub_rebuild`). The new Hub is built over
   the old one. (Blocks of the old layout that are outside the new one are
   not removed automatically.)

If the origin moves, also update `static_spawnpoint` in `minetest.conf`
and increase `sel_hub.LOCATION_VERSION`, so players of existing worlds are
brought to the new Hub when they join.

## Known limitations / ideas for later

* The gold block reward can be farmed (dig again and again). Harmless for
  now; can be limited to once per child if it becomes a problem.
* Signposts for the village and the irrigation fields appear at the
  crossroads when those activities are built (`sel_hub.register_destination`).
