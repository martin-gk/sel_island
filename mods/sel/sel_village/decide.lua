--[[
    decide.lua - the steps of the Village Decision
    ==============================================

    States (stored in the world, so a restart does not lose them):

      "gather"      mining gems, listening to both sides
         | everyone on the Decision Stone for 3 s (all have heard both)
      "decide"      the pedestals sparkle and wait for a gemstone
         | first gemstone on a pedestal
      "build_gold"  everyone has gem lamps; goal: DECOR_GOAL lamps on the square
      "build_blue"  everyone has planks; goal: every block of the gap filled
         | goal reached
      "done"        celebration, home pad - until /sel village_reset
]]

local S = sel_village.S
local L = sel_village.layout
local storage = core.get_mod_storage()
local KIT_KEY = "sel_village:kit_round"

local VALID = {gather = true, decide = true, build_gold = true, build_blue = true, done = true}
sel_village.state = VALID[storage:get_string("state")] and storage:get_string("state") or "gather"

local function set_state(state)
	sel_village.state = state
	storage:set_string("state", state)
end

-- The round number: +1 with every reset, so kits are handed out again.
local function round()
	return math.max(1, storage:get_int("round"))
end

----------------------------------------------------------------------------
-- Step 2: everyone on the Decision Stone
----------------------------------------------------------------------------
local function on_stone(player)
	return sel_core.in_box(sel_core.pos_under(player), L.stone_min, L.stone_max)
end

local last_reminder = 0 -- so the "listen first" picture is not shown constantly

sel_core.register_hold({
	seconds = sel_village.HOLD_SECONDS,
	countdown = true,

	check = function()
		if sel_village.state ~= "gather" then
			return {}, false
		end
		local everyone = sel_village.participants()
		local standing = {}
		for _, player in ipairs(everyone) do
			if on_stone(player) then
				table.insert(standing, player)
			end
		end
		if #everyone == 0 or #standing < #everyone then
			return standing, false -- somebody is not on the stone (yet)
		end

		-- Everybody is on the stone. It only counts if all have heard both
		-- sides. If not: show those children whom they still have to
		-- listen to (the first picture of that story), every few seconds.
		local all_heard = true
		local now = core.get_us_time() / 1e6
		local remind = now - last_reminder > 4
		for _, player in ipairs(everyone) do
			if not sel_village.heard_both(player) then
				all_heard = false
				if remind then
					local missing = sel_core.has_heard(player, "mayor")
						and "sel_village_child_1.png" or "sel_village_mayor_1.png"
					sel_core.show_hint(player, missing, 3)
					sel_core.play("sel_core_reset", player)
				end
			end
		end
		if not all_heard and remind then
			last_reminder = now
		end
		return standing, all_heard
	end,

	on_complete = function(players)
		set_state("decide")
		sel_core.play("sel_core_success", L.stone_min)
		for _, player in ipairs(players) do
			sel_core.show_hint(player, "sel_village_choice.png", 5)
		end
	end,
})

