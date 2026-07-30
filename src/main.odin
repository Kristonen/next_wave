package game

import "core:fmt"
import rl "vendor:raylib"
import "ecs"

Gravity_Component :: struct{
    grav : f32
}

main :: proc(){
    init_game()
    // rl.SetTargetFPS(500)

    player := create_entity()
    game.player = player
    ecs.add_component(world, player, Transform{{1000, 500}, 0, {1, 1}})
    ecs.add_component(world, player, Circle{PLAYER_RADIUS/2, rl.BEIGE})
    ecs.add_component(world, player, Auto_Attack{600, 5, 0, 20})
    ecs.add_component(world, player, Movement{{}, 500})
    ecs.add_component(world, player, Health{100, 100, 0, 0, false})
    ecs.add_component(&game.world, player, Player{})
    player_body := Physic_Body{
        mass = 100,
        type = .Dynamic,
        shape = {
            is_circle = true,
            size = {},
            radius = 32/2,
            offset = {},
        }
    }
    ecs.add_component(world, player, player_body)

    e1 := create_entity()
    ecs.add_component(&game.world, e1, Transform{{250, 200}, 0, {1, 1}})
    ecs.add_component(&game.world, e1, Rectangle{ENEMY_WIDTH, ENEMY_HEIGHT, rl.GREEN})
    ecs.add_component(world, e1, Enemy{})
    ecs.add_component(world, e1, Movement{{}, 0})
    ecs.add_component(world, e1, Enemy_Melee{1})
    ecs.add_component(world, e1, Health{20, 100, 0, 0, false})
    e1_body := Physic_Body{
        mass = 10,
        type = .Dynamic,
        shape = {
            is_circle = false,
            size = {ENEMY_WIDTH, ENEMY_HEIGHT},
            offset = {},
        }
    }
    ecs.add_component(world, e1, e1_body)


    rl.InitWindow(1920, 1080, "Next Wave: Onslaught")
    for !rl.WindowShouldClose(){
        game.dt = rl.GetFrameTime()
        build_spatial_grid(&game_grid)
        // refresh_pairs()
        // Input
        sys_input()

        // Update
        sys_test()
        flush_spawns()
        sys_update()

        // Collision
        sys_collision()

        // Camera

        // Draw
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        sys_render()
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
