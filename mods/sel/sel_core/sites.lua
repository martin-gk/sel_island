--[[
    sites.lua - named places and the /sel_goto command
    ==================================================

    Each activity registers where children should arrive:

        sel_core.register_site("lake", {x = -12, y = 3, z = 48})

    The teacher then moves the class between activities with:

        /sel_goto            list all sites
        /sel_goto lake       teleport yourself to the lake
        /sel_goto lake all   teleport EVERYONE to the lake
        /sel_goto lake Anna  teleport one child

    Also defines the HOME PAD block (bottom of this file).
]]

local S = sel_core.S
local sites = {} -- name -> position

function sel_core.register_site(name, pos)
	sites[name] = pos
end

function sel_core.get_site(name)
	return sites[name]
end

-- Teleport a player to a site, spread out a little so a whole class does
-- not land inside each other.
function sel_core.send_to_site(player, name)
	local pos = sites[name]
	local offset = {x = math.random(-2, 2), y = 0, z = math.random(-1, 1)}
	player:set_pos(vector.add(pos, offset))
end

core.register_chatcommand("sel_goto", {
	params = S("<site> [all | <name>]"),
	description = S("Teleport to an activity site (yourself, everyone, or one player)"),
	privs = {sel_teacher = true},
	func = function(name, param)
		local site, who = param:match("^(%S+)%s*(%S*)$")
		if not site or not sites[site] then
			local names = {}
			for n in pairs(sites) do
				table.insert(names, n)
			end
			table.sort(names)
			return false, S("Sites: @1", table.concat(names, ", "))
		end
		local targets
		if who == "" then
			targets = {core.get_player_by_name(name)}
		elseif who == "all" then
			targets = core.get_connected_players()
		else
			local p = core.get_player_by_name(who)
			if not p then
				return false, S("Player @1 is not online.", who)
			end
			targets = {p}
		end
		for _, player in ipairs(targets) do
			sel_core.send_to_site(player, site)
		end
		return true
	end,
})

----------------------------------------------------------------------------
-- Home pad: a glowing purple block. Stepping on it brings the child back
-- to the Hub. Activities place one where an adventure ends ("a way back
-- home appears"). Purple is the Hub's colour (crystal, crossroads centre).
----------------------------------------------------------------------------
core.register_node("sel_core:home_pad", {
	description = "SEL home pad",
	tiles = {"sel_core_path.png^[multiply:#c77dff"},
	light_source = 12,
	groups = {sel_unbreakable = 1},
	diggable = false,
	on_blast = function() end,
	_sel_on_step = function(pos, player)
		sel_core.sparkle(pos, sel_core.colors.purple, 30)
		sel_core.play("sel_core_chime", player)
		sel_core.send_to_site(player, "hub")
	end,
})
