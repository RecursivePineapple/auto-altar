
local os = require("os")
local component = require("component")
local event = require("event")

local utils = require("blood_altar.utils")
local orbs = require("blood_altar.orbs")
local logging = require("blood_altar.logging")

local config = utils.load("/etc/blood-altar.cfg")

if config == nil then
    print("error: could not load config")
    return
end

local function check_address(addr, name)
    if addr == nil then
        print("error: " .. name .. " address was not set")
        return false
    end

    if component.proxy(addr) == nil then
        print("error: " .. name .. " address is set, but the altar was not connected to the computer: try re-entering it")
        return false
    end

    return true
end

local tpose_sides = {}

local function check_tpose_side(transposer, side, name)
    if side == nil then
        print("error: '" .. name .. "' side was not set")
        return false
    end

    if transposer.getInventoryName(side) == nil then
        print("error: '" .. name .. "' side was set, but no inventory is present at that side")
        return false
    end

    if tpose_sides[side] then
        print("error: '" .. name .. "' side conflicts with '" .. tpose_sides[side]:lower() .. "' side: two inventories cannot share the same transposer side")
        return false
    end

    tpose_sides[side] = name

    return true
end

if not check_address(config.altar, "altar") then return end
if not check_address(config.transposer, "transposer") then return end
if not check_address(config.redstone, "redstone") then return end

local altar = component.proxy(config.altar)
local transposer = component.proxy(config.transposer)
local redstone = component.proxy(config.redstone)

if not check_tpose_side(transposer, config.input_side, "input") then return end
if not check_tpose_side(transposer, config.altar_side, "altar") then return end
if not check_tpose_side(transposer, config.staging_side, "staging") then return end
if not check_tpose_side(transposer, config.output_side, "output") then return end

if config.redstone_side == nil then
    print("error: redstone side was not set")
    return
end

local logger = logging({
    app_name = "blood_altar",
    debug = config.debug_logs,
    max_level = config.max_log_level,
})

local idle_timeout = 10

local is_active = nil
local last_inserted_item = nil

function set_active(active)
    if active == is_active then
        return
    end
    is_active = active

    if active then
        logger.info("starting altar")
        if config.on_high then
            redstone.setOutput(config.redstone_side, 15)
        else
            redstone.setOutput(config.redstone_side, 0)
        end
    else
        logger.info("stopping altar")
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
    logger.info("clearing altar: " .. message)
    transposer.transferItem(config.altar_side, config.staging_side, 64)
    set_active(false)
end

function fill_altar(input_side, input_slot)
    -- sleep so that the altar doesn't eat the item
    while altar.getProgress() > 0 do
        if event.pull(0, "interrupted") ~= nil then
            logger.info("interrupted")
            set_active(false)
            os.exit()
        end
    end
    transposer.transferItem(input_side, config.altar_side, 64, input_slot)
    last_inserted_item = get_active_item()
    logger.info("putting item into altar: " .. (last_inserted_item and last_inserted_item.label or "nil"))
end

function wait_until_finished(start_item)
    local start_item = start_item or get_active_item()

    if start_item == nil then
        set_active(false)
        return
    end

    local idle_since = nil
    local last_progress = altar.getProgress()

    local start = os.time() / 72

    set_active(true)

    local waiting_for_orb = orbs.is_item_an_orb(start_item)

    if waiting_for_orb then
        logger.info("waiting for soul network to fill")
    else
        logger.info("waiting for " .. start_item.label .. " to finish")
    end

    while true do
        local now = os.time() / 72

        if waiting_for_orb then
            local current_blood = altar.getCurrentBlood()
    
            if current_blood >= altar.getCapacity() * 0.9 or current_blood == 0 then
                if idle_since == nil then
                    idle_since = now
                end
            else
                idle_since = nil
            end
    
            if idle_since ~= nil and (now - idle_since) > idle_timeout then 
                if current_blood > 0 then
                    clear_altar("soul network is full")
                    return true
                else
                    clear_altar("altar ran out of LP")
                    return false
                end
            end
        else
            if idle_since ~= nil and (now - idle_since) > idle_timeout then
                if current_blood > 0 then
                    clear_altar("altar is idle")
                    return true
                else
                    clear_altar("altar ran out of LP")
                    return false
                end
            end
        end

        local current_item = get_active_item()

        if current_item == nil or current_item.name == nil then
            clear_altar("item is missing")
            return true
        end

        if current_item.name ~= start_item.name then
            clear_altar("item has changed")
            return true
        end

        if event.pull(0, "interrupted") ~= nil then
            logger.info("interrupted")
            return false
        end
    end
