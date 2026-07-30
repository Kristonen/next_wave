package ecs

import "core:mem"
Entity :: distinct u32
INVALID_ENTITY :: Entity(0)

World :: struct{
    next_id : Entity,
    entities : map[Entity]List(any),
}

create_entity :: proc{
	create_entity_new,
	create_entity_id,
}

create_entity_new :: proc(w : ^World) -> Entity{
    id := Entity(w.next_id)
    w.next_id += 1
    w.entities[id] = make_list(any)
    return id;
}

create_entity_id :: proc(w : ^World, e : Entity) -> Entity{
	w.entities[e] = make_list(any)
	return e
}

destroy_entity :: proc(w : ^World, e : Entity){
    list, ok := w.entities[e]
    if !ok do return

    for item in list.items{
        free(item.data, list.allocator)
    }

    destroy_list(&list)

    delete_key(&w.entities, e)
}

add_component :: proc(w : ^World, e : Entity, component : $T){
    list, ok := &w.entities[e]
    if !ok do return

    data_ptr := new(T)
    data_ptr^ = component

    append_list(list, data_ptr^)
}

add_component_any :: proc(w : ^World, e : Entity, component : any){
    list, ok := &w.entities[e]
    if !ok do return
    size := type_info_of(component.id).size
    data_ptr, _ := mem.alloc(size)
    mem.copy(data_ptr, component.data, size)
    typed_any := any{
        data = data_ptr,
        id = component.id,
    }
    append_list(list, typed_any)
}

get_component :: proc(w : ^World, e : Entity, $T : typeid) -> (^T, bool){
    list, ok := w.entities[e]
    if !ok do return nil, false

    for item in list.items{
        if item.id == T do return cast(^T)item.data, true
    }
    return nil, false
}

has_component :: proc(w : ^World, e : Entity, $T : typeid) -> bool{
    list, ok := w.entities[e]
    if !ok do return false

    for item in list.items{
        if item.id == T do return true
    }
    return false
}
