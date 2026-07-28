package ecs

import "core:mem"

List :: struct($T : typeid){
    len : i32,
    cap : i32,
    items : []T,
    allocator : mem.Allocator,
}

make_list :: proc($T : typeid, capacity : i32 = 2, allocator := context.allocator) -> List(T){
    return List(T){
        len = 0,
        cap = capacity,
        items = make([]T, capacity, allocator),
        allocator = allocator
    }
}

destroy_list :: proc(list : ^List($T)){
    delete(list.items, list.allocator)
    list.len = 0
}

append_list :: proc(list : ^List($T), item : T){
    if list.len == list.cap{
        new_cap := list.cap * 2
        new_items := make([]T, new_cap, list.allocator)
        copy(new_items, list.items)
        delete(list.items, list.allocator)
        list.items = new_items
        list.cap = new_cap
    }
    
    list.items[list.len] = item
    list.len += 1
}

remove_unordered :: proc(list : List($T), index : int){
    if index < 0 || index >= list.len do return

    list.items[index] = list.items[list.len - 1]
    list.len -= 1
    list.items = list.items[:list.len]
}

remove_ordered :: proc(list : List($T), index : int){
    if index < 0 || index >= list.len do return

    for i in index..<list.len - 1{
        list.items[i] = list.items[i + 1]
    }

    list.len -= 1
    list.items = list.items[:list.len]
}