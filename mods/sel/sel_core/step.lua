--[[
    step.lua - "a player stepped onto this block"
    =============================================

    Any node can react to being stepped on by adding a field to its
    definition:

        core.register_node("mymod:marker", {
            ...
            _sel_on_step = function(pos, player)
                -- called ONCE when a player steps onto this kind of block
            end,
        })

    The callback fires when the type of block under the player CHANGES to
    this block. Walking across several identical blocks (e.g. a 3x3 crystal
    floor) therefore only fires once. Stepping off and on again fires again.
]]

local CHECK_INTERVAL = 0.2 -- seconds between checks (5 times per second)

local last_node = {} -- player name -> name of the block they stood on
local timer = 0

core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < CHECK_INTERVAL then
		return
	end
	timer = 0

	for _, player in ipairs(core.get_connected_players()) do
		local name = player:get_player_name()
		local pos = sel_core.pos_under(player)
		local node = core.get_node(pos).name

		-- Ignore "air" so a jump does not count as stepping off and on.
		if node ~= "air" and node ~= last_node[name] then
			last_node[name] = node
			local def = core.registered_nodes[node]
			if def and def._sel_on_step then
				def._sel_on_step(pos, player)
			end
		end
	end
end)

core.register_on_leaveplayer(function(player)
	last_node[player:get_player_name()] = nil
end)
