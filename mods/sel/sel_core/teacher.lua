--[[
    teacher.lua - who is the teacher? (and "child mode" for testing)
    ================================================================

    The teacher gets the privilege "sel_teacher". It allows:
      * all /sel ... chat commands
      * building and digging inside protected zones (Hub, docks, ...)
      * using the Teacher's Wand, placing and removing Breathing Flowers

    On a server, the admin grants it with:   /grant <name> sel_teacher
    In singleplayer the local player is the teacher automatically (and
    Luanti does not allow revoking that privilege there).

    CHILD MODE - to try everything exactly as a child would:
        /sel child      switch child mode on / off
    While it is on, the teacher is treated like a child everywhere
    (protected zones apply, the wand does nothing, flowers cannot be
    placed or removed). The /sel commands keep working, so the teacher can
    always switch back. Child mode is remembered until switched off.

    The /sel command
    ----------------
    Every teacher command exists in two spellings:
        /sel_wand        (one word)
        /sel wand        (with a space - easier to type and remember)
    Typing just  /sel  lists all of them.
]]

local S = sel_core.S
local CHILD_KEY = "sel_core:child_mode"

core.register_privilege("sel_teacher", {
	description = S("Teacher of SEL Island: may use /sel commands and build anywhere"),
	give_to_singleplayer = true,
	give_to_admin = true,
})

-- Is this player currently in child mode?
function sel_core.in_child_mode(name)
	local player = core.get_player_by_name(name)
	return player ~= nil and player:get_meta():get_int(CHILD_KEY) == 1
end

-- Returns true if the player with this name is a teacher (and not
-- pretending to be a child at the moment).
function sel_core.is_teacher(name)
	return core.check_player_privs(name, {sel_teacher = true})
		and not sel_core.in_child_mode(name)
end

core.register_chatcommand("sel_child", {
	description = S("Switch child mode on/off (play exactly like a child)"),
	privs = {sel_teacher = true},
	func = function(name)
		local player = core.get_player_by_name(name)
		if not player then
			return false
		end
		local on = not sel_core.in_child_mode(name)
		player:get_meta():set_int(CHILD_KEY, on and 1 or 0)
		if on then
			return true, S("Child mode ON: you now play like a child. Type /sel child again to switch back.")
		end
		return true, S("Child mode OFF: you are the teacher again.")
	end,
})

-- Remind the teacher on joining that child mode is still on.
core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if sel_core.in_child_mode(name) then
		core.chat_send_player(name, S("Child mode is ON. Type /sel child to switch it off."))
	end
end)

----------------------------------------------------------------------------
-- /sel <command> ...  =  /sel_<command> ...
----------------------------------------------------------------------------
core.register_chatcommand("sel", {
	params = S("<command> [...]"),
	description = S("SEL Island teacher commands. Type /sel to list them."),
	privs = {sel_teacher = true},
	func = function(name, param)
		local sub, rest = param:match("^(%S+)%s*(.*)$")
		local def = sub and core.registered_chatcommands["sel_" .. sub]
		if def then
			if not core.check_player_privs(name, def.privs or {}) then
				return false, S("You are not allowed to use this command.")
			end
			return def.func(name, rest)
		end

		-- no (or unknown) command: list everything that starts with sel_
		local names = {}
		for cmd in pairs(core.registered_chatcommands) do
			if cmd:sub(1, 4) == "sel_" then
				table.insert(names, cmd:sub(5))
			end
		end
		table.sort(names)
		local lines = {S("Teacher commands:")}
		for _, cmd in ipairs(names) do
			local d = core.registered_chatcommands["sel_" .. cmd]
			table.insert(lines, "  /sel " .. cmd .. " " .. (d.params or "")
				.. "  -  " .. (d.description or ""))
		end
		return true, table.concat(lines, "\n")
	end,
})
