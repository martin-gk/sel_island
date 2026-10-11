--[[
    story_area.lua - the story area and the fence around it
    =======================================================

    The world has two parts:

      INSIDE the fence  - the STORY AREA: Hub, crossroads, paths, the
                          Breathing Garden and the activities. Here the
                          world stays as it is: children cannot dig or
                          build - except what an activity asks them to do
                          (the vessel on the lake, the channel, ...) and
                          planting their own Breathing Flower.
      OUTSIDE the fence - free land: explore, mine and build as you like.

    The story area is one big box (STORY_MIN .. STORY_MAX below). A white
    fence stands on its border wherever there is normal land. Where the
    border runs through the lake or along the high cliff in the south-west
    there is no fence - water and rock are borders of their own.
    The fence has OPENINGS (marked by two tall posts with lamps): children
    are free to walk out and come back in. The fence is a sign that says
    "from here on you may dig and build", not a wall to keep anyone in.

    How the rule works (KISS):
      * the box is a protected zone (protect.lua): no digging, no placing
      * wherever ANOTHER zone covers the spot (Hub, lake, field, village),
        the story area keeps out of it - that activity has its own rules
      * a child's own Breathing Flower may be planted and picked up anywhere

    So an activity that lets children build must register its building
    place as a zone of its own (sel_core.protect_zone with `allow`).

    Teachers are never restricted (unless in child mode, /sel child).
]]

----------------------------------------------------------------------------
-- CONFIG: where the story area is
----------------------------------------------------------------------------
-- Bump to rebuild the fence on the next start (or /sel fence_rebuild).
local FENCE_VERSION = 1

-- The box. Only x and z matter; it reaches from far below to far above.
local STORY_MIN = {x = -727, y = -200, z = -873}
local STORY_MAX = {x = -598, y = 400, z = -724}

-- Openings in the fence: no fence where x and z are inside one of these.
local OPENINGS = {
	{x1 = -598, x2 = -598, z1 = -836, z2 = -834}, -- east: behind the fields
	{x1 = -598, x2 = -598, z1 = -790, z2 = -788}, -- east: towards the beach
	{x1 = -652, x2 = -650, z1 = -873, z2 = -873}, -- south
	{x1 = -690, x2 = -688, z1 = -873, z2 = -873}, -- south: behind the village
	{x1 = -727, x2 = -727, z1 = -861, z2 = -859}, -- west: beside the village
}

-- No fence on ground higher than this (the cliff is its own border).
local MAX_FENCE_Y = 60

sel_core.story_area = {minp = STORY_MIN, maxp = STORY_MAX, openings = OPENINGS}

----------------------------------------------------------------------------
-- The fence block
----------------------------------------------------------------------------
-- Looks like a light wooden fence and joins up with its neighbours, but
-- cannot be dug (also not from the free side). Like every fence it is a
-- bit too high to jump over - that is what the openings are for.
core.register_node("sel_core:fence", {
	description = "SEL story area fence",
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"default_fence_aspen_wood.png"},
	node_box = {
		type = "connected",
		fixed = {-1/8, -1/2, -1/8, 1/8, 1/2, 1/8},
		connect_front = {{-1/16, 3/16, -1/2, 1/16, 5/16, -1/8}, {-1/16, -5/16, -1/2, 1/16, -3/16, -1/8}},
		connect_left = {{-1/2, 3/16, -1/16, -1/8, 5/16, 1/16}, {-1/2, -5/16, -1/16, -1/8, -3/16, 1/16}},
		connect_back = {{-1/16, 3/16, 1/8, 1/16, 5/16, 1/2}, {-1/16, -5/16, 1/8, 1/16, -3/16, 1/2}},
		connect_right = {{1/8, 3/16, -1/16, 1/2, 5/16, 1/16}, {1/8, -5/16, -1/16, 1/2, -3/16, 1/16}},
	},
	collision_box = {
		type = "connected",
		fixed = {-1/8, -1/2, -1/8, 1/8, 1, 1/8},
		connect_front = {-1/8, -1/2, -1/2, 1/8, 1, -1/8},
		connect_left = {-1/2, -1/2, -1/8, -1/8, 1, 1/8},
		connect_back = {-1/8, -1/2, 1/8, 1/8, 1, 1/2},
		connect_right = {1/8, -1/2, -1/8, 1/2, 1, 1/8},
	},
	connects_to = {"sel_core:fence", "sel_core:post"},
	groups = {sel_unbreakable = 1, fence = 1},
	diggable = false,
	on_blast = function() end,
})

----------------------------------------------------------------------------
-- The rule
----------------------------------------------------------------------------
function sel_core.in_story_area(pos)
	return sel_core.in_box(pos, STORY_MIN, STORY_MAX)
end

local story_zone -- defined below; needed by has_own_rules

-- Does an activity (another zone) cover this spot?
local function has_own_rules(pos)
	return sel_core.in_other_zone(pos, story_zone)
end

local function is_flower(name)
	return core.get_item_group(name, "sel_flower") > 0
end

