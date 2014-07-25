-- https://github.com/camdat

-- This rc.lua is essentially a terrible 
-- compilation of various not-terrible widgets with terrible tweaks by me (camdat).

-- I would read through the comments and make changes as you see fit however the tl;dr
-- would essentially be to tweak the run-once at the very bottom
-- and to make sure you are using my theme or have changed the relevent icons.

-- Finally this rc file was built using the awesome debian/3.4.13-1 (Octopus) version
-- any changes must be made if using on another awesome version and/or distro


-- Standard awesome library
vicious = require("vicious")
require("awful")
scratch = require("scratch")
require("awful.autofocus")
require("awful.rules")
require("awful.widget")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Load Debian menu entries
require("debian.menu")

-- Wallpaper Config
mytimer = timer({ timeout = 30 })                  --be sure to define where wallpapers are kept and your prefered wallpaper manager, I ususally use feh.
mytimer:add_signal("timeout", function() os.execute("python /home/camdat/scripts/shapepaper/shapepaper.py") mytimer:stop() mytimer.timeout = 30 mytimer:start() end)
mytimer:start()


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")


-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor


-- Default modkey.
modkey = "Mod4"
-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    -- If you don't like the default tags they can be changed here.
    tags[s] = awful.tag({ "☰", "☱", "☲", "☴"}, s, layouts[6])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
-- I haven't really changed the awesome menu because of how little I use it.


myawesometest = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })
                        


mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox




-- ALSA widget set-up (This is actually two parts: the set up, and define the widget)
-- Designed by Farhaven (http://awesome.naquadah.org/wiki/Farhavens_volume_widget)
-- Small tweaks to useability and color by me (camdat)
 cardid  = 0
 channel = "Master"
 function volume (mode, widget)
 	if mode == "update" then
              local fd = io.popen("amixer")
              
              -- -c " .. cardid .. " -- sget " .. channel
              local status = fd:read("*all")
              fd:close()
 		
 		local volume = string.match(status, "(%d?%d?%d)%%")
 		volume = string.format("% 3d", volume)
 
 		status = string.match(status, "%[(o[^%]]*)%]")
 
 		if string.find(status, "on", 1, true) then
 			volume = volume .. "%"
 		else
 			volume = volume .. "M"
 		end
 		widget.text = '<span color="#A7DBD8">'..volume..'</span> -- '
 	elseif mode == "up" then
 		io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%+"):read("*all")
 		volume("update", widget)
 	elseif mode == "down" then
 		io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%-"):read("*all")
 		volume("update", widget)
 	else
 		io.popen("amixer -q sset " .. channel .. " toggle"):read("*all")
 		volume("update", widget)
 	end
 end
 
  tb_volume = widget({ type = "textbox", name = "tb_volume", align = "right" })
 tb_volume:buttons({
 	button({ }, 4, function () volume("up", tb_volume) end),
 	button({ }, 5, function () volume("down", tb_volume) end),
 	button({ }, 1, function () volume("mute", tb_volume) end)
 })
 
--  Network usage widget
 netwidget = widget({ type = "textbox" })
 vicious.register(netwidget, vicious.widgets.net, '<span color="#69D2E7">${eth0 down_kb}</span> | <span color="#69D2E7">${eth0 up_kb} </span> -- ', 3)
 
-- MPD widget using the base code of the volume widget
mpdwidget = widget({ type = "textbox", name = "mpdvicious" })
vicious.register(mpdwidget, vicious.widgets.mpd,
    function (widget, args)
        if args["{state}"] == "Stop" then 
            return " mpd broken or stopped -- "
        elseif args["{state}"] == "Pause" then 
            return "mpd paused -- "
        else 
            return '<span color="#6BF273">'.. args["{Artist}"]..'</span>'..' | '..'<span color="#68EDA6">'..args["{Title}"]..'</span> -- '
            
        end
     
    end, 1)
 
 mpdwidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function()
       awful.util.spawn("mpc toggle")
       
      end),
   awful.button({ }, 4, function()
        awful.util.spawn("mpc next")
       vicious.force({ mpdwidget })
   end),
   awful.button({ }, 5, function()
       awful.util.spawn("mpc prev")
       vicious.force({ mpdwidget })
    end)
))

-- Dota 2 Compendium Widget, really stupid and made over an hour.

mywidget = widget({ type = "textbox" })
    vicious.register(mywidget, script_output, "<span color='#ffffff'> $1% </span>")

-- memory widget
memwidget = widget({ type = "textbox" })
vicious.register(memwidget, vicious.widgets.mem, "<span color='#E0E4CC'> $1% </span> -- ", 13)

-- cpu widget
cpuwidget = widget({ type = "textbox" })
vicious.register(cpuwidget, vicious.widgets.cpu, "<span color='#F38630'> $1%</span> -- ")


-- textclock widget
mytextclock = awful.widget.textclock({ align = "right" },  '<span color="#FA6900"> %a %b %d, %I:%M </span>', 60)

-- systray
mysystray = widget({ type = "systray" })
 
--Defining all the icons, most of them are either designed by me or from the great icon pack SansCons

 musicon = widget({ type = "imagebox" })
 musicon.image = image("/usr/share/awesome/themes/default/icons/darkmusic.png")

 cpuicon = widget({ type = "imagebox" })
 cpuicon.image = image("/usr/share/awesome/themes/default/icons/cpu.png")

 memicon = widget({ type = "imagebox" })
 memicon.image = image("/usr/share/awesome/themes/default/icons/mem.png")

 volicon = widget({ type = "imagebox" })
 volicon.image = image("/usr/share/awesome/themes/default/icons/volume_low.png")
 
 wificon = widget({ type = "imagebox" })
 wificon.image = image("/usr/share/awesome/themes/default/icons/wifi.png")
 
 clockicon = widget({ type = "imagebox" })
 clockicon.image = image("/usr/share/awesome/themes/default/icons/time2.png")
 
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    -- If you want to change the height or orientation of the taskbar, here is where you would do that.
    mywibox[s] = awful.wibox({ position = "bottom", height = "16", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
 -- widget box      
        mylayoutbox[s],
        mytextclock,
        clockicon,
        cpuwidget,
        cpuicon,
        memwidget,
        memicon,
        tb_volume,
        volicon,
        netwidget,
        wificon,
        mpdwidget,
        musicon,
        
        -- s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
	awful.key({ modkey }, "s", function () scratch.drop("urxvt", "top") end),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () awful.util.spawn("iceweasel") end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),
	awful.key({modkey,            }, "F1",     function () awful.screen.focus(3) end),
	awful.key({modkey,            }, "F2",     function () awful.screen.focus(1) end),
	awful.key({modkey,            }, "F3",     function () awful.screen.focus(2) end),
    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "iceweasel" },
      properties = { floating = false } },
      
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
        { rule = { class = "URxvt" },
      properties = { 
                     size_hints_honor = false } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- You will probably want to change this, it essentially defines things the must run on awesome starting.
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
    findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end
-- In order, spawns MPD, starts the Google Music proxy to play music, starts the x screensaver program.
run_once("mpd")
run_once("GMusicProxy")
run_once("xscreensaver -no-splash")
-- Reloads the volume widget at set intervels
awful.hooks.timer.register(10, function () volume("update", tb_volume) end)
