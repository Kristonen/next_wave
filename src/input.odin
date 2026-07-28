package game

input : Input

Inputs :: enum{
    Left, W, A, S, D
}

Input :: struct{
    down : map[Inputs]bool,
    pressed : map[Inputs]bool,
    released : map[Inputs]bool,
}

delete_input :: proc(){
    delete(input.down)
    delete(input.pressed)
    delete(input.released)
}