# Teacher Guide

This guide explains how to run SEL Island with a class. It grows with
every activity that is added.

## 1. Setting up

### One world for the whole class

All children play together in **one world** hosted by the teacher's computer
(or a school server):

1. Create the world (see `README.md` → "Create the class world").
2. In the Luanti main menu, on the **Start Game** tab, tick
   **Host Server**, choose your teacher name and a password, and start.
3. Children open Luanti → **Join Game**, enter the teacher computer's
   address (shown in the network settings of that computer) and port
   `30000`, choose their own name and join.

Damage and creative mode are switched off by the game — children cannot get
hurt and do not have unlimited blocks.

### Becoming the teacher

The teacher needs the privilege **`sel_teacher`**:

* The person hosting the world from the main menu ("Host Server") is the
  admin and gets it automatically.
* To give it to another adult: `/grant <name> sel_teacher`
* In singleplayer you are the teacher automatically (Luanti does not let
  you revoke that there).

Teachers can build and dig everywhere, including in the protected Hub and
on the docks.

### Child mode — try it exactly like a child

Type **`/sel child`** to switch child mode on, and again to switch it off.
While it is on you are treated like a child: protected places cannot be
dug, the Teacher's Wand does nothing, flowers cannot be placed or removed.
The `/sel` commands keep working, so you can always switch back. Use this
whenever you want to check what the children will experience.

## 2. Chat commands

