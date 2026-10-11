--[[
    nodes.lua - the blocks of the Irrigation Channel
    ================================================

      sel_irrigation:channel      a wooden trough (dry)          \  group
      sel_irrigation:channel_wet  ... with water running in it    | sel_channel:
      sel_irrigation:pump         a pump station (dry)            | water can
      sel_irrigation:pump_wet     ... while the water flows      /  pass through
      sel_irrigation:source       the blue Water Source block (unbreakable)
      sel_irrigation:garden_dry   dry garden bed    \ group sel_garden
      sel_irrigation:garden_wet   watered garden bed/ (unbreakable)
      sel_irrigation:crate        spare parts: a few more channel blocks
                                  for a child who has none left (unbreakable)

    Blocks of group sel_channel that touch each other (6 sides) form the
    channel. The "wet" versions are only looks: flow.lua swaps dry <-> wet.
    Digging a wet block gives back the normal (dry) item.

    A pump remembers who placed it ("owner" in its metadata). Only the
    owner (or the teacher) can take it away again, and in the launch each
    child must stand on their OWN pump.
]]

local S = sel_irrigation.S

-- A trough: a floor slab with a rim all around (so it looks like it can
-- hold water). The wet version has a water surface inside.
local trough = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, -0.125, 0.5},    -- floor slab
		{-0.5, -0.125, -0.5, 0.5, 0.125, -0.3125}, -- rim north/south/west/east
		{-0.5, -0.125, 0.3125, 0.5, 0.125, 0.5},
		{-0.5, -0.125, -0.3125, -0.3125, 0.125, 0.3125},
		{0.3125, -0.125, -0.3125, 0.5, 0.125, 0.3125},
	},
}
local trough_wet = table.copy(trough)
table.insert(trough_wet.fixed, {-0.3125, -0.125, -0.3125, 0.3125, 0.0625, 0.3125}) -- water

local function register_channel(name, def)
	core.register_node("sel_irrigation:" .. name, {
		description = def.description,
		drawtype = "nodebox",
		node_box = def.box,
		selection_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.125, 0.5}},
		tiles = {def.top, "default_wood.png", "default_wood.png"},
		paramtype = "light",
		light_source = def.light,
		-- quick to dig, by hand or with the Builder's Tool
		groups = {oddly_breakable_by_hand = 3, sel_channel = 1,
			not_in_creative_inventory = def.hidden and 1 or 0},
		drop = "sel_irrigation:channel",
		sounds = default.node_sound_wood_defaults(),
	})
end

register_channel("channel", {
	description = S("Channel Block"),
	box = trough,
	top = "sel_irrigation_channel_top.png",
})
register_channel("channel_wet", {
	description = S("Channel Block"),
	box = trough_wet,
	top = "sel_irrigation_channel_top_wet.png",
	light = 4,
	hidden = true,
})

-- Who may dig a pump: its owner or the teacher.
local function can_dig_pump(pos, player)
	if not player then
		return false
	end
	local name = player:get_player_name()
	return sel_core.is_teacher(name) or core.get_meta(pos):get_string("owner") == name
end

local function register_pump(name, def)
	core.register_node("sel_irrigation:" .. name, {
		description = S("Pump Station"),
		tiles = {def.top, "sel_irrigation_pump_side.png", "sel_irrigation_pump_side.png"},
		light_source = def.light,
		groups = {oddly_breakable_by_hand = 3, sel_channel = 1, sel_pump = 1,
			not_in_creative_inventory = def.hidden and 1 or 0},
		drop = "sel_irrigation:pump",
		sounds = default.node_sound_metal_defaults(),
		can_dig = can_dig_pump,
		-- remember who placed it
		after_place_node = function(pos, placer)
			if placer and placer:is_player() then
				core.get_meta(pos):set_string("owner", placer:get_player_name())
			end
		end,
	})
end

register_pump("pump", {top = "sel_irrigation_pump_top.png"})
register_pump("pump_wet", {top = "sel_irrigation_pump_top_wet.png", light = 6, hidden = true})

-- Shared settings of unbreakable SEL blocks (see sel_core/items.lua).
local function unbreakable(def)
	def.groups = def.groups or {}
	def.groups.sel_unbreakable = 1
	def.diggable = false
	def.on_blast = function() end
	return def
end

core.register_node("sel_irrigation:source", unbreakable({
	description = S("Water Source"),
	tiles = {"sel_irrigation_source.png"},
	light_source = 10,
	sounds = default.node_sound_stone_defaults(),
}))

core.register_node("sel_irrigation:garden_dry", unbreakable({
	description = S("Dry Garden Bed"),
	tiles = {"sel_irrigation_garden_dry.png"},
	groups = {sel_garden = 1},
	sounds = default.node_sound_dirt_defaults(),
}))

core.register_node("sel_irrigation:garden_wet", unbreakable({
	description = S("Watered Garden Bed"),
	tiles = {"sel_irrigation_garden_wet.png"},
	groups = {sel_garden = 1, soil = 1},
	sounds = default.node_sound_dirt_defaults(),
}))

-- The spare-parts crate: a wooden frame full of channel blocks, so
-- children recognise it without reading. A right click hands out a few
-- channel blocks - but only to a child who has none left. So nobody can
-- hoard, and a small group (or one child alone) can still finish.
core.register_node("sel_irrigation:crate", unbreakable({
	description = S("Spare Channel Blocks"),
	tiles = {"sel_irrigation_channel_top.png^sel_irrigation_crate_frame.png"},
	sounds = default.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, clicker)
		if not (clicker and clicker:is_player()) then
			return
		end
		if clicker:get_inventory():contains_item("main", "sel_irrigation:channel") then
			sel_core.play("sel_core_tick", clicker, 0.4) -- "use up yours first"
			return
		end
		sel_core.give(clicker, "sel_irrigation:channel " .. sel_irrigation.CRATE_CHANNELS)
		sel_core.sparkle(vector.offset(pos, 0, 1, 0), sel_core.colors.blue, 15)
		sel_core.play("sel_core_chime", clicker, 0.7)
	end,
}))
