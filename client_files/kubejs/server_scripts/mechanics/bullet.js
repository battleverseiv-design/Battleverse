// Логирование для проверки загрузки на гибридных ядрах
console.info('[KubeJS] Загрузка продвинутого скрипта tacz_cmd_advanced.js...');

ServerEvents.commandRegistry(event => {
    const { commands: Commands, arguments: Arguments } = event;

    // Вспомогательная функция: Заряжает все пушки в инвентаре конкретного игрока
    // Возвращает количество перезаряженных пушек
    const reloadGunsForPlayer = (player, amount) => {
        let reloadedCount = 0;

        // Перебираем ВСЕ предметы в инвентаре (хотбар, рюкзак, вторая рука, броня)
        player.inventory.allItems.forEach(item => {
            // Проверяем, является ли предмет пушкой TACZ
            if (item.id === 'tacz:modern_kinetic_gun') {
                
                // Устанавливаем патроны в магазин
                item.nbt.putInt('GunCurrentAmmoCount', amount);
                
                // Обрабатываем патрон в патроннике
                // Если патроны есть (>0), то и в стволе патрон есть (true)
                item.nbt.putBoolean('HasBulletInBarrel', amount > 0);
                
                reloadedCount++;
            }
        });

        // Визуальные и звуковые эффекты для игрока, которому выдали патроны
        if (reloadedCount > 0) {
            player.playSound('item.armor.equip_generic', 1.0, 1.0); // Звук экипировки
            // Показываем сообщение над хотбаром самому игроку
            player.displayClientMessage(Text.of(`§6[TACZ] §fВаши магазины (${reloadedCount} шт.) пополнены на §e${amount} §fпатр.`), true);
        }

        return reloadedCount;
    };

    // Регистрация команды
    event.register(
        Commands.literal('setammo')
            .requires(src => src.hasPermission(2)) // 1. Только для админов (OP)
            .then(Commands.argument('amount', Arguments.INTEGER.create(event))
                
                // ВАРИАНТ 1: Если игрок не указан -> выдаем СЕБЕ
                .executes(ctx => {
                    const src = ctx.source;
                    const player = src.player;

                    if (!player) {
                        src.sendFailure(Text.of('§cКонсоль должна указать игрока: /setammo <кол-во> <игрок>'));
                        return 0;
                    }

                    const amount = Arguments.INTEGER.getResult(ctx, 'amount');
                    const count = reloadGunsForPlayer(player, amount);

                    src.sendSuccess(Text.of(`§a[Успех] §fВы перезарядили себе §6${count} §fпушек.`), false);
                    return 1;
                })

                // ВАРИАНТ 2: Если указаны игроки (селектор @a, никнейм и т.д.)
                .then(Commands.argument('targets', Arguments.PLAYERS.create(event))
                    .executes(ctx => {
                        const src = ctx.source;
                        const amount = Arguments.INTEGER.getResult(ctx, 'amount');
                        const targets = Arguments.PLAYERS.getResult(ctx, 'targets'); // Получаем список игроков

                        let totalGuns = 0;

                        // Проходимся по всем выбранным игрокам
                        targets.forEach(targetPlayer => {
                            totalGuns += reloadGunsForPlayer(targetPlayer, amount);
                        });

                        // Сообщение админу, который ввел команду
                        src.sendSuccess(Text.of(`§a[Успех] §fВыдано по §e${amount} §fпатронов игрокам: §b${targets.length} чел.`), true);
                        return 1;
                    })
                )
            )
    );
});