end

function is_item_the_orb(item)
    return item ~= nil and item.name ~= nil and item.name == config.blood_orb
end

last_inserted_item = get_active_item()
last_refill = 0
skip_next_wait = false

if is_item_the_orb(last_inserted_item) then
    logger.info("the orb was already in the altar: moving to the idle state")
    goto enter_idle
end

::enter_active::
logger.info("entering active state")

::active::

if is_item_the_orb(last_inserted_item) then
    last_refill = os.time() / 72
end

if not skip_next_wait and last_inserted_item ~= nil then
    if not wait_until_finished(last_inserted_item) then
        logger.error("could not wait for altar to finish: program will exit")
        set_active(false)
        return
    end
end

skip_next_wait = false

found_orb = false

for i, item in pairs(transposer.getAllStacks(config.staging_side).getAll()) do
    if not found_orb and is_item_the_orb(item) then
        -- only keep one orb
        found_orb = true
    elseif item.name ~= nil then
        transposer.transferItem(config.staging_side, config.output_side, 64, i + 1)
        logger.info("moving item from staging to output: " .. item.label)
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
            found_orb = true
            if config.refill_period == nil or (os.time() / 72 - last_refill) > config.refill_period then
                fill_altar(config.staging_side, i + 1)
            else
                -- we want to add a non-orb item to the altar, but we don't want to wait for an empty altar
                last_inserted_item = item
                skip_next_wait = true
            end
        elseif item.name ~= nil then
            transposer.transferItem(config.staging_side, config.output_side, 64, i + 1)
            logger.info("moving item from staging to output: " .. item.label)
        end
    end

    if not found_orb then
        set_active(false)
        logger.warn("could not find an orb: put one in the staging chest; script will sleep 30s")
        if event.pull(30, "interrupted") ~= nil then
            logger.info("interrupted")
            set_active(false)
            return
        end
        
        goto active
    end
end

if last_inserted_item == nil then
    logger.info("no items in input chest: idling")
    goto enter_idle
end

if event.pull(0, "interrupted") ~= nil then
    logger.info("interrupted")
    set_active(false)
    return
end

goto active

::enter_idle::
logger.info("entering idle state")

local last_blood = altar.getCurrentBlood()

::idle::
for i, item in pairs(transposer.getAllStacks(config.input_side).getAll()) do
    if item.label ~= nil then
        logger.info("found a pending input item: " .. item.label)
        goto enter_active
    end
end

local active_item = get_active_item()

if active_item ~= nil and active_item.label ~= nil and not is_item_the_orb(active_item) then
    last_inserted_item = active_item
    logger.info("found an item in the altar: activating")
    goto enter_active
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
        logger.warn("could not find an orb: put one in the staging chest; script will sleep 30s")
        if event.pull(30, "interrupted") ~= nil then
            logger.info("interrupted")
            set_active(false)
            return
        end
        
        goto idle
    end
end

local current_blood = altar.getCurrentBlood()

if current_blood < last_blood then
    if not wait_until_finished() then
        logger.error("could not wait for soul network to fill: program will exit")
        set_active(false)
        return
    end
    last_blood = altar.getCurrentBlood()
end

if event.pull(1, "interrupted") ~= nil then
    logger.info("interrupted")
    set_active(false)
    return
end

goto idle
