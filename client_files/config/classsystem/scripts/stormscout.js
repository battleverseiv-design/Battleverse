function onTick(player) {
    // Обработка активной суперспособности (Грозовой Режим)
    if (API.hasMetadata(player, "stormscout_active")) {
        var activeTicks = API.getMetadata(player, "stormscout_active");
        if (activeTicks > 0) {
            activeTicks--;
            API.setMetadata(player, "stormscout_active", activeTicks);
            
            var pos = API.getPosition(player);
            
            // Настоящие электрические разряды (менее хаотичные, чуть медленнее, размер +25%, ТЕСТ: без аддитивности и мерцания)
            for (var i = 0; i < 3; i++) {
                var angle = Math.random() * Math.PI * 2;
                var radius = 0.2 + Math.random() * 0.4;
                var sx = pos[0] + Math.cos(angle) * radius;
                var sz = pos[2] + Math.sin(angle) * radius;
                var sy = pos[1] + 0.1 + Math.random() * 1.8;
                
                // Скорость частиц уменьшена в 3 раза для стабильности и плавности (менее хаотично)
                var vx = (Math.random() - 0.5) * 0.3;
                var vy = (Math.random() - 0.5) * 0.3;
                var vz = (Math.random() - 0.5) * 0.3;
                
                // Используем thin_extruding_spark и sparkle для эффекта ветвистых молний
                var pType = Math.random() < 0.6 ? "thin_extruding_spark" : "sparkle";
                
                // ТЕСТ: передаем false, false
                API.spawnLodestoneParticleOptions(
                    player, pType,
                    sx, sy, sz,
                    0.4, 0.9, 1.0,   // r1, g1, b1 (Неоновый голубой)
                    1.0, 1.0, 1.0,   // r2, g2, b2 (Чистый белый)
                    0.11, 0.012,     // Масштаб
                    1.0, 0.0,        // прозрачность
                    4 + Math.floor(Math.random() * 5), // Сверхкороткая жизнь
                    vx, vy, vz,      // скорости
                    0.02,            // randomOffset
                    false,           // ADDITIVE = false
                    false            // TWINKLING = false
                );
            }
            
            // Вспышка звуков разряда каждые несколько тиков
            if (activeTicks % 6 === 0 && Math.random() < 0.6) {
                API.playSound(player, "minecraft:entity.lightning_bolt.impact", 0.4, 1.9);
            }
            
            if (activeTicks === 0) {
                API.removeMetadata(player, "stormscout_active");
                API.sendMessage(player, "§8[§eМолния§8] §7Грозовой режим завершен.");
            }
        }
    }
}

function onAbilityUse(player, abilityIndex) {
    if (abilityIndex === 1) {
        // Проверяем кулдаун (25 секунд)
        if (API.isOnCooldown(player, 1)) {
            var rem = Math.ceil(API.getCooldownRemainingMs(player, 1) / 1000.0);
            API.sendMessage(player, "§8[§eМолния§8] §cСпособность перезаряжается! Ждите " + rem + " сек.");
            API.playSound(player, "minecraft:block.fire.extinguish", 0.8, 1.2);
            return;
        }

        // Активируем Грозовой Режим на 8 секунд (160 тиков):
        API.setMetadata(player, "stormscout_active", 160);
        
        // В 3 раза быстрее! Скорость XV (amplifier 14) и прыжок VII (amplifier 6) на 8 секунд
        API.addPotionEffect(player, "minecraft:speed", 160, 14); // Скорость XV (невероятная скорость!)
        API.addPotionEffect(player, "minecraft:jump_boost", 160, 6); // Прыгучесть VII
        
        // Звуки удара молнии
        API.playSound(player, "minecraft:entity.lightning_bolt.thunder", 0.9, 1.6);
        API.playSound(player, "minecraft:entity.lightning_bolt.impact", 1.0, 1.4);
        
        var pos = API.getPosition(player);
        
        // Мощный выброс 20 электрических дуг со скоростью молнии (ТЕСТ: false, false)
        for (var i = 0; i < 20; i++) {
            var angle = Math.random() * Math.PI * 2;
            var speed = 0.3 + Math.random() * 0.35;
            var vx = Math.cos(angle) * speed;
            var vz = Math.sin(angle) * speed;
            var vy = (Math.random() - 0.5) * 0.2;
            
            API.spawnLodestoneParticleOptions(
                player, "thin_extruding_spark",
                pos[0], pos[1] + 0.8, pos[2],
                0.3, 0.85, 1.0,  // r1, g1, b1 (Неоновый голубой)
                1.0, 1.0, 1.0,   // r2, g2, b2 (Чистый белый)
                0.15, 0.012,     // Масштаб
                1.0, 0.0,        // прозрачность (alpha1, alpha2)
                8 + Math.floor(Math.random() * 6), // время жизни
                vx, vy, vz,      // скорости
                0.12,            // разброс
                false,           // ADDITIVE = false
                false            // TWINKLING = false
            );
        }

        API.sendMessage(player, "§8[§eМолния§8] §fВы активировали §eГрозовой Режим§f! Вы получили Грозовое Ускорение XV.");
        
        // Устанавливаем кулдаун 25 секунд
        API.setCooldown(player, 1, 25000);
    }
}

function onApply(player) {
    API.sendMessage(player, "§eВы выбрали класс Грозовой Разведчик! §fДоступные способности:\n§e[1] ⚡ Грозовой Режим (Скорость XV, Прыжок VII, электрическая аура, перезарядка 25 сек)");
}

function onReset(player) {
    API.removeMetadata(player, "stormscout_active");
    API.removePotionEffect(player, "minecraft:speed");
    API.removePotionEffect(player, "minecraft:jump_boost");
    API.sendMessage(player, "§cВы покинули класс Грозовой Разведчик.");
}
