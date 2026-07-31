package game

import rl "vendor:raylib"
import "ecs"

Player :: struct{}
// Enemy
Enemy :: struct{}
Enemy_Melee :: struct{
	dmg : f32
}

Movement :: struct{
    dir : rl.Vector2,
    speed : f32,
}

Transform :: struct{
    pos : rl.Vector2,
    rotation : f32,
    scale : rl.Vector2,
}

Circle :: struct{
    radius : f32,
    color : rl.Color,
}

Rectangle :: struct{
    width, height : f32,
    color : rl.Color,
}

//Physics

Body_Type :: enum{
    Dynamic, Static, Kinmetic
}

Physic_Body :: struct{
    type : Body_Type,
    mass : f32,
    shape : Collision_Shape,
}

Collision_Shape :: struct{
    offset : rl.Vector2,
    size : rl.Vector2,
    radius : f32,
    is_circle : bool,
}

//Attack Player

Auto_Attack :: struct{
    range : f32,
    cooldown : f32,
    cooldown_timer : f32,
    damage : f32,
}

Bullet :: struct{
    is_player : bool,
    speed : f32,
    dmg : f32,
    hiited_e : [dynamic]ecs.Entity
}

Health :: struct{
    cur, max, min, dmg_amount : f32,
    is_dead : bool,
}

Lifetime :: struct{
    life, max_life : f32
}

// Interactable_State

Interactable :: struct{
	prompt : string,
	shape : Collision_Shape,
	is_active : bool,
}

Interactor :: struct{
	shape : Collision_Shape,
}

//UI Stuff

Text :: struct{
	content : string,
	size : i32,
}

Text_Box :: struct{
	rec : Rectangle,
	txt : Text,
}
