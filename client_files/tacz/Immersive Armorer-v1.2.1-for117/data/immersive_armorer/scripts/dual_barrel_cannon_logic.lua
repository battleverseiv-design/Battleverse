local M = {}

local function getReloadTimingFromParam(param)
    local empty_feed = param.empty_feed * 1000
    local empty_cooldown = param.empty_cooldown * 1000
    local tactical_feed = param.tactical_feed * 1000
    local tactical_cooldown = param.tactical_cooldown * 1000
    if (empty_feed == nil or empty_cooldown == nil or tactical_feed == nil or tactical_cooldown == nil) then
        return nil
    end
    return empty_feed, empty_cooldown, tactical_feed, tactical_cooldown
end

function M.start_reload(api)
    local cache = {
        needed_count = api:getNeededAmmoAmount(),
        reloaded_flag = 0,
        is_tactical = api:getAmmoAmount() >= 6,
    }
    api:cacheScriptData(cache)
    return true
end

function M.tick_reload(api)
    local param = api:getScriptParams();
    local empty_feed, empty_cooldown, tactical_feed, tactical_cooldown = getReloadTimingFromParam(param)
    local reload_time = api:getReloadTime()
    local cache = api:getCachedScriptData()
    if (empty_feed == nil or empty_cooldown == nil or tactical_feed == nil or tactical_cooldown == nil) then
        return nil
    end
    if (cache.is_tactical) then
        -- 战术
        if (reload_time < tactical_feed) then
            return TACTICAL_RELOAD_FEEDING, tactical_feed - reload_time
        elseif (reload_time >= tactical_feed and reload_time < tactical_cooldown) then
            if (cache.reloaded ~= 1) then
                if (api:isReloadingNeedConsumeAmmo()) then
                    api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                else
                    api:putAmmoInMagazine(cache.needed_count)
                end
                cache.reloaded = 1
                api:cacheScriptData(cache)
            end
            return TACTICAL_RELOAD_FINISHING, tactical_cooldown - reload_time
        else
            return NOT_RELOADING, -1
        end
    else
        -- 空仓
        if (reload_time < empty_feed) then
            return TACTICAL_RELOAD_FEEDING, empty_feed - reload_time
        elseif (reload_time >= empty_feed and reload_time < empty_cooldown) then
            if (cache.reloaded ~= 1) then
                if (api:isReloadingNeedConsumeAmmo()) then
                    api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                else
                    api:putAmmoInMagazine(cache.needed_count)
                end
                cache.reloaded = 1
                api:cacheScriptData(cache)
            end
            return TACTICAL_RELOAD_FINISHING, empty_cooldown - reload_time
        else
            return NOT_RELOADING, -1
        end
    end
end

return M