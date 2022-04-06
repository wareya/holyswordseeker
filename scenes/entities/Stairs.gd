extends Node2D

export var next_floor = 1
export var next_name = "Prelude of Dust"

func trigger(other):
    if other.is_player:
        Manager.current_floor += 1
        Manager.change_to("res://scenes/LevelgenTest.tscn")
        return true
    return false
