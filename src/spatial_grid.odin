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

    for i in 0..<len(game.entities){
        e := game.entities[i]
        t, has_t := ecs.get_component(world, e, Transform)
        b, has_b := ecs.get_component(world, e, Physic_Body)
        i, has_i := ecs.get_component(world, e, Interactable)
        a, has_a := ecs.get_component(world, e, Interactor)
        if !has_t do continue

        if has_b{
       		append_spatial_grid(grid, e, t.pos, b.shape)
        }

        if has_i{
       		append_spatial_grid(grid, e, t.pos, i.shape)
        }

        if has_a{
       		append_spatial_grid(grid, e, t.pos, a.shape)
        }
        // min, max := get_bounds(t.pos, b.shape)
        // min_key := get_grid_key(min)
        // max_key := get_grid_key(max)

        // for x in min_key.x..=max_key.x{
        //     for y in min_key.y..=max_key.y{
        //         key := Grid_Key{x, y}
        //         if key not_in grid{
        //             grid[key] = make([dynamic]ecs.Entity)//ecs.make_list(ecs.Entity)
        //         }
        //         append(&grid[key], e)
        //     }
        // }
    }
}

append_spatial_grid :: proc(grid : ^Spatial_Grid, e : ecs.Entity, pos : rl.Vector2, shape : Collision_Shape){
	min, max := get_bounds(pos, shape)
    min_key := get_grid_key(min)
    max_key := get_grid_key(max)

    for x in min_key.x..=max_key.x{
        for y in min_key.y..=max_key.y{
            key := Grid_Key{x, y}
            if key not_in grid do grid[key] = make([dynamic]ecs.Entity)//ecs.make_list(ecs.Entity)
            if is_entity_already_in_gridkey(grid[key], e) do continue
            append(&grid[key], e)
        }
    }
}

is_entity_already_in_gridkey :: proc(arr : [dynamic]ecs.Entity, e : ecs.Entity) -> bool{
	for other_e in arr{
		if e == other_e do return true
	}
	return false
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
