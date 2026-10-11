--[[
    npc.lua - story characters that "speak" in pictures
    ===================================================

    The Ferrymaster, the Mayor, the village child and the Inventor tell
    their part of the story with PICTURES, not text: when a child walks
    close, a strip of picture panels appears at the top of their screen,
    one panel after the other (like a comic). Walking away hides it.
    The pictures are meant to stay even when recorded voices are added
    later (a voice file can then be played at the same moment).

    For activity mods:

        sel_core.register_npc("ferrymaster", {
            skin   = "sel_lake_ferrymaster.png",   -- 64x32 player skin
            story  = {"sel_lake_story_1.png", ...}, -- 64x64 picture panels
            radius = 6,                            -- how close is "near"
            size   = 1,                            -- body size (0.75 = a child)
            on_heard = function(player) end,       -- optional: after the
                                                   -- LAST panel was shown
        })

        sel_core.spawn_npc("ferrymaster", pos, yaw)  -- place it in the world
        sel_core.has_heard(player, "ferrymaster")    -- saw the whole story?

    The NPC is an entity using Minetest Game's player model. It stands
    still, turns to face the nearest child and cannot be hurt.
    Right-clicking it shows the story again from the start.
]]

local PANEL_INTERVAL = 1.2  -- seconds between two panels appearing
local PANEL_SCALE = 2.5     -- 64 px pictures -> 160 px on screen
local PANEL_GAP = 170       -- px between panel centres
local CHECK_INTERVAL = 0.5  -- seconds between proximity checks
local LEAVE_EXTRA = 2       -- hide only when this much further than radius

local storage = core.get_mod_storage()
local defs = {}        -- npc id -> definition
local viewing = {}     -- player name -> {id=, huds={}, shown=, timer=}

function sel_core.register_npc(id, def)
	def.radius = def.radius or 6
	defs[id] = def
end

----------------------------------------------------------------------------
-- "Has heard" memory (player metadata), e.g. the Village Decision needs
-- children to have heard BOTH sides before deciding.
----------------------------------------------------------------------------
local function heard_key(id)
	return "sel_core:heard_" .. id
end

function sel_core.has_heard(player, id)
	return player:get_meta():get_int(heard_key(id)) == 1
end

function sel_core.forget_heard(player, id)
	player:get_meta():set_string(heard_key(id), "")
end

----------------------------------------------------------------------------
-- The entity
----------------------------------------------------------------------------
-- Each spawn of an NPC id gets a new "token". Old copies of the entity
-- (e.g. from before a rebuild) see that their token is outdated when they
-- are loaded and remove themselves. So there is never more than one.
local function current_token(id)
	return storage:get_int("npc_token_" .. id)
end

core.register_entity("sel_core:npc", {
	initial_properties = {
		visual = "mesh",
		mesh = "character.b3d",        -- from Minetest Game's player_api
		textures = {"character.png"},
		visual_size = {x = 1, y = 1},
		collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
		selectionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
		physical = true,
		static_save = true,
	},

	on_activate = function(self, staticdata)
		local data = core.deserialize(staticdata) or {}
		local def = defs[data.id or ""]
		if not def or data.token ~= current_token(data.id) then
			self.object:remove() -- unknown or outdated copy
			return
		end
		self.npc_id, self.token = data.id, data.token
		local size = def.size or 1 -- e.g. 0.75 for a child
		self.object:set_properties({
			textures = {def.skin},
			visual_size = {x = size, y = size},
			collisionbox = {-0.3 * size, 0.0, -0.3 * size, 0.3 * size, 1.7 * size, 0.3 * size},
			selectionbox = {-0.3 * size, 0.0, -0.3 * size, 0.3 * size, 1.7 * size, 0.3 * size},
		})
		self.object:set_armor_groups({immortal = 1})
		self.object:set_animation({x = 0, y = 79}, 30) -- "stand" animation
		self.turn_timer = 0
	end,

	get_staticdata = function(self)
		return core.serialize({id = self.npc_id, token = self.token})
	end,

	-- Once a second: turn towards the nearest player within 8 blocks.
	on_step = function(self, dtime)
		self.turn_timer = self.turn_timer + dtime
		if self.turn_timer < 1 then
			return
		end
		self.turn_timer = 0
		local pos = self.object:get_pos()
		local nearest, best
		for _, player in ipairs(core.get_connected_players()) do
			local d = vector.distance(pos, player:get_pos())
			if d < 8 and (not best or d < best) then
				nearest, best = player, d
			end
		end
		if nearest then
			local dir = vector.subtract(nearest:get_pos(), pos)
			self.object:set_yaw(math.atan2(-dir.x, dir.z))
		end
	end,

	-- Right click: show the story again from the first panel.
	on_rightclick = function(self, clicker)
		if clicker and clicker:is_player() then
			sel_core.show_story(clicker, self.npc_id)
		end
	end,
})

