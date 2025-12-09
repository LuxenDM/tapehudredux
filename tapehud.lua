--[[
[modreg]
API=3
id=tapehud
name=TapeHUD Redux
version=2.0.0
path=tapehud.lua
author=Luxen De'Mark, mr_spuck
website=

[dependencies]
depid1=helium
depvs1=1.1.0
depmx1=1.5.9

[metadata]
description=TapeHUD is a management system for using simulated cockpits in non-VR clients of Vendetta Online
version=2.0.0
owner=tapehud|2.0.0
type=lua
created=2025-12-08
]]--

local mod_path = lib.get_path() or "plugins/tapehudredux/"
local mod_ver = lib.mod_read_str(mod_path .. "tapehud.lua", nil, "modreg", "version")
local mod_standalone = (mod_path == "plugins/tapehudredux/") and (gksys.IsExist(mod_path .. "tapehud.lua"))

local he_ver = lib.get_latest("helium", "1.1.0", "1.5.9")
local he = lib.get_class("helium", he_ver)

local babel, lang_key, update_class, public
local private = {}
private.he = he
private.bstr = function(id, val)
	return val
end
private.registry = {} --list of cockpits

--todo: trigger this via lib.require later!
local babel_func = function()
	babel = lib.get_class("babel", "0")
	lang_key = babel.register(mod_path .. "lang/", {'en', 'es', 'fr', 'pt'})
	
	private.bstr = function(id, val)
		return babel.fetch(lang_key, id, val)
	end
	
	public.add_translation = function(path, lang_code)
		babel.add_new_lang(lang_key, path, lang_code)
	end
	
	update_class()
end

local config = {
	active = "NO",
	cockpit = "Basic",
}

public = {
	CCD1 = true,
	manifest = {
		"tapehud.lua",
	},
	
	config_load = function()
		for k, v in pairs(config) do
			config[k] = gkini.ReadString("tapehud", k, v)
		end
	end,
	config_save = function()
		for k, v in pairs(config) do
			gkini.WriteString("tapehud", k, v)
		end
	end,
	config_get = function(key)
		return config[key]
	end,
	config_set = function(key, value)
		if not config[key] then
			return
		end
		config[key] = tostring(value)
	end,
	add_new_lang = function() end, --placeholder till babel is ready
	register_cockpit = function(intable)
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
			width_interval = "128", --X resolution of stretch (assumes height matches)
			height = "480", --Y resolution of primary image
		}

		for k, v in pairs(intable) do
			default[k] = v
		end

		if default.name == "null" then
			lib.log_error("Cannot register a cockpit with no provided name!")
			return false
		end

		lib.log_error("Registered cockpit " .. default.name)
		table.insert(private.registry, default)
	end,
	get_num_entries = function()
		return #private.registry
	end,
	get_entry_table = function(id)
		return private.registry[id]
	end,
	find_id_by_name = function(name)
		local id = -1
		for i, v in ipairs(private.registry) do
			if v.name == name then
				id = i
				break
			end
		end
		return id
	end,
	get_active_cockpit_id = function()
		return public.find_id_by_name(config.cockpit)
	end,
	make_preview_list = function()
		local list = {}
		for i, entry in ipairs(registry) do
			table.insert(list, {
				name = entry.name,
				preview = entry.preview,
				active = config.cockpit == entry.name,
			})
		end

		return list
	end,
}

update_class = function()
	public.description = private.bstr(-1, "TapeHUD provides a system for selecting and managing simulated cockpits for non-VR clients of Vendetta Online.")
	public.smart_config = {
		title = "Tapehud Redux",
		cb = function(ref_key, new_value)
			if config[ref_key] then
				config[ref_key] = tostring(new_value)
			end
		end,
		"active",
		"cockpit",
		active = {
			type = "toggle",
			default = config.active,
		},
		cockpit = {
			type = "dropdown",
			default = 1,
			[1] = "empty",
		},
	}

	local cblist = public.smart_config.cockpit
	for index, entry in ipairs(registry) do
		cblist[index] = entry.name
		if entry.name == config.cockpit then
			cblist.default = index
		end
	end

	lib.set_class("tapehud", mod_ver, public)
end

private.load_module = function() end --stub

private.load_module("constructor.lua") --creates active cockpit view
private.load_module("injector.lua") --injects into default interface (non-default can pull from constructor)
private.load_module("interface.lua") --basic management front-end

update_class()
lib.require({{name = "babel", version = "0"}}, babel_func)

public.register_cockpit {
	name = "No cockpit",
	description = private.bstr(-1, "Do not apply a cockpit to the HUD"),
}

public.register_cockpit {
	name = "TapeHUD (Classic)",
	description = private.bstr(-1, "The classic tape by Mr_Spuck"),
}

public.register_cockpit {
	name = "Basic",
	description = private.bstr(-1, "A simple hatch-top cockpit design distributed with TapeHUD"),
}

public.register_cockpit {
	name = "Rallycar",
	description = private.bstr(-1, "Simulates the hood-down view of being in a rally racecar! Spaceships? What are those?"),
}