story_zone = {
	name = "story area",
	minp = STORY_MIN,
	maxp = STORY_MAX,
	allow = function(pos)
		if has_own_rules(pos) then
			return true -- the activity decides
		end
		local name = core.get_node(pos).name
		local def = core.registered_nodes[name]
		-- an empty spot (air, a grass tuft): placing is checked below;
		-- and a child's own Breathing Flower can be picked up again
		return (def and def.buildable_to) or is_flower(name)
	end,
}
sel_core.protect_zone(story_zone)

-- Placing: undo it unless it is a Breathing Flower.
-- Returning true tells Luanti NOT to take the block from the inventory.
core.register_on_placenode(function(pos, newnode, placer, oldnode)
	if not (placer and placer:is_player() and sel_core.in_story_area(pos)) then
		return
	end
	if sel_core.is_teacher(placer:get_player_name()) or is_flower(newnode.name)
			or has_own_rules(pos) then
		return
	end
	core.set_node(pos, oldnode) -- as if nothing happened
	return true
end)

----------------------------------------------------------------------------
-- Building the fence
----------------------------------------------------------------------------
local storage = core.get_mod_storage()

local function in_opening(x, z)
	for _, o in ipairs(OPENINGS) do
		if x >= o.x1 and x <= o.x2 and z >= o.z1 and z <= o.z2 then
			return true
		end
	end
	return false
end

-- Ground height for a fence post at (x, z), or nil where no fence
-- belongs: over water and on the high cliff.
local function fence_ground(x, z)
	local y = sel_core.path_height(x, z)
	local below = core.registered_nodes[core.get_node({x = x, y = y - 1, z = z}).name]
	if y > MAX_FENCE_Y or (below and below.liquidtype ~= "none") then
		return nil
	end
	return y
end

-- One straight side of the box, given as a list of {x=, z=} columns.
local function build_side(columns)
	local ground = {}
	for i, c in ipairs(columns) do
		ground[i] = fence_ground(c.x, c.z)
	end
	for i, c in ipairs(columns) do
		local y = ground[i]
		if y and not in_opening(c.x, c.z) then
			-- on a slope: as high as the higher neighbour's foot, so the
			-- fence has no holes (but never a tower)
			local top = math.max(y, (ground[i - 1] or y) - 1, (ground[i + 1] or y) - 1)
			top = math.min(top, y + 3)
			for yy = y + 1, top + 1 do
				core.set_node({x = c.x, y = yy, z = c.z}, {name = "sel_core:fence"})
			end
		elseif y then
			-- an opening: mark both ends with a tall post and a lamp
			local before = columns[i - 1] and in_opening(columns[i - 1].x, columns[i - 1].z)
			local after = columns[i + 1] and in_opening(columns[i + 1].x, columns[i + 1].z)
			if not (before and after) then
				for yy = y + 1, y + 3 do
					core.set_node({x = c.x, y = yy, z = c.z}, {name = "sel_core:post"})
				end
				core.set_node({x = c.x, y = y + 4, z = c.z}, {name = "default:meselamp"})
			end
		end
	end
end

-- Build one side after making sure its strip of the map exists.
local function build_side_when_loaded(columns, next_step)
	local first, last = columns[1], columns[#columns]
	sel_core.when_loaded({x = first.x - 1, y = -8, z = first.z - 1},
		{x = last.x + 1, y = 80, z = last.z + 1}, function()
			build_side(columns)
			next_step()
		end)
end

function sel_core.build_story_fence(done)
	local a, b = STORY_MIN, STORY_MAX
	local sides = {{}, {}, {}, {}}
	for x = a.x, b.x do
		table.insert(sides[1], {x = x, z = a.z}) -- south
		table.insert(sides[2], {x = x, z = b.z}) -- north
	end
	for z = a.z + 1, b.z - 1 do
		table.insert(sides[3], {x = a.x, z = z}) -- west
		table.insert(sides[4], {x = b.x, z = z}) -- east
	end
	core.log("action", "[sel_core] building the story area fence ...")
	local i = 0
	local function next_side()
		i = i + 1
		if sides[i] then
			build_side_when_loaded(sides[i], next_side)
			return
		end
		storage:set_int("fence_version", FENCE_VERSION)
		sel_core.story_area.fence_built = true
		core.log("action", "[sel_core] story area fence built (version " .. FENCE_VERSION .. ")")
		if done then
			done()
		end
	end
	next_side()
end

-- Build on first start / when FENCE_VERSION is increased (after the sites).
core.after(10, function()
	if storage:get_int("fence_version") < FENCE_VERSION then
		sel_core.build_story_fence()
	else
		sel_core.story_area.fence_built = true
	end
end)

core.register_chatcommand("sel_fence_rebuild", {
	description = sel_core.S("Rebuild the fence around the story area"),
	privs = {sel_teacher = true},
	func = function(name)
		sel_core.build_story_fence(function()
			core.chat_send_player(name, sel_core.S("The fence has been rebuilt."))
		end)
		return true, sel_core.S("Rebuilding the fence ...")
	end,
})
