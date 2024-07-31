local awful = require("awful")
local gtable = require("gears.table")
local gtimer = require("gears.timer")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local helpers = require("helpers")
local setmetatable = setmetatable
local ipairs = ipairs

local capi = { awesome = awesome, mouse = mouse, tag = tag }

local menu = { mt = {} }

function menu:set_pos(args)
	args = args or {}

	local coords = args.coords
	local wibox = args.wibox
	local widget = args.widget
	local offset = args.offset or { x = 0, y = 0 }

	if offset.x == nil then
		offset.x = 0
	end
	if offset.y == nil then
		offset.y = 0
	end

	local screen_workarea = awful.screen.focused().workarea
	local screen_w = screen_workarea.x + screen_workarea.width
	local screen_h = screen_workarea.y + screen_workarea.height

	if not coords and wibox and widget then
		coords = helpers.get_widget_geometry(wibox, widget)
	else
		coords = args.coords or capi.mouse.coords()
	end

	if coords.x + self.width > screen_w then
		if self.parent_menu ~= nil then
			self.x = coords.x - (self.width * 2) - offset.x
		else
			self.x = coords.x - self.width + offset.x
		end
	else
		self.x = coords.x + offset.x
	end

	if coords.y + self.height > screen_h then
		self.y = screen_h - self.height + offset.y
	else
		self.y = coords.y + offset.y
	end
end

function menu:hide_parents_menus()
	if self.parent_menu ~= nil then
		self.parent_menu:hide(true)
	end
end

function menu:hide_children_menus()
	if self.widget then
		for _, button in ipairs(self.widget.children) do
			if button.sub_menu ~= nil then
				button.sub_menu:hide()
			end
		end
	end
end

function menu:hide(hide_parents)
	if self.visible == false then
		return
	end

	-- Hide self
	self.visible = false

	-- Hides all child menus
	self:hide_children_menus()

	if hide_parents == true then
		self:hide_parents_menus()
	end
end

function menu:show(args)
	if self.visible == true then
		return
	end

	self.can_hide = false

	gtimer({
		timeout = 0.1,
		autostart = true,
		call_now = false,
		single_shot = true,
		callback = function()
			self.can_hide = true
		end,
	})

	-- Hide sub menus belonging to the menu of self
	if self.parent_menu ~= nil then
		for _, button in ipairs(self.parent_menu.widget.children) do
			if button.sub_menu ~= nil and button.sub_menu ~= self then
				button.sub_menu:hide()
			end
		end
	end

	self:set_pos(args)
	self.visible = true
end

function menu:toggle(args)
	if self.visible == true then
		self:hide()
	else
		self:show(args)
	end
end

function menu:add(widget)
	if widget.sub_menu then
		widget.sub_menu.parent_menu = self
	end
	widget.menu = self
	self.widget:add(widget)
end

function menu:remove(widget)
	self.widget:remove(widget)
end

function menu:reset()
	self.widget:reset()
end

function menu.menu(widgets, width)
	local widget = awful.popup({
		x = 32500,
		type = "menu",
		visible = false,
		ontop = true,
		minimum_width = width or 210,
		maximum_width = width or 210,
		shape = helpers.rrect(10),
		widget = wibox.layout.fixed.vertical,
	})
	gtable.crush(widget, menu, true)

	awful.mouse.append_client_mousebinding(awful.button({ "Any" }, 1, function(c)
		if widget.can_hide == true then
			widget:hide(true)
		end
	end))

	awful.mouse.append_client_mousebinding(awful.button({ "Any" }, 3, function(c)
		if widget.can_hide == true then
			widget:hide(true)
		end
	end))

	awful.mouse.append_global_mousebinding(awful.button({ "Any" }, 1, function(c)
		if widget.can_hide == true then
			widget:hide(true)
		end
	end))

	awful.mouse.append_global_mousebinding(awful.button({ "Any" }, 3, function(c)
		if widget.can_hide == true then
			widget:hide(true)
		end
	end))

	capi.tag.connect_signal("property::selected", function(t)
		widget:hide(true)
	end)

	capi.awesome.connect_signal("menu::toggled_on", function(menu)
		if menu ~= widget and menu.parent_menu == nil then
			widget:hide(true)
		end
	end)

	for _, menu_widget in ipairs(widgets) do
		widget:add(menu_widget)
	end

	return widget
end

function menu.sub_menu_button(args)
	local icon = wibox.widget({
		image = gears.color.recolor_image(
			gears.filesystem.get_configuration_dir() .. "/themes/assets/awm.png",
			helpers.randomColor()
		),
		resize = true,
		forced_height = 15,
		forced_width = 15,
		valign = "center",
		widget = wibox.widget.imagebox,
	})

	local widget = wibox.widget({
		{
			{
				layout = wibox.layout.align.horizontal,
				forced_width = 200,
				{
					icon,
					{
						font = beautiful.sans .. " 12",
						markup = args.text,
						widget = wibox.widget.textbox,
						halign = "start",
					},
					layout = wibox.layout.fixed.horizontal,
					spacing = 20,
				},
				nil,
				{
					font = beautiful.icon .. " 12",
					markup = "󰅂",
					widget = wibox.widget.textbox,
					halign = "left",
				},
			},
			widget = wibox.container.margin,
			left = 30,
			right = 15,
		},
		id = "bg",
		bg = beautiful.darker,
		forced_height = 50,
		widget = wibox.container.background,
	})
	widget:connect_signal("mouse::enter", function(self)
		local coords = helpers.get_widget_geometry(self.menu, self)
		coords.x = coords.x + self.menu.x + self.menu.width
		coords.y = coords.y + self.menu.y
		args.sub_menu:show({ coords = coords, offset = { x = -5 } })
	end)
	helpers.addHoverBg(widget, "bg", beautiful.darker, beautiful.lighter)
	widget.sub_menu = args.sub_menu

	return widget
end

function menu.button(args)
	local icon = wibox.widget({
		font = beautiful.icon .. " 15",
		markup = helpers.colorizeText(args.icon.icon, helpers.randomColor()),
		widget = wibox.widget.textbox,
		halign = "start",
	})

	local text_widget = wibox.widget({
		font = beautiful.sans .. " 12",
		markup = args.text,
		widget = wibox.widget.textbox,
		halign = "start",
	})

	local widget = wibox.widget({
		{
			{
				icon,
				text_widget,
				layout = wibox.layout.fixed.horizontal,
				spacing = 10,
			},
			widget = wibox.container.margin,
			left = 30,
		},
		id = "bg",
		bg = beautiful.darker,
		forced_height = 45,
		buttons = {
			awful.button({}, 1, function()
				args.on_press(menu, text_widget)
				menu:hide(true)
			end),
		},
		widget = wibox.container.background,
	})
	widget:connect_signal("mouse::enter", function(self)
		if self.menu.widget then
			self.menu:hide_children_menus()
		end
	end)
	helpers.addHoverBg(widget, "bg", beautiful.darker, beautiful.lighter)
	return widget
end

function menu.separator()
	return wibox.widget({
		widget = wibox.container.margin,
		left = 30,
		right = 30,
		{
			widget = wibox.widget.separator,
			forced_height = 2,
			orientation = "horizontal",
			color = beautiful.foreground .. "55",
		},
	})
end

function menu.mt:__call(...)
	return menu.menu(...)
end

return setmetatable(menu, menu.mt)
