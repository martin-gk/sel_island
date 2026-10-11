--[[
    kit.lua - who takes part, the kit, and the rules of the field
    =============================================================

    Whoever (child) walks into the activity area takes part and receives
    the kit once per round: 15 channel blocks and 1 pump station.
    A "round" lasts until the teacher resets the activity
    (/sel irrigation_reset); the round number is stored in the world, and
    each player remembers the last round they got a kit for.
    (Whoever runs out can get a few more channel blocks from the
    spare-parts crate beside the Inventor, see nodes.lua.)

    Inside the area children can only place and dig channel blocks and
    pumps (and plant their own Breathing Flower). The field itself, the
    pool, the garden, the boulders, the fence and the tree cannot be
    changed. (Grass tufts simply give way to a channel block.)

    Teachers are not part of this (no kit, no restrictions) - unless they
    switch on child mode (/sel child).
]]

local L = sel_irrigation.layout
local storage = core.get_mod_storage()
local ROUND_KEY = "sel_irrigation:round"

function sel_irrigation.in_area(pos)
	return sel_core.in_box(pos, L.area_min, L.area_max)
end

-- All children (non-teachers) who are inside the activity area right now.
function sel_irrigation.participants()
	local list = {}
	for _, player in ipairs(core.get_connected_players()) do
		if sel_irrigation.in_area(player:get_pos())
				and not sel_core.is_teacher(player:get_player_name()) then
			table.insert(list, player)
		end
	end
	return list
end

-- The current round (starts at 1, +1 with every reset).
function sel_irrigation.round()
	return math.max(1, storage:get_int("round"))
end

function sel_irrigation.next_round()
	storage:set_int("round", sel_irrigation.round() + 1)
end

-- Give the kit if this player has not received it in this round yet.
-- Returns true if it was given.
function sel_irrigation.give_kit(player)
	local meta = player:get_meta()
	if meta:get_int(ROUND_KEY) == sel_irrigation.round() then
		return false
	end
	meta:set_int(ROUND_KEY, sel_irrigation.round())
	sel_core.give(player, "sel_irrigation:channel " .. sel_irrigation.KIT_CHANNELS)
	sel_core.give(player, "sel_irrigation:pump " .. sel_irrigation.KIT_PUMPS)
	sel_core.sparkle(player:get_pos(), sel_core.colors.blue, 25)
	sel_core.play("sel_core_chime", player, 0.7)
	return true
end

-- Twice a second: hand the kit to children who just walked in.
local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then
		return
	end
	timer = 0
	for _, player in ipairs(sel_irrigation.participants()) do
		sel_irrigation.give_kit(player)
	end
end)

----------------------------------------------------------------------------
-- The rules: digging and placing inside the area
----------------------------------------------------------------------------
local function is_channel(name)
	return core.get_item_group(name, "sel_channel") > 0
end
local function is_flower(name)
	return core.get_item_group(name, "sel_flower") > 0
end

-- Digging (and placing, which Luanti checks at the still-empty spot).
sel_core.protect_zone({
	name = "irrigation field",
	minp = L.area_min,
	maxp = L.area_max,
	allow = function(pos)
		local node = core.get_node(pos).name
		local def = core.registered_nodes[node]
		if def and def.buildable_to then
			return true -- empty spot: placing is checked below
		end
		-- channel blocks and pumps (a pump also checks its owner itself),
		-- and a child's own Breathing Flower
		return is_channel(node) or is_flower(node)
	end,
})

-- Placing: undo it if the block is not a channel block, pump or flower.
-- Returning true tells Luanti NOT to take the block from the inventory.
core.register_on_placenode(function(pos, newnode, placer, oldnode)
	if not (placer and placer:is_player() and sel_irrigation.in_area(pos)) then
		return
	end
	if sel_core.is_teacher(placer:get_player_name())
			or is_channel(newnode.name) or is_flower(newnode.name) then
		return
	end
	core.set_node(pos, oldnode) -- as if nothing happened
	return true
end)
