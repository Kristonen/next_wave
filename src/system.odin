package game

import "vendor:windows/GameInput"
import "core:fmt"
import "ecs"
import rl "vendor:raylib"

sys_test :: proc(){
    if input.pressed[.Left]{
        fmt.println("Wurde geklickt!")
    }
}

sys_input :: proc(){
    input.down[.Left] = rl.IsMouseButtonDown(.LEFT)
    input.pressed[.Left] = rl.IsMouseButtonPressed(.LEFT)
    input.released[.Left] = rl.IsMouseButtonReleased(.LEFT)

    input.down[.W] = rl.IsKeyDown(.W)
    input.pressed[.W] = rl.IsKeyPressed(.W)
    input.released[.W] = rl.IsKeyReleased(.W)

    input.down[.A] = rl.IsKeyDown(.A)
    input.pressed[.A] = rl.IsKeyPressed(.A)
    input.released[.A] = rl.IsKeyReleased(.A)

    input.down[.S] = rl.IsKeyDown(.S)
    input.pressed[.S] = rl.IsKeyPressed(.S)
    input.released[.S] = rl.IsKeyReleased(.S)

    input.down[.D] = rl.IsKeyDown(.D)
    input.pressed[.D] = rl.IsKeyPressed(.D)
    input.released[.D] = rl.IsKeyReleased(.D)

    if rl.IsKeyPressed(.F2){
        game.helper_active = !game.helper_active
    }
}

sys_player_movement :: proc(){
    e := game.player
    transform, has_transform := ecs.get_component(&game.world, e, Transform)
    movement, has_movment := ecs.get_component(world, e, Movement)

    if has_transform && has_movment{
        movement.dir = {}
        if input.down[.A] do movement.dir.x -= 1
        if input.down[.W] do movement.dir.y -= 1
        if input.down[.S] do movement.dir.y += 1
        if input.down[.D] do movement.dir.x += 1
    }

    if rl.Vector2Length(movement.dir) > 0{
        movement.dir = rl.Vector2Normalize(movement.dir)
    }
    // transform.pos += dir * speed.speed * game.dt
}

sys_bullet :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        b, has_b := ecs.get_component(world, e, Bullet)
        t, has_t := ecs.get_component(world, e, Transform)
        if !has_b || !has_t do continue
        // t.pos += b.dir * b.speed * game.dt
    }
}

sys_pushback_entities :: proc(){
    list := game.entities

    tested_pairs : map[Entity_Pair]bool
    defer delete(tested_pairs)

    for key, e_in_cell in game_grid{
        for i in 0..<len(e_in_cell){
            e1 := e_in_cell[i]
            t1, has_t1 := ecs.get_component(world, e1, Transform)
            b1, has_b1 := ecs.get_component(world, e1, Physic_Body)
            if !has_t1 || !has_b1 do continue
            if b1.type == .Kinmetic do continue

            for j in i + 1..<len(e_in_cell){
                e2 := e_in_cell[j]
                pair := make_pair(e1, e2)
                if pair in tested_pairs do continue
                tested_pairs[pair] = true
                t2, has_t2 := ecs.get_component(world, e2, Transform)
                b2, has_b2 := ecs.get_component(world, e2, Physic_Body)
                if !has_t2 || !has_b2 do continue
                if b2.type == .Kinmetic do continue
                if !entities_collide(t1^, t2^, b1.shape, b2.shape) do continue

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
        }
    }
}

sys_check_bullets :: proc(){
    for key, e_in_cell in game_grid{
        for i in 0..<len(e_in_cell){
            e1 := e_in_cell[i]
            t1, has_t1 := ecs.get_component(world, e1, Transform)
            body1, has_body1 := ecs.get_component(world, e1, Physic_Body)
            if !has_t1 || !has_body1 do continue

            bullet1, is_bullet1 := ecs.get_component(world, e1, Bullet)
            enemy1, is_enemy1 := ecs.get_component(world, e1, Enemy)
            if !is_bullet1 && !is_enemy1 do continue

            for j in i + 1..<len(e_in_cell){
                e2 := e_in_cell[j]
                body2, has_body2 := ecs.get_component(world, e2, Physic_Body)
                t2, has_t2 := ecs.get_component(world, e2, Transform)
                if !has_t2 || !has_body2 do continue
                bullet2, is_bullet2 := ecs.get_component(world, e2, Bullet)
                enemy2, is_enemy2 := ecs.get_component(world, e2, Enemy)
                if !is_bullet2 && !is_enemy2 do continue

                if is_bullet1 && is_bullet2 do continue
                if is_enemy1 && is_enemy2 do continue

                if check_if_pair_already_exist({e1, e2}) do continue
                if !entities_collide(t1^, t2^, body1.shape, body2.shape) do continue

                if is_bullet1{
                    h, has_h := ecs.get_component(world, e2, Health)
                    if !has_h do continue
                    h.dmg_amount += bullet1.dmg
                    // ecs.destroy_entity(world, e1)
                    remove_entity(e1)

                    create_particle(t2.pos, e2)
                } else{
                    h, has_h := ecs.get_component(world, e1, Health)
                    if !has_h do continue
                    h.dmg_amount += bullet2.dmg
                    // ecs.destroy_entity(world, e2)
                    remove_entity(e2)

                    create_particle(t1.pos, e1)
                }


                fmt.println("Bullet hat attackiert!")
            }
        }
    }
}

sys_enemy :: proc(){
    for key, e_in_cell in game_grid{
        for i in 0..<len(e_in_cell){
            e := e_in_cell[i]
            enemy, is_enemy := ecs.get_component(world, e, Enemy)
        }
    }
}

sys_health :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        h, has_h := ecs.get_component(world, e, Health)
        if !has_h do continue
        h.cur -= h.dmg_amount
        h.dmg_amount = 0
        if h.cur <= h.min{
            h.is_dead = true
        }
        if h.is_dead{
            // ecs.destroy_entity(world, e)
            remove_entity(e)
        }
    }
}

