package game

import rl "vendor:raylib"
import "ecs"

sys_update :: proc(){
	for i in 0..<len(game.entities){
		e := game.entities[i]
		// Player
		sys_player_movement()

		sys_enemy(e)
		sys_auto_attack(e)
		sys_movement(e)

		sys_lifetime(e)

        sys_particle(e)

        sys_health(e)
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

sys_movement :: proc(e : ecs.Entity){
    m, has_m := ecs.get_component(world, e, Movement)
    t, has_t := ecs.get_component(world, e, Transform)
    if !has_m || !has_t do return
    t.pos += m.dir * m.speed * game.dt

    if !is_in_view(t.pos) && !ecs.has_component(world, e, Player){
        remove_entity(e)
    }
}

sys_enemy :: proc(e : ecs.Entity){
    enemy, is_enemy := ecs.get_component(world, e, Enemy)
    if !is_enemy do return
    m, has_m := ecs.get_component(world, e, Enemy_Melee)
    if !has_m do return
    t, has_t := ecs.get_component(world, e, Transform)
    move, has_move := ecs.get_component(world, e, Movement)
    if !has_t || !has_move do return

    player_t, has_player_t := ecs.get_component(world, game.player, Transform)
    if !has_player_t do return
    move.dir = {}
    dir := player_t.pos - t.pos
    if rl.Vector2Length(dir) > 0{
    	move.dir = rl.Vector2Normalize(dir)
    }
}

sys_health :: proc(e : ecs.Entity){
    h, has_h := ecs.get_component(world, e, Health)
    if !has_h do return
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

sys_lifetime :: proc(e : ecs.Entity){
    l, has_l := ecs.get_component(world, e, Lifetime)
    if !has_l do return
    l.life -= game.dt
}

sys_particle :: proc(e : ecs.Entity){
    l, has_l := ecs.get_component(world, e, Lifetime)
    if !has_l do return

    cir, has_cir := ecs.get_component(world, e, Circle)
    t, has_t := ecs.get_component(world, e, Transform)
    m, has_m := ecs.get_component(world, e, Movement)

    if !has_t || !has_cir do return

    cir.color.a = u8(255*(l.life/l.max_life))

    if l.life <= 0{
        // ecs.destroy_entity(world, e)
        remove_entity(e)
    }
}

sys_auto_attack :: proc(e : ecs.Entity){
    atk, has_atk := ecs.get_component(world, e, Auto_Attack)
    t, has_t := ecs.get_component(world, e, Transform)

    if !has_atk || !has_t do return
    atk.cooldown_timer -= game.dt
    if atk.cooldown_timer > 0 do return

    target_e, target_pos, found := find_closest_enemy(t.pos, atk.range)
    if !found do return

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
