TTTBots.Locale = {
    Priorities = {}
}



--- Adds a localized string in the given language to the type
--- Unlike chat messages, we don't need to deal with variance.
---@param name string The identifier of the localized string
---@param text string The content of the localized string
---@param lang string The language to add the localized string to, e.g. "en"
function TTTBots.Locale.AddLocalizedString(name, text, lang)
    local lang = lang or "en"
    TTTBots.Locale[lang] = TTTBots.Locale[lang] or {}
    TTTBots.Locale[lang][name] = text
end

--- Gets a localized string name from the given language.
---@param name string
---@param ... any|nil Any varargs to pass to string.format
---@return string|nil string returns string if line exists, nil if it doesn't
function TTTBots.Locale.GetLocalizedString(name, ...)
    local lang = GetConVar("ttt_bot_language"):GetString()
    local str = TTTBots.Locale[lang] and TTTBots.Locale[lang][name] or ("ERR: no lang '" .. lang .. "'")

    -- check if we have any varargs before formatting
    if ... then
        str = string.format(str, ...)
        return str
    end

    return str
end

--- warning: do not move this include to the top of the file, it will cause an error. leave it below GetLocalizedString
AddCSLuaFile("tttbots2/locale/sh_strings_en.lua")
include("tttbots2/locale/sh_strings_en.lua")

--- Add a line into the localized strings table, according to its language. Depending on the type of event, the line may contain parameters.
--- An example is "Hi, my name is {{botname}}" -> "Hi, my name is Bob"
---@param event_name string The name of the event
---@param line string The line to add
---@param lang string The language to add the line to, e.g. "en"
---@param archetype string A string corresponding to a TTTBots.Archetypes enum
function TTTBots.Locale.AddLine(event_name, line, lang, archetype)
    local lang = lang or "en"
    local langtable = TTTBots.Locale[lang]
    if not langtable then
        TTTBots.Locale[lang] = {}
        langtable = TTTBots.Locale[lang]
    end
    langtable[event_name] = langtable[event_name] or {}

    table.insert(langtable[event_name], {
        line = line,
        archetype = archetype or "default"
    })

    -- print(string.format("Added line '%s' to event '%s' in language '%s'", line, event_name, lang))
end

--- Format a line with parameters
---@param line string The line to format
---@param params table<string, string> A table of parameters to replace in the line
---@return string line The formatted line
function TTTBots.Locale.FormatLine(line, params)
    if not line then return "" end
    if not (params) then return line end
    for key, value in pairs(params) do
        line = line:gsub("{{" .. tostring(key) .. "}}", tostring(value))
    end
    return line
end

local function getArchetypalLines(bot, localizedTbl, forceDefault)
    local archetypeLocalized = {}
    local personality = bot.components.personality ---@type CPersonality
    for i, entry in pairs(localizedTbl) do
        if entry.archetype == (forceDefault and TTTBots.Archetypes.Default) or personality.archetype then
            table.insert(archetypeLocalized, entry)
        end
    end
    if #archetypeLocalized == 0 and not forceDefault then -- add forceDefault check to prevent infinite recursion
        return getArchetypalLines(bot, localizedTbl, true)
    end

    return archetypeLocalized
end

--- Gets a random valid line from the given event name and language. After 20 attempts, it will return nil.
---@param event_name string
---@param lang string
---@param bot Player
---@param attemptN number|nil
---@return string|nil
function TTTBots.Locale.GetLine(event_name, lang, bot, attemptN)
    if attemptN and attemptN > 20 then return nil end
    local localizedTbl = TTTBots.Locale[lang] and TTTBots.Locale[lang][event_name]
    if not localizedTbl then
        TTTBots.Locale[lang] = TTTBots.Locale[lang] or {}
        TTTBots.Locale[lang][event_name] = TTTBots.Locale[lang][event_name] or {}
        print("No localized strings for event " ..
            event_name .. " in language " .. lang .. "... try setting lang cvar to 'en'.")
        return
    end

    local archetypeLocalizedLines = getArchetypalLines(bot, localizedTbl)
    local randArchetypal = table.Random(archetypeLocalizedLines)

    if not randArchetypal then return nil end

    return randArchetypal.line
end

function TTTBots.Locale.GetLocalizedLine(event_name, bot, params)
    local lang = TTTBots.Lib.GetConVarString("language")

    -- Test that the event event_name exists in the language.
    local exists = TTTBots.Locale.TestEventExists(event_name)
    if not exists then
        print("No localized strings for event " ..
            event_name .. " in language " .. lang .. "... try setting lang cvar to 'en'.")
        return false
    end
    -- Check if this selected category is enabled, per the user's settings.
    local categoryEnabled = TTTBots.Locale.CategoryIsEnabled(event_name)
    if not categoryEnabled then return false end

    -- Get the localized line for this event, then format it.
    local formatted = TTTBots.Locale.FormatLine(TTTBots.Locale.GetLine(event_name, lang, bot), params)

    -- Sometimes it will format to nothing or be nil, so we check for that.
    if not formatted or formatted == "" then return false end
    return formatted
end

--- Return true if the event has any lines associated in this language.
---@param event_name string
---@return boolean
function TTTBots.Locale.TestEventExists(event_name)
    local lang = TTTBots.Lib.GetConVarString("language")
    return TTTBots.Locale[lang] and TTTBots.Locale[lang][event_name] and true or false
end

function TTTBots.Locale.GetLocalizedPlanLine(event_name, bot, params)
    local lang = TTTBots.Lib.GetConVarString("language")
    local modifiedEvent = "Plan." .. event_name

    return TTTBots.Locale.GetLocalizedLine(modifiedEvent, bot, params)
end

--- Registers an event type with the given priority. This is used to cull undesired chatter (user customization)
function TTTBots.Locale.RegisterCategory(event_name, lang, priority)
    local lang = lang or "en"
    local langtable = TTTBots.Locale[lang]
    if not langtable then
        TTTBots.Locale[lang] = {}
        langtable = TTTBots.Locale[lang]
    end
    langtable[event_name] = langtable[event_name] or {}
    TTTBots.Locale.Priorities[event_name] = priority
end

function TTTBots.Locale.CategoryIsEnabled(event_name)
    local maxlevel = TTTBots.Lib.GetConVarFloat("chatter_lvl")
    local level = TTTBots.Locale.Priorities[event_name]
    return level and (level <= maxlevel) or false
end
