-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = MONITOR1,
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "0x0", scale = 1.25 })
hl.monitor({ output = "{{MONITOR_2}}", mode = "1920x1080@144", position = "auto", scale = 1 })
hl.monitor({ output = "{{MONITOR_3}}", mode = "1920x1080", position = "auto", scale = 1 })
