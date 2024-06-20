
local os = require("os")

local LEVEL_ERROR = 0
local LEVEL_WARN = 1
local LEVEL_INFO = 2
local LEVEL_TRACE = 3
local LEVEL_DEBUG = 4

return function(settings)
    local logging = {}
    
    logging.settings = {
        debug = settings.debug or false,
        max_level = settings.max_level or LEVEL_INFO,
        start_time = settings.start_time or os.time() / 72,
    }

    function logging.log(level, message)
        local since_start = (os.time() / 72 - logging.settings.start_time)
        print(string.format("[%4.2f %s] %s", since_start, level, message))
    end

    function logging.error(message)
        if logging.settings.max_level >= LEVEL_ERROR then
            logging.log("ERROR", message)
        end
    end

    function logging.warn(message)
        if logging.settings.max_level >= LEVEL_WARN then
            logging.log("WARNING", message)
        end
    end

    function logging.info(message)
        if logging.settings.max_level >= LEVEL_INFO then
            logging.log("INFO", message)
        end
    end

    function logging.trace(message)
        if logging.settings.max_level >= LEVEL_TRACE then
            logging.log("TRACE", message)
        end
    end

    function logging.debug(message)
        if logging.settings.max_level >= LEVEL_DEBUG or logging.settings.debug then
            logging.log("DEBUG", message)
        end
    end

    return logging
end
