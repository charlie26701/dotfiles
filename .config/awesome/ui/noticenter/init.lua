local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local helpers = require("helpers")
local wibox = require("wibox")
local gears = require("gears")
local empty = require("ui.noticenter.mods.empty")
local make = require("ui.noticenter.mods.make")
local progs = require("ui.noticenter.mods.progs")

awful.screen.connect_for_each_screen(function(s)
	local notify = wibox({
		screen = s,
		width = beautiful.width / 4,
		height = beautiful.height / 1.33,
		bg = beautiful.darker,
		shape = helpers.rrect(10),
		ontop = true,
		visible = false,
	})

	local finalcontent = wibox.widget({
		layout = require("modules.overflow").vertical,
		scrollbar_enabled = false,
		spacing = 15,
	})
	finalcontent:insert(1, empty)

	local remove_notifs_empty = true

	notif_center_reset_notifs_container = function()
		finalcontent:reset(finalcontent)
		finalcontent:insert(1, empty)
		remove_notifs_empty = true
	end

	notif_center_remove_notif = function(box)
		finalcontent:remove_widgets(box)
		if #finalcontent.children == 0 then
			finalcontent:insert(1, empty)
			remove_notifs_empty = true
		end
	end

	local title = wibox.widget({
		font = beautiful.sans .. " 15",
		markup = helpers.colorizeText("Notification Center", beautiful.foreground),
		widget = wibox.widget.textbox,
	})

	local clearButton = wibox.widget({
		image = gears.filesystem.get_configuration_dir() .. "/themes/assets/notify/trash.png",
		resize = true,
		forced_height = 25,
		forced_width = 25,
		halign = "center",
		widget = wibox.widget.imagebox,
		buttons = {
			awful.button({}, 1, function()
				notif_center_reset_notifs_container()
			end),
		},
	})
	naughty.connect_signal("request::display", function(n)
		if #finalcontent.children == 1 and remove_notifs_empty then
			finalcontent:reset(finalcontent)
			remove_notifs_empty = false
		end

		local appicon = n.icon or n.app_icon
		if not appicon then
			appicon = gears.color.recolor_image(
				gears.filesystem.get_configuration_dir() .. "/themes/assets/awm.png",
				helpers.randomColor()
			)
		end
		finalcontent:insert(1, make(appicon, n))
	end)

	notify:setup({
		{
			{
				{
					title,
					nil,
					clearButton,
					widget = wibox.layout.align.horizontal,
				},
				widget = wibox.container.margin,
				margins = 20,
			},
			widget = wibox.container.background,
			bg = beautiful.background,
		},
		{
			{
				finalcontent,
				widget = wibox.container.margin,
				margins = 15,
			},
			widget = wibox.container.background,
		},
		progs,
		layout = wibox.layout.align.vertical,
	})
	helpers.placeWidget(notify, "bottom_right", 0, 2, 0, 2)
	awesome.connect_signal("toggle::notify", function()
		notify.visible = not notify.visible
	end)
	awesome.connect_signal("close::notify", function()
		notify.visible = false
	end)
end)
