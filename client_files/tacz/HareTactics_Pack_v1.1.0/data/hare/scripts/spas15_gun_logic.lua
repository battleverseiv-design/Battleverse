local M = {}

function M.shoot(api)
    if (api:getFireMode() == BURST) then
        api:shootOnce(api:isShootingNeedConsumeAmmo())
        if (api:removeAmmoFromMagazine(1) == 1) then
            api:setAmmoInBarrel(true)
        end
    else
        api:shootOnce(api:isShootingNeedConsumeAmmo())
    end
end

function M.start_bolt(api)
    return true
end

function M.tick_bolt(api)
    local params = api:getScriptParams()
    local total_bolt_time = params.bolt_time * 1000
    local bolt_feed_time = params.bolt_feed_time * 1000
    if (total_bolt_time == nil or bolt_feed_time == nil) then
        return false
    end
    local bolt_time = api:getBoltTime()
    if (bolt_time < bolt_feed_time) then
        return true
    else
        if (not api:hasAmmoInBarrel()) then
            if (api:removeAmmoFromMagazine(1) ~= 0) then
                api:setAmmoInBarrel(true)
            end
        end
        return bolt_time < total_bolt_time
    end
end

-- 当开始换弹的时候会调用一次
function M.start_reload(api)
    return true
end

-- 这是个 lua 函数，用来从枪 data 文件里获取装弹相关的动画时间点，由于 lua 内的时间是毫秒，所以要和 1000 做乘算
local function getReloadTimingFromParam(param)
    local reload_empty_semi_feed = (param.reload_empty_semi_feed or 0) * 1000
    local reload_empty_semi_cooldown = (param.reload_empty_semi_cooldown or 0.8) * 1000
    local reload_empty_feed = (param.reload_empty_feed or 0) * 1000
    local reload_empty_cooldown = (param.reload_empty_cooldown or 0.8) * 1000
    local reload_tactical_semi_feed = (param.reload_tactical_semi_feed or 0) * 1000
    local reload_tactical_semi_cooldown = (param.reload_tactical_semi_cooldown or 0.5) * 1000
    local reload_tactical_feed = (param.reload_tactical_feed or 0) * 1000
    local reload_tactical_cooldown = (param.reload_tactical_cooldown or 0.5) * 1000

    if (reload_empty_semi_feed == nil or reload_empty_semi_cooldown == nil or 
        reload_empty_feed == nil or reload_empty_cooldown == nil or
        reload_tactical_semi_feed == nil or reload_tactical_semi_cooldown == nil or
        reload_tactical_feed == nil or reload_tactical_cooldown == nil) then
        return nil
    end

    return reload_empty_semi_feed, reload_empty_semi_cooldown, reload_empty_feed, reload_empty_cooldown,
           reload_tactical_semi_feed, reload_tactical_semi_cooldown, reload_tactical_feed, reload_tactical_cooldown
end

-- 判断这个状态是否是空仓换弹过程中的其中一个阶段。包括空仓换弹的收尾阶段
local function isReloadingEmpty(stateType)
    return stateType == EMPTY_RELOAD_FEEDING or stateType == EMPTY_RELOAD_FINISHING
end

-- 判断这个状态是否是战术换弹过程中的其中一个阶段。包括战术换弹的收尾阶段
local function isReloadingTactical(stateType)
    return stateType == TACTICAL_RELOAD_FEEDING or stateType == TACTICAL_RELOAD_FINISHING
end

-- 判断这个状态是否是任意换弹过程中的其中一个阶段。包括任意换弹的收尾阶段
local function isReloading(stateType)
    return isReloadingEmpty(stateType) or isReloadingTactical(stateType)
end

-- 判断这个状态是否是任意换弹过程中的的收尾阶段
local function isReloadFinishing(stateType)
    return stateType == EMPTY_RELOAD_FINISHING or stateType == TACTICAL_RELOAD_FINISHING
end

