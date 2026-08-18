-- firing_logic.lua

local M = {}
local firing_anim = require("firing_state_machine")

function M.shoot(api)
    -- Shoot logic
    api:shootOnce(api:isShootingNeedConsumeAmmo())

    -- Animation based on ammo
    local context = api:getContext()
    local ammo = api:getAmmoCount()
    firing_anim.playAmmoBasedShootAnim(context, ammo)
end

return M
