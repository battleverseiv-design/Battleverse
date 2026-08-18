local default = require("tacz_default_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local main_track_states = default.main_track_states
local MAIN_TRACK = default.MAIN_TRACK
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK
local bolt_caught_states = default.bolt_caught_states

local normal_states = setmetatable({}, {__index = bolt_caught_states.normal})
local caught_states = setmetatable({}, {__index = bolt_caught_states.bolt_caught})

local idle_state = setmetatable({}, {__index = main_track_states.idle})


function idle_state.transition(this, context, input)
    if (input == INPUT_BOLT) then
        if (context:getAmmoCount() % 4 == 0 and context:getAmmoCount() < 16) then
            context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        end
        return this.main_track_states.idle
    end
    return main_track_states.idle.transition(this, context, input)
end

local function isNoAmmo(context)
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

function normal_states.entry(this, context)
    context:runAnimation("bullet_state", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, PLAY_ONCE_STOP, 0)
    return this.bolt_caught_states.normal
end


function normal_states.update(this, context)
    if (isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
    context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), 1 - (context:getAmmoCount()+1)/context:getMaxAmmoCount(), false)
end

function caught_states.update(this, context)
    if (not isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_NORMAL)
    end
end

local M = setmetatable({
    main_track_states = setmetatable({
        idle = idle_state
    }, {__index = main_track_states}),
        bolt_caught_states = setmetatable({
        bolt_caught = caught_states,
        normal = normal_states
    }, {__index = bolt_caught_states}),
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
end

return M