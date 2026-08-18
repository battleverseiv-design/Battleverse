// startup_scripts/custom_items.js

StartupEvents.registry('item', event => {
    event.create('laser_designator')
        .displayName('§bОгневая поддержка [Град]')
        .unstackable()
        .tooltip('§7Вызывает мгновенный кассетный удар по точке наведения.')
        .tooltip('§eОперативное время подлета: 5 сек.')
})