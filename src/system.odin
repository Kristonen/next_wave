package game

import "core:fmt"
import "ecs"
import rl "vendor:raylib"

sys_test :: proc(){
    if input.pressed[.Left]{
        fmt.println("Wurde geklickt!")
    }
}

sys_input :: #force_inline proc(){
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

sys_render :: proc(){
	for i in 0..<len(game.entities){
        e := game.entities[i]
        t, has_t := ecs.get_component(world, e, Transform)
        circle, has_circle := ecs.get_component(world, e, Circle)
        rec, has_rec := ecs.get_component(world, e, Rectangle)
        if !has_t do continue
        if !is_in_view(t.pos) do continue
        if has_circle{
            rl.DrawCircleV(t.pos, circle.radius * t.scale.x, circle.color)
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
