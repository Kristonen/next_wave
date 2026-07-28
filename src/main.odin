package game

import "core:c"
import "core:path/slashpath"
import "core:fmt"
import rl "vendor:raylib"
import "ecs"

Gravity_Component :: struct{
    grav : f32
}

main :: proc(){
    // list := ecs.make_list(i32, 2)
    // for i in 0..<1000{
    //     ecs.append_list(&list, i32(i))
    // }

    // for i in 0..<list.len{
    //     fmt.println(list.items[i])
    // }

    // ecs.destroy_list(&list)
    init_game()
    
    player := create_entity()
    game.player = player
    world = &game.world
    ecs.add_component(world, player, Transform{{1000, 500}, 0, {1, 1}})
    ecs.add_component(world, player, Circle{PLAYER_RADIUS/2, rl.BEIGE})
    ecs.add_component(world, player, Auto_Attack{600, 5, 0, 20})
    // ecs.add_component(world, player, Rectangle{0, 0, 100, 50})
    ecs.add_component(&game.world, player, Player{})
    ecs.add_component(&game.world, player, Speed{500})
    player_body := Physic_Body{
        mass = 1,
        type = .Dynamic,
        shape = {
            is_circle = true,
            size = {},
            radius = 32/2,
            offset = {},
        }
    }
    ecs.add_component(world, player, player_body)

    e := create_entity()
    ecs.add_component(&game.world, e, Transform{{250, 200}, 0, {1, 1}})
    ecs.add_component(&game.world, e, Rectangle{ENEMY_WIDTH, ENEMY_HEIGHT, rl.GREEN})
    ecs.add_component(world, e, Enemy{})
    e_body := Physic_Body{
        mass = 10,
        type = .Dynamic,
        shape = {
            is_circle = false,
            size = {ENEMY_WIDTH, ENEMY_HEIGHT},
            offset = {},
        }
    }
    ecs.add_component(world, e, e_body)

    e = create_entity()
    ecs.add_component(&game.world, e, Transform{{125, 200}, 0, {1, 1}})
    ecs.add_component(&game.world, e, Rectangle{ENEMY_WIDTH, ENEMY_HEIGHT, rl.GRAY})
    ecs.add_component(world, e, Enemy{})
    e_body = Physic_Body{
        mass = 50,
        type = .Dynamic,
        shape = {
            is_circle = false,
            size = {ENEMY_WIDTH, ENEMY_HEIGHT},
            offset = {},
        }
    }
    ecs.add_component(world, e, e_body)

    // task : Spawn_Task
        // task.components = ecs.make_list(any)
        // ecs.append_list(&task.components, new_component(Bullet{dir, 500}))
        // ecs.append_list(&task.components, new_component(Transform{t.pos, 0, {1, 1}}))
        // ecs.append_list(&task.components, new_component(Circle{12, rl.SKYBLUE}))
    cd : f32 = 0
    max_cd : f32 = 20
    


    rl.InitWindow(1920, 1080, "Next Wave: Onslaught")
    for !rl.WindowShouldClose(){
        game.dt = rl.GetFrameTime()
        build_spatial_grid(&game_grid)
        // Input
        sys_input()
        // Update
        sys_test()
        flush_spawns()
        sys_player_movement()
        sys_auto_attack()
        sys_bullet()
        // Collision
        // sys_collision()
        sys_pushback_entities()
        // Camera
        // Draw
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        sys_render()
        rl.EndDrawing()
        cd -= game.dt
        if cd <= 0{
            cd = max_cd
            // bullet := create_entity()
            // ecs.add_component(world, bullet, Bullet{{1, 1}, 500})
            // ecs.add_component(world, bullet, Transform{{0, 0}, 0, {1, 1}})
            // ecs.add_component(world, bullet, Circle{12, rl.SKYBLUE})
        }
    }

    rl.CloseWindow()
}