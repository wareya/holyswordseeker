tool
extends Node


func _ready():
    if Engine.editor_hint:
        return
    pass

var turn_progress = 1.0
var _turn_time = 1/6.0

func characters():
    return get_tree().get_nodes_in_group("Character")

func is_simulation_allowed():
    if Manager.fading:
        return false
    for node in get_tree().get_nodes_in_group("TextBubble"):
        if node.focused and !node.display_only:
            return false
    for node in get_tree().get_nodes_in_group("TextWindow"):
        if node.focused:
            return false
    return true

func get_next_turn_entity(list):
    var lowest_time = -1
    var lowest_entity = null
    for entity in list:
        if entity is Object and entity.has_method("cannot_act") and entity.cannot_act():
            continue
        if lowest_time < 0 or entity.turn_wait < lowest_time:
            lowest_time = entity.turn_wait
            lowest_entity = entity
    return lowest_entity

func check_overspeed():
    var ents = []
    for entity in characters():
        if entity.cannot_act():
            continue
        entity.reset_overspeed()
        var ent = {speed = entity.ent.stats.turnspeed(), turn_wait = entity.turn_wait, object = entity}
        ents.push_back(ent)
    
    var lowest_entity = get_next_turn_entity(ents)
    if !lowest_entity:
        return
    
    var num_times_seen_player = 0
    #var i = 0
    while num_times_seen_player < 2:
        if lowest_entity.object.is_player:
            num_times_seen_player += 1
        lowest_entity.object.tick_overspeed()
        var wait = lowest_entity.turn_wait
        for ent in ents:
            ent.turn_wait -= wait
        lowest_entity.turn_wait += lowest_entity.object.ent.stats.turnspeed()
        
        lowest_entity = get_next_turn_entity(ents)

func find_player():
    for entity in characters():
        if entity.is_player:
            return entity
    return null

func player_can_act():
    for entity in characters():
        if entity.is_player:
            return !entity.cannot_act()
    return false

signal player_turn_ready

var first = true
var sleep_before_next_player_turn = false
var last_turn_progress = turn_progress
var waiting_for_player = false
func _process(delta):
    if Engine.editor_hint:
        return
    
    if first:
        check_overspeed()
        first = false
    
    if turn_progress >= 1.0:
        if !is_simulation_allowed():
            return
        for entity in characters():
            entity.cycle_interp_data(true)
        turn_progress = 1.0
        var break_on_next_player_turn = false
        var player_advanced = false
        waiting_for_player = false
        while true:
            var next = get_next_turn_entity(characters())
            if !next:
                break
            var advancement = next.turn_wait
            for entity in characters():
                entity.turn_wait -= advancement
            if next.is_player:
                if last_turn_progress < 1.0:
                    emit_signal("player_turn_ready")
                    last_turn_progress = 1.0
                if break_on_next_player_turn:
                    break_on_next_player_turn = false
                    if player_advanced:
                        check_overspeed()
                    else:
                        waiting_for_player = true
                    break
                if sleep_before_next_player_turn:
                    sleep_before_next_player_turn = false
                    turn_progress = 0.0
                    break
                var endtype = next.advance_turn()
                if endtype == Character.TURN_END_INSTANT:
                    print("player turn")
                    player_advanced = true
                    turn_progress = 0.0
                elif endtype == Character.TURN_END_ANIMATE:
                    print("player turn")
                    turn_progress = 0.0
                    sleep_before_next_player_turn = true
                    break
                break_on_next_player_turn = true
            else:
                if !player_can_act():
                    for entity in characters():
                        entity.clear_overspeed()
                var endtype = next.advance_turn()
                print("enemy turn")
                if !player_can_act() or (next.has_been_seen and endtype == Character.TURN_END_ANIMATE):
                    turn_progress = 0.0
                    break
        last_turn_progress = turn_progress
    else:
        last_turn_progress = turn_progress
        if _turn_time > 0.0:
            turn_progress += delta/_turn_time
        else:
            turn_progress = 1.0
