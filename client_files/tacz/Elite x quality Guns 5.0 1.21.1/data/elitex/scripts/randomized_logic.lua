---
--- Created by Argos_Marlstrom.
--- DateTime: 15/05/2025 10:01 pm
---
-- randomized_logic.lua

local M = {}
local random_state = require("randomized_state_machine")

function M.shoot(api)
    -- Shoot normally
    api:shootOnce(api:isShootingNeedConsumeAmmo())

    -- Play a random shooting animation
    local context = api:getContext()
    random_state.playRandomShootAnim(context)
end

return M
