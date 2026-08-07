package game

import "core:strings"
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
        tb, is_tb := ecs.get_component(world, e, Text_Box)
        if !has_t do continue
        if !is_in_view(t.pos) do continue
        if has_circle{
            rl.DrawCircleV(t.pos, circle.radius * t.scale.x, circle.color)
        } else if has_rec{
            rl.DrawRectangleRec(get_rec(t^, rec^), rec.color)
        } else if is_tb{
       		draw_text(get_rec(t^, tb.rec), tb.txt)
        	// rl.DrawRectangleRec(get_rec(t^, tb.rec), tb.rec.color)
        }

        at, has_at := ecs.get_component(world, e, Animation_Texture)
        if has_at{
        	src_rec : rl.Rectangle = {f32(at.width) * f32(at.current_frame), 0, f32(at.width), f32(at.width)}
         	dest_rec : rl.Rectangle = {t.pos.x, t.pos.y, 64, 64}
          	rl.DrawTexturePro(at.tex^, src_rec, dest_rec, {}, t.rotation, rl.WHITE)
        }

        if !game.helper_active do continue
        b, has_b := ecs.get_component(world, e, Physic_Body)
        i, has_i := ecs.get_component(world, e, Interactable)
        if !has_t do continue
        if !has_b && !has_i do continue
        shape := has_i ? i.shape : b.shape
        color : rl.Color = has_i ? {0, 0, 150, 100} : {150, 25, 150, 200}
        if shape.is_circle{
            pos, r := get_cir_collider(t^, shape)
            rl.DrawCircleV(pos, r, color)
        } else{
            rl.DrawRectangleRec(get_rec_collider(t^, shape), color)
        }

        for key in game_grid{
            rl.DrawRectangleLinesEx({f32(key.x) * CELL_SIZE, f32(key.y) * CELL_SIZE, CELL_SIZE, CELL_SIZE}, 2, rl.RED)
        }
    }
    rl.DrawFPS(25, 25)
}

draw_text :: proc(rec : rl.Rectangle, txt : Text){
	c_string := strings.clone_to_cstring(fmt.tprintf("%v", txt.content))
	len := f32(rl.MeasureText(c_string, txt.size))
	x : f32 = (rec.x + rec.width/2) - (len/2)
	y : f32 = (rec.y + rec.height/2) - (f32(txt.size)/2)
	other_text := txt
	draw_text := strings.clone_to_cstring(other_text.content)
	rl.DrawText(draw_text, i32(x), i32(y), txt.size, rl.WHITE)
	delete(c_string)
	delete(draw_text)
}
