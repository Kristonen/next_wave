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
    prompt : ^Text_Box,
}

init_game :: proc(){
    world = &game.world
    // game.entities = ecs.make_list(ecs.Entity)
    // rl.SetTargetFPS(60)
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
