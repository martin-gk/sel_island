--[[
    protect.lua - areas children cannot dig or build in
    ===================================================

    Activity mods register zones (boxes). Inside a zone, children cannot
    dig or place blocks - except where the zone's `allow` function says so
    (e.g. the shiny block of the tutorial may be dug).

    Teachers (privilege "sel_teacher") are never blocked.

        sel_core.protect_zone({
            name = "hub",
            minp = {x=..., y=..., z=...},
            maxp = {x=..., y=..., z=...},
            -- optional: return true to ALLOW digging/placing at pos
            allow = function(pos, player_name) return false end,
        })

    Luanti asks core.is_protected(pos, name) before every dig and every
    place. We wrap the existing function (other mods may have their own).
]]

local zones = {}

function sel_core.protect_zone(zone)
	table.insert(zones, zone)
end

-- Is `pos` inside any SEL zone that forbids `name` to change it?
function sel_core.is_protected_for(pos, name)
	for _, zone in ipairs(zones) do
		if sel_core.in_box(pos, zone.minp, zone.maxp) then
			if not (zone.allow and zone.allow(pos, name)) then
				return true
			end
		end
	end
	return false
end

-- Is `pos` inside a zone other than `zone`? (Used by the story area, which
-- keeps out of every place that has rules of its own.)
function sel_core.in_other_zone(pos, zone)
	for _, other in ipairs(zones) do
		if other ~= zone and sel_core.in_box(pos, other.minp, other.maxp) then
			return true
		end
	end
	return false
end

local old_is_protected = core.is_protected

function core.is_protected(pos, name)
	if not sel_core.is_teacher(name) and sel_core.is_protected_for(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end
