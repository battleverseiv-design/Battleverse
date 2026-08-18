var charges = {};
var reloadTimers = {};

var MAX_CHARGES = 3;
var RELOAD_TIME_TICKS = 300; // 15 секунд

function onTick(player) {
    var uuid = API.getUUID(player);
    
    // Инициализация/обработка зарядов для первой способности (Рывок)
    if (charges[uuid] === undefined) charges[uuid] = MAX_CHARGES;
    
    if (reloadTimers[uuid] !== undefined && reloadTimers[uuid] > 0) {
        reloadTimers[uuid]--;
        
        if (reloadTimers[uuid] === 0) {
            charges[uuid] = MAX_CHARGES;
            
            API.sendMessage(player, "§a⚡ Заряды рывков полностью восстановлены (3/3)!");
            API.playSound(player, "minecraft:entity.player.levelup", 1.0, 2.0);
        }
    }
}

function onAbilityUse(player, abilityIndex) {
    var uuid = API.getUUID(player);

    // ==========================================
    // СПОСОБНОСТЬ 1: Быстрый Рывок (Quick Dash)
    // ==========================================
    if (abilityIndex === 1) {
        // Проверяем кулдаун (мини-перезарядка 0.4 сек или полная перезарядка 15 сек)
        if (API.isOnCooldown(player, 1)) {
            return;
        }

        if (charges[uuid] === undefined) charges[uuid] = MAX_CHARGES;
        
        if (charges[uuid] > 0) {
            charges[uuid]--;
            
            // Ослабленный рывок вперед (сила 1.5, подлет вверх 0.15)
            API.pushPlayer(player, 1.5, 0.15);
            API.sendMessage(player, "§b💨 Рывок! Зарядов: " + charges[uuid] + "/3");
            
            API.playSound(player, "minecraft:entity.ender_dragon.flap", 0.8, 1.6);
            API.spawnParticle(player, "minecraft:cloud", 20, 0.05);
            
            if (charges[uuid] === 0) {
                reloadTimers[uuid] = RELOAD_TIME_TICKS;
                API.sendMessage(player, "§e⏳ Перезарядка рывков (15 секунд)...");
                // Устанавливаем официальный кулдаун 15 секунд на HUD
                API.setCooldown(player, 1, 15000);
            } else {
                // Устанавливаем мини-перезарядку 0.4 секунды (400 мс) между рывками
                API.setCooldown(player, 1, 400);
            }
        } else {
            var remTicks = reloadTimers[uuid] || 0;
            var remSecs = Math.ceil(remTicks / 20.0);
            API.sendMessage(player, "§c❌ Нет зарядов! Ждите перезарядки (" + remSecs + " сек).");
        }
    }
}

function onApply(player) {
    var uuid = API.getUUID(player);
    charges[uuid] = MAX_CHARGES;
    reloadTimers[uuid] = 0;
    
    API.sendMessage(player, "§aВы выбрали класс Рывок! Доступна суперспособность:\n§e[1] 💨 Быстрый Рывок (3 заряда, перезарядка 15 сек, задержка 0.4 сек)");
}

function onReset(player) {
    var uuid = API.getUUID(player);
    delete charges[uuid];
    delete reloadTimers[uuid];
}