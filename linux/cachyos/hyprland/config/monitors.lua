-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = MONITOR1,
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "0x0", scale = 1.25 })
hl.monitor({ output = "desc:AOC 24G2W1G4 UKCN7XA003070", mode = "1920x1080@144", position = "auto", scale = 1 })
hl.monitor({ output = "desc:Dell Inc. DELL P2317H 4WY7073T4P8B", mode = "1920x1080", position = "auto", scale = 1 })
