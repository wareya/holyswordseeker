extends Node

var player_ent : Character.Entity
var player_inventory : Array
var player_ent_name : String = "Player"

func savify_player_data():
    var player = Scheduler.find_player()
    if !player:
        return
    player_ent = player.ent.clone()
    player_ent_name = player.ent_name
    player_inventory = []
    for item in player.inventory:
        player_inventory.push_back(item.clone())
    

func unsavify_player_data():
    var player = Scheduler.find_player()
    if !player:
        return
    player.ent = player_ent.clone()
    player.ent_name = player_ent_name
    player.inventory = []
    for item in player_inventory:
        player.inventory.push_back(item.clone())

func _process(_delta):
    pass

func _ready():
    pass
