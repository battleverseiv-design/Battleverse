-- 脚本的位置是 "{命名空间}:{路径}"，那么 require 的格式为 "{命名空间}_{路径}"
-- 注意！require 取得的内容不应该被修改，应仅调用
local default = require("tacz_default_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local GUN_KICK_TRACK_LINE = default.GUN_KICK_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local main_track_states = default.main_track_states
-- main_track_states.idle 是我们要重写的状态。
local idle_state = setmetatable({}, {__index = main_track_states.idle})

local shoot_state = {}

function shoot_state.transition(this, context, input)
    -- 玩家按下开火键时需要在射击轨道行里寻找空闲轨道去播放射击动画(如果没有空闲会分配新的),需要注意的是射击动画要向下混合
    if (input == INPUT_SHOOT) then
        local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
        -- 这里是混合动画，一般是可叠加的 gun kick
        if (context:getAmmoCount() == 0) then
            context:runAnimation("shoot_last", track, true, PLAY_ONCE_STOP, 0)
        else
            context:runAnimation("shoot", track, true, PLAY_ONCE_STOP, 0)
        end
    end
    return nil
end

local reload_state = {
    need_ammo = 0,
    loaded_ammo = 0,
    reload_type = "NULL"
}

-- 重写 idle 状态的 transition 函数，将输入 INPUT_RELOAD 重定向到新定义的 reload_state 状态
function idle_state.transition(this, context, input)
    if (input == INPUT_RELOAD) then
        return this.main_track_states.reload
    end
    return main_track_states.idle.transition(this, context, input)
end

function reload_state.entry(this, context)
    local isNoAmmo = not context:hasBulletInBarrel()
    local state = this.main_track_states.reload
    if (isNoAmmo) then
        reload_state.reload_type = "EMPTY"
        context:runAnimation("reload_empty", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
    elseif (context:getAmmoCount() == 0) then
        reload_state.reload_type = "EMPTY_01"
        context:runAnimation("reload_tactical_01", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
    else
        reload_state.reload_type = "NULL"
        context:runAnimation("reload_intro", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_HOLD, 0.2)
    end
    state.need_ammo = context:getMaxAmmoCount() - context:getAmmoCount()
    state.loaded_ammo = 0
end

function reload_state.update(this, context)
    if (reload_state.reload_type == "NULL") then
        local state = this.main_track_states.reload
        if (state.loaded_ammo > state.need_ammo or not context:hasAmmoToConsume()) then
            context:trigger(this.INPUT_RELOAD_RETREAT)
        else
            local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
            if (context:isHolding(track)) then
                if (state.need_ammo - state.loaded_ammo > 1) then
                    context:runAnimation("reload_loop_2", track, false, PLAY_ONCE_HOLD, 0)
                    state.loaded_ammo = state.loaded_ammo + 2
                elseif (state.need_ammo - state.loaded_ammo <= 1) then
                    context:runAnimation("reload_loop", track, false, PLAY_ONCE_HOLD, 0)
                    state.loaded_ammo = state.loaded_ammo + 1
                end
            end
        end
    else
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if (not context:isHolding(track)) then
            context:trigger("mag_reload_finish")
        end
    end
end

function reload_state.transition(this, context, input)
    if (input == "mag_reload_finish") then
        return this.main_track_states.idle
    end
    if (input == this.INPUT_RELOAD_RETREAT or input == INPUT_CANCEL_RELOAD) then
        -- LOVE CIMA
        if (reload_state.reload_type == "NULL") then
            context:runAnimation("reload_end", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        end
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end

-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        idle = idle_state,
        reload = reload_state
    }, {__index = main_track_states}),
    gun_kick_state = shoot_state,
    INPUT_RELOAD_RETREAT = "reload_retreat"
}, {__index = default})
-- 先调用父级状态机的初始化函数，然后进行自己的初始化
function M:initialize(context)
    default.initialize(self, context)
    self.main_track_states.reload.need_ammo = 0
    self.main_track_states.reload.loaded_ammo = 0
end
-- 导出状态机
return M