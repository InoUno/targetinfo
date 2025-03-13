--[[
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2025 InoUno
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy
 *	of this software and associated documentation files (the "Software"), to
 *	deal in the Software without restriction, including without limitation the
 *	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the Software is
 *	furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *	DEALINGS IN THE SOFTWARE.
]]
--

addon.name = "targetinfo"
addon.author = "InoUno"
addon.version = "1.0.0"
addon.desc = "Shows information about the current target."
addon.link = "https://github.com/InoUno/targetinfo"

require("common")
local fonts = require("fonts")
local scale = require("scaling")
local settings = require("settings")

---------------------------------------------------------------------------------------------------
-- desc: Default configuration table.
---------------------------------------------------------------------------------------------------
local default_settings = T({
    font = {
        color = 0xFFFFFFFF,
        font_family = "Verdana",
        font_height = scale.scale_font(10),
        padding = 1,
        position_x = scale.scale_w(130),
        position_y = scale.scale_h(0),
        background = {
            color = 0x96000000,
            visible = true,
        },
    },
})

local targetinfo = T({
    font = nil,
    settings = settings.load(default_settings),
})

local update_settings = function(s)
    if s ~= nil then
        targetinfo.settings = s
    end

    -- Apply the font settings..
    if targetinfo.font ~= nil then
        targetinfo.font:apply(targetinfo.settings.font)
    end

    settings.save()
end

-------------------------------------------------
-- Misc. functionality
-------------------------------------------------

local function addon_print(text)
    print("\31\200[\31\05" .. addon.name .. "\31\200]\30\01 " .. text)
end

----------------------------------------------------------------------------------------------------
-- func: usage
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function print_usage(cmd, help)
    -- Loop and print the help commands..
    for _, v in pairs(help) do
        addon_print("\30\68Syntax:\30\02 " .. v[1] .. "\30\71 " .. v[2])
    end
end

local compassDirections = {
    "N",
    "NE",
    "E",
    "SE",
    "S",
    "SW",
    "W",
    "NW",
    "N",
}

local function update_text()
    local target = AshitaCore:GetMemoryManager():GetTarget()
    local index = target:GetTargetIndex(0)
    if index == 0 then
        targetinfo.font.text = ""
        return
    end

    local entity = AshitaCore:GetMemoryManager():GetEntity():GetRawEntity(index)
    if not entity then
        targetinfo.font.text = ""
        return
    end

    local id = entity.ServerId
    local name = entity.Name

    local pos = entity.Movement.LocalPosition
    local x = pos.X
    local y = pos.Y
    local z = pos.Z

    local yaw = pos.Yaw
    local rot = yaw * 128 / math.pi + 64
    if rot > 256 then
        rot = rot - 256
    elseif rot < 0 then
        rot = rot + 256
    end
    local compass = compassDirections[math.floor((rot + 16) / 32) + 1]

    local zone = GetPlayerEntity().ZoneId

    local doorId = entity.DoorId
    local doorStr = ""
    if doorId > 0 then
        doorStr = (" (%s)"):fmt(
            string.char(bit.band(doorId, 0xFF))
                .. string.char(bit.band(bit.rshift(doorId, 8), 0xFF))
                .. string.char(bit.band(bit.rshift(doorId, 16), 0xFF))
                .. string.char(bit.band(bit.rshift(doorId, 24), 0xFF))
        )
    end

    targetinfo.font.text = ("  %s%s  |  %u [0x%03X]  |  (%.1f, %.1f, %.1f)  |  %3u %s  |  Zone: %u  "):fmt(
        name,
        doorStr,
        id,
        index,
        x,
        y,
        z,
        rot,
        compass,
        zone
    )
end

---------------------------------------------------------------------------------------------------
-- Registers a callback for the settings to monitor for character switches.
---------------------------------------------------------------------------------------------------
settings.register("settings", "settings_update", update_settings)

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.events.register("load", "load_cb", function()
    targetinfo.font = fonts.new(targetinfo.settings.font)
end)

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.events.register("unload", "unload_cb", function()
    if targetinfo.font ~= nil then
        targetinfo.font:destroy()
        targetinfo.font = nil
    end
end)

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.events.register("command", "command_cb", function(e)
    -- Get the arguments of the command..
    local args = e.command:args()
    if args[1] ~= "/tinfo" then
        return false
    end

    -- Prints the addon help..
    print_usage("/tinfo", {})
    return true
end)

---------------------------------------------------------------------------------------------------
-- event: d3d_present
-- desc : Event called when the Direct3D device is presenting a scene.
---------------------------------------------------------------------------------------------------
ashita.events.register("d3d_present", "present_cb", function()
    update_text()
end)
