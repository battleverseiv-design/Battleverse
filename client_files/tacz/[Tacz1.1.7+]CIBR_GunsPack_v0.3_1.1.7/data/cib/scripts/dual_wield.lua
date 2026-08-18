local M = {}

function M.shoot(api)
    if(api:getFireMode() == SEMI)then
        api:shootOnce(api:isShootingNeedConsumeAmmo())
    elseif (api:getFireMode() == BURST) then
        if(api:getAmmoCountInMagazine()>1)then
            api:shootOnce(api:isShootingNeedConsumeAmmo())
        end
        api:shootOnce(api:isShootingNeedConsumeAmmo())
    end

end

return M