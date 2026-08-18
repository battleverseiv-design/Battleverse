local M = {}

function M.shoot(api)
    api:shootOnce(api:isShootingNeedConsumeAmmo())

    if (api:getAmmoAmount() % 4 ~= 0 or api:getAmmoAmount() == 16) then
        if (api:removeAmmoFromMagazine(1) ~= 0) then
            api:setAmmoInBarrel(true);
        end
        return false
    end
end

return M