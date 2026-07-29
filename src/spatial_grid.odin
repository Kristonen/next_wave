package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"
import "ecs"

CELL_SIZE :: 64

Grid_Key :: struct{
    x, y : i32
}

Spatial_Grid :: map[Grid_Key][dynamic]ecs.Entity//ecs.List(ecs.Entity)

build_spatial_grid :: proc(grid : ^Spatial_Grid){
    for _, &list in grid{
        delete(list)
    }
    clear(grid)

    for i in 0..<game.entities.len{
        e := game.entities.items[i]
        t, has_t := ecs.get_component(world, e, Transform)
        b, has_b := ecs.get_component(world, e, Physic_Body)
        if !has_t || !has_b do continue
        
        min, max := get_collider_bounds(t.pos, b.shape)
        min_key := get_grid_key(min)
        max_key := get_grid_key(max)

        for x in min_key.x..=max_key.x{
            for y in min_key.y..=max_key.y{
                key := Grid_Key{x, y}
                if key not_in grid{
                    grid[key] = make([dynamic]ecs.Entity)//ecs.make_list(ecs.Entity)
                }
                append(&grid[key], e)
            }
        }
    }
}

get_grid_key :: proc(pos : rl.Vector2) -> Grid_Key{
    
    return{
        x = i32(math.floor(pos.x / CELL_SIZE)),
        y = i32(math.floor(pos.y / CELL_SIZE))
    }
}

find_closest_enemy :: proc(pos : rl.Vector2, range : f32) -> (target_e : ecs.Entity, target_pos : rl.Vector2, found : bool){
    min_world : rl.Vector2 = {pos.x - range, pos.y - range}
    max_world : rl.Vector2 = {pos.x + range, pos.y + range}

    min_key := get_grid_key(min_world)
    max_key := get_grid_key(max_world)

    closest_dist_sq := range * range

    for x in min_key.x..=max_key.x{
        for y in min_key.y..=max_key.y{
            key := Grid_Key{x, y}
            e_in_cell, exist := game_grid[key]
            if !exist do continue
            for e in game_grid[key]{
                if !ecs.has_component(world, e, Enemy) do continue
                t, has_t := ecs.get_component(world, e, Transform)
                b, has_b := ecs.get_component(world, e, Physic_Body)
                if !has_t || !has_b do continue
                c_pos := get_center_collider(t^, b^)
                diff := c_pos - pos
                dist_sq := diff.x * diff.x + diff.y * diff.y

                if dist_sq <= closest_dist_sq{
                    closest_dist_sq = dist_sq
                    target_e = e
                    target_pos = c_pos
                    found = true
                }
            }
        }
    }
    return target_e, target_pos, found
}