--[[
[metadata]
description=This module takes the actively selected cockpit and creates the IUP representation of it
version=1.0.0
owner=tapehud|2.0.0
type=lua
created=2025-12-09
]]--

local file_args = {...}

local public = file_args[1]
local private = file_args[2]
local config = file_args[3]

local he = private.he

public.generate_cockpit = function()
	--creates the cockpit iup object and returns it.
	local active_cockpit_id = public.get_active_cockpit_id()
	local active = public.get_entry_table(active_cockpit_id)

	--[[
	local default = {
		name = "null",
		description = "",
		preview = mod_path .. "assets/no_preview.png",
		primary = "", --centered image
		nineslice = "", --segmentation of centered image for single-image stretching
		stretch_left = "", --infinite stretch left
		stretch_right = "", --infinite stretch right
		dynamic = "", --path to lua file for interactive objects or custom image placement
		disable_scaling = "NO", --yes for no resizing
		width = "640", --X resolution of primary image
		width_interval = "128"
		height = "480", --Y resolution of primary image
	}
	]]--
	--todo: figure out how the nineslice works!
	
	local primary_artifact = iup.label {
		title = "",
		image = active.primary,
		bgcolor = (not gksys.IsExist(active.primary) and "0 0 0 0 *") or nil,
	}

	local primary_width, primary_height = he.util.scale_to_target(active.width, active.height, gkinterface.GetYResolution(), false, 1)
	primary_artifact.size = tostring(primary_width) .. "x" .. tostring(primary_height)

	--todo: if width < screen width, add stretch images on left and right to compensate
	local left_w = iup.hbox {}
	local right_w = iup.hbox {}
	local left_t = {}
	local right_t = {}
	local interval = aspect_ratio * tonumber(active.width_interval)
	local gap = gkinterface.GetYResolution() - primary_width
	gap = gap / 2
	for i=gap, 0, interval * -1 do
		local L_entry = iup.label {
			label = "",
			image = active.stretch_left,
			bgcolor = (not gksys.IsExist(active.stretch_left) and "0 0 0 0 *") or nil,
			size = tostring(interval) .. "x" .. tostring(primary_height),
		}
		local R_entry = iup.label {
			label = "",
			image = active.stretch_right,
			bgcolor = (not gksys.IsExist(active.stretch_right) and "0 0 0 0 *") or nil,
			size = tostring(interval) .. "x" .. tostring(primary_height),
		}
		table.insert(left_t, L_entry)
		table.insert(right_t, R_entry)
		left_w:append(L_entry)
		right_w:append(R_entry)
	end

	local img_container = iup.hbox {
		left_w, primary_artifact, right_w,
	}

	local img_root = he.primitives.clearframe {
		cx = 0, cy = 0,
		expand = "YES",
		img_container,
	}

	local cockpit_root = he.primitives.clearframe {
		expand = "YES",
		iup.cbox {
			img_root,
		},
		shake = function(self)
			--todo
		end,
		toggle_visibility = function(self, toggle_state)
			primary_artifact.visible = toggle_state,
			for index, obj in ipairs(left_t) do
				obj.visible = toggle_state,
				right_t[index].visible = toggle_state,
			end
		end,
	}

	cockpit_root:toggle_visibility(config.active)

	return cockpit_root
end
