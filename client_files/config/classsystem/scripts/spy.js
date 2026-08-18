var PotionEffectType = null;
var PotionEffect = null;

try {
    PotionEffectType = org.bukkit.potion.PotionEffectType;
    PotionEffect = org.bukkit.potion.PotionEffect;
} catch(e) {}

function onTick(player) {
    // Получаем предмет в руке через наш API
    var heldItem = API.getHeldItem(player, "main");
    
    // Невидимость пропадает, если в руке любое оружие TACZ или меч
    var isHoldingWeapon = heldItem.startsWith("tacz:") || heldItem.endsWith("_sword");
    
    var bukkitPlayer = API.getBukkitPlayer(player);
    if (bukkitPlayer != null && PotionEffectType != null) {
        // ==========================================
        // РЕЖИМ СЕРВЕРА (Использует Bukkit/Spigot API)
        // ==========================================
        if (isHoldingWeapon) {
            bukkitPlayer.removePotionEffect(PotionEffectType.INVISIBILITY);
        } else {
            // Выдаем невидимость на 2 секунды (обновляется каждый тик), без частиц
            bukkitPlayer.addPotionEffect(new PotionEffect(PotionEffectType.INVISIBILITY, 40, 0, false, false, false));
        }
    } else {
        // ==========================================
        // РЕЖИМ ТЕСТА (Одиночная игра, нативный Forge)
        // ==========================================
        if (isHoldingWeapon) {
            API.removePotionEffect(player, "minecraft:invisibility");
        } else {
            API.addPotionEffect(player, "minecraft:invisibility", 40, 0);
        }
    }
}

// Вызывается при нажатии кнопки способности
function onAbilityUse(player, abilityIndex) {
    // Способность 0 (первая абилка, например на кнопку F)
    if (abilityIndex === 1) {
        // Вызываем функцию отключения звуков шагов на 5 секунд
        API.setSilentSteps(player, 5); 
        
        // Отправляем сообщение игроку
        var bukkitPlayer = API.getBukkitPlayer(player);
        if (bukkitPlayer != null) {
            bukkitPlayer.sendMessage("§8[§cСпай§8] §fВы активировали бесшумные шаги на 5 секунд!");
        } else {
            API.sendMessage(player, "§8[§cСпай§8] §fВы активировали бесшумные шаги на 5 секунд!");
        }
    }
}

function onApply(player) {
    var bukkitPlayer = API.getBukkitPlayer(player);
    if (bukkitPlayer != null) {
        bukkitPlayer.sendMessage("§aВы выбрали класс Спай! Спрячьте оружие для невидимости.");
    } else {
        API.sendMessage(player, "§aВы выбрали класс Спай! Спрячьте оружие для невидимости.");
    }
}

function onReset(player) {
    // Очистка при смене класса (чтобы невидимость не осталась навсегда)
    var bukkitPlayer = API.getBukkitPlayer(player);
    if (bukkitPlayer != null && PotionEffectType != null) {
        bukkitPlayer.removePotionEffect(PotionEffectType.INVISIBILITY);
        bukkitPlayer.sendMessage("§cВы покинули класс Спай.");
    } else {
        API.removePotionEffect(player, "minecraft:invisibility");
        API.sendMessage(player, "§cВы покинули класс Спай.");
    }
}
