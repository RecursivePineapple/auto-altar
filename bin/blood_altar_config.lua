
local component = require("component")
local serialization = require("serialization")
local filesystem = require("filesystem")
local sides = require("sides")

local utils = require("blood_altar.utils")
local orbs = require("blood_altar.orbs")

local config_utils = require("blood_altar.config_utils")

local config = utils.load("/etc/blood-altar.cfg") or {}

if config.on_high == nil then
    config.on_high = true
end

if config.refill_period == nil then
    config.refill_period = 0
end

print("blood altar configuration tool")

local function get_side_name(side, transposer)
    if side == nil then
        return "nil"
    else
        local inv_name = nil

        local proxy = component.proxy(transposer or "")
        if proxy ~= nil then
            inv_name = proxy.getInventoryName(side)
        end

        if inv_name ~= nil then
            return utils.side_names[side] .. " (inventory name = " .. inv_name .. ")"
        else
            return utils.side_names[side]
        end
    end
end

local function print_address(name, address, target_type)
    local proxy = component.proxy(address or "")

    print(name .. " address: " .. (address or "nil") .. (proxy and (" (address refers to component of type '" .. proxy.type .. "')") or (address and " (address invalid - component not connected)" or "")))

    if proxy and target_type and proxy.type ~= target_type then
        print("Warning: component should be a " .. target_type)
    end
end

local function print_side(name, side, transposer)
    print(name .. " side: " .. get_side_name(side, transposer))
end

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
        "Set enable signal to " .. (config.on_high and "'Disable with Redstone'" or "'Enable with Redstone'"),
        "Select orb",
        "Set minimum time between soul network refills",
        "Save and exit"
    })

    if option == 1 then
        break
    elseif option == 2 then
        print_address("Altar", config.altar, "blood_altar")
        print_address("Transposer", config.transposer, "transposer")
        print_address("Redstone I/O", config.redstone, "redstone")
        print()

        print_side("Input", config.input_side, config.transposer)
        print_side("Staging", config.staging_side, config.transposer)
        print_side("Altar", config.altar_side, config.transposer)
        print_side("Output", config.output_side, config.transposer)
        print_side("Redstone enable", config.redstone_side, nil)
        print()

        if config.on_high then
            print("Redstone signal will be high when the altar should be on")
        else
            print("Redstone signal will be low when the altar should be on")
        end

        print()
        print("Orb: ".. (orbs.get_orb_label(config.blood_orb) or "nil"))
        print()
        print("Soul network refill period: " .. (config.refill_period or "nil"))
        print()

    elseif option == 3 then
        config_utils.select_component("blood_altar", config, "altar")
    elseif option == 4 then
        config_utils.select_component("transposer", config, "transposer")
    elseif option == 5 then
        config.input_side = config_utils.get_transposer_side(config.transposer) or config.input_side
    elseif option == 6 then
        config.output_side = config_utils.get_transposer_side(config.transposer) or config.output_side
    elseif option == 7 then
        config.staging_side = config_utils.get_transposer_side(config.transposer) or config.staging_side
    elseif option == 8 then
        config.altar_side = config_utils.get_transposer_side(config.transposer) or config.altar_side
    elseif option == 9 then
        config_utils.select_component("redstone", config, "redstone")
    elseif option == 10 then
        config.redstone_side = config_utils.get_side() or config.redstone_side
    elseif option == 11 then
        config.on_high = not config.on_high
    elseif option == 12 then
        local options = { "Cancel" }

        for i, orb in ipairs(orbs.orbs) do
            options[#options + 1] = orb.label
        end

        local opt = config_utils.get_option(options)

        if opt ~= 1 then
            config.blood_orb = orbs.orbs[opt - 1].name
        end
    elseif option == 13 then
        while true do
            io.write("Enter the number of seconds between soul network refills (while active): ")
    
            local n = io.read("*n")
    
            if n ~= nil and n >= 0 then
                print()
                config.refill_period = n
                break
            end
    
            print("Invalid option, expected a number greater than or equal to zero")
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
