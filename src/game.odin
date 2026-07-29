package game

import "ecs"
import rl "vendor:raylib"

game : Game
world : ^ecs.World
game_grid : Spatial_Grid

make_pair :: proc(e1, e2 : ecs.Entity) -> Entity_Pair{
    return { e1, e2 }
}

Game :: struct{
    player : ecs.Entity,
    entities : ecs.List(ecs.Entity),
    world : ecs.World,
    dt : f32,
    helper_active : bool,
}

init_game :: proc(){
    game.entities = ecs.make_list(ecs.Entity)
    // rl.SetTargetFPS(60)
}

create_entity :: proc() -> ecs.Entity{
    e := ecs.create_entity(&game.world)
    ecs.append_list(&game.entities, e)
    return e
}