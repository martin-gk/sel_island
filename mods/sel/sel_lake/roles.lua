--[[
    roles.lua - material roles: who may use which material
    ======================================================

    Every child who walks into the activity area (config.lua: area_min /
    area_max) automatically gets ONE material role: Wood, Stone, Glass or
    Gardener. Roles are handed out evenly (always the role that has the
    fewest children). A child keeps the role until the teacher resets the
    activity - walking out and in again does not change it.

    What a role means, inside the area:
      * only the crate of your material opens for you
      * you can only place and dig blocks of your material
      * everything else is blocked: if you try, nothing happens
    So the children have to talk: "I need glass here - who has glass?"

    Small groups: if NO child has a certain role, that material is free
    for everybody (the vessel still needs all four materials).

    Four small pictures in the top left corner show the materials:
    bright = you may use it, dark = ask someone else.

    Teachers are not part of this (no role, no restrictions) - unless they
    switch on child mode (/sel child).
]]

local L = sel_lake.layout
local ROLES, MATERIALS = sel_lake.ROLES, sel_lake.MATERIALS

local role_of = {}  -- player name -> role (kept until reset)
local huds = {}     -- player name -> {ids = {...}, shown = "signature"}

-- node name -> role, e.g. "default:wood" -> "wood"
sel_lake.node_role = {}
for role, mat in pairs(MATERIALS) do
	for _, node in ipairs(mat.nodes) do
		sel_lake.node_role[node] = role
	end
end

----------------------------------------------------------------------------
-- Who takes part?
----------------------------------------------------------------------------
function sel_lake.in_area(pos)
	return sel_core.in_box(pos, L.area_min, L.area_max)
end

-- All children (non-teachers) who are inside the activity area right now.
function sel_lake.participants()
	local list = {}
	for _, player in ipairs(core.get_connected_players()) do
		if sel_lake.in_area(player:get_pos())
				and not sel_core.is_teacher(player:get_player_name()) then
			table.insert(list, player)
		end
	end
	return list
end

function sel_lake.get_role(player)
	return role_of[player:get_player_name()]
end

-- How many participants have each role right now? role -> number
local function role_counts()
	local counts = {}
	for _, role in ipairs(ROLES) do
		counts[role] = 0
	end
	for _, player in ipairs(sel_lake.participants()) do
		local role = sel_lake.get_role(player)
		if role then
			counts[role] = counts[role] + 1
		end
	end
	return counts
end

-- Give a new participant the role that has the fewest children
-- (the first one in ROLES order if several are equal).
local function assign_role(player)
	local counts = role_counts()
	local best = ROLES[1]
	for _, role in ipairs(ROLES) do
		if counts[role] < counts[best] then
			best = role
		end
	end
	role_of[player:get_player_name()] = best
	-- show the child which crate is theirs
	sel_core.sparkle(vector.offset(L.crates[best], 0, 0.5, 0), sel_core.colors.gold, 30)
	sel_core.play("sel_core_chime", player, 0.7)
	return best
end

-- May this player use (take, place, dig) the material of `role`?
function sel_lake.may_use(player, role)
	if sel_core.is_teacher(player:get_player_name()) then
		return true
	end
	if sel_lake.get_role(player) == role then
		return true
	end
	return role_counts()[role] == 0 -- nobody has that role: free for all
end

-- Forget all roles (teacher reset; see launch.lua).
function sel_lake.clear_roles()
	role_of = {}
end

----------------------------------------------------------------------------
-- The role pictures at the top of the screen
----------------------------------------------------------------------------
-- Picture of a material: its texture on a coloured background (so glass
-- and leaves, which have see-through parts, are clearly visible).
function sel_lake.material_picture(role)
	local mat = MATERIALS[role]
	return "[fill:16x16:" .. mat.background .. "^" .. mat.texture
		.. "^sel_lake_crate_frame.png"
end

local function hide_hud(player)
	local name = player:get_player_name()
	if huds[name] then
		for _, id in ipairs(huds[name].ids) do
			player:hud_remove(id)
		end
		huds[name] = nil
	end
end

local function update_hud(player)
	local name = player:get_player_name()
	-- which materials are bright? build a short "signature" to notice changes
	local bright, signature = {}, ""
	for i, role in ipairs(ROLES) do
		bright[i] = sel_lake.may_use(player, role)
		signature = signature .. (bright[i] and "1" or "0")
	end
	local hud = huds[name]
	if hud and hud.shown == signature then
		return -- nothing changed
	end
	if not hud then
		hud = {ids = {}}
		huds[name] = hud
		for i = 1, #ROLES do
			hud.ids[i] = player:hud_add({
				type = "image",
				-- top LEFT corner (the top centre belongs to the tutorial
				-- icons and to the story pictures of the Ferrymaster)
				position = {x = 0, y = 0},
				alignment = {x = 1, y = 1},
				offset = {x = 16 + (i - 1) * 58, y = 16},
				scale = {x = 3, y = 3},
				text = "",
			})
		end
	end
	for i, role in ipairs(ROLES) do
		local picture = sel_lake.material_picture(role)
		if not bright[i] then
			picture = picture .. "^[colorize:#000000:180"
		end
		player:hud_change(hud.ids[i], "text", picture)
	end
	hud.shown = signature
end

-- Twice a second: hand out roles to newcomers, keep the pictures current.
local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then
		return
	end
	timer = 0
	for _, player in ipairs(core.get_connected_players()) do
		local name = player:get_player_name()
		if sel_lake.in_area(player:get_pos()) and not sel_core.is_teacher(name) then
			if not role_of[name] then
				assign_role(player)
			end
			update_hud(player)
		else
			hide_hud(player)
		end
	end
end)

core.register_on_leaveplayer(function(player)
	huds[player:get_player_name()] = nil
end)

----------------------------------------------------------------------------
-- The rules: digging and placing inside the area
----------------------------------------------------------------------------
local function is_flower(name)
	return core.get_item_group(name, "sel_flower") > 0
end

-- Digging (and placing, which Luanti checks at the still-empty spot).
sel_core.protect_zone({
	name = "lake roles",
	minp = L.area_min,
	maxp = L.area_max,
	allow = function(pos, name)
		local player = core.get_player_by_name(name)
		if not player then
			return false
		end
		local node = core.get_node(pos).name
		local def = core.registered_nodes[node]
		if def and def.buildable_to then
			return true -- empty spot (air, water): placing is checked below
		end
		if is_flower(node) then
			return true -- a child's own Breathing Flower
		end
		local role = sel_lake.node_role[node]
		return role ~= nil and sel_lake.may_use(player, role)
	end,
})

-- Placing: undo it if the block is not one of the child's materials.
-- Returning true tells Luanti NOT to take the block from the inventory.
core.register_on_placenode(function(pos, newnode, placer, oldnode)
	if not (placer and placer:is_player() and sel_lake.in_area(pos)) then
		return
	end
	if sel_core.is_teacher(placer:get_player_name()) or is_flower(newnode.name) then
		return
	end
	local role = sel_lake.node_role[newnode.name]
	if role and sel_lake.may_use(placer, role) then
		return
	end
	core.set_node(pos, oldnode) -- as if nothing happened
	return true
end)
