local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local pctl = require("modules.playerctl")
local helpers = require("helpers")
local playerctl = pctl.lib()

local art = wibox.widget({
	image = helpers.cropSurface(1.9, gears.surface.load_uncached(beautiful.songdefpicture)),
	opacity = 0.5,
	resize = true,
	clip_shape = helpers.rrect(5),
	widget = wibox.widget.imagebox,
})

local next = wibox.widget({
	align = "center",
	font = beautiful.icon .. " 30",
	text = "󰒭",
	widget = wibox.widget.textbox,
	buttons = {
		awful.button({}, 1, function()
			playerctl:next()
		end),
	},
})

local prev = wibox.widget({
	align = "center",
	font = beautiful.icon .. " 30",
	text = "󰒮",
	widget = wibox.widget.textbox,
	buttons = {
		awful.button({}, 1, function()
			playerctl:previous()
		end),
	},
})

local play = wibox.widget({
	align = "center",
	font = beautiful.icon .. " 30",
	markup = helpers.colorizeText("󰐍 ", beautiful.foreground),
	widget = wibox.widget.textbox,
	buttons = {
		awful.button({}, 1, function()
			playerctl:play_pause()
		end),
	},
})
playerctl:connect_signal("playback_status", function(_, playing, player_name)
	play.markup = playing and helpers.colorizeText("󰏦 ", beautiful.foreground)
		or helpers.colorizeText("󰐍 ", beautiful.foreground)
end)

awful.screen.connect_for_each_screen(function(s)
	local music = wibox({
		screen = s,
		width = beautiful.width / 4,
		height = (beautiful.height / 3) * 0.56,
		bg = beautiful.background .. "00",
		ontop = true,
		visible = false,
	})
	awful.placement.bottom_right(music, {
		honor_workarea = true,
		margins = {
			bottom = beautiful.useless_gap * 74,
			right = beautiful.useless_gap * 2,
		},
	})

	music:setup({
		{
			{
				nil,
				{
					art,
					{
						{
							widget = wibox.widget.textbox,
						},
						bg = {
							type = "linear",
							from = { 0, 0 },
							to = { 250, 0 },
							stops = { { 0, beautiful.background .. "ff" }, { 1, beautiful.background .. "00" } },
						},
						shape = helpers.rrect(5),
						widget = wibox.container.background,
					},
					{
						{
							{
								{
									id = "songname",
									font = beautiful.sans .. " 20",
									markup = helpers.colorizeText("Song Name", beautiful.foreground),
									widget = wibox.widget.textbox,
								},
								{
									id = "artist",
									font = beautiful.sans .. " 12",
									markup = helpers.colorizeText("Artist Name", beautiful.foreground),
									widget = wibox.widget.textbox,
								},
								spacing = 20,
								layout = wibox.layout.fixed.vertical,
							},
							nil,
							{
								id = "player",
								font = beautiful.sans .. " 12",
								markup = helpers.colorizeText("", beautiful.foreground),
								widget = wibox.widget.textbox,
							},
							layout = wibox.layout.align.vertical,
						},
						widget = wibox.container.margin,
						left = 20,
						bottom = 20,
						top = 20,
					},
					layout = wibox.layout.stack,
				},
				{
					{
						{
							{
								prev,
								{
									play,
									widget = wibox.container.margin,
									left = 15,
								},
								next,
								layout = wibox.layout.align.vertical,
							},
							widget = wibox.container.margin,
							top = 30,
							bottom = 30,
							left = 10,
							right = 5,
						},
						shape = helpers.rrect(5),
						widget = wibox.container.background,
						bg = beautiful.background,
					},
					widget = wibox.container.margin,
					left = 15,
				},
				layout = wibox.layout.align.horizontal,
			},
			widget = wibox.container.margin,
			margins = 15,
		},
		forced_height = 300,
		widget = wibox.container.background,
		bg = beautiful.darker,
		shape = helpers.rrect(5),
	})

	awesome.connect_signal("toggle::music", function()
		music.visible = not music.visible
	end)
	awesome.connect_signal("close::music", function()
		music.visible = false
	end)
	playerctl:connect_signal("metadata", function(_, title, artist, album_path, album, new, player_name)
		if album_path == "" then
			album_path = beautiful.songdefpicture
		end
		if string.len(title) > 40 then
			title = string.sub(title, 0, 35) .. "..."
		end
		if string.len(artist) > 25 then
			artist = string.sub(artist, 0, 25) .. "..."
		end
		art.image = helpers.cropSurface(1.9, gears.surface.load_uncached(album_path))
		helpers.gc(music, "songname"):set_markup_silently(helpers.colorizeText(title or "NO", beautiful.foreground))
		helpers.gc(music, "artist"):set_markup_silently(helpers.colorizeText(artist or "HM", beautiful.foreground))
		helpers
			.gc(music, "player")
			:set_markup_silently(helpers.colorizeText("Playing On: " .. player_name or "", beautiful.foreground))
	end)
end)
