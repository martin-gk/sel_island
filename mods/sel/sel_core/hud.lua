--[[
    hud.lua - big centre-screen text (countdowns 3, 2, 1) and picture hints
    =======================================================================

    Numbers are fine for 9-10 year olds even though we avoid sentences.
    Each player can show at most one "big text" at a time.
]]

local big_text_ids = {} -- player name -> HUD element id

-- Show (or update) a big text in the middle of a player's screen.
function sel_core.show_big_text(player, text, color)
	local name = player:get_player_name()
	local id = big_text_ids[name]
	if id then
		player:hud_change(id, "text", text)
		player:hud_change(id, "number", color or 0xFFFFFF)
		return
	end
	big_text_ids[name] = player:hud_add({
		type = "text",
		position = {x = 0.5, y = 0.35},
		alignment = {x = 0, y = 0},
		text = text,
		number = color or 0xFFFFFF, -- text colour as 0xRRGGBB
		size = {x = 6, y = 0},      -- 6 times the normal font size
		style = 1,                  -- bold
		z_index = 100,
	})
end

-- Remove the big text from a player's screen (safe to call any time).
function sel_core.hide_big_text(player)
	local name = player:get_player_name()
	if big_text_ids[name] then
		player:hud_remove(big_text_ids[name])
		big_text_ids[name] = nil
	end
end

-- Forget HUD ids of players who leave (ids are per connection).
core.register_on_leaveplayer(function(player)
	big_text_ids[player:get_player_name()] = nil
end)

----------------------------------------------------------------------------
-- Picture hint: show one picture in the middle of the screen for a few
-- seconds (e.g. "you still need these materials"). No words needed.
----------------------------------------------------------------------------
local hint_ids = {} -- player name -> HUD element id

function sel_core.show_hint(player, texture, seconds)
	local name = player:get_player_name()
	if hint_ids[name] then
		player:hud_remove(hint_ids[name])
	end
	local id = player:hud_add({
		type = "image",
		position = {x = 0.5, y = 0.4},
		alignment = {x = 0, y = 0},
		scale = {x = 4, y = 4}, -- 64 px pictures -> 256 px on screen
		text = texture,
		z_index = 90,
	})
	hint_ids[name] = id
	core.after(seconds or 4, function()
		local p = core.get_player_by_name(name)
		-- only remove it if no newer hint has replaced it meanwhile
		if p and hint_ids[name] == id then
			p:hud_remove(id)
			hint_ids[name] = nil
		end
	end)
end

core.register_on_leaveplayer(function(player)
	hint_ids[player:get_player_name()] = nil
end)
