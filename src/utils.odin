package game

import "ecs"
import rl "vendor:raylib"

pairs : [dynamic]Entity_Pair

Entity_Pair :: struct{
    e1, e2 : ecs.Entity
}

refresh_pairs :: proc(){
    delete(pairs)
    pairs = make([dynamic]Entity_Pair)
}

check_if_pair_already_exist :: proc(pair : Entity_Pair) -> bool{
    for i in 0..<len(pairs){
        o_pair := pairs[i]
        if (pair.e1 == o_pair.e1 || pair.e2 == o_pair.e2) && (pair.e2 == o_pair.e1 || pair.e2 == o_pair.e2){
            return true
        }
    }
    append(&pairs, pair)
    return false
}

create_particle :: proc(pos : rl.Vector2, e : ecs.Entity){
    // task : Spawn_Task
    cir, has_cir := ecs.get_component(world, e, Circle)
    rec, has_rec := ecs.get_component(world, e, Rectangle)
    mid_pos : rl.Vector2
    if has_cir{
        mid_pos = pos + {cir.radius/2, cir.radius/2}
    } else if has_rec{
        mid_pos = pos + {rec.width/2, rec.height/2}
    }

    dirs : []rl.Vector2 = {{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}
    for dir in dirs{
        p := create_entity()
        ecs.add_component(world, p, Transform{mid_pos, 0, {1,1}})
        ecs.add_component(world, p, Circle{5, rl.GOLD})
        ecs.add_component(world, p, Movement{dir, 50})
        ecs.add_component(world, p, Lifetime{2, 2})
    }
}
