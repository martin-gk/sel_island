--[[
    commands.lua - teacher command for the Breathing Flower
    =======================================================

      /sel_flower   puts a Breathing Flower into your inventory.
                    Place it with right click; remove it by digging it.
]]

local S = sel_flower.S

core.register_chatcommand("sel_flower", {
	description = S("Get a Breathing Flower to place"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_core.give(core.get_player_by_name(name), "sel_flower:flower")
		return true, S("Place the flower with a right click. Dig it to remove it.")
	end,
})
