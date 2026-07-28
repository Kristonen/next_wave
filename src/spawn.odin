package game

// Spawn_Task :: #type proc()
pending_spawns : [dynamic]Spawn_Task

import "ecs"

Spawn_Task :: struct{
    components : ecs.List(any)

}

new_component :: proc(val : $T) -> any{
    // 1. Speicher auf dem Temp-Allocator reservieren
    ptr := new(T, context.temp_allocator)
    // 2. Wert hineinkopieren
    ptr^ = val
    // 3. als 'any' zurückgeben
    return ptr^
}

flush_spawns :: proc() {
    for task in pending_spawns {
        e := create_entity()
        for comp in task.components.items {
            // comp ist vom Typ 'any'
            ecs.add_component_any(world, e, comp)
        }
    }
    
    // Hauptliste leeren
    clear(&pending_spawns)
    // Der context.temp_allocator wird sowieso am Frame-Ende in deiner main.odin geleert!
}