--[[
    nodes.lua - the blocks of the tutorial course
    =============================================

    Each station has its own, brightly coloured, glowing block. What the
    block DOES is written in stations.lua; here we only describe how it
    looks. The `_sel_on_step` fields are picked up by sel_core/step.lua.

    Custom fields used by this mod:
      _sel_color    : particle colour for the gentle ambient sparkles
      _sel_on_step  : function(pos, player) when a player steps on it
]]

local S = sel_hub.S
local stone_sounds = default.node_sound_stone_defaults()

-- Shared look for all floor markers: glowing, cannot be dug by children
-- (cracky needs a pickaxe, and the Hub is protected anyway).
local function register_marker(name, def)
	core.register_node("sel_hub:" .. name, {
		description = def.description,
		tiles = {def.texture},
		light_source = def.light or 8,
		groups = {cracky = 2, sel_hub_glow = 1},
		sounds = stone_sounds,
		_sel_color = def.color,
		_sel_on_step = def.on_step,
	})
end

-- Station 1: blue start marker
register_marker("marker_start", {
	description = S("Start Marker"),
	texture = "sel_hub_marker_blue.png",
	color = sel_core.colors.blue,
	on_step = function(pos, player) sel_hub.on_start_marker(pos, player) end,
})

-- Station 3: green place marker (put a block ON TOP of it)
register_marker("marker_place", {
	description = S("Place Marker"),
	texture = "sel_hub_marker_green.png",
	color = sel_core.colors.green,
})

-- Station 4: yellow landing markers (after the gap)
register_marker("marker_landing", {
	description = S("Landing Marker"),
	texture = "sel_hub_marker_yellow.png",
	color = sel_core.colors.gold,
	on_step = function(pos, player) sel_hub.on_landing(pos, player) end,
})

-- Station 5: orange plate (checked by a group hold in stations.lua,
-- so it needs no on_step)
register_marker("plate", {
	description = S("Together Plate"),
	texture = "sel_hub_plate.png",
	color = sel_core.colors.orange,
})

-- Station 6: the finish crystal (brightest of all)
register_marker("crystal", {
	description = S("Finish Crystal"),
	texture = "sel_hub_crystal.png",
	color = sel_core.colors.purple,
	light = 12,
	on_step = function(pos, player) sel_hub.on_crystal(pos, player) end,
})

-- Station 2: the shiny block. Children CAN dig it with their bare hands
-- (about 2 seconds). It drops nothing itself; stations.lua pops out the
-- reward and puts the block back.
core.register_node("sel_hub:shiny_block", {
	description = S("Shiny Block"),
	tiles = {"sel_hub_shiny.png"},
	light_source = 6,
	groups = {oddly_breakable_by_hand = 2, sel_hub_glow = 1},
	drop = "",
	sounds = default.node_sound_metal_defaults(),
	_sel_color = sel_core.colors.gold,
	after_dig_node = function(pos, oldnode, oldmeta, digger)
		sel_hub.on_shiny_dug(pos, digger)
	end,
})

-- Gentle sparkles above every station block so children notice them.
-- ABMs only run near players, so this costs nothing when nobody is here.
core.register_abm({
	label = "SEL hub marker sparkles",
	nodenames = {"group:sel_hub_glow"},
	interval = 2,
	chance = 1,
	action = function(pos, node)
		local def = core.registered_nodes[node.name]
		sel_core.ambient_sparkle(pos, def._sel_color)
	end,
})

-- Signpost picture for "this way to the Hub" (the crystal).
sel_core.register_sign("sel_hub:sign", "sel_hub_sign.png")
