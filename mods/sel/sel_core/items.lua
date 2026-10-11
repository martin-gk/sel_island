--[[
    items.lua - tools for children and teacher, and the unbreakable glass
    =====================================================================

    Builder's Tool  (sel_core:tool)
        ONE tool that digs everything a child may dig: stone, wood, dirt,
        leaves, ... One tool instead of pickaxe/axe/shovel means children
        never have to switch tools. It never wears out and cannot be
        dropped (the Q key does nothing), so it cannot get lost.
        Children receive it when they finish the tutorial (sel_hub).

    Teacher's Wand  (sel_core:teacher_wand)
        Left click removes ANY block instantly, including Shield Glass.
        Does nothing in the hands of a child. Teachers get it with /sel_wand.

    Shield Glass  (sel_core:shield_glass)
        A clear glass block with a light-blue frame that NOBODY can break
        with tools (only the Teacher's Wand removes it). Use it for parts
        of activity sites that must survive while children build right
        next to them (bridge rails, the edge of a building area, ...).
        Children learn quickly: "blue-framed glass = cannot be broken".

    Two ways to protect things - when to use which:
        * protected zone (protect.lua): nobody may dig OR build in an area,
          invisible. For sites that must stay exactly as built (the Hub).
        * Shield Glass: visible, only that block is unbreakable; children
          can still build around it. For sites where children build.
]]

local S = sel_core.S

----------------------------------------------------------------------------
-- Builder's Tool
----------------------------------------------------------------------------
-- Digging times in seconds for the group levels 1 (hard) .. 3 (soft).
-- uses = 0 means the tool never wears out.
local function caps(t1, t2, t3)
	return {times = {[1] = t1, [2] = t2, [3] = t3}, uses = 0, maxlevel = 3}
end

core.register_tool("sel_core:tool", {
	description = S("Builder's Tool"),
	inventory_image = "sel_core_tool.png",
	tool_capabilities = {
		full_punch_interval = 0.8,
		max_drop_level = 1,
		groupcaps = {
			cracky  = caps(1.6, 0.8, 0.4),  -- stone, ores, bricks
			choppy  = caps(1.6, 0.8, 0.4),  -- trees, wood
			crumbly = caps(0.9, 0.5, 0.3),  -- dirt, sand, gravel
			snappy  = caps(0.6, 0.3, 0.15), -- leaves, plants, wool
			oddly_breakable_by_hand = caps(1.0, 0.5, 0.25),
		},
		damage_groups = {fleshy = 1},
	},
	-- Returning the stack unchanged = the item is NOT dropped.
	on_drop = function(itemstack)
		return itemstack
	end,
})

-- Does the player have a Builder's Tool somewhere in the inventory?
function sel_core.has_tool(player)
	return player:get_inventory():contains_item("main", "sel_core:tool")
end

-- Give the Builder's Tool if the player does not have one yet.
-- Returns true if a tool was given.
function sel_core.ensure_tool(player)
	if sel_core.has_tool(player) then
		return false
	end
	sel_core.give(player, "sel_core:tool")
	sel_core.sparkle(player:get_pos(), sel_core.colors.blue, 20)
	return true
end

----------------------------------------------------------------------------
-- Teacher's Wand
----------------------------------------------------------------------------
core.register_tool("sel_core:teacher_wand", {
	description = S("Teacher's Wand (removes any block)"),
	inventory_image = "sel_core_wand.png",
	range = 10,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" or not user then
			return
		end
		if not sel_core.is_teacher(user:get_player_name()) then
			return -- children: nothing happens
		end
		local pos = pointed_thing.under
		core.remove_node(pos)
		sel_core.sparkle(pos, sel_core.colors.gold, 12)
	end,
})

----------------------------------------------------------------------------
-- Shield Glass (unbreakable)
----------------------------------------------------------------------------
core.register_node("sel_core:shield_glass", {
	description = S("Shield Glass (unbreakable)"),
	drawtype = "glasslike",
	tiles = {"sel_core_shield_glass.png"},
	use_texture_alpha = "blend",
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 3,
	-- No digging groups -> no tool can dig it.
	groups = {sel_unbreakable = 1},
	diggable = false,
	-- Explosions do not destroy it either.
	on_blast = function() end,
	sounds = {
		footstep = {name = "default_glass_footstep", gain = 0.3},
	},
})

----------------------------------------------------------------------------
-- Teacher commands
----------------------------------------------------------------------------
core.register_chatcommand("sel_wand", {
	description = S("Get the Teacher's Wand"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_core.give(core.get_player_by_name(name), "sel_core:teacher_wand")
		return true
	end,
})

----------------------------------------------------------------------------
-- Give Builder's Tools
----------------------------------------------------------------------------
core.register_chatcommand("sel_tools", {
	params = S("<name> | all"),
	description = S("Give the Builder's Tool to a player (or everyone)"),
	privs = {sel_teacher = true},
	func = function(name, param)
		local targets = {}
		if param == "all" then
			targets = core.get_connected_players()
		else
			local p = core.get_player_by_name(param ~= "" and param or name)
			if not p then
				return false, S("Player @1 is not online.", param)
			end
			targets = {p}
		end
		for _, player in ipairs(targets) do
			sel_core.ensure_tool(player)
		end
		return true, S("Builder's Tools handed out.")
	end,
})
