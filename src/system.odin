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

is_in_view :: proc(pos : rl.Vector2) -> bool{
    if pos.x < 0 || pos.y < 0 do return false
    if pos.x > f32(rl.GetScreenWidth()) || pos.y > f32(rl.GetScreenHeight()) do return false
    return true
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
