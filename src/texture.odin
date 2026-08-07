package game

import rl "vendor:raylib"

texture_manager : Texture_Manager

Texture_Manager :: struct{
	fire : rl.Texture2D,
}

Animation_Texture :: struct{
	tex : ^rl.Texture2D,
	width : i32,
	current_frame, max_frame : int,
	cur_time, frame_time : f32,
}
