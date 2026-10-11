--[[
    progress.lua - which stations has each child done?
    ==================================================

    Progress is stored in the player's metadata (saved with the world) as a
    string of six characters, "0" = not done, "1" = done. Example: "110000"
    means stations 1 and 2 are done.

    The icon row: six station pictures at the top of the screen. Done
    stations are bright, open ones are dark. This is the only "progress
    bar" - children can see what is left without reading anything.
]]

local META_KEY = "sel_hub:progress"
local STATION_COUNT = 6

-- Picture for each station = the texture of its block.
local ICONS = {
	"sel_hub_marker_blue.png",   -- 1 walk
	"sel_hub_shiny.png",         -- 2 break
	"sel_hub_marker_green.png",  -- 3 place
	"sel_hub_marker_yellow.png", -- 4 jump
	"sel_hub_plate.png",         -- 5 together
	"sel_hub_crystal.png",       -- 6 finish
}
local ICON_SIZE = 48     -- pixels on screen (16 px texture * 3)
local ICON_SPACING = 58  -- pixels between icon centres

local hud_ids = {} -- player name -> {id1, ..., id6}

-- Read the progress string, always 6 characters long.
local function get_progress(player)
	local s = player:get_meta():get_string(META_KEY)
	if #s ~= STATION_COUNT then
		s = string.rep("0", STATION_COUNT)
	end
	return s
end

-- Texture of icon i: bright if done, darkened if not.
local function icon_texture(i, done)
	if done then
		return ICONS[i]
	end
	return ICONS[i] .. "^[colorize:#000000:170"
end

function sel_hub.is_done(player, i)
	return get_progress(player):sub(i, i) == "1"
end

-- Has the child reached the crystal (= tutorial finished)?
function sel_hub.is_finished(player)
	return sel_hub.is_done(player, STATION_COUNT)
end

-- Number of done stations (for the teacher overview).
function sel_hub.count_done(player)
	local _, n = get_progress(player):gsub("1", "")
	return n
end

-- Short visual summary for the teacher, e.g. "##----"
function sel_hub.progress_bar(player)
	return (get_progress(player):gsub("1", "#"):gsub("0", "-"))
end

-- Show the icon row (if not already shown) and refresh it.
function sel_hub.show_hud(player)
	local name = player:get_player_name()
	if not hud_ids[name] then
		hud_ids[name] = {}
		for i = 1, STATION_COUNT do
			hud_ids[name][i] = player:hud_add({
				type = "image",
				position = {x = 0.5, y = 0},   -- top centre of the screen
				alignment = {x = 0, y = 1},
				offset = {x = (i - 3.5) * ICON_SPACING, y = 12},
				scale = {x = ICON_SIZE / 16, y = ICON_SIZE / 16},
				text = icon_texture(i, sel_hub.is_done(player, i)),
			})
		end
		return
	end
	for i = 1, STATION_COUNT do
		player:hud_change(hud_ids[name][i], "text",
			icon_texture(i, sel_hub.is_done(player, i)))
	end
end

function sel_hub.hide_hud(player)
	local name = player:get_player_name()
	if hud_ids[name] then
		for _, id in ipairs(hud_ids[name]) do
			player:hud_remove(id)
		end
		hud_ids[name] = nil
	end
end

-- Mark station i as done. Returns true if it was NOT done before
-- (so the caller can play the big "first time" feedback).
function sel_hub.mark_done(player, i)
	local s = get_progress(player)
	if s:sub(i, i) == "1" then
		return false
	end
	s = s:sub(1, i - 1) .. "1" .. s:sub(i + 1)
	player:get_meta():set_string(META_KEY, s)
	sel_hub.show_hud(player)
	return true
end

-- Forget all progress of a player (teacher command).
function sel_hub.reset_progress(player)
	player:get_meta():set_string(META_KEY, "")
	sel_hub.show_hud(player)
end

-- If the Hub has moved since this player last played (an older world),
-- bring them to the new Hub. Otherwise they would stand at the old,
-- abandoned Hub and find no paths. Returns true if the player was moved.
function sel_hub.check_location(player)
	local meta = player:get_meta()
	if meta:get_int("sel_hub:location") == sel_hub.LOCATION_VERSION then
		return false
	end
	meta:set_int("sel_hub:location", sel_hub.LOCATION_VERSION)
	player:set_pos(sel_hub.layout.spawn)
	return true
end

-- On join: unfinished children see the icon row; finished children get
-- their Builder's Tool back if it went missing (e.g. put into a chest).
core.register_on_joinplayer(function(player)
	sel_hub.check_location(player)
	if sel_hub.is_finished(player) then
		sel_core.ensure_tool(player)
		sel_flower.ensure_flower(player)
	else
		sel_hub.show_hud(player)
	end
end)

core.register_on_leaveplayer(function(player)
	hud_ids[player:get_player_name()] = nil
end)
