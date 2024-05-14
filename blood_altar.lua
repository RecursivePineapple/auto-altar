
local os = require("os")
local component = require("component")

local utils = require("utils")
local orbs = require("orbs")

local config = utils.load("/etc/blood-altar.cfg")

if config == nil then
    print("could not load config")
    return
end

local wait_timeout = 5 * 60
local idle_timeout = 5

local altar = component.proxy(config.altar)
local transposer = component.proxy(config.transposer)
local redstone = component.proxy(config.redstone)

local is_active = nil
local last_inserted_item = nil

function set_active(active)
    if active == is_active then
        return
    end
    is_active = active

    if active then
        print("starting altar")
        if config.on_high then
            redstone.setOutput(config.redstone_side, 15)
        else
            redstone.setOutput(config.redstone_side, 0)
        end
    else
        print("stopping altar")
        if config.on_high then
            redstone.setOutput(config.redstone_side, 0)
        else
            redstone.setOutput(config.redstone_side, 15)
        end
    end
end

function get_active_item()
    return transposer.getStackInSlot(config.altar_side, 1)
end

function clear_altar(message)
    print("clearing altar: " .. message)
    transposer.transferItem(config.altar_side, config.staging_side, 64)
    set_active(false)
end

function fill_altar(input_side, input_slot)
    transposer.transferItem(input_side, config.altar_side, 64, input_slot)
    last_inserted_item = get_active_item()
    print("putting item into altar: " .. last_inserted_item.label)
end

function wait_until_finished(start_item)
    local start_item = start_item or get_active_item()

    if start_item == nil then
        set_active(false)
        return
    end

    local idle_since = nil

    local start = os.time() / 72

    set_active(true)

    local last_blood = nil
    
    local waiting_for_orb = orbs.is_item_an_orb(start_item)

    while true do
        local now = os.time() / 72

        if (now - start) > wait_timeout then
            clear_altar("timed out while waiting for altar to finish")
            return false
        end

        if waiting_for_orb then
            local amount_filled = redstone.getInput(config.redstone_input_side)

            if amount_filled == 15 then
                clear_altar("soul network is full")

                return true
            end
        else
            local current_blood = altar.getCurrentBlood()

            if current_blood == last_blood then
                if idle_since == nil then
                    idle_since = now
                end
            else
                idle_since = nil
            end

            if idle_since ~= nil and (now - idle_since) > idle_timeout then
                if last_blood == altar.getCapacity() then
                    clear_altar("altar is idle")
                    return true
                else
                    clear_altar("altar ran out of LP")
                    return false
                end
            end

            last_blood = current_blood
        end

        local current_item = get_active_item()

        if current_item == nil or current_item.name == nil then
            clear_altar("item is missing")
            return false
        end

        if current_item.name ~= start_item.name then
            clear_altar("item has changed")
            return true
        end

        os.sleep(0)
    end
end

function is_item_the_orb(item)
    return item ~= nil and item.name ~= nil and item.name == config.blood_orb
end

last_inserted_item = get_active_item()

::active::

if last_inserted_item ~= nil then
    if not wait_until_finished(last_inserted_item) then
        if interrupted then
            return
        end

        print("could not wait for altar to finish: program will exit")
        set_active(false)
        return
    end
end

local found_orb = false

for i, item in pairs(transposer.getAllStacks(config.staging_side).getAll()) do
    if not found_orb and is_item_the_orb(item) then
        found_orb = true
    elseif item.name ~= nil then
        print("moving item from staging to output: " .. item.label)
        transposer.transferItem(config.staging_side, config.output_side, 64, i + 1)
    end
end

if last_inserted_item ~= nil and is_item_the_orb(last_inserted_item) then
    last_inserted_item = nil

    for i, item in pairs(transposer.getAllStacks(config.input_side).getAll()) do
        if item.label ~= nil then
            fill_altar(config.input_side, i + 1)
            break
        end
    end
else
    last_inserted_item = nil

    local found_orb = false

    for i, item in pairs(transposer.getAllStacks(config.staging_side).getAll()) do
        if not found_orb and is_item_the_orb(item) then
            fill_altar(config.staging_side, i + 1)
            found_orb = true
        elseif item.name ~= nil then
            transposer.transferItem(config.staging_side, config.output_side, 64, i + 1)
            print("moving item from staging to output: " .. item.label)
        end
    end

    if not found_orb then
        set_active(false)
        print("could not find an orb: put one in the staging chest")
        return
    end
end

if last_inserted_item == nil then
    print("no items in input chest: idling")
    goto idle
end

os.sleep(0)

goto active

::idle::
os.sleep(0)

for i, item in pairs(transposer.getAllStacks(config.input_side).getAll()) do
    if item.label ~= nil then
        print("found a pending input item: activating")
        goto active
    end
end

local active_item = get_active_item()

if active_item ~= nil and active_item.label ~= nil and not is_item_the_orb(active_item) then
    last_inserted_item = active_item
    print("found an item in the altar: activating")
    goto active
end

if active_item == nil or active_item.label == nil then
    local found_orb = false
    
    for i, item in pairs(transposer.getAllStacks(config.staging_side).getAll()) do
        if is_item_the_orb(item) then
            fill_altar(config.staging_side, i + 1)
            found_orb = true
            break
        end
    end

    if not found_orb then
        set_active(false)
        print("could not find an orb: put one in the staging chest")
        return
    end
end

local amount_filled = redstone.getInput(config.redstone_input_side)

if amount_filled == 15 then
    if is_active then
        print("soul network is full")
        set_active(false)
    end
else
    if not is_active and is_item_the_orb(get_active_item()) then
        print("soul network isn't full")
        set_active(true)
    end
end

goto idle
