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

    			sys_enemy_player(e1, e2)
				sys_pushback_entities(e1, e2)
				sys_check_bullets(e1, e2)
				sys_interactable(e1, e2)
			}
		}
	}
}

sys_pushback_entities :: proc(e1, e2 : ecs.Entity){

    t1, has_t1 := ecs.get_component(world, e1, Transform)
    b1, has_b1 := ecs.get_component(world, e1, Physic_Body)
    if !has_t1 || !has_b1 do return
    if b1.type == .Kinmetic do return

    t2, has_t2 := ecs.get_component(world, e2, Transform)
    b2, has_b2 := ecs.get_component(world, e2, Physic_Body)
    if !has_t2 || !has_b2 do return
    if b2.type == .Kinmetic do return
    if !entities_collide(t1^, t2^, b1.shape, b2.shape) do return

    diff := get_center_collider(t2^, b2^) - get_center_collider(t1^, b1^)
    dist := rl.Vector2Length(diff)
    if dist == 0{
        diff = {0.1, 0.0}
        dist = 0.1
    }
    dir := diff/dist

    // r1 := b1.shape.is_circle ? b1.shape.radius : b1.shape.size.x * 0.5
    // r2 := b2.shape.is_circle ? b2.shape.radius : b2.shape.size.x * 0.5
    // overlap := (r1 + r2) - dist

    // if overlap <= 0 do continue

    total_mass := b1.mass + b2.mass

    ratio1 := b2.type == .Static ? 1.0 : b2.mass / total_mass
    ratio2 := b1.type == .Static ? 1.0 : b1.mass / total_mass

    t1.pos = b1.type == .Static ? t1.pos : t1.pos - dir * ratio1
    t2.pos = b2.type == .Static ? t2.pos : t2.pos + dir * ratio2
}

sys_check_bullets :: proc(e1, e2 : ecs.Entity){
    t1, has_t1 := ecs.get_component(world, e1, Transform)
    body1, has_body1 := ecs.get_component(world, e1, Physic_Body)
    if !has_t1 || !has_body1 do return

    bullet1, is_bullet1 := ecs.get_component(world, e1, Bullet)
    enemy1, is_enemy1 := ecs.get_component(world, e1, Enemy)
    if !is_bullet1 && !is_enemy1 do return

    body2, has_body2 := ecs.get_component(world, e2, Physic_Body)
    t2, has_t2 := ecs.get_component(world, e2, Transform)
    if !has_t2 || !has_body2 do return
    bullet2, is_bullet2 := ecs.get_component(world, e2, Bullet)
    enemy2, is_enemy2 := ecs.get_component(world, e2, Enemy)
    if !is_bullet2 && !is_enemy2 do return

    if is_bullet1 && is_bullet2 do return
    if is_enemy1 && is_enemy2 do return

    if !entities_collide(t1^, t2^, body1.shape, body2.shape) do return

    if is_bullet1{
        h, has_h := ecs.get_component(world, e2, Health)
        if !has_h do return
        h.dmg_amount += bullet1.dmg
        // ecs.destroy_entity(world, e1)
        remove_entity(e1)

        create_particle(t2.pos, e2)
    } else{
        h, has_h := ecs.get_component(world, e1, Health)
        if !has_h do return
        h.dmg_amount += bullet2.dmg
        // ecs.destroy_entity(world, e2)
        remove_entity(e2)

        create_particle(t1.pos, e1)
    }
}

sys_interactable :: proc(e1, e2 : ecs.Entity){
	t1, has_t1 := ecs.get_component(world, e1, Transform)
	t2, has_t2 := ecs.get_component(world, e2, Transform)
	i1, has_i1 := ecs.get_component(world, e1, Interactable)
	i2, has_i2 := ecs.get_component(world, e2, Interactable)
	a1, has_a1 := ecs.get_component(world, e1, Interactor)
	a2, has_a2 := ecs.get_component(world, e2, Interactor)

	if !has_t1 || !has_t2 do return
	if !has_i1 && !has_i2 do return
	if !has_a1 && !has_a2 do return

	s1 := has_i1 ? i1.shape : a1.shape
	s2 := has_i2 ? i2.shape : a2.shape

	if !entities_collide(t1^, t2^, s1, s2) do return

	if has_i1{
		game.prompt.txt.content = i1.prompt
	} else{
		game.prompt.txt.content = i2.prompt
	}
}

sys_enemy_player :: proc(e1, e2 : ecs.Entity){
	p1, is_p1 := ecs.get_component(world, e1, Player)
	p2, is_p2 := ecs.get_component(world, e2, Player)

	if !is_p1 && !is_p2 do return

	t1, has_t1 := ecs.get_component(world, e1, Transform)
	b1, has_b1 := ecs.get_component(world, e1, Physic_Body)
	t2, has_t2 := ecs.get_component(world, e2, Transform)
	b2, has_b2 := ecs.get_component(world, e2, Physic_Body)

	if !has_t1 || !has_t2 do return
	if !has_b1 || !has_b2 do return

	if !entities_collide(t1^, t2^, b1.shape, b2.shape) do return

	if is_p1{
		do_enemy_stuff(e1, e2)
	} else{
		do_enemy_stuff(e2, e1)
	}

}

do_enemy_stuff :: proc(p : ecs.Entity, e : ecs.Entity){
	melee, is_melee := ecs.get_component(world, e, Enemy_Melee)
	player_h, has_player_h := ecs.get_component(world, p, Health)

	if is_melee && has_player_h{
		player_h.dmg_amount += melee.dmg
	}
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
