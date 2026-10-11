--[[
    nodes.lua - material crates and the launch platform
    ===================================================

    Crates: one per material. Right-click a crate to take a handful of
    that material. They look like a wooden frame filled with the material,
    so children recognise them without reading. Unbreakable.

    A crate only opens for children whose role allows that material
    (see roles.lua). For the others nothing happens - they have to ask
    the child who has that role.

    Launch platform: glowing teal floor at the edge of the south dock.
    The vessel is built starting from here; at the end, everyone stands on
    it together. Unbreakable.
]]

local S = sel_lake.S

-- Shared settings of unbreakable SEL blocks (see sel_core/items.lua).
local function unbreakable(def)
	def.groups = def.groups or {}
	def.groups.sel_unbreakable = 1
	def.diggable = false
	def.on_blast = function() end
	return def
end

local CRATE_NAMES = {
	wood = S("Wood Crate"),
	stone = S("Stone Crate"),
	glass = S("Glass Crate"),
	garden = S("Garden Crate"),
}

for _, role in ipairs(sel_lake.ROLES) do
	local mat = sel_lake.MATERIALS[role]
	local look = sel_lake.material_picture(role)
	core.register_node("sel_lake:crate_" .. role, unbreakable({
		description = CRATE_NAMES[role],
		tiles = {look},
		sounds = default.node_sound_wood_defaults(),
		_sel_role = role,
		on_rightclick = function(pos, node, clicker)
			if not (clicker and clicker:is_player()) then
				return
			end
			if not sel_lake.may_use(clicker, role) then
				return -- not your material: nothing happens
			end
			for _, item in ipairs(mat.items) do
				sel_core.give(clicker, item)
			end
			sel_core.sparkle(vector.offset(pos, 0, 0.5, 0), sel_core.colors.gold, 10)
			sel_core.play("default_place_node", pos, 0.6)
		end,
	}))
end

core.register_node("sel_lake:launch", unbreakable({
	description = S("Launch Platform"),
	tiles = {"sel_lake_launch.png"},
	light_source = 8,
	sounds = default.node_sound_stone_defaults(),
}))