-- Put an NPC into the world (replaces any earlier copy of the same NPC).
function sel_core.spawn_npc(id, pos, yaw)
	local token = current_token(id) + 1
	storage:set_int("npc_token_" .. id, token)
	-- remove loaded copies right away (unloaded ones remove themselves)
	for _, obj in ipairs(core.get_objects_inside_radius(pos, 32)) do
		local ent = obj:get_luaentity()
		if ent and ent.name == "sel_core:npc" and ent.npc_id == id then
			obj:remove()
		end
	end
	local obj = core.add_entity(pos, "sel_core:npc",
		core.serialize({id = id, token = token}))
	if obj and yaw then
		obj:set_yaw(yaw)
	end
	return obj
end

----------------------------------------------------------------------------
-- The picture story on the player's screen
----------------------------------------------------------------------------
local function hide_story(player)
	local name = player:get_player_name()
	local v = viewing[name]
	if v then
		for _, id in ipairs(v.huds) do
			player:hud_remove(id)
		end
		viewing[name] = nil
	end
end

-- Start showing the story of NPC `id` to `player` (from panel 1).
function sel_core.show_story(player, id)
	hide_story(player)
	viewing[player:get_player_name()] = {id = id, huds = {}, shown = 0, timer = PANEL_INTERVAL}
	sel_core.play("sel_core_tick", player, 0.6) -- a soft "pling" as the story starts
end

-- Add the next panel; returns true when all panels are visible.
local function reveal_next(player, v)
	local story = defs[v.id].story
	if v.shown >= #story then
		return true
	end
	v.shown = v.shown + 1
	local i = v.shown
	table.insert(v.huds, player:hud_add({
		type = "image",
		position = {x = 0.5, y = 0.05},
		alignment = {x = 0, y = 1},
		offset = {x = (i - (#story + 1) / 2) * PANEL_GAP, y = 0},
		scale = {x = PANEL_SCALE, y = PANEL_SCALE},
		text = story[i],
		z_index = 50,
	}))
	if v.shown == #story then
		-- the whole story has been "heard"
		local key = heard_key(v.id)
		if player:get_meta():get_int(key) ~= 1 then
			player:get_meta():set_int(key, 1)
			if defs[v.id].on_heard then
				defs[v.id].on_heard(player)
			end
		end
		return true
	end
	return false
end

-- Nearest NPC entity to the player within `max_dist`: returns id, distance.
local function nearest_npc(player, max_dist)
	local best_id, best
	local ppos = player:get_pos()
	for _, obj in ipairs(core.get_objects_inside_radius(ppos, max_dist)) do
		local ent = obj:get_luaentity()
		if ent and ent.name == "sel_core:npc" and ent.npc_id then
			local d = vector.distance(ppos, obj:get_pos())
			if not best or d < best then
				best_id, best = ent.npc_id, d
			end
		end
	end
	return best_id, best
end

local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < CHECK_INTERVAL then
		return
	end
	local step = timer
	timer = 0

	for _, player in ipairs(core.get_connected_players()) do
		local name = player:get_player_name()
		local v = viewing[name]
		local id, dist = nearest_npc(player, 16)

		if v then
			-- already watching a story: hide it when walking away
			local radius = defs[v.id].radius
			if v.id ~= id or dist > radius + LEAVE_EXTRA then
				hide_story(player)
				v = nil
			else
				v.timer = v.timer + step
				if v.timer >= PANEL_INTERVAL then
					v.timer = 0
					reveal_next(player, v)
				end
			end
		end

		if not v and id and dist <= defs[id].radius then
			sel_core.show_story(player, id)
		end
	end
end)

core.register_on_leaveplayer(function(player)
	viewing[player:get_player_name()] = nil
end)
