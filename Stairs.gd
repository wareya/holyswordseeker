extends Node2D

func trigger(other):
    if other.is_player:
        Manager.change_to("res://LevelgenTest.tscn")
        return true
    return false