sys_movement :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        m, has_m := ecs.get_component(world, e, Movement)
        t, has_t := ecs.get_component(world, e, Transform)
        if !has_m || !has_t do continue
        t.pos += m.dir * m.speed * game.dt

        if !is_in_view(t.pos) && !ecs.has_component(world, e, Player){
            // ecs.destroy_entity(world, e)
            remove_entity(e)
        }
    }
}

is_in_view :: proc(pos : rl.Vector2) -> bool{
    if pos.x < 0 || pos.y < 0 do return false
    if pos.x > f32(rl.GetScreenWidth()) || pos.y > f32(rl.GetScreenHeight()) do return false
    return true
}

sys_auto_attack :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        atk, has_atk := ecs.get_component(world, e, Auto_Attack)
        t, has_t := ecs.get_component(world, e, Transform)

        if !has_atk || !has_t do continue
        atk.cooldown_timer -= game.dt
        if atk.cooldown_timer > 0 do continue

        target_e, target_pos, found := find_closest_enemy(t.pos, atk.range)
        if !found do continue

        atk.cooldown_timer = 2.0

        dir := target_pos - t.pos
        if rl.Vector2Length(dir) > 0{
            dir = rl.Vector2Normalize(dir)
        }

        task : Spawn_Task
        task.components = ecs.make_list(any)
        ecs.append_list(&task.components, new_component(Bullet{true, 500, 0, make([dynamic]ecs.Entity)}))
        ecs.append_list(&task.components, new_component(Transform{t.pos, 0, {1, 1}}))
        ecs.append_list(&task.components, new_component(Circle{12, rl.SKYBLUE}))
        ecs.append_list(&task.components, new_component(Movement{dir, 500}))
        bulelt_body := Physic_Body{
            type = .Kinmetic,
            mass = 0,
            shape = {
                is_circle = true,
                radius = 8,
                // offset = { 200, 200}
            }
        }
        ecs.append_list(&task.components, new_component(bulelt_body))
        append(&pending_spawns, task)
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

sys_particle :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        l, has_l := ecs.get_component(world, e, Lifetime)
        if !has_l do continue

        cir, has_cir := ecs.get_component(world, e, Circle)
        t, has_t := ecs.get_component(world, e, Transform)
        m, has_m := ecs.get_component(world, e, Movement)

        if !has_t || !has_cir do continue

        cir.color.a = u8(255*(l.life/l.max_life))

        if l.life <= 0{
            // ecs.destroy_entity(world, e)
            remove_entity(e)
        }
    }
}

sys_lifetime :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        l, has_l := ecs.get_component(world, e, Lifetime)
        if !has_l do continue
        l.life -= game.dt
    }
}

sys_render :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        t, has_t := ecs.get_component(&game.world, e, Transform)
        circle, has_circle := ecs.get_component(&game.world, e, Circle)
        rec, has_rec := ecs.get_component(&game.world, e, Rectangle)
        if !has_t do continue
        if !is_in_view(t.pos) do continue
        if has_circle{
            rl.DrawCircleV(t.pos, circle.radius, circle.color)
        } else if has_rec{
            rl.DrawRectangleRec(get_rec(t^, rec^), rec.color)
        }

        if !game.helper_active do continue
        color : rl.Color = {150, 25, 150, 200}
        b, has_b := ecs.get_component(world, e, Physic_Body)
        if !has_b || !has_t do continue
        if b.shape.is_circle{
            pos, r := get_cir_collider(t^, b.shape)
            rl.DrawCircleV(pos, r, color)
        } else{
            rl.DrawRectangleRec(get_rec_collider(t^, b.shape), color)
        }

        for key in game_grid{
            rl.DrawRectangleLinesEx({f32(key.x) * CELL_SIZE, f32(key.y) * CELL_SIZE, CELL_SIZE, CELL_SIZE}, 2, rl.RED)
        }
    }
    rl.DrawFPS(25, 25)
}

get_rec :: proc(t : Transform, rec : Rectangle) -> rl.Rectangle{
    return { t.pos.x, t.pos.y, rec.width, rec.height}
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