----------------------------------------------------------------------------
-- Step 3: the pedestals
----------------------------------------------------------------------------
-- How many blocks does each child get, so that `needed` can be reached
-- together (with two spare)? At least `minimum`.
local function share(needed, minimum)
	local n = math.max(1, #sel_village.participants())
	return math.max(minimum, math.ceil(needed / n) + 2)
end

-- Hand out the blocks for the chosen task (once per round and child).
local function give_kit(player)
	local meta = player:get_meta()
	if meta:get_int(KIT_KEY) == round() then
		return false
	end
	meta:set_int(KIT_KEY, round())
	if sel_village.state == "build_gold" then
		-- gem lamps in three colours
		local each = math.ceil(share(sel_village.DECOR_GOAL, 6) / #sel_village.LAMPS)
		for _, color in ipairs(sel_village.LAMPS) do
			sel_core.give(player, "sel_village:lamp_" .. color .. " " .. each)
		end
	else
		local gap = (L.gap_max.x - L.gap_min.x + 1) * (L.gap_max.z - L.gap_min.z + 1)
		sel_core.give(player, "sel_village:plank " .. share(gap, 6))
	end
	sel_core.sparkle(player:get_pos(), sel_core.colors.gold, 25)
	return true
end
sel_village.give_kit = give_kit

-- Called when a pedestal is right-clicked (see nodes.lua).
function sel_village.on_pedestal(choice, clicker, itemstack)
	if sel_village.state ~= "decide" or not (clicker and clicker:is_player())
			or itemstack:get_name() ~= "sel_village:gem" then
		return itemstack -- not the time, or no gemstone in the hand
	end
	itemstack:take_item()

	-- the choice is made
	local pos = choice == "gold" and L.pedestal_gold or L.pedestal_blue
	core.swap_node(pos, {name = "sel_village:pedestal_" .. choice .. "_on"})
	sel_core.sparkle(pos, choice == "gold" and sel_core.colors.gold or sel_core.colors.blue, 60)
	sel_core.play("sel_core_success", pos)
	set_state("build_" .. choice)
	storage:set_string("chosen_by", clicker:get_player_name())

	local outcome = choice == "gold" and "sel_village_mayor_3.png" or "sel_village_child_4.png"
	for _, player in ipairs(sel_village.participants()) do
		give_kit(player)
		sel_core.show_hint(player, outcome, 4)
	end
	return itemstack
end

----------------------------------------------------------------------------
-- Step 4: building - how far are they?
----------------------------------------------------------------------------
-- Progress of the chosen task, 0 .. 1.
function sel_village.progress()
	if sel_village.state == "build_gold" then
		local lamps = core.find_nodes_in_area(L.decor_min, L.decor_max, {"group:sel_village_decor"})
		return math.min(1, #lamps / sel_village.DECOR_GOAL)
	elseif sel_village.state == "build_blue" then
		local planks = core.find_nodes_in_area(L.gap_min, L.gap_max, {"group:sel_village_plank"})
		local gap = (L.gap_max.x - L.gap_min.x + 1) * (L.gap_max.z - L.gap_min.z + 1)
		return #planks / gap
	end
	return 0
end

----------------------------------------------------------------------------
-- Step 5: celebration
----------------------------------------------------------------------------
local function celebrate()
	local where = sel_village.state == "build_gold" and L.stone_min or L.gap_min
	set_state("done")
	core.set_node(L.home_pad, {name = "sel_core:home_pad"})
	sel_core.fireworks(vector.offset(where, 0, 1, 0), 8)
	core.after(2, function()
		sel_core.fireworks(vector.offset(L.stone_min, 1, 1, 1), 6)
	end)
	core.log("action", "[sel_village] the village task is finished")
end

-- Twice a second: icons, kits for late-comers, sparkling pedestals, goal.
local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.5 then
		return
	end
	timer = 0
	local state = sel_village.state
	local progress = sel_village.progress()

	if state == "decide" then
		sel_core.ambient_sparkle(L.pedestal_gold, sel_core.colors.gold)
		sel_core.ambient_sparkle(L.pedestal_blue, sel_core.colors.blue)
	elseif state == "build_gold" or state == "build_blue" then
		for _, player in ipairs(sel_village.participants()) do
			give_kit(player) -- children who arrive later get their blocks too
		end
		if progress >= 1 then
			celebrate()
		end
	end
	sel_village.update_huds(progress)
end)

----------------------------------------------------------------------------
-- Reset for the next group
----------------------------------------------------------------------------
function sel_village.reset()
	-- take away everything that was built
	local built = core.find_nodes_in_area(L.area_min, L.area_max,
		{"group:sel_village_decor", "group:sel_village_plank"})
	for _, pos in ipairs(built) do
		core.remove_node(pos)
	end
	-- pedestals without gemstone, all deposits full, no home pad
	core.set_node(L.pedestal_gold, {name = "sel_village:pedestal_gold"})
	core.set_node(L.pedestal_blue, {name = "sel_village:pedestal_blue"})
	for _, gem in ipairs(L.gems) do
		core.set_node({x = gem.x, y = L.ground_y + 1, z = gem.z}, {name = "sel_village:gem_ore"})
	end
	core.set_node(L.home_pad, {name = "default:sandstonebrick"})

	-- everyone online: empty the pockets, forget the two stories
	for _, player in ipairs(core.get_connected_players()) do
		local inv = player:get_inventory()
		inv:remove_item("main", "sel_village:gem 999")
		inv:remove_item("main", "sel_village:plank 999")
		for _, color in ipairs(sel_village.LAMPS) do
			inv:remove_item("main", "sel_village:lamp_" .. color .. " 999")
		end
		sel_core.forget_heard(player, "mayor")
		sel_core.forget_heard(player, "village_child")
	end
	storage:set_int("round", round() + 1)
	set_state("gather")
end

core.register_chatcommand("sel_village_reset", {
	description = S("Village Decision: clean up and start again"),
	privs = {sel_teacher = true},
	func = function()
		sel_village.reset()
		return true, S("The Village Decision is ready for the next group.")
	end,
})
