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


    npc := create_entity()
    ecs.add_component(world, npc, Transform{{200, 900}, 0, {1, 1}})
    ecs.add_component(world, npc, Circle{16, rl.BROWN})
    body : Physic_Body
    body.mass = 20
    body.type = .Static
    body.shape = {
   		is_circle = true,
    	radius = 16,
    }
    ecs.add_component(world, npc, body)
    interactable : Interactable
    interactable.prompt = "Es wird interagiert!"
    interactable.is_active = true
    interactable.shape.is_circle = true
    interactable.shape.radius = 100
    ecs.add_component(world, npc, interactable)

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
