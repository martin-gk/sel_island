--[[
    flower.lua - the flower blocks and the breathing cycle
    ======================================================

    The flower has 5 looks ("stages", 0 = bud ... 4 = wide open) and a
    COLOUR for each breathing phase, so children see which phase it is:

        in   (breathe in)  = sky blue,  opening   stages 0 -> 4
        hold               = warm gold, wide open stage 4
        out  (breathe out) = violet,    closing   stages 4 -> 0

    Blocks (one per phase + stage):
      sel_flower:flower          blue bud (in, stage 0). This is also the
                                 item the teacher places.
      sel_flower:flower_in_1..4  blue, more and more open
      sel_flower:flower_hold_4   gold, wide open
      sel_flower:flower_out_0..4 violet, closing
    Only sel_flower:flower is ever in an inventory; digging any of them
    gives it back.

    Each flower keeps its own clock in its node metadata ("t" = seconds
    into the current breath, 0 .. CYCLE). Because the clock is stored in
    the block, it survives server restarts, and several flowers can run
    independently.
]]

local S = sel_flower.S
local C = sel_core.colors

local IN, HOLD, OUT = sel_flower.IN_TIME, sel_flower.HOLD_TIME, sel_flower.OUT_TIME
local CYCLE, STAGES, TICK = sel_flower.CYCLE, sel_flower.STAGES, sel_flower.TICK

-- Node name for a phase ("in", "hold", "out") and stage number (0 = bud).
local function node_name(phase, stage)
	if phase == "in" and stage == 0 then
		return "sel_flower:flower"
	end
	return "sel_flower:flower_" .. phase .. "_" .. stage
end
sel_flower.node_name = node_name

----------------------------------------------------------------------------
-- The breathing maths
----------------------------------------------------------------------------

-- Which part of the breath are we in at time t (0 <= t < CYCLE)?
-- Returns "in", "hold" or "out".
function sel_flower.phase(t)
	if t < IN then
		return "in"
	elseif t < IN + HOLD then
		return "hold"
	end
	return "out"
end

-- How open is the flower at time t? 0 = closed bud, 1 = wide open.
--   in:   0 -> 1 evenly over 4 s
--   hold: 1
--   out:  1 -> 0 evenly over 8 s
function sel_flower.openness(t)
	local phase = sel_flower.phase(t)
	if phase == "in" then
		return t / IN
	elseif phase == "hold" then
		return 1
	end
	return 1 - (t - IN - HOLD) / OUT
end

-- Stage number (0 .. STAGES-1) for time t, rounded to the nearest look.
function sel_flower.stage(t)
	return math.floor(sel_flower.openness(t) * (STAGES - 1) + 0.5)
end

----------------------------------------------------------------------------
-- Sparkles - one small spawner per tick, in the colour of the phase
----------------------------------------------------------------------------
local SPARK = {
	["in"] = "sel_core_spark.png^[multiply:" .. C.blue,
	hold   = "sel_core_spark.png^[multiply:" .. C.gold,
	out    = "sel_core_spark.png^[multiply:" .. C.purple,
}

local function sparkles(pos, phase)
	local head = vector.offset(pos, 0, sel_flower.HEAD_HEIGHT, 0)
	local def = {
		amount = 3,
		time = TICK,
		texture = SPARK[phase],
		glow = 14,
		size = {min = 1.0, max = 2.0},
	}
	if phase == "in" then
		-- start at the flower head and drift outward in all directions
		def.pos = head
		def.vel = {min = {x = -0.9, y = -0.2, z = -0.9}, max = {x = 0.9, y = 0.5, z = 0.9}}
		def.exptime = {min = 2.0, max = 3.0}
	elseif phase == "hold" then
		-- appear in a cloud around the flower and float almost still
		def.pos = head
		def.radius = {min = 1.5, max = 2.6}
		def.vel = {min = {x = -0.05, y = -0.05, z = -0.05}, max = {x = 0.05, y = 0.1, z = 0.05}}
		def.exptime = {min = 1.0, max = 1.8}
	else
		-- appear in a cloud around the flower and sink back into the head
		def.pos = head
		def.radius = {min = 1.8, max = 2.6}
		def.attract = {
			kind = "point",
			origin = head,
			strength = 0.35,      -- speed = strength x distance: slow & calm
			die_on_contact = true,
		}
		def.exptime = {min = 3.0, max = 4.0}
	end
	core.add_particlespawner(def)
