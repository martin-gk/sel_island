--[[
    util.lua - small general helpers
    ================================
]]

-- Position of the block a player is standing on.
--
-- A player's position is at their feet. Standing on a block at height y,
-- the feet are at y + 0.5 (block centres are whole numbers). So we look
-- 0.1 below the feet and round to the nearest block.
function sel_core.pos_under(player)
	local pos = player:get_pos()
	return vector.round(vector.offset(pos, 0, -0.1, 0))
end

-- Name of the block a player is standing on (e.g. "default:dirt").
function sel_core.node_under(player)
	return core.get_node(sel_core.pos_under(player)).name
end

-- Is `pos` inside the box from `minp` to `maxp` (inclusive)?
function sel_core.in_box(pos, minp, maxp)
	return pos.x >= minp.x and pos.x <= maxp.x
		and pos.y >= minp.y and pos.y <= maxp.y
		and pos.z >= minp.z and pos.z <= maxp.z
end

-- Returns a list of all players standing on one of the given positions.
-- `positions` is a list of block positions, e.g. the two "together" plates.
-- Result: { {player = <ObjectRef>, index = <which position>}, ... }
function sel_core.players_on_positions(positions)
	local result = {}
	for _, player in ipairs(core.get_connected_players()) do
		local under = sel_core.pos_under(player)
		for i, p in ipairs(positions) do
			if vector.equals(under, p) then
				table.insert(result, {player = player, index = i})
				break
			end
		end
	end
	return result
end

-- Give an item stack to a player; whatever does not fit is dropped at
-- their feet so nothing is ever lost.
function sel_core.give(player, itemstring)
	local leftover = player:get_inventory():add_item("main", itemstring)
	if not leftover:is_empty() then
		core.add_item(player:get_pos(), leftover)
	end
end
