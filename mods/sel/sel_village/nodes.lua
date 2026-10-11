--[[
    nodes.lua - the blocks and items of the Village Decision
    ========================================================

      sel_village:gem_ore          gemstone deposit: mine it (hand or
                                   Builder's Tool), it grows back
      sel_village:gem              a gemstone (item)
      sel_village:decision_stone   the white Decision Stone
      sel_village:pedestal_gold / _blue        the two pedestals
      sel_village:pedestal_gold_on / _blue_on  ... with the gemstone on top
      sel_village:lamp_gold / _teal / _pink    gem lamps (decorations)
      sel_village:plank            bridge plank

    What happens when a pedestal is right-clicked is in decide.lua.
]]

local S = sel_village.S

-- Shared settings of unbreakable SEL blocks (see sel_core/items.lua).
local function unbreakable(def)
	def.groups = def.groups or {}
	def.groups.sel_unbreakable = 1
	def.diggable = false
	def.on_blast = function() end
	return def
end

----------------------------------------------------------------------------
-- Gemstones
----------------------------------------------------------------------------
core.register_craftitem("sel_village:gem", {
	description = S("Gemstone"),
	inventory_image = "sel_village_gem.png",
})

core.register_node("sel_village:gem_ore", {
	description = S("Gemstone Deposit"),
	tiles = {"sel_village_gem_ore.png"},
	light_source = 7,
	groups = {oddly_breakable_by_hand = 2, sel_village_glow = 1},
	drop = "sel_village:gem",
	sounds = default.node_sound_stone_defaults(),
	-- the deposit grows back, so every child finds some
	after_dig_node = function(pos)
		sel_core.sparkle(pos, sel_core.colors.blue, 20)
		core.after(sel_village.GEM_REGROW_TIME, function()
			if core.get_node(pos).name == "air" then
				core.set_node(pos, {name = "sel_village:gem_ore"})
			end
		end)
	end,
})

-- Sparkles so the deposits can be found ("sparkling gemstone deposits").
core.register_abm({
	label = "SEL village gem sparkles",
	nodenames = {"group:sel_village_glow"},
	interval = 2,
	chance = 1,
	action = function(pos)
		sel_core.ambient_sparkle(pos, sel_core.colors.blue)
	end,
})

----------------------------------------------------------------------------
-- Decision Stone and pedestals
----------------------------------------------------------------------------
core.register_node("sel_village:decision_stone", unbreakable({
	description = S("Decision Stone"),
	tiles = {"sel_village_decision_stone.png"},
	light_source = 9,
	sounds = default.node_sound_stone_defaults(),
}))

sel_core.register_sign("sel_village:sign_decision", "sel_village_sign_decision.png")

-- A pedestal: a slim column with a plate on top.
local pedestal_box = {
	type = "fixed",
	fixed = {
		{-0.375, -0.5, -0.375, 0.375, -0.3125, 0.375}, -- foot
		{-0.25, -0.3125, -0.25, 0.25, 0.3125, 0.25},   -- column
		{-0.4375, 0.3125, -0.4375, 0.4375, 0.5, 0.4375}, -- plate
	},
}

for _, choice in ipairs({"gold", "blue"}) do
	for _, on in ipairs({false, true}) do
		local top = "sel_village_pedestal_" .. choice .. "_top" .. (on and "_on" or "") .. ".png"
		local side = "sel_village_pedestal_" .. choice .. "_side.png"
		core.register_node("sel_village:pedestal_" .. choice .. (on and "_on" or ""), unbreakable({
			description = choice == "gold" and S("Gold Pedestal (decorate the village)")
				or S("Blue Pedestal (finish the bridge)"),
			drawtype = "nodebox",
			node_box = pedestal_box,
			tiles = {top, side, side},
			paramtype = "light",
			light_source = on and 12 or 5,
			groups = {not_in_creative_inventory = on and 1 or 0},
			sounds = default.node_sound_stone_defaults(),
			-- returns the (possibly smaller) stack the player holds
			on_rightclick = function(pos, node, clicker, itemstack)
				return sel_village.on_pedestal(choice, clicker, itemstack)
			end,
		}))
	end
end

----------------------------------------------------------------------------
-- What the children build with
----------------------------------------------------------------------------
local LAMP_NAMES = {gold = S("Gold Gem Lamp"), teal = S("Teal Gem Lamp"), pink = S("Pink Gem Lamp")}

for _, color in ipairs(sel_village.LAMPS) do
	core.register_node("sel_village:lamp_" .. color, {
		description = LAMP_NAMES[color],
		tiles = {"sel_village_lamp_" .. color .. ".png"},
		light_source = 12,
		groups = {oddly_breakable_by_hand = 3, sel_village_decor = 1},
		sounds = default.node_sound_glass_defaults(),
	})
end

core.register_node("sel_village:plank", {
	description = S("Bridge Plank"),
	tiles = {"sel_village_plank.png"},
	groups = {oddly_breakable_by_hand = 3, sel_village_plank = 1},
	sounds = default.node_sound_wood_defaults(),
})
