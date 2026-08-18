ItemEvents.rightClicked('kubejs:laser_designator', event => {
    const { player, server, level, item } = event
    if (level.isClientSide()) return

    if (player.persistentData.strike_phase && player.persistentData.strike_phase > 0) return

    let ray = player.rayTrace(150)
    if (!ray.block) return

    player.persistentData.strike_phase = 1
    player.persistentData.strike_timer = 100 
    
    player.persistentData.strike_x = ray.block.x
    player.persistentData.strike_y = ray.block.y
    player.persistentData.strike_z = ray.block.z

    if (!player.isCreative()) {
        item.count--
    }
})

PlayerEvents.tick(event => {
    const { player, server, level } = event
    if (!player.persistentData.strike_phase || player.persistentData.strike_phase === 0) return

    let cx = player.persistentData.strike_x
    let cy = player.persistentData.strike_y
    let cz = player.persistentData.strike_z
    let timer = player.persistentData.strike_timer

    if (player.persistentData.strike_phase === 1) {
        // Визуал остается
        if (player.age % 2 === 0) {
            server.runCommandSilent(`execute in ${level.dimension} run particle minecraft:campfire_cosy_smoke ${cx} ${cy} ${cz} 0.5 2 0.5 0.05 10`)
        }

        // ЗВУК ЗА 1 СЕКУНДУ ДО ВЗРЫВА (на 20 тике Фазы 1)
        if (timer === 20) {
            // Воспроизводим звук всем игрокам в радиусе 50 блоков от точки
            server.runCommandSilent(`execute in ${level.dimension} positioned ${cx} ${cy} ${cz} run playsound kubejs:airstrike_warning master @a[distance=..50] ${cx} ${cy} ${cz} 1 1`)
        }

        player.persistentData.strike_timer--

        if (player.persistentData.strike_timer <= 0) {
            player.persistentData.strike_phase = 2
            player.persistentData.strike_timer = 200
        }
    }

    else if (player.persistentData.strike_phase === 2) {
        let outer_radius = 30
        let inner_radius = 5

        if (timer % 5 === 0) {
            let tx_outer = cx + (Math.random() - 0.5) * outer_radius * 2
            let tz_outer = cz + (Math.random() - 0.5) * outer_radius * 2
            let ty_outer = level.getHeight('motion_blocking', tx_outer, tz_outer)

            server.runCommandSilent(`execute in ${level.dimension} positioned ${tx_outer} ${ty_outer} ${tz_outer} run summon minecraft:tnt ~ ~ ~ {Fuse:0}`)
            server.runCommandSilent(`execute in ${level.dimension} run playsound minecraft:entity.ghast.shoot ambient @a ${tx_outer} ${ty_outer + 20} ${tz_outer} 5 0.7`)
            
            for (let i = 0; i < 2; i++) {
                let tx_inner = cx + (Math.random() - 0.5) * inner_radius * 2
                let tz_inner = cz + (Math.random() - 0.5) * inner_radius * 2
                let ty_inner = level.getHeight('motion_blocking', tx_inner, tz_inner)
                server.runCommandSilent(`execute in ${level.dimension} positioned ${tx_inner} ${ty_inner} ${tz_inner} run summon minecraft:tnt ~ ~ ~ {Fuse:0}`)
            }
        }

        player.persistentData.strike_timer--

        if (player.persistentData.strike_timer <= 0) {
            player.persistentData.strike_phase = 0 
        }
    }
})