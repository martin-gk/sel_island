--[[
    rules.lua - who takes part, what may be dug/placed, the screen icons
    ====================================================================

    Participants are the children (non-teachers) inside the activity area.

    Inside the area children can only
      * mine gemstone deposits,
      * place and take away gem lamps    (after choosing GOLD),
      * place and take away bridge planks (after choosing BLUE),
      * plant their own Breathing Flower.
    The houses, the square, the bridge ends and the ground cannot be changed.

    Screen icons (top left corner):
      * while gathering: two faces - the Mayor and the village child.
        Dark = not heard yet, bright = heard.
      * while building: a row of ten gems that fills up with the progress.
]]

local L = sel_village.layout

function sel_village.in_area(pos)
	return sel_core.in_box(pos, L.area_min, L.area_max)
end

-- All children (non-teachers) who are inside the activity area right now.
function sel_village.participants()
	local list = {}
	for _, player in ipairs(core.get_connected_players()) do
		if sel_village.in_area(player:get_pos())
				and not sel_core.is_teacher(player:get_player_name()) then
			table.insert(list, player)
		end
	end
	return list
end

-- Has this child heard BOTH sides of the story?
function sel_village.heard_both(player)
	return sel_core.has_heard(player, "mayor") and sel_core.has_heard(player, "village_child")
end

----------------------------------------------------------------------------
-- Digging and placing
----------------------------------------------------------------------------
local function group(name, g)
	return core.get_item_group(name, g) > 0
end

-- May a child PLACE this block here right now?
local function may_place(name)
	if group(name, "sel_flower") then
		return true
	end
	if group(name, "sel_village_decor") then
		return sel_village.state == "build_gold"
	end
	if group(name, "sel_village_plank") then
		return sel_village.state == "build_blue"
	end
	return false
end

sel_core.protect_zone({
	name = "village",
	minp = L.area_min,
	maxp = L.area_max,
	allow = function(pos)
		local node = core.get_node(pos).name
		local def = core.registered_nodes[node]
		if def and def.buildable_to then
			return true -- empty spot: placing is checked below
		end
		return node == "sel_village:gem_ore"
			or group(node, "sel_village_decor") or group(node, "sel_village_plank")
			or group(node, "sel_flower")
	end,
})

-- Placing: undo anything a child may not place here right now.
-- Returning true tells Luanti NOT to take the block from the inventory.
core.register_on_placenode(function(pos, newnode, placer, oldnode)
	if not (placer and placer:is_player() and sel_village.in_area(pos)) then
		return
	end
	if sel_core.is_teacher(placer:get_player_name()) or may_place(newnode.name) then
		return
	end
	core.set_node(pos, oldnode) -- as if nothing happened
	return true
end)

----------------------------------------------------------------------------
-- Screen icons
----------------------------------------------------------------------------
local huds = {} -- player name -> {kind = "heard"/"progress", ids = {...}, shown = "..."}

local function hide_hud(player)
	local name = player:get_player_name()
	if huds[name] then
		for _, id in ipairs(huds[name].ids) do
			player:hud_remove(id)
		end
		huds[name] = nil
	end
end

-- Two faces: who has this child listened to?
local function show_heard(player)
	local name = player:get_player_name()
	local heard = {sel_core.has_heard(player, "mayor"), sel_core.has_heard(player, "village_child")}
	local signature = (heard[1] and "1" or "0") .. (heard[2] and "1" or "0")
	local hud = huds[name]
	if hud and hud.kind ~= "heard" then
		hide_hud(player)
		hud = nil
	end
	if hud and hud.shown == signature then
		return
	end
	if not hud then
		hud = {kind = "heard", ids = {}}
		huds[name] = hud
		for i = 1, 2 do
			hud.ids[i] = player:hud_add({
				type = "image",
				position = {x = 0, y = 0},
				alignment = {x = 1, y = 1},
				offset = {x = 16 + (i - 1) * 58, y = 16},
				scale = {x = 3, y = 3},
				text = "",
			})
		end
	end
	local pictures = {"sel_village_portrait_mayor.png", "sel_village_portrait_child.png"}
	for i = 1, 2 do
		local picture = pictures[i]
		if not heard[i] then
			picture = picture .. "^[colorize:#000000:190"
		end
		player:hud_change(hud.ids[i], "text", picture)
	end
	hud.shown = signature
end

-- A row of ten gems: `fraction` (0 .. 1) of them are filled.
local function show_progress(player, fraction)
	local name = player:get_player_name()
	local filled = math.floor(fraction * 20 + 0.5) -- in half gems
	local hud = huds[name]
	if hud and hud.kind ~= "progress" then
		hide_hud(player)
		hud = nil
	end
	if not hud then
		hud = {kind = "progress", ids = {}}
		huds[name] = hud
		hud.ids[1] = player:hud_add({
			type = "statbar",
			position = {x = 0, y = 0},
			offset = {x = 16, y = 16},
			text = "sel_village_gem.png",
			text2 = "sel_village_gem.png^[colorize:#000000:200", -- empty places
			number = filled,
			item = 20,
			size = {x = 32, y = 32},
		})
	elseif hud.shown ~= filled then
		player:hud_change(hud.ids[1], "number", filled)
	end
	hud.shown = filled
end

-- Called twice a second by decide.lua with the current progress.
function sel_village.update_huds(progress)
	local taking_part = {}
	for _, player in ipairs(sel_village.participants()) do
		taking_part[player:get_player_name()] = true
		local state = sel_village.state
		if state == "gather" then
			show_heard(player)
		elseif state == "build_gold" or state == "build_blue" then
			show_progress(player, progress)
		else
			hide_hud(player)
		end
	end
	for _, player in ipairs(core.get_connected_players()) do
		if not taking_part[player:get_player_name()] then
			hide_hud(player)
		end
	end
end

core.register_on_leaveplayer(function(player)
	huds[player:get_player_name()] = nil
end)
