local M = {}

function M.shoot(api)
    api:shootOnce(api:isShootingNeedConsumeAmmo())
end

local function isNoAmmo(api)
    return (not api:hasAmmoInBarrel()) and (api:getAmmoAmount() <= 0)
end

function M.start_reload(api)
    -- Initialize cache that will be used in reload ticking
    local cache = {
        reloaded_count = 0,
        needed_count = api:getNeededAmmoAmount(),
        is_tactical = api:getReloadStateType() == TACTICAL_RELOAD_FEEDING,
        interrupted_time = -1,
        reload_type = "NULL"
    }
    if (api:getAmmoAmount() <= 0 and (not api:hasAmmoInBarrel())) then
        cache.reload_type = "EMPTY"
    else
        cache.reload_type = "TACTICAL"
    end
    api:cacheScriptData(cache)
    -- Return true to start ticking
    return true
end

local function getReloadTimingFromParam(param, api)
    -- Need to convert time from seconds to milliseconds
    local intro = 0
    local loop = 0
    local ending = 0
    local loop_feed = 0
    local cache = api:getCachedScriptData()
    if (cache.reload_type == "EMPTY") then
        intro = param.intro_empty * 1000
        loop = param.loop_empty * 1000
        ending = param.ending_empty * 1000
        loop_feed = param.loop_empty_feed * 1000
    elseif (cache.reload_type == "TACTICAL") then
        intro = param.intro_tactical * 1000
        loop = param.loop_tactical * 1000
        ending = param.ending_tactical * 1000
        loop_feed = param.loop_tactical_feed * 1000
    end
    return intro, loop, ending, loop_feed
end

function M.tick_reload(api)
    -- Get all timings from script parameter in gun data
    local param = api:getScriptParams();
    local intro, loop, ending, loop_feed = getReloadTimingFromParam(param, api)

    -- Get reload time (The time from the start of reloading to the current time) from api
    local reload_time = api:getReloadTime()
    -- Get cache from api, it will be used to count loaded ammo, mark reload interruptions, etc.
    local cache = api:getCachedScriptData()
    local interrupted_time = cache.interrupted_time
    -- Handle interrupting reload
    if (interrupted_time ~= -1) then
        local int_time = reload_time - interrupted_time
        if (int_time >= ending) then
            return NOT_RELOADING, -1
        else
            if (cache.is_tactical) then
                return TACTICAL_RELOAD_FINISHING, ending - int_time
            else
                return EMPTY_RELOAD_FINISHING, ending - int_time
            end
        end
    else
        -- if there is no ammo to consume, interrupt reloading
        if (not api:hasAmmoToConsume()) then
            interrupted_time = api:getReloadTime()
        end
    end
    -- Put an ammo into the barrel first
    local reloaded_count = cache.reloaded_count;
    if (reloaded_count == 0) then
        if (reload_time > intro) then
            reloaded_count = reloaded_count + 1
        end
    end
    -- Load the ammo into the magazine one by one
    if (reloaded_count > 0) then
        local base_time = (reloaded_count -1) * loop + loop_feed
        base_time = base_time + intro
        while (base_time < reload_time) do
            if (reloaded_count > cache.needed_count) then
                break
            end
            reloaded_count = reloaded_count + 1
            base_time = base_time + loop
            api:consumeAmmoFromPlayer(1)
            api:putAmmoInMagazine(1)
        end
    end
    -- Write back cache
    if (reloaded_count > cache.needed_count) then
        interrupted_time = api:getReloadTime() - loop_feed + loop
    end
    cache.interrupted_time = interrupted_time
    cache.reloaded_count = reloaded_count
    api:cacheScriptData(cache)
    -- return reloadstate
    local total_time = cache.needed_count * loop
    if (not cache.is_tactical) then
        total_time = total_time + intro
        return EMPTY_RELOAD_FEEDING, total_time - reload_time
    else
        total_time = total_time + intro
        return TACTICAL_RELOAD_FEEDING, total_time - reload_time
    end
end

function M.interrupt_reload(api)
    local cache = api:getCachedScriptData()
    if (cache ~= nil and cache.interrupted_time == -1) then
        cache.interrupted_time = api:getReloadTime()
    end
end

return M