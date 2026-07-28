package game

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
    speed, has_speed := ecs.get_component(&game.world, e, Speed)
    dir : rl.Vector2

    if has_transform && has_speed{
        if input.down[.W] do dir.y -= 1
        if input.down[.A] do dir.x -= 1
        if input.down[.S] do dir.y += 1
        if input.down[.D] do dir.x += 1
    }

    if rl.Vector2Length(dir) > 0{
        dir = rl.Vector2Normalize(dir)
    }
    transform.pos += dir * speed.speed * game.dt
}

sys_bullet :: proc(){
    for i in 0..<game.entities.len{
        e := game.entities.items[i]
        b, has_b := ecs.get_component(world, e, Bullet)
        t, has_t := ecs.get_component(world, e, Transform)
        if !has_b || !has_t do continue
        t.pos += b.dir * b.speed * game.dt

        if !is_in_view(t.pos){
            ecs.destroy_entity(world, e)
        }
    }
}

is_in_view :: proc(pos : rl.Vector2) -> bool{
    if pos.x < 0 || pos.y < 0 do return false
    if pos.x > f32(rl.GetScreenWidth()) || pos.y > f32(rl.GetScreenHeight()) do return false
    return true
}

sys_pushback_entities :: proc(){
    list := game.entities

    tested_pairs : map[Entity_Pair]bool
    defer delete(tested_pairs)

    for key, e_in_cell in game_grid{
        for i in 0..<e_in_cell.len{
            e1 := e_in_cell.items[i]
            t1, has_t1 := ecs.get_component(world, e1, Transform)
            b1, has_b1 := ecs.get_component(world, e1, Physic_Body)
            if !has_t1 || !has_b1 do continue

            for j in i + 1..<e_in_cell.len{
                e2 := e_in_cell.items[j]
                pair := make_pair(e1, e2)
                if pair in tested_pairs do continue
                tested_pairs[pair] = true
                t2, has_t2 := ecs.get_component(world, e2, Transform)
                b2, has_b2 := ecs.get_component(world, e2, Physic_Body)
                if !has_t2 || !has_b2 do continue
                
                if !entities_collide(t1^, t2^, b1.shape, b2.shape) do continue
                
                diff := get_center_collider(t2^, b2^) - get_center_collider(t1^, b1^)
                dist := rl.Vector2Length(diff)
                if dist == 0{
                    diff = {0.1, 0.0}
                    dist = 0.1
                }
                dir := diff/dist

                r1 := b1.shape.is_circle ? b1.shape.radius : b1.shape.size.x * 0.5
                r2 := b2.shape.is_circle ? b2.shape.radius : b2.shape.size.x * 0.5
                overlap := (r1 + r2) - dist

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

sys_auto_attack :: proc(){
    for i in 0..<game.entities.len{
        e := game.entities.items[i]
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
        ecs.append_list(&task.components, new_component(Bullet{dir, 500}))
        ecs.append_list(&task.components, new_component(Transform{t.pos, 0, {1, 1}}))
        ecs.append_list(&task.components, new_component(Circle{12, rl.SKYBLUE}))
        // append(&pending_spawns, task)
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

sys_render :: proc(){
    for i in 0..<game.entities.len{
        e := game.entities.items[i]
        t, has_t := ecs.get_component(&game.world, e, Transform)
        circle, has_circle := ecs.get_component(&game.world, e, Circle)
        rec, has_rec := ecs.get_component(&game.world, e, Rectangle)

        if has_t && has_circle{
            rl.DrawCircleV(t.pos, circle.radius, circle.color)
        } else if has_t && has_rec{
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

get_collider_bounds :: proc(p: rl.Vector2, s: Collision_Shape) -> (min, max: rl.Vector2) {
    min = p + s.offset
    if s.is_circle {
        min -= {s.radius, s.radius}
        // Ein Kreis mit Radius R erstreckt sich von min bis min + 2*R
        max = p + s.offset + {s.radius, s.radius}
    } else {
        max = p + s.offset + s.size
    }
    return min, max
}