
local component = require("component")
local io = require("io")
local serialization = require("serialization")

local utils = {}

function utils.table_to_string_pretty(tbl, indent)
    if type(tbl) ~= "table" then
        return serialization.serialize(tbl)
    end

    if next(tbl) == nil then
        return "{}"
    end

    indent = indent or ""
    local result = "{"

    local is_first = true

    for k, v in pairs(tbl) do
        if type(k) == "number" then
            k = "[" .. k .. "]"
        end

        if type(v) == "table" then
            v = utils.table_to_string_pretty(v, indent .. "  ")
        end

        if is_first then
            is_first = false
        else
            result = result .. ","
        end

        result =  result .. "\n" .. indent .. "  " .. k .. " = " .. tostring(v)
    end

    return result .. "\n" .. indent .. "}"
end

function utils.slice(tbl, first, last, step)
    local sliced = {}
  
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end
  
    return sliced
end

function utils.keys(tbl)
    local keys = {}

    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end

    return keys
end

function utils.get_database_size(db)
    if type(db) == "string" then
        db = component.proxy(db)
    end

    if db.type ~= "database" then
        error("get_database_size must be called with a database component (proxy or address) as a parameter")
    end

    if pcall(db.get, 81) then
        return 81
    elseif pcall(db.get, 25) then
        return 25
    elseif pcall(db.get, 9) then
        return 9
    end

    error("could not determine database size: this should never happen")
end

local sides = require("sides")

utils.side_names = {
    [sides.bottom] = "bottom",
    [sides.top] = "top",
    [sides.west] = "west",
    [sides.east] = "east",
    [sides.north] = "north",
    [sides.south] = "south",
}

function utils.load(file)
    local file = io.open(file, "r")
    
    if file == nil then
        return nil
    end

    local contents = file:read("*a")
    
    if contents == "" then
        contents = nil
    end
    
    if contents ~= nil then
        contents = serialization.unserialize(contents)
    end
    
    file:close()
    
    return contents
end

function utils.save(file, contents)
    local file = io.open(file, "w")
    
    file:write(serialization.serialize(contents))
    file:flush()
    
    file:close()
end

function utils.deep_copy(value)
    if type(value) == "table" then
        local copy = {}
        for k, v in pairs(value) do
            copy[k] = utils.deep_copy(v)
        end
        return copy
    else
        return value
    end
end

return utils
