
local component = require("component")
local serialization = require("serialization")
local filesystem = require("filesystem")
local sides = require("sides")

local utils = require("utils")
local orbs = require("orbs")

local config_utils = require("config_utils")

local config = utils.load("/etc/blood-altar.cfg") or {}

if config.on_high == nil then
    config.on_high = true
end


print("blood altar configuration tool")

while true do
    ::start::

    local option = config_utils.get_option({
        "Exit without saving",
        "Show pending altar config",
        "Set altar",
        "Set transposer",
        "Set input chest side",
        "Set output chest side",
        "Set staging chest side",
        "Set altar side",
        "Set redstone i/o",
        "Set altar redstone WA enable side",
        "Set altar redstone comparator side",
        "Set enable signal to " .. (config.on_high and "'Disable with Redstone'" or "'Enable with Redstone'"),
        "Select orb",
        "Save and exit"
    })

    if option == 1 then
        break
    elseif option == 2 then
        print(utils.table_to_string_pretty(config))
    elseif option == 3 then
        config_utils.select_component("blood_altar", config, "altar")
    elseif option == 4 then
        config_utils.select_component("transposer", config, "transposer")
    elseif option == 5 and config.transposer ~= nil then
        config.input_side = config_utils.get_transposer_side(config.transposer)
    elseif option == 6 and config.transposer ~= nil then
        config.output_side = config_utils.get_transposer_side(config.transposer)
    elseif option == 7 and config.transposer ~= nil then
        config.staging_side = config_utils.get_transposer_side(config.transposer)
    elseif option == 8 and config.transposer ~= nil then
        config.altar_side = config_utils.get_transposer_side(config.transposer)
    elseif option == 9 then
        config_utils.select_component("redstone", config, "redstone")
    elseif option == 10 then
        local side = config_utils.get_side()

        if side ~= nil then
            config.redstone_side = side
        end
    elseif option == 11 then
        local side = config_utils.get_side()

        if side ~= nil then
            config.redstone_input_side = side
        end
    elseif option == 12 then
        config.on_high = not config.on_high
    elseif option == 13 then
        local options = { "Cancel" }

        for i, orb in ipairs(orbs.orbs) do
            options[#options + 1] = orb.label
        end

        local opt = config_utils.get_option(options)

        if opt ~= 1 then
            config.blood_orb = orbs.orbs[opt - 1].name
        end
    elseif option == 14 then
        if filesystem.exists("/etc/blood-altar.cfg") then
            filesystem.rename("/etc/blood-altar.cfg", "/etc/blood-altar-backup.cfg")
            print("Backed up old config to /etc/blood-altar-backup.cfg")
        end

        utils.save("/etc/blood-altar.cfg", config)
        print("Saved altar config")
        break
    end
end
