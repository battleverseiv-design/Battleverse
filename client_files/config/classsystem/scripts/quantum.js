function onTick(player) {
    // =========================================================================
    // 1. Обработка Квантового Состояния (Залоченный Спектатор - Способность 1)
    // =========================================================================
    if (API.hasMetadata(player, "quantum_locked_pos")) {
        var startPos = API.getMetadata(player, "quantum_locked_pos");
        var curPos = API.getPosition(player);

        // Проверяем, сдвинулся ли игрок от стартовой позиции
        var dx = curPos[0] - startPos[0];
        var dy = curPos[1] - startPos[1];
        var dz = curPos[2] - startPos[2];
        var distance = Math.sqrt(dx*dx + dy*dy + dz*dz);

        // Если игрок сдвинулся более чем на 0.1 блока, возвращаем его на место
        if (distance > 0.1) {
            API.teleport(player, startPos[0], startPos[1], startPos[2], startPos[3], startPos[4]);
        }

        // Спавним красивые квантовые частицы портала вокруг залоченного игрока
        if (Math.random() < 0.3) {
            API.spawnParticle(player, "minecraft:portal", 5, 0.05);
        }

        // Обработка ограничения времени (макс. 5 секунд / 100 тиков)
        if (API.hasMetadata(player, "quantum_locked_timer")) {
            var lockTime = API.getMetadata(player, "quantum_locked_timer");
            if (lockTime > 0) {
                lockTime = lockTime - 1;
                API.setMetadata(player, "quantum_locked_timer", lockTime);
                if (lockTime === 0) {
                    exitQuantumState(player);
                }
            }
        }
    }

    // =========================================================================
    // 2. Обработка Квантового Фазирования (Прохождение стен - Способность 2)
    // =========================================================================
    if (API.hasMetadata(player, "quantum_phase_timer")) {
        var ticksLeft = API.getMetadata(player, "quantum_phase_timer");
        var startPos = API.getMetadata(player, "quantum_phase_start");
        var curPos = API.getPosition(player);

        var dx = curPos[0] - startPos[0];
        var dy = curPos[1] - startPos[1];
        var dz = curPos[2] - startPos[2];
        var dist = Math.sqrt(dx*dx + dy*dy + dz*dz);

        // Проверяем, вылетел ли игрок из стены в безопасное место
        // Мы требуем, чтобы он пролетел хотя бы 0.4 блока, чтобы авто-выход не срабатывал мгновенно в точке старта
        if (dist > 0.4 && API.isPositionSafe(player, curPos[0], curPos[1], curPos[2])) {
            // Игрок перелетел через стену! Автоматически завершаем фазирование немедленно
            endPhasing(player);
        } else if (ticksLeft > 0) {
            ticksLeft = ticksLeft - 1;
            API.setMetadata(player, "quantum_phase_timer", ticksLeft);
            
            // Спавним частицы прохождения сквозь стены
            API.spawnParticle(player, "minecraft:witch", 2, 0.01);
            
            // Если время вышло, завершаем фазирование
            if (ticksLeft === 0) {
                endPhasing(player);
            }
        }
    }
}

function onAbilityUse(player, abilityIndex) {
    // =========================================================================
    // СПОСОБНОСТЬ 1: Квантовое состояние (Спектатор + Замок на месте)
    // =========================================================================
    if (abilityIndex === 1) {
        if (API.hasMetadata(player, "quantum_locked_pos")) {
            // Ручной досрочный выход из состояния - всегда разрешен без проверок кулдауна
            exitQuantumState(player);
        } else {
            // Вход в состояние - проверяем кулдаун
            if (API.isOnCooldown(player, 1)) {
                var rem = Math.ceil(API.getCooldownRemainingMs(player, 1) / 1000.0);
                API.sendMessage(player, "§cСпособность 1 перезаряжается! Ждите " + rem + " сек.");
                API.playSound(player, "minecraft:block.fire.extinguish", 0.8, 1.2);
                return;
            }

            if (API.hasMetadata(player, "quantum_phase_timer")) {
                API.sendMessage(player, "§cНельзя исчезнуть во время фазирования!");
                return;
            }
            
            var currentPos = API.getPosition(player);
            API.setMetadata(player, "quantum_locked_pos", currentPos);
            API.setMetadata(player, "quantum_locked_timer", 100); // 5 секунд (100 тиков)
            
            API.setGameMode(player, "spectator");
            
            API.playSound(player, "minecraft:entity.ender_eye.launch", 1.0, 0.8);
            API.spawnParticle(player, "minecraft:portal", 25, 0.1);
            
            API.sendMessage(player, "§bВы вошли в квантовое состояние (на 5 секунд). Движение заблокировано.");
            
            // Устанавливаем кулдаун 20 секунд (20000 мс)
            API.setCooldown(player, 1, 20000);
        }
    }

    // =========================================================================
    // СПОСОБНОСТЬ 2: Прохождение сквозь стены (0.5 сек в спектаторе с авто-выходом)
    // =========================================================================
    if (abilityIndex === 2) {
        if (API.hasMetadata(player, "quantum_locked_pos")) {
            API.sendMessage(player, "§cНельзя фазировать в квантовом состоянии!");
            return;
        }

        // Проверяем кулдаун
        if (API.isOnCooldown(player, 2)) {
            var rem = Math.ceil(API.getCooldownRemainingMs(player, 2) / 1000.0);
            API.sendMessage(player, "§cСпособность 2 перезаряжается! Ждите " + rem + " сек.");
            API.playSound(player, "minecraft:block.fire.extinguish", 0.8, 1.2);
            return;
        }

        if (API.hasMetadata(player, "quantum_phase_timer")) {
            // Досрочное завершение фазирования при повторном нажатии
            endPhasing(player);
        } else {
            // Старт фазирования
            var currentPos = API.getPosition(player);
            API.setMetadata(player, "quantum_phase_start", currentPos);
            API.setMetadata(player, "quantum_phase_timer", 10); // 10 тиков = 0.5 секунды
            
            API.setGameMode(player, "spectator");
            API.playSound(player, "minecraft:item.chorus_fruit.teleport", 1.0, 1.5);
            API.spawnParticle(player, "minecraft:enchanted_hit", 15, 0.05);
            
            API.sendMessage(player, "§bФазирование! Летите сквозь стену (авто-выход при прохождении, макс 0.5 сек).");
            
            // Устанавливаем кулдаун 30 секунд (30000 мс)
            API.setCooldown(player, 2, 30000);
        }
    }
}

