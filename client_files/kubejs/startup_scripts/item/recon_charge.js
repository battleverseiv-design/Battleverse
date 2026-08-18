StartupEvents.registry('item', event => {
    event.create('recon_charge')
        .displayName(Text.of('Recon Charge').gold())
        .maxStackSize(16) // Ограничиваем стак для баланса
        .glow(true)       // Делает предмет светящимся (как зачарованный)
        .tooltip(Text.of('Подсвечивает всех игроков на карте.').gray());
});