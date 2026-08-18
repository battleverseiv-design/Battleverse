-- firing_state_machine.lua

local M = {}

function M.playAmmoBasedShootAnim(context, ammo)
    local param = context:getParams()
    local anim = nil

    -- You can define animation mapping per ammo count
    if ammo == 1 then
        anim = param["shoot_1_anim"] or "shoot_1"
    elseif ammo == 2 then
        anim = param["shoot_2_anim"] or "shoot_2"
    elseif ammo == 0 then
        anim = param["shoot_last_anim"] or "shoot_last"
    else
        anim = param["shoot_anim"] or "shoot"
    end

    context:runAnimation(anim, context:getTrack("STATIC_TRACK_LINE", "MAIN_TRACK"), false, PLAY_ONCE_STOP, 0.05)
end

return M
