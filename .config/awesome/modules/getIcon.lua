local icon_cache = {}
local getUser = os.getenv("USER")
local t = "/home/" .. getUser .. "/.icons/Reversal-Black/"

local custom = {
	{
		name = "org.wezfurlong.wezterm",
		to = "terminal",
	},
	{
		name = "Alacritty",
		to = "terminal",
	},
	{
		name = "St",
		to = "terminal",
	},
	{
		name = "clearpad",
		to = "terminal",
	},
	{
		name = "ncmpcpppad",
		to = "deepin-music-player",
	},
	{
		name = "jetbrains-idea",
		to = "intellij-idea-ultimate-edition",
	},
	{
		name = "TelegramDesktop",
		to = "telegram-desktop",
	},
	{
		name = "neovide",
		to = "neovim",
	},
	{
		name = "libreoffice-writer",
		to = "libreoffice-writer",
	},
	{
		name = "libreoffice-calc",
		to = "libreoffice-calc",
	},
	{
		name = "libreoffice-impress",
		to = "libreoffice-impress",
	},
}

local function hasValue(str)
	local f = false
	local ind = 0
	for i, j in ipairs(custom) do
		if j.name == str then
			f = true
			ind = i
			break
		end
	end
	return f, ind
end

local function Get_icon(client, program_string, class_string)
	client = client or nil
	program_string = program_string or nil
	class_string = class_string or nil

	if client or program_string or class_string then
		local clientName
		local isCustom, pos = hasValue(class_string)
		if isCustom == true then
			clientName = custom[pos].to .. ".svg"
		elseif client then
			if client.class then
				clientName = string.lower(client.class:gsub(" ", "")) .. ".svg"
			elseif client.name then
				clientName = string.lower(client.name:gsub(" ", "")) .. ".svg"
			else
				if client.icon then
					return client.icon
				else
					return t .. "/apps/scalable/default-application.svg"
				end
			end
		else
			if program_string then
				clientName = program_string .. ".svg"
			else
				clientName = class_string .. ".svg"
			end
		end

		for index, icon in ipairs(icon_cache) do
			if icon:match(clientName) then
				return icon
			end
		end

		local iconDir = t .. "/apps/scalable/"
		local ioStream = io.open(iconDir .. clientName, "r")
		if ioStream ~= nil then
			icon_cache[#icon_cache + 1] = iconDir .. clientName
			return iconDir .. clientName
		else
			clientName = clientName:gsub("^%l", string.upper)
			iconDir = t .. "/apps/scalable/"
			ioStream = io.open(iconDir .. clientName, "r")
			if ioStream ~= nil then
				icon_cache[#icon_cache + 1] = iconDir .. clientName
				return iconDir .. clientName
			elseif not class_string then
				return t .. "/apps/scalable/default-application.svg"
			else
				clientName = class_string .. ".svg"
				iconDir = t .. "/apps/scalable/"
				ioStream = io.open(iconDir .. clientName, "r")
				if ioStream ~= nil then
					icon_cache[#icon_cache + 1] = iconDir .. clientName
					return iconDir .. clientName
				else
					return t .. "/apps/scalable/default-application.svg"
				end
			end
		end
	end
	if client then
		return t .. "/apps/scalable/default-application.svg"
	end
end

return Get_icon
