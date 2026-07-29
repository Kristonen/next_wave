package game

import "ecs"

pairs : [dynamic]Entity_Pair

Entity_Pair :: struct{
    e1, e2 : ecs.Entity
}

refresh_pairs :: proc(){
    delete(pairs)
    pairs = make([dynamic]Entity_Pair)
}

check_if_pair_already_exist :: proc(pair : Entity_Pair) -> bool{
    for i in 0..<len(pairs){
        o_pair := pairs[i]
        if (pair.e1 == o_pair.e1 || pair.e2 == o_pair.e2) && (pair.e2 == o_pair.e1 || pair.e2 == o_pair.e2){
            return true
        }
    }
    append(&pairs, pair)
    return false
}