// Принудительный или автоматический выход из Квантового Состояния
function exitQuantumState(player) {
    if (!API.hasMetadata(player, "quantum_locked_pos")) return;
    
    var startPos = API.getMetadata(player, "quantum_locked_pos");
    API.removeMetadata(player, "quantum_locked_pos");
    API.removeMetadata(player, "quantum_locked_timer");
    
    API.setGameMode(player, "survival");
    API.teleport(player, startPos[0], startPos[1], startPos[2], startPos[3], startPos[4]);
    
    API.playSound(player, "minecraft:entity.ender_eye.death", 1.0, 1.2);
    API.spawnParticle(player, "minecraft:dragon_breath", 20, 0.1);
    
    API.sendMessage(player, "§bВы вернулись в физическое состояние.");
}

// Завершить прохождение сквозь стену
function endPhasing(player) {
    if (!API.hasMetadata(player, "quantum_phase_timer")) return;
    
    var startPos = API.getMetadata(player, "quantum_phase_start");
    var currentPos = API.getPosition(player);
    
    API.removeMetadata(player, "quantum_phase_start");
    API.removeMetadata(player, "quantum_phase_timer");
    
    // Проверяем, находится ли игрок в безопасном месте (не в стене)
    if (API.isPositionSafe(player, currentPos[0], currentPos[1], currentPos[2])) {
        var dx = currentPos[0] - startPos[0];
        var dy = currentPos[1] - startPos[1];
        var dz = currentPos[2] - startPos[2];
        var dist = Math.sqrt(dx*dx + dy*dy + dz*dz);
        
        if (dist > 2.5) {
            // Превышено максимальное расстояние прохождения сквозь стены (макс. 1 блок)
            API.setGameMode(player, "survival");
            API.teleport(player, startPos[0], startPos[1], startPos[2], startPos[3], startPos[4]);
            
            API.playSound(player, "minecraft:block.fire.extinguish", 1.0, 0.8);
            API.spawnParticle(player, "minecraft:smoke", 15, 0.05);
            API.sendMessage(player, "§cСтена слишком широкая (макс. 1 блок)! Фазирование отменено.");
            return;
        }
        
        API.setGameMode(player, "survival");
        
        if (dist > 0.4) {
            // Прошел сквозь стену - наносим чуть-чуть урона (1 сердечко = 2 урона)
            API.damagePlayer(player, 2.0);
            API.playSound(player, "minecraft:entity.player.hurt_on_fire", 0.8, 1.5);
            API.spawnParticle(player, "minecraft:damage_indicator", 10, 0.1);
            API.sendMessage(player, "§bУспешное фазирование! Вы получили квантовое смещение (1❤ урона).");
        } else {
            API.playSound(player, "minecraft:entity.enderman.teleport", 0.5, 1.8);
        }
    } else {
        // Застрял в стене или не успел выйти - телепортируем обратно
        API.setGameMode(player, "survival");
        API.teleport(player, startPos[0], startPos[1], startPos[2], startPos[3], startPos[4]);
        
        API.playSound(player, "minecraft:block.fire.extinguish", 1.0, 0.8);
        API.spawnParticle(player, "minecraft:smoke", 15, 0.05);
        API.sendMessage(player, "§cНе удалось завершить фазирование. Вы были возвращены назад.");
    }
}

function onApply(player) {
    // Сбрасываем старые состояния при надевании класса
    API.removeMetadata(player, "quantum_locked_pos");
    API.removeMetadata(player, "quantum_locked_timer");
    
    API.sendMessage(player, "§bВы выбрали класс Квант! §fДоступные способности:\n§eСпособность 1 (Бинд) §7- Квантовое исчезновение (спектатор без движения на 5 сек)\n§eСпособность 2 (Бинд) §7- Квантовое фазирование (прохождение стен)");
}

function onReset(player) {
    // Очищаем состояния и принудительно возвращаем сурвайвал, чтобы не застрял в спектаторе
    if (API.hasMetadata(player, "quantum_locked_pos")) {
        var startPos = API.getMetadata(player, "quantum_locked_pos");
        API.teleport(player, startPos[0], startPos[1], startPos[2], startPos[3], startPos[4]);
    }
    
    API.removeMetadata(player, "quantum_locked_pos");
    API.removeMetadata(player, "quantum_locked_timer");
    
    API.setGameMode(player, "survival");
    API.sendMessage(player, "§cВы покинули класс Квант.");
}