local function finishReload(api, is_tactical)
    local needAmmoCount = api:getNeededAmmoAmount();
    if (api:isReloadingNeedConsumeAmmo()) then
        -- 需要消耗弹药（生存或冒险）的话就消耗换弹所需的弹药并将消耗的数量装填进弹匣
        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(needAmmoCount))
    else
        -- 不需要消耗弹药（创造）的话就直接把弹匣塞满
        api:putAmmoInMagazine(needAmmoCount)
    end
    if not is_tactical then
        local i = api:removeAmmoFromMagazine(1);
        if i ~= 0 then
            api:setAmmoInBarrel(true)
        end
    end
end

function M.tick_reload(api)
    -- 从枪 data 文件中获取所有需要传入逻辑机的参数，注意此时的 param 是个列表，还不能直接拿来用
    local param = api:getScriptParams();
    -- 调用刚才的 lua 函数，把 param 里包含的八个参数依次赋值给我们新定义的变量
    local reload_empty_semi_feed, reload_empty_semi_cooldown, reload_empty_feed, reload_empty_cooldown, reload_tactical_semi_feed, reload_tactical_semi_cooldown, reload_tactical_feed, reload_tactical_cooldown = getReloadTimingFromParam(param)
    -- 照例检查是否有参数缺失
    if (reload_empty_semi_feed == nil or reload_empty_semi_cooldown == nil or 
        reload_empty_feed == nil or reload_empty_cooldown == nil or
        reload_tactical_semi_feed == nil or reload_tactical_semi_cooldown == nil or
        reload_tactical_feed == nil or reload_tactical_cooldown == nil) then
        return NOT_RELOADING, -1
    end

    local countDown = -1
    local stateType = NOT_RELOADING
    local oldStateType = api:getReloadStateType()
    local is_burst = (api:getFireMode() == BURST)

    -- 获取换弹时间，在玩家按下 R 的一瞬间作为零点，单位是毫秒。假设玩家在一秒前按下了 R ，那么此时这个时间就是 1000
    local progressTime = api:getReloadTime()

    local empty_feed, empty_cooldown
    if is_burst then
        empty_feed = reload_empty_semi_feed
        empty_cooldown = reload_empty_semi_cooldown
    else
        empty_feed = reload_empty_feed
        empty_cooldown = reload_empty_cooldown
    end

    local tactical_feed, tactical_cooldown
    if is_burst then
        tactical_feed = reload_tactical_semi_feed
        tactical_cooldown = reload_tactical_semi_cooldown
    else
        tactical_feed = reload_tactical_feed
        tactical_cooldown = reload_tactical_cooldown
    end

    -- 然后像 xmag 一样，用 oldStateType 驱动状态机
    if isReloadingEmpty(oldStateType) then
        local feed_time = empty_feed
        local finishing_time = empty_cooldown  -- 注意：这是总时间，不是增量！

        if progressTime < feed_time then
            stateType = EMPTY_RELOAD_FEEDING
            countDown = feed_time - progressTime
        elseif progressTime < finishing_time then
            stateType = EMPTY_RELOAD_FINISHING
            countDown = finishing_time - progressTime
        else
            stateType = NOT_RELOADING
            countDown = -1
        end

    elseif isReloadingTactical(oldStateType) then
        local feed_time = tactical_feed
        local finishing_time = tactical_cooldown

        if progressTime < feed_time then
            stateType = TACTICAL_RELOAD_FEEDING
            countDown = feed_time - progressTime
        elseif progressTime < finishing_time then
            stateType = TACTICAL_RELOAD_FINISHING
            countDown = finishing_time - progressTime
        else
            stateType = NOT_RELOADING
            countDown = -1
        end
    else
        stateType = NOT_RELOADING
        countDown = -1
    end

    if oldStateType == EMPTY_RELOAD_FEEDING and oldStateType ~= stateType then
        finishReload(api,false);
    end

    if oldStateType == TACTICAL_RELOAD_FEEDING and oldStateType ~= stateType then
        finishReload(api, true);
    end

    return stateType, countDown
end

-- 向模组返回整个逻辑机，定式
return M


