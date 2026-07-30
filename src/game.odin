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
    world = &game.world
    game.entities = ecs.make_list(ecs.Entity)
    init_room()
    // rl.SetTargetFPS(60)
}

init_room :: proc(){
    room := create_entity()
    ecs.add_component(world, room, Transform{{100, 50}, 0, {1, 1}})
    ecs.add_component(world, room, Rectangle{1700, 980, rl.DARKGRAY})

    wall := create_entity()
    ecs.add_component(world, wall, Transform{{75, 25}, 0, {1, 1}})
    ecs.add_component(world, wall, Rectangle{1750, 25, rl.RED})
    wall_body := Physic_Body{
        mass = 1,
        type = .Static,
        shape = {
            size = {1750, 25},
            offset = {},
        }
    }
    ecs.add_component(world, wall, wall_body)

    wall = create_entity()
    ecs.add_component(world, wall, Transform{{1800, 25}, 0, {1, 1}})
    ecs.add_component(world, wall, Rectangle{25, 1030, rl.RED})
    wall_body = Physic_Body{
        mass = 1,
        type = .Static,
        shape = {
            size = {25, 1030}
        }
    }
    ecs.add_component(world, wall, wall_body)

    wall = create_entity()
    ecs.add_component(world, wall, Transform{{75, 25}, 0, {1, 1}})
    ecs.add_component(world, wall, Rectangle{25, 1030, rl.RED})
    wall_body = Physic_Body{
        mass = 1,
        type = .Static,
        shape = {
            size = {25, 1030}
        }
    }
    ecs.add_component(world, wall, wall_body)

    wall = create_entity()
    ecs.add_component(world, wall, Transform{{75, 1030}, 0, {1, 1}})
    ecs.add_component(world, wall, Rectangle{1750, 25, rl.RED})
}

create_entity :: proc() -> ecs.Entity{
    e := ecs.create_entity(&game.world)
    ecs.append_list(&game.entities, e)
    return e
}