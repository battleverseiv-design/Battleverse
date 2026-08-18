-- 脚本的位置是 "{命名空间}:{路径}"，那么 require 的格式为 "{命名空间}_{路径}"
-- 注意！require 取得的内容不应该被修改，应仅调用
local default = require("tacz_default_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local main_track_states = default.main_track_states
local static_track_top = default.static_track_top
-- main_track_states.idle 是我们要重写的状态。
local inspect_state = setmetatable({}, {__index = main_track_states.inspect})
local idle_state = setmetatable({}, {__index = main_track_states.idle})
-- bolt_state 是定义的新状态，用于执行定时抛壳
local bolt_state = {
    timestamp = -1,
    ejection_time = 0,
    popped = false
}
local function increment(obj)
    obj.value = obj.value + 1
    return obj.value - 1
end
local FIRE_MODE_TRACK = increment(static_track_top)
local SWITCH_MODE_TRACK = increment(static_track_top)
-- 重写 idle 状态的 transition 函数，讲输入 INPUT_RELOAD 重定向到 bolt_state 状态
function idle_state.transition(this, context, input)
    if (input == INPUT_BOLT) then
        context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.bolt
    end
    if (input == INPUT_SHOOT) then
        -- 绕过抛壳，因为手动上膛的枪不会自动抛壳
        return this.main_track_states.idle
    end
    return main_track_states.idle.transition(this, context, input)
end
-- 进入 bolt 状态，初始化时间戳和参数
function bolt_state.entry(this, context)
    local state = this.main_track_states.bolt
    local ejection_time = context:getStateMachineParams().bolt_shell_ejecting_time
    if (ejection_time) then
        state.ejection_time = ejection_time * 1000
    else
        state.ejection_time = 0
    end
    state.timestamp = context:getCurrentTimestamp()
    state.popped = false
end
-- 在恰当的时候执行抛壳逻辑，然后退出状态
function bolt_state.update(this, context)
    local state = this.main_track_states.bolt
    if (state.popped) then
        return
    end
    local base_timestamp = state.timestamp
    local current_timestamp = context:getCurrentTimestamp()
    if (current_timestamp - base_timestamp > state.ejection_time) then
        context:popShellFrom(0)
        state.popped = true
        context:trigger(this.INPUT_BOLT_RETREAT)
    end
end
function bolt_state.transition(this, context, input)
    if (input == this.INPUT_BOLT_RETREAT) then
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end

-- 此处为开火模式轨道的状态,专门为快慢机动画服务,兼容其他动作,可按需求添加三种射击模式(semi、burst、auto)
local fire_mode_state = {
    -- 半自动状态
    semi = {},
    -- 全自动状态
    burst = {},
    -- 掏枪状态
    draw = {}
}
-- 这一块专门用来检测枪械在掏枪(播放draw)时枪械处于什么射击模式,并切换到对应模式的idle
function fire_mode_state.draw.update(this, context)
    context:trigger(this.INPUT_MODE_DRAW)
end

function fire_mode_state.draw.transition(this, context,input)
    if (input == this.INPUT_MODE_DRAW) then
        if (context:getFireMode() == SEMI) then
            context:runAnimation("static_semi", context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK), true, PLAY_ONCE_HOLD, 0)
            return fire_mode_state.semi
        elseif (context:getFireMode() == BURST) then
            context:runAnimation("static_burst", context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK), true, PLAY_ONCE_HOLD, 0)
            return fire_mode_state.burst
        end
    end
end
-- 注意!后面关于每个开火模式对应状态之间的切换,需要按照data里填写的顺序进行转换
function fire_mode_state.semi.update(this, context)
    -- 当进入特定开火模式的状态时,挂起动画
    local track = context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK)
    if (context:isHolding(track)) then
        context:runAnimation("static_semi", track, true, PLAY_ONCE_HOLD, 0)
    end
    -- 为特定开火模式定义输入状态
    if (context:getFireMode() == BURST) then
        context:trigger(this.INPUT_MODE_BURST)
    end
end
-- 当检测到对应输入状态时播放对应快慢机动画
function fire_mode_state.semi.transition(this, context,input)
    if(input == this.INPUT_MODE_BURST)then
        context:runAnimation("switch_burst", context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK), false, PLAY_ONCE_STOP, 0)
        return fire_mode_state.burst
    end
-- 检测到开火输入,换弹输入,检视输入时后停止播放动画,不然会出现两个动画在不同的轨道播放,从而出现动画衔接问题
    if(input == INPUT_SHOOT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_RELOAD)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_INSPECT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
end
-- 和上面同理
function fire_mode_state.burst.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, FIRE_MODE_TRACK)
    if (context:isHolding(track)) then
        context:runAnimation("static_burst", track, true, PLAY_ONCE_HOLD, 0)
    end
    if (context:getFireMode() == SEMI) then
        context:trigger(this.INPUT_MODE_SEMI)
    end
end

function fire_mode_state.burst.transition(this, context,input)
    if(input == this.INPUT_MODE_SEMI)then
        context:runAnimation("switch_semi", context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK), false, PLAY_ONCE_STOP, 0)
        return fire_mode_state.semi
    end
    if(input == INPUT_SHOOT)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_RELOAD)then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
    if(input == INPUT_INSPECT )then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, SWITCH_MODE_TRACK))
    end
end

-- 当检测到开火模式切换输入时应该直接停止动画并返回闲置态
function inspect_state.transition(this, context, input)
    if (input == INPUT_FIRE_SELECT) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))
        return this.main_track_states.idle
    end
    return main_track_states.inspect.transition(this, context, input)
end
-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        -- 自定义的 idle 状态需要覆盖掉父级状态机的对应状态，新建的 bolt 状态也要加进来
        idle = idle_state,
        bolt = bolt_state,
    }, {__index = main_track_states}),
    INPUT_BOLT_RETREAT = "bolt_retreat",
    FIRE_MODE_TRACK = FIRE_MODE_TRACK,
    SWITCH_MODE_TRACK = SWITCH_MODE_TRACK,
    INPUT_MODE_SEMI = "input_mode_semi",
    INPUT_MODE_BURST = "input_mode_burst",
    INPUT_MODE_DRAW = "input_mode_draw",
    fire_mode_state = fire_mode_state
}, {__index = default})
function M:initialize(context)
    default.initialize(self, context)
end
function M:states()
    return {
        self.base_track_state,
        self.bolt_caught_states.normal,
        self.main_track_states.start,
        self.gun_kick_state,
        self.movement_track_states.idle,
        self.ADS_states.normal,
        self.slide_states.normal,
        self.fire_mode_state.draw
    }
end
-- 导出状态机
return M