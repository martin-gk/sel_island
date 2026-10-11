--[[
    calm.lua - calm corners: a Breathing Flower at every activity
    =============================================================

    Children who feel overwhelmed should always find something grounding
    nearby. So every activity site gets a CALM CORNER that always looks
    the same, wherever it is:

        a 3 x 3 patch of soft, light-green "calm grass"
        with a Breathing Flower in the middle

    Children learn once: "green patch with the big flower = calm place,
    I can go there and breathe with the flower".

    For activity mods:
        sel_flower.build_calm_corner(pos)
            pos = the CENTRE block of the 3x3 grass patch (ground level).
            The flower grows one block above it. The space above is cleared.

    Every flower (calm corner or placed by the teacher with /sel_flower)
    is remembered in a list, so the teacher can bring a child to the
    nearest one:
        /sel_calm <name>   teleport a child next to the nearest flower
        /sel_calm          ... yourself
]]

local S = sel_flower.S
local storage = core.get_mod_storage()

----------------------------------------------------------------------------
-- Calm grass: soft and unbreakable (children have Builder's Tools, and the
-- calm corner should never be dug away). Only the Teacher's Wand removes it.
----------------------------------------------------------------------------
core.register_node("sel_flower:calm_grass", {
	description = S("Calm Grass"),
	tiles = {"sel_flower_calm_grass.png"},
	groups = {sel_unbreakable = 1},
	diggable = false,
	on_blast = function() end,
	sounds = {footstep = {name = "default_grass_footstep", gain = 0.4}},
})

----------------------------------------------------------------------------
-- The list of all flowers (positions), saved in mod storage.
----------------------------------------------------------------------------
local flowers = core.deserialize(storage:get_string("flowers")) or {}

local function save()
	storage:set_string("flowers", core.serialize(flowers))
end

-- Called by every flower block when it is created / removed (flower.lua).
function sel_flower.remember(pos)
	flowers[core.pos_to_string(pos)] = true
	save()
end

function sel_flower.forget(pos)
	flowers[core.pos_to_string(pos)] = nil
	save()
end

-- Position of the flower nearest to `pos`, or nil if there is none.
function sel_flower.nearest(pos)
	local best, best_dist
	for key in pairs(flowers) do
		local p = core.string_to_pos(key)
		local d = vector.distance(pos, p)
		if not best_dist or d < best_dist then
			best, best_dist = p, d
		end
	end
	return best
end

----------------------------------------------------------------------------
-- Building a calm corner
----------------------------------------------------------------------------
function sel_flower.build_calm_corner(pos)
	-- clear 4 blocks of air above the patch (room for the 3-tall flower)
	sel_core.fill(vector.offset(pos, -1, 1, -1), vector.offset(pos, 1, 4, 1), "air")
	sel_core.fill(vector.offset(pos, -1, 0, -1), vector.offset(pos, 1, 0, 1),
		"sel_flower:calm_grass")
	-- set_node runs on_construct: the flower starts breathing and is
	-- added to the list
	local flower = vector.offset(pos, 0, 1, 0)
	core.set_node(flower, {name = "sel_flower:flower", param2 = 2})
	-- "fixed": children cannot pick up the flower of a calm corner
	core.get_meta(flower):set_int("fixed", 1)
end

----------------------------------------------------------------------------
-- /sel_calm
----------------------------------------------------------------------------
core.register_chatcommand("sel_calm", {
	params = S("[<name>]"),
	description = S("Bring a player (or yourself) to the nearest Breathing Flower"),
	privs = {sel_teacher = true},
	func = function(name, param)
		local target = core.get_player_by_name(param ~= "" and param or name)
		if not target then
			return false, S("Player @1 is not online.", param)
		end
		local flower = sel_flower.nearest(target:get_pos())
		if not flower then
			return false, S("There is no Breathing Flower in the world yet.")
		end
		-- stand on the grass patch, one block east of the flower
		target:set_pos(vector.offset(flower, 1, 0, 0))
		return true
	end,
})
