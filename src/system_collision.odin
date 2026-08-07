package game

import "core:fmt"
import rl "vendor:raylib"
import "ecs"

sys_collision :: proc(){
	game.prompt.txt.content = ""
	tested_pairs : map[Entity_Pair]bool
    defer delete(tested_pairs)

	for key, e_in_cell in game_grid{
		for i in 0..<len(e_in_cell){
			e1 := e_in_cell[i]
			for j in i + 1..<len(e_in_cell){
				e2 := e_in_cell[j]

				pair := make_pair(e1, e2)
    			if pair in tested_pairs do continue
    			tested_pairs[pair] = true

    			sys_interactable(e1, e2)
			}
		}
	}
}

sys_interactable :: proc(e1, e2 : ecs.Entity){
	i1, has_i1 := ecs.get_component(world, e1, Interactable)
	i2, has_i2 := ecs.get_component(world, e2, Interactable)

	if !has_i1 && !has_i2 do return

	a1, has_a1 := ecs.get_component(world, e1, Interactor)
	a2, has_a2 := ecs.get_component(world, e1, Interactor)

	if !has_a1 && !has_a2 do return

	if has_i1 && has_a2 do game.prompt.txt.content = i1.prompt
	if has_i2 && has_a1 do game.prompt.txt.content = i2.prompt
}

entities_collide :: proc(t1, t2 : Transform, s1, s2 : Collision_Shape) -> bool{

    if s1.is_circle && s2.is_circle{ //Cir vs Cir
        pos1 := t1.pos + s1.offset
        pos2 := t2.pos + s2.offset
        return rl.CheckCollisionCircles(pos1, s1.radius, pos2, s2.radius)
    } else if !s1.is_circle && s2.is_circle{ //Rec vs Cir
        pos2 := t2.pos + s2.offset
        return rl.CheckCollisionCircleRec(pos2, s2.radius, get_rec_collider(t1, s1))
    } else if s1.is_circle && !s2.is_circle{ //Cir vs Rec
        pos1 := t1.pos + s1.offset
        return rl.CheckCollisionCircleRec(pos1, s1.radius, get_rec_collider(t2, s2))
    } else if !s1.is_circle && !s2.is_circle{ //Rec vs Rec
        return rl.CheckCollisionRecs(get_rec_collider(t1, s1), get_rec_collider(t2, s2))
    }

    return false
}
