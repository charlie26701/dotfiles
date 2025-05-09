local gears = require("gears")
local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")

local path_icon = os.getenv("HOME") .. "/.icons/" .. _User.IconName .. "/"
local icon_cache = {}
local DEFAULT_ICON = path_icon .. "/apps/scalable/default-application.svg"
local ICON_DIR = path_icon .. "/apps/scalable/"
local desktop_cache = {}

local function cache_desktop_files_from_dir(dir)
	local p = io.popen("ls " .. dir .. "*.desktop 2>/dev/null")
	if p then
		for file in p:lines() do
			local name = file:match("([^/]+)%.desktop$")
			if name then
				desktop_cache[name:lower()] = file
			end
		end
		p:close()
	end
end
cache_desktop_files_from_dir("/usr/share/applications/")
cache_desktop_files_from_dir(os.getenv("HOME") .. "/.local/share/applications/")

local function findDesktopIcon(class_string)
	if not class_string then return nil end

	local file_path = desktop_cache[class_string:lower()]
	if file_path then
		local file = io.open(file_path, "r")
		if file then
			for line in file:lines() do
				local icon = line:match("^Icon=(.+)$")
				if icon then
					file:close()
					if not icon:match("/") then
						local svg_icon = "/usr/share/pixmaps/" .. icon .. ".svg"
						local png_icon = "/usr/share/pixmaps/" .. icon .. ".png"

						local svg_open = io.open(svg_icon, "r")
						local png_open = io.open(svg_icon, "r")
						if svg_open then
							svg_open:close()
							icon = svg_icon
						elseif png_open then
							icon = png_icon
						else
							icon = nil
						end
					end
					return icon
				end
			end
			file:close()
		end
	end

	return nil
end

local function findCustomIcon(str)
	if not str then return false, 0 end

	for i, icon in ipairs(_User.Custom_Icon) do
		if icon.name == str then
			return true, i
		end
	end
	return false, 0
end

local function findInCache(clientName)
	for _, icon in ipairs(icon_cache) do
		if icon:match(clientName) then
			return icon
		end
	end
	return nil
end

local function checkIcon(name)
	if not name then return nil end

	local fullPath = ICON_DIR .. name
	local file = io.open(fullPath, "r")

	if file then
		file:close()
		icon_cache[#icon_cache + 1] = fullPath
		return fullPath
	end
	return nil
end

local icons = {}

icons.getIcon = function(client, program_string, class_string)
	if not (client or program_string or class_string) then
		return client and DEFAULT_ICON
	end

	local clientName
	local isCustom, pos = findCustomIcon(class_string)

	if isCustom then
		clientName = _User.Custom_Icon[pos].to .. ".svg"
	elseif client then
		if client.class then
			clientName = string.lower(client.class:gsub(" ", "")) .. ".svg"
		elseif client.name then
			clientName = string.lower(client.name:gsub(" ", "")) .. ".svg"
		else
			return client.icon or DEFAULT_ICON
		end
	else
		clientName = (program_string or class_string) .. ".svg"
	end

	local cachedIcon = findInCache(clientName)
	if cachedIcon then return cachedIcon end

	local icon = checkIcon(clientName) or
		checkIcon(clientName:gsub("^%l", string.upper))
	if icon then return icon end

	local pngName = clientName:gsub("%.svg$", ".png")
	icon = checkIcon(pngName) or
		checkIcon(pngName:gsub("^%l", string.upper))
	if icon then return icon end

	if class_string then
		local desktop_icon = findDesktopIcon(class_string)
		if desktop_icon ~= nil then return desktop_icon end
	end

	return DEFAULT_ICON
end

icons.lookup_icon = function(args)
	if type(args) == "string" then
		return icons.lookup_icon({ icon_name = args })
	elseif type(args) == "table" then
		if #args >= 1 and not args.icon_name then
			local path = nil
			for _, value in ipairs(args) do
				path = icons.lookup_icon(value)
				if path then
					return path
				end
			end
			return
		elseif args.icon_name and type(args.icon_name) == "table" then
			local path
			for _, value in ipairs(args.icon_name) do
				path = icons.lookup_icon({
					icon_name = value,
					size = args.size,
					path = args.path,
					recolor = args.recolor,
				})
				if path then
					return path
				end
			end
			return
		end
	end

	if not args or not args.icon_name then
		return
	end

	args = gears.table.crush({ icon_name = "", size = 128, path = true, recolor = nil, }, args, false)

	local theme = Gtk.IconTheme.get_default()
	local icon_info, path

	for _, name in ipairs({
		args.icon_name,
		args.icon_name:lower(),
		args.icon_name:upper(),
		args.icon_name:gsub("^%l", string.upper)
	}) do
		icon_info = theme:lookup_icon(name, args.size, Gtk.IconLookupFlags.USE_BUILTIN)

		if not icon_info then
			goto continue
		end

		path = icon_info:get_filename()

		if not path then
			goto continue
		end

		if args.path then
			if args.recolor ~= nil then
				return _Utils.image.recolor_image(path, args.recolor, args.size, args.size)
			else
				return path
			end
		else
			return icon_info
		end

		::continue::
	end
end

return icons
