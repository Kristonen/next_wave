package game

import "core:math"
import "ecs"
import rl "vendor:raylib"

Entity_Pair :: struct{
    e1, e2 : ecs.Entity
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

get_rotation :: proc(dir : rl.Vector2) -> f32{
	radians := math.atan2(dir.y, dir.x)
	rotation := math.to_degrees(radians)
	return rotation
}

get_rec :: proc(t : Transform, rec : Rectangle) -> rl.Rectangle{
    return { t.pos.x, t.pos.y, rec.width * t.scale.x, rec.height * t.scale.y}
}

get_cir_collider :: proc(t : Transform, s : Collision_Shape) -> (rl.Vector2, f32){
    return {t.pos.x + s.offset.x, t.pos.y + s.offset.y}, s.radius
}

get_rec_collider :: proc(t : Transform, s : Collision_Shape) -> rl.Rectangle{
    return {t.pos.x + s.offset.x, t.pos.y + s.offset.y, s.size.x, s.size.y}
}

get_center_collider :: proc(t : Transform, b : Physic_Body) -> rl.Vector2{
    pos : rl.Vector2
    if b.shape.is_circle{
        pos = get_center_collider_cir(t, b)
    } else{
        pos = get_center_collider_rec(t, b)
    }
    return pos
}

get_center_collider_cir :: proc(t : Transform, b : Physic_Body) -> rl.Vector2{
    pos : rl.Vector2
    pos.x = t.pos.x + b.shape.radius + b.shape.offset.x
    pos.y = t.pos.y + b.shape.radius + b.shape.offset.y
    return pos
}

get_center_collider_rec :: proc(t : Transform, b : Physic_Body) -> rl.Vector2{
    pos : rl.Vector2
    pos.x = t.pos.x + b.shape.size.x/2 + b.shape.offset.x
    pos.y = t.pos.y + b.shape.size.y/2 + b.shape.offset.y
    return pos
}

get_bounds :: proc{
    get_rec_bounds,
    get_cir_bounds,
    get_collider_bounds,
}

get_rec_bounds :: proc(p : rl.Vector2, rec : Rectangle) -> (min, max : rl.Vector2){
    min = p
    max = p + {rec.width, rec.height}
    return min, max
}

get_cir_bounds :: proc(p : rl.Vector2, cir : Circle) -> (min, max : rl.Vector2){
    min = p - {cir.radius/2, cir.radius/2}
    max = p + {cir.radius/2, cir.radius/2}
    return min, max
}

get_collider_bounds :: proc(p: rl.Vector2, s: Collision_Shape) -> (min, max: rl.Vector2) {
    min = p + s.offset
    if s.is_circle {
        min -= {s.radius, s.radius}
        max = p + s.offset + {s.radius, s.radius}
    } else {
        max = p + s.offset + s.size
    }
    return min, max
}

trigger_interaction :: proc(interactable : ecs.Entity, actor : ecs.Entity){

}