end

----------------------------------------------------------------------------
-- The timer: advance the clock, swap the look, sparkle
----------------------------------------------------------------------------
local function on_timer(pos, elapsed)
	local meta = core.get_meta(pos)
	local t = (meta:get_float("t") + elapsed) % CYCLE
	meta:set_float("t", t)

	local node = core.get_node(pos)
	local wanted = node_name(sel_flower.phase(t), sel_flower.stage(t))
	if node.name ~= wanted then
		-- swap_node keeps the metadata (our clock) and the timer running
		core.swap_node(pos, {name = wanted, param2 = node.param2})
	end

	sparkles(pos, sel_flower.phase(t))
	return true -- keep the timer running with the same interval
end

----------------------------------------------------------------------------
-- Register the blocks
----------------------------------------------------------------------------
-- Who may remove a flower?
--   * a flower of a calm corner ("fixed"): only the teacher
--   * any other flower (placed by a child or the teacher): everybody -
--     children carry their own flower and can pick it up again
local function can_dig(pos, player)
	if not player then
		return false
	end
	if core.get_meta(pos):get_int("fixed") == 1 then
		return sel_core.is_teacher(player:get_player_name())
	end
	return true
end

-- Every child owns one Breathing Flower (given after the tutorial, see
-- sel_hub) and can plant it wherever they need a calm moment - except in
-- protected places. Returns true if a flower was given.
function sel_flower.ensure_flower(player)
	if player:get_inventory():contains_item("main", "sel_flower:flower") then
		return false
	end
	sel_core.give(player, "sel_flower:flower")
	return true
end

-- Register one block for a phase + stage.
local function register_flower(phase, stage)
	local picture = "sel_flower_" .. phase .. "_" .. stage .. ".png"
	local is_item = phase == "in" and stage == 0
	core.register_node(node_name(phase, stage), {
		description = S("Breathing Flower"),
		drawtype = "plantlike",
		tiles = {picture},
		inventory_image = "sel_flower_in_2.png",
		wield_image = "sel_flower_in_2.png",
		visual_scale = sel_flower.SIZE,
		paramtype = "light",
		-- "meshoptions" + param2 = 2 draws the picture 3 times in a star
		-- shape, so the flower looks round from every side.
		paramtype2 = "meshoptions",
		place_param2 = 2,
		sunlight_propagates = true,
		light_source = 8,
		walkable = true,
		-- children bump into the stem, not into the big petals
		collision_box = {type = "fixed", fixed = {-0.25, -0.5, -0.25, 0.25, 1.0, 0.25}},
		selection_box = {type = "fixed", fixed = {-0.4, -0.5, -0.4, 0.4, 2.0, 0.4}},
		groups = {
			dig_immediate = 3,
			sel_flower = 1,
			not_in_creative_inventory = is_item and 0 or 1,
		},
		drop = "sel_flower:flower",
		can_dig = can_dig,
		on_construct = function(pos)
			core.get_meta(pos):set_float("t", 0)
			core.get_node_timer(pos):start(TICK)
			sel_flower.remember(pos) -- for /sel_calm (calm.lua)
		end,
		-- called when the flower is dug/removed (NOT when it changes stage,
		-- because swap_node does not call it)
		on_destruct = function(pos)
			sel_flower.forget(pos)
		end,
		on_timer = on_timer,
	})
end

-- in: stages 0..4 (blue) - hold: stage 4 (gold) - out: stages 4..0 (violet)
for stage = 0, STAGES - 1 do
	register_flower("in", stage)
	register_flower("out", stage)
end
register_flower("hold", STAGES - 1)

-- Flowers placed with the first version (one colour, names _1 .. _4) keep
-- working: their old names now point to the blue "in" blocks.
for stage = 1, STAGES - 1 do
	core.register_alias("sel_flower:flower_" .. stage, node_name("in", stage))
end
