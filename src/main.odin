package game

import "core:fmt"
import rl "vendor:raylib"
import "ecs"

main :: proc(){
	rl.InitWindow(1920, 1080, "Next Wave: Onslaught")
    init_game()

    player := create_entity()
    game.player = player
    ecs.add_component(world, player, Transform{{1000, 500}, 0, {1, 1}})
    ecs.add_component(world, player, Circle{PLAYER_RADIUS/2, rl.BEIGE})
    ecs.add_component(world, player, Auto_Attack{600, 5, 0, 20})
    ecs.add_component(world, player, Movement{{}, 500})
    ecs.add_component(world, player, Health{100, 100, 0, 0, false})
    ecs.add_component(world, player, Player{})
    interactor : Interactor
    interactor.shape.is_circle = true
    interactor.shape.radius = PLAYER_RADIUS/2
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
    ecs.add_component(world, player, interactor)

    e1 := create_entity()
    ecs.add_component(world, e1, Transform{{250, 200}, 0, {1, 1}})
    ecs.add_component(world, e1, Rectangle{ENEMY_WIDTH, ENEMY_HEIGHT, rl.GREEN})
    ecs.add_component(world, e1, Enemy{})
    ecs.add_component(world, e1, Movement{{}, 0})
    ecs.add_component(world, e1, Enemy_Melee{1})
    ecs.add_component(world, e1, Health{100, 100, 0, 0, false})
    e1_body := Physic_Body{
        mass = 10,
        type = .Dynamic,
        shape = {
            is_circle = false,
            size = {ENEMY_WIDTH, ENEMY_HEIGHT},
            offset = {},
        }
    }
    ecs.add_component(world, e1, Health_Bar{0, 0, 0, 0, 60, 20, rl.RED, rl.GRAY})
    ecs.add_component(world, e1, e1_body)

    text_interact := create_entity()
    ecs.add_component(world, text_interact, Transform{{f32(rl.GetScreenWidth())/2-250, 5}, 0, {1, 1}})
    // ecs.add_component(world, text_interact, Rectangle{500, 50, rl.ORANGE})
    box : Text_Box
    box.rec.width = 500
    box.rec.height = 50
    box.rec.color = rl.ORANGE
    box.txt.content = ""
    box.txt.size = 40
    ecs.add_component(world, text_interact, box)
    game.prompt, _ = ecs.get_component(world, text_interact, Text_Box)

    texture_manager.fire = rl.LoadTexture("assets/fire.png")

    fire := create_entity()
    ecs.add_component(world, fire, Transform{{500, 500}, 180, {1, 1}})
    body : Physic_Body
    body.type = .Kinmetic
    body.shape.is_circle = true
    body.shape.offset = {}
    body.shape.radius = 10
    ecs.add_component(world, fire, body)
    fire_tex : Animation_Texture
    fire_tex.tex = &texture_manager.fire
    fire_tex.max_frame = 3
    fire_tex.width = 32
    fire_tex.cur_time = 0.1
    fire_tex.frame_time = 0.1
    ecs.add_component(world, fire, fire_tex)

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
