package game

import "core:fmt"
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
    entities : [dynamic]ecs.Entity,
    useable_entities : [dynamic]ecs.Entity,
    world : ecs.World,
    dt : f32,
    helper_active : bool,
}

init_game :: proc(){
    world = &game.world
    // game.entities = ecs.make_list(ecs.Entity)
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
	e : ecs.Entity
	if len(game.useable_entities) > 0{
		e = game.useable_entities[0]
		unordered_remove(&game.useable_entities, 0)
		e = ecs.create_entity(world, e)
	} else{
    	e = ecs.create_entity(world)
	}
    append(&game.entities, e)
    return e
}

remove_entity :: proc{
	remove_entity_id,
	remove_entity_index,
}

remove_entity_id :: proc(e : ecs.Entity){
	for i in 0..<len(game.entities){
		if e == game.entities[i]{
			ecs.destroy_entity(world, e)
			append(&game.useable_entities, e)
			unordered_remove(&game.entities, i)
		}
	}
}

remove_entity_index :: proc(index : int){
	e := game.entities[index]
	ecs.destroy_entity(world, e)
	append(&game.useable_entities, e)
	unordered_remove(&game.entities, index)
}
