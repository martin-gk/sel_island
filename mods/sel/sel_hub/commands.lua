--[[
    commands.lua - chat commands for the teacher
    ============================================

    All commands need the "sel_teacher" privilege (see sel_core/teacher.lua).

      /sel_hub                   teleport yourself to the Hub
      /sel_hub all               teleport EVERYONE to the Hub (gather the class)
      /sel_hub <name>            teleport one child to the Hub
      /sel_tutorial              show every child's tutorial progress
      /sel_tutorial_reset <name> start the tutorial again for one child
      /sel_tutorial_reset all    ... for everyone online
      /sel_hub_rebuild           rebuild the Hub (repairs any damage)
]]

local S = sel_hub.S
local L = sel_hub.layout

-- The Hub is also a site for /sel_goto (see sel_core/sites.lua).
sel_core.register_site("hub", L.spawn)
sel_core.register_site("crossroads", vector.offset(L.crossroads, 0, 1, 0))

-- Teleport a player to the spawn point, spreading players a little so a
-- whole class does not land inside each other.
local function to_hub(player)
	local offset = {x = math.random(-3, 3), y = 0, z = math.random(-3, 3)}
	player:set_pos(vector.add(L.spawn, offset))
end

core.register_chatcommand("sel_hub", {
	params = S("[all | <name>]"),
	description = S("Teleport to the Hub (yourself, everyone, or one player)"),
	privs = {sel_teacher = true},
	func = function(name, param)
		if param == "" then
			to_hub(core.get_player_by_name(name))
			return true
		elseif param == "all" then
			for _, player in ipairs(core.get_connected_players()) do
				to_hub(player)
			end
			return true, S("Everyone is at the Hub.")
		end
		local target = core.get_player_by_name(param)
		if not target then
			return false, S("Player @1 is not online.", param)
		end
		to_hub(target)
		return true, S("@1 is at the Hub.", param)
	end,
})

core.register_chatcommand("sel_tutorial", {
	description = S("Show the tutorial progress of all players"),
	privs = {sel_teacher = true},
	func = function(name)
		local lines = {S("Tutorial progress (# = station done):")}
		for _, player in ipairs(core.get_connected_players()) do
			table.insert(lines, string.format("  %-16s %s  %d/6",
				player:get_player_name(),
				sel_hub.progress_bar(player),
				sel_hub.count_done(player)))
		end
		return true, table.concat(lines, "\n")
	end,
})

core.register_chatcommand("sel_tutorial_reset", {
	params = S("<name> | all"),
	description = S("Start the tutorial again for a player (or everyone)"),
	privs = {sel_teacher = true},
	func = function(name, param)
		if param == "all" then
			for _, player in ipairs(core.get_connected_players()) do
				sel_hub.reset_progress(player)
			end
			return true, S("Tutorial reset for everyone.")
		end
		local target = core.get_player_by_name(param)
		if not target then
			return false, S("Player @1 is not online.", param)
		end
		sel_hub.reset_progress(target)
		return true, S("Tutorial reset for @1.", param)
	end,
})

core.register_chatcommand("sel_hub_rebuild", {
	description = S("Rebuild the Hub and the tutorial course"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_hub.build(function()
			core.chat_send_player(name, S("The Hub has been rebuilt."))
		end)
		return true, S("Rebuilding the Hub ...")
	end,
})
