local awful = require("awful")
local wibox = require("wibox")
local Gio = require("lgi").Gio
local iconTheme = require("lgi").require("Gtk", "3.0").IconTheme.get_default()
local beautiful = require("beautiful")
local gears = require("gears")

local Conf = {
	rows = 4,
	entry_height = 90,
	entry_width = 450,
	popup_margins = 15,
}

local prompt = wibox.widget({
	{
		image = _Utils.image.cropSurface(4, gears.surface.load_uncached(_User.Wallpaper)),
		opacity = 1,
		forced_height = 120,
		clip_shape = beautiful.radius,
		forced_width = Conf.entry_height,
		widget = wibox.widget.imagebox,
	},
	{
		{
			{
				{
					{
						markup = "",
						forced_height = 10,
						id = "txt",
						font = beautiful.sans .. " 12",
						widget = wibox.widget.textbox,
					},
					{
						markup = "Search...",
						forced_height = 10,
						id = "placeholder",
						font = beautiful.sans .. " 12",
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.stack,
				},
				widget = wibox.container.margin,
				left = 20,
			},
			forced_width = Conf.entry_width - 200,
			forced_height = 55,
			shape = beautiful.radius,
			widget = wibox.container.background,
			bg = beautiful.darker .. "AA",
			shape_border_width = beautiful.border_width_custom,
			shape_border_color = beautiful.border_color,
		},
		widget = wibox.container.place,
	},
	layout = wibox.layout.stack,
})

local entries_container = wibox.widget({
	layout = wibox.layout.grid,
	homogeneous = false,
	expand = true,
	forced_num_cols = 1,
	forced_width = Conf.entry_width,
})

local main_widget = wibox.widget({
	widget = wibox.container.background,
	bg = beautiful.lighter,
	shape = beautiful.radius,
	shape_border_width = beautiful.border_width_custom,
	shape_border_color = beautiful.border_color,
	forced_height = (Conf.entry_height * (Conf.rows + 1)) + Conf.popup_margins,
	{
		{
			layout = wibox.layout.fixed.vertical,
			spacing = Conf.popup_margins,
			prompt,
			entries_container,
		},
		widget = wibox.container.margin,
		left = Conf.popup_margins,
		right = Conf.popup_margins,
		bottom = Conf.popup_margins,
		top = Conf.popup_margins,
	},
})

local popup_widget = awful.popup({
	bg = beautiful.lighter,
	ontop = true,
	visible = false,
	placement = function(d)
		_Utils.widget.placeWidget(d, "center", 0, 0, 0, 0)
	end,
	maximum_width = Conf.entry_width + Conf.entry_height + Conf.popup_margins * 3,
	shape = beautiful.radius,
	widget = main_widget,
})

local index_entry, index_start = 1, 1
local unfiltered, filtered, regfiltered = {}, {}, {}

local function next()
	if index_entry ~= #filtered then
		index_entry = index_entry + 1
		if index_entry > index_start + Conf.rows - 1 then
			index_start = index_start + 1
		end
	else
		index_entry = 1
		index_start = 1
	end
end

local function back()
	if index_entry ~= 1 then
		index_entry = index_entry - 1
		if index_entry < index_start then
			index_start = index_start - 1
		end
	else
		index_entry = #filtered
		index_start = #filtered - Conf.rows + 1
	end
end

local function gen()
	local entries = {}
	for _, entry in ipairs(Gio.AppInfo.get_all()) do
		if entry:should_show() then
			local name = entry:get_name():gsub("&", "&amp;"):gsub("<", "&lt;"):gsub("'", "&#39;")
			local path = entry:get_icon():to_string()
			local icon_info = iconTheme:lookup_icon(path, 48, 0)
			local p = icon_info and icon_info:get_filename() or _Utils.icon.getIcon(nil, name, name)
			table.insert(entries, { name = name, appinfo = entry, icon = p })
		end
	end
	return entries
end

local function filter(input)
	local clear_input = input:gsub("[%(%)%[%]%%]", "")

	filtered = {}
	regfiltered = {}

	for _, entry in ipairs(unfiltered) do
		if entry.name:lower():sub(1, clear_input:len()) == clear_input:lower() then
			table.insert(filtered, entry)
		elseif entry.name:lower():match(clear_input:lower()) then
			table.insert(regfiltered, entry)
		end
	end

	table.sort(filtered, function(a, b)
		return a.name:lower() < b.name:lower()
	end)
	table.sort(regfiltered, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	for i = 1, #regfiltered do
		filtered[#filtered + 1] = regfiltered[i]
	end

	entries_container:reset()

	for i, entry in ipairs(filtered) do
		local entry_widget = wibox.widget({
			shape = beautiful.radius,
			buttons = {
				awful.button({}, 1, function()
					if index_entry == i then
						entry.appinfo:launch()
						awesome.emit_signal("close::launcher")
					else
						index_entry = i
						filter(input)
					end
				end),
				awful.button({}, 4, function()
					back()
					filter(input)
				end),
				awful.button({}, 5, function()
					next()
					filter(input)
				end),
			},
			widget = wibox.container.background,
			shape_border_width = beautiful.border_width_custom,
			{
				{
					{
						image = entry.icon,
						clip_shape = beautiful.radius,
						forced_height = 51,
						forced_width = 51,
						widget = wibox.widget.imagebox,
					},
					{
						markup = entry.name,
						id = "name",
						widget = wibox.widget.textbox,
						font = beautiful.sans .. " 13",
					},
					spacing = 20,
					layout = wibox.layout.fixed.horizontal,
				},
				left = 30,
				top = 10,
				bottom = 10,
				widget = wibox.container.margin,
			},
		})

		if index_start <= i and i <= index_start + Conf.rows - 1 then
			entries_container:add(entry_widget)
		end

		if i == index_entry then
			entry_widget.bg = beautiful.lighter1
			entry_widget.shape_border_color = beautiful.border_color
			_Utils.widget.gc(entry_widget, "name"):set_font(beautiful.sans .. " Medium 13")
			_Utils.widget.gc(entry_widget, "name"):set_markup_silently(_Utils.widget.colorizeText(entry.name,
				beautiful.blue))
		else
			entry_widget.shape_border_color = beautiful.foreground .. "00"
		end
	end

	if index_entry > #filtered then
		index_entry, index_start = 1, 1
	elseif index_entry < 1 then
		index_entry = 1
	end

	collectgarbage("collect")
end

local exclude = {
	"Shift_R",
	"Shift_L",
	"Super_R",
	"Super_L",
	"Tab",
	"Alt_R",
	"Alt_L",
	"Control_L",
	"Control_R",
	"Caps_Lock",
	"Print",
	"Insert",
	"CapsLock",
	"Home",
	"End",
	"Down",
	"Up",
	"Left",
	"Right",
}
local function has_value(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

local prompt_grabber = awful.keygrabber({
	auto_start = true,
	stop_event = "release",
	keypressed_callback = function(self, mod, key, command)
		local addition = ""
		if key == "Escape" then
			awesome.emit_signal("close::launcher")
		elseif key == "BackSpace" then
			_Utils.widget.gc(prompt, "txt"):set_markup_silently(_Utils.widget.gc(prompt, "txt").markup:sub(1, -2))
			filter(_Utils.widget.gc(prompt, "txt").markup)
		elseif key == "Delete" then
			_Utils.widget.gc(prompt, "txt"):set_markup_silently("")
			filter(_Utils.widget.gc(prompt, "txt").markup)
		elseif key == "Return" then
			local entry = filtered[index_entry]
			if entry then
				entry.appinfo:launch()
			end
			awesome.emit_signal("close::launcher")
		elseif key == "Up" then
			back()
		elseif key == "Down" then
			next()
		elseif has_value(exclude, key) then
			addition = ""
		else
			addition = key
		end
		_Utils.widget.gc(prompt, "txt"):set_markup_silently(_Utils.widget.gc(prompt, "txt").markup .. addition)
		filter(_Utils.widget.gc(prompt, "txt").markup)
		if string.len(_Utils.widget.gc(prompt, "txt").markup) > 0 then
			_Utils.widget.gc(prompt, "placeholder"):set_markup_silently("")
		else
			_Utils.widget.gc(prompt, "placeholder"):set_markup_silently("Search...")
		end
	end,
})

awesome.connect_signal("close::launcher", function()
	popup_widget.visible = false
	prompt_grabber:stop()
	_Utils.widget.gc(prompt, "txt"):set_markup_silently("")
end)

awesome.connect_signal("toggle::launcher", function()
	if not popup_widget.visible then
		popup_widget.visible = true
		unfiltered = gen()
		filter("")
		prompt_grabber:start()
	else
		awesome.emit_signal("close::launcher")
	end
end)