Open the chat with **T** (or **/** to start with a slash already typed).

Every command works in two spellings: `/sel wand` (with a space) or
`/sel_wand` (one word). **`/sel`** alone lists all commands.

| Command | What it does |
|---|---|
| `/sel` | List all teacher commands |
| `/sel child` | Child mode on/off: play exactly like a child |
| `/sel hub` | Teleport yourself to the Hub |
| `/sel hub all` | Teleport **everyone** to the Hub (gather the class) |
| `/sel hub <name>` | Teleport one child to the Hub |
| `/sel tutorial` | Show every child's tutorial progress (`#` = station done) |
| `/sel tutorial_reset <name>` | Let one child do the tutorial again |
| `/sel tutorial_reset all` | Let everyone online do the tutorial again |
| `/sel hub_rebuild` | Rebuild the Hub if anything looks wrong |
| `/sel tools <name>` / `/sel tools all` | Give the Builder's Tool (to children who have none) |
| `/sel wand` | Get the Teacher's Wand (removes any block, also Shield Glass) |
| `/sel flower` | Get a Breathing Flower to place |
| `/sel calm <name>` | Bring a child to the nearest Breathing Flower (calm corner) |
| `/sel goto` | List activity sites (hub, crossroads, garden, lake, irrigation, village) |
| `/sel goto <site> all` | Bring **everyone** to an activity site |
| `/sel goto <site>` / `/sel goto <site> <name>` | Go there yourself / send one child |
| `/sel lake_reset` | Lake Crossing: remove the vessel, new roles — ready for the next group |
| `/sel lake_rebuild` | Rebuild the Lake Crossing site |
| `/sel irrigation_reset` | Irrigation Channel: remove the channel, dry garden, new kits |
| `/sel irrigation_rebuild` | Rebuild the Irrigation Channel site |
| `/sel village_reset` | Village Decision: remove what was built, new gemstones, start again |
| `/sel village_rebuild` | Rebuild the village |
| `/sel garden_rebuild` | Rebuild the Breathing Garden |
| `/sel fence_rebuild` | Rebuild the white fence around the story area |

Example output of `/sel_tutorial`:

```
Tutorial progress (# = station done):
  Anna             ######  6/6
  Ben              ####--  4/6
```

## 3. Activity 1 — Tutorial & Hub

Children appear on the **Hub**, a stone plaza on an island in the middle
of a lake. A wooden walkway leads south across the water — it is the
tutorial course and at the same time the bridge to the shore — with six
stations. At the top of their screen children see
**six small pictures**, one per station; each lights up when done.

| # | Station | What the child does | What happens |
|---|---|---|---|
| 1 | Walk | Step on the **blue** glowing block | Sparkles, "ding-ding" |
| 2 | Break | Hold the left mouse button on the **shiny gold** block (≈2 s) | A gold block pops out; the shiny block returns |
| 3 | Place | Put a block (e.g. the gold block) **on top of the green** marker (right click) | Gold sparkles, "ding-ding"; the block vanishes after 3 s so the next child can try |
| 4 | Jump | Jump (space) over the gap and land on the **yellow** row | Sparkles, "ding-ding". Falling into the gap is harmless — just jump out |
| 5 | Together | **Two** children stand on the two **orange** plates at the same time | Both get the station; a short melody |
| 6 | Finish | Step on the **purple** crystal | Fireworks! The pictures disappear after a few seconds |

Between the stations there is some **parkour** to practise the controls
(no pictures for these — they are just fun):

| Where | Obstacle | Practises |
|---|---|---|
| after the blue block | **Stepping stones** over a shallow pit | jumping and steering |
| after the shiny block | **Climbing wall** with ladders, a step down behind it | climbing (walk into the ladder and hold **W** or **space**) |
| after the yellow row | **Balance beam**, one block wide | careful walking (holding **Shift** keeps you from falling off) |

All pits are only one block deep: whoever falls in simply jumps out.

After the crystal the children receive the **Builder's Tool** and their own
**Breathing Flower**. The walkway
ends at the **crossroads**, a small paved square on the shore.

### How children look

Every child gets one of eight looks (different skin tones, hair, clothes).
At the **wardrobe** on the Hub plaza — a cupboard with three shirts on it —
a right click changes to the next look, and a small picture shows it. Give
the class a minute for this at the start; it matters to them. No look is
"for boys" or "for girls". More in the Inclusion section of the README.

### Finding the activities: crossroads, signposts, coloured paths

At the crossroads every activity has a **signpost with a picture** and a
**path with a glowing coloured line** that leads all the way there:

| Colour | Picture | Leads to |
|---|---|---|
| teal | sailing boat | Lake Crossing (≈ 65 blocks, along the shore to the beach) |
| purple | crystal | back to the Hub |
| gold | house | Village Decision (≈ 38 blocks, over the hill to the south-west) |
| blue | water drop | Irrigation Channel (≈ 33 blocks, south-east to the green field) |
| pink | flower | Breathing Garden (≈ 10 blocks, right beside the crossroads) |

Tell the class only: *"Follow the colour."* The paths cannot be dug up.
You can still move everyone at once with `/sel_goto lake all`.

**Tips**

* Let the children explain to each other how to do a station, instead of
  showing it yourself.
* Station 5 needs a partner: it is the first moment where they must ask
  someone. If a child is alone in the world, one plate is enough.
* Mouse/keys reminder for the class: **WASD** walk, **space** jump,
  **left click (hold)** dig, **right click** place, **mouse wheel / 1–8**
  choose item.

## 4. Tools and protection

| Item | Who | What it does |
|---|---|---|
| **Builder's Tool** (blue pick-hammer) | Every child, after finishing the tutorial | Digs stone, wood, dirt, leaves … Never breaks and cannot be dropped or thrown away (on purpose, so it cannot get lost). If one is missing anyway: `/sel tools <name>` |
| **Teacher's Wand** (gold star) | Teacher only (`/sel_wand`) | Left click removes any block instantly, including Shield Glass. Does nothing for children |
| **Shield Glass** (glass with a blue frame) | Built into activity sites | Nobody can break it with tools. Children can build next to it |

### Inside the fence, outside the fence

The world has two parts, separated by a **white fence**:

* **Inside — the story area.** Hub, crossroads, paths, Breathing Garden
  and the three activity sites. Children **cannot dig or build** here: the
  land stays as it is for every group. The only exceptions are what an
  activity asks for (the vessel on the lake, the channel on the field, the
  gemstones, lamps and bridge planks in the village) and their own
  Breathing Flower, which they may plant anywhere.
* **Outside — free land.** Beyond the fence children may **explore, mine
  and build** whatever they like with the Builder's Tool.

The fence has **openings** (two tall posts with a lamp on each side): on
the east side behind the fields and towards the beach, on the south side,
and on the west side beside the village. The fence is a sign — "from here
on you may dig" — not a wall: children can always walk out and back in.
There is no fence in the lake and along the high cliff in the south-west;
water and rock are borders of their own. Nobody but you can remove the
fence.

Tip for the class: *"White fence = the edge of the story. Behind it the
land is yours."* If you prefer the class to stay inside during a lesson,
say so — the game does not lock anyone in.

**Shield Glass** (glass with a blue frame) cannot be broken by anyone but
you, wherever it stands.

## 5. Activity 2 — Breathing Flower

1. Type `/sel_flower`; a flower appears in your inventory.
2. Right-click the ground where the class should gather. The flower is
   about three blocks tall.
3. It breathes on its own, endlessly:

| Flower | Colour | Children | Sparkles |
|---|---|---|---|
| opens (4 s) | **blue** | breathe **in** | drift outwards |
| stays open (7 s) | **gold** | **hold** | float around the flower |
| closes into a bud (8 s) | **violet** | breathe **out** | sink back into the flower |

The colour change is the signal: *blue = in, gold = hold, violet = out.*

4. Let the children follow a few rounds. Counting quietly along helps at
   the start ("in 2, 3, 4 — hold … — out …").
5. Remove it by digging it (left click) or with the Teacher's Wand.

**Children have their own flower too.** After the tutorial every child has
one Breathing Flower in the inventory. They can plant it wherever they
need a calm moment and dig it up again to take it along. They cannot
remove the flowers of the calm corners.

### The Breathing Garden

Right beside the crossroads (**pink path**, signpost with a flower) lies a
small hedged garden with **five Breathing Flowers**, seats, flower beds
and butterflies. The **Gardener** stands just inside and shows in five
pictures how the flower works:

![The Gardener's story](images/gardener_story.png)

1. When everything is too much: go to a flower.
2. It **opens** and is **blue** → breathe **in** (count to 4).
3. It is **open** and **gold** → **hold** (count to 7).
4. It **closes** and is **violet** → breathe **out** (count to 8).
5. Calm again — and round it goes, as often as you like.

A good first stop after the tutorial: `/sel goto garden all`, let the
children look at the pictures, then sit down and breathe three rounds
together. The five flowers breathe in the same rhythm. Children may plant
their own flower here too.

### Calm corners

Every activity site has a **calm corner**: a light-green grass patch with a
Breathing Flower. Show it to the class at the start: *"If it gets too much,
you can always go to the flower and breathe with it."* A child can walk
there on their own; you can also bring them with `/sel_calm <name>`.

## 6. Story characters speak in pictures

Characters such as the Ferrymaster do not use text or voice. When a child
walks up to them, a row of **picture panels** appears at the top of the
screen, one after the other, like a comic. Walking away hides it; walking
back or right-clicking the character shows it again. Ask the children:
*"What is he telling us?"* — interpreting the pictures together is part of
the activity.

## 7. Activity 3 — Lake Crossing

**Getting there:** teal path from the crossroads (boat signpost), or
`/sel goto lake all`.

**What happens**

1. On the beach dock each child automatically gets **one material**: wood,
   stone, glass or garden (leaves and flowers). Four pictures in the top
   left corner show it: bright = "I can use this", dark = "someone else has
   this". With fewer than four children, the materials nobody has are free
   for everyone.
2. The **Ferrymaster** tells the story in five pictures: the ferry is
   broken → here are materials → talk and share → build something across
   the water → everyone on the platform.
3. Children take blocks from the **crates** (right-click). Only their own
   crate opens. They can only place and dig their own material — if they
   try anything else, nothing happens. **This is the point:** they must
   ask each other.
4. They build from the teal **launch platform** out over the water, any
   shape. It needs at least one block of **every** material and must reach
   at least 5 blocks out.
5. When they think it is finished, **all** children in the area stand on
   the launch platform. A big 3-2-1 counts down; if anyone steps off, it
   starts again. A child who refuses to come blocks the launch — the group
   has to win them over.
6. Not ready? A picture shows what is missing, and the crates of missing
   materials sparkle. Let them work it out.
7. Ready? They are lifted onto their vessel and it **sails** across to the
   Hub island. Fireworks! A glowing purple **home pad** appears: stepping
   on it brings a child back to the Hub.

**For the next group:** `/sel lake_reset` cleans the water and hands out
new roles.

**Good to know**

* You, the teacher, get no role and are not needed on the platform. To try
  the activity yourself, switch on child mode: `/sel child`.
* A child who walks away from the area is no longer waited for.
* Every child also carries their own Breathing Flower and can plant it on
  the vessel or the beach if things get too much; the calm corner is at the
  north end of the dock.

## 8. Activity 5 — Irrigation Channel

**Getting there:** blue path from the crossroads (water-drop signpost), or
`/sel goto irrigation all`.

**What happens**

1. On the fenced field every child receives **15 channel blocks and one
   pump**. The **Inventor** shows the task in five pictures.
2. The children build a channel from the blue **Water Source** block (by
   the pool) to the brown **garden bed** on the dry side of the field.
   **Boulders lie in the straight way** — around or over them, the group
   decides. Blocks must touch with a full side.
   One child's blocks are not enough: they have to share. Who has none
   left gets 5 more from the **crate beside the Inventor** (it gives
   nothing to a child who still has some).
3. Each child builds their **own pump** into the channel.
4. When they think it is done, **everyone** stands on their own pump:
   3-2-1.
5. The water runs along the channel.
   * It **stops** somewhere? Then there is a gap (or someone's pump is not
     on the channel). After a few seconds the channel is dry again. Let the
     children find the gap — this is where the real talking happens.
   * It **arrives**: the garden blooms, the dry yellow half of the field
     turns green, fireworks, and a purple home pad takes the children back
     to the Hub.

**For the next group:** `/sel irrigation_reset`.

**Good to know**

* Blocks that only touch at a corner are *not* connected.
* A child can pick up only their own pump.
* Staying on the pumps does not start the water again: everyone steps off
  and on for a new try.
* You get no kit and are not counted; use `/sel child` to try it yourself.
  Alone, the 16 pieces are just enough for the straight line.

## 9. Activity 4 — Village Decision

**Getting there:** gold path from the crossroads (house signpost), or
`/sel goto village all`.

**What happens**

1. The children find and mine **gemstones** around the houses (they
   sparkle; they grow back).
2. They listen to two people. The **Mayor**, where the path arrives, would
   like to decorate the village square with the gemstones. A **child from
   the village**, at the broken bridge, would like to finish the bridge to
   the grandparents on the other side. Two little faces in the corner of
   the screen show whom a child has already listened to.
3. **Now it is your turn.** Bring the group together and let them talk:
   What does each of the two want? Why? What speaks for it? There is no
   right answer — both are good, they just mean different things.
4. When they think they agree, **everyone** stands on the white **Decision
   Stone** for three seconds. A child who is not convinced can simply stay
   off the stone, and the game will not go on. Do not solve this for them:
   the group has to win that child over, or change its mind.
5. The two pedestals start to sparkle. The first gemstone placed on one
   (right click, gemstone in the hand) decides: **gold = village**,
   **blue = bridge**. This cannot be undone.
6. Everyone receives blocks and they **build it**: gem lamps for the
   square, or planks for the gap in the bridge. A row of gems on the
   screen shows how far they are.
7. Fireworks either way. After the bridge, the grandparents are waiting on
   the other side.

**For the next group:** `/sel village_reset`.

**Good to know**

* The Decision Stone only works when every child has listened to both
  people; otherwise it shows that child a picture of whom to visit first.
* A good question afterwards: *"How did it feel when not everyone agreed
  yet?"* and *"What made you change your mind?"*
* Groups often want both. That is a fine thing to notice together: here,
  the gemstones are only enough for one.

## 10. A game for every child

Please read the Inclusion section of the README once. Three things only you can do:

* Do not split groups by gender, and let children find their own partner
  for the "together" plates.
* When you talk about the characters, use what the children see ("the
  Inventor", "the Mayor") — the pictures leave room for their own ideas.
* If a child does not find a look they like, tell me (the developer):
  adding one is easy.
