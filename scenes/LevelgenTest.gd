extends Node2D


enum TILE {
    OPEN,
    CLOSED
}

var tiles : TileMap
var fog : TileMap
var map = {}
var openset = {}
var open = []
var frontier = []
var w = 64
var h = 64

var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

func valid_coord(v):
    return !(v.x < 0 or v.x >= w or v.y < 0 or v.y >= h)

func open(v, nofrontier = false):
    map[v] = TILE.OPEN
    open.push_back(v)
    openset[v] = null
    if nofrontier:
        return
    
    var i = frontier.find(v)
    while i >= 0:
        frontier.remove(i)
        i = frontier.find(v)
    for offset in directions:
        var v2 = v + offset*2
        if !valid_coord(v2):
            continue
        if not v2 in openset:
            frontier.push_back(v)
            break

var loop_frequency = 0.03

class Prefab:
    var rect = null
    var source = preload("res://prefabs/SmallRoom.tscn")
    var dict = {}
    func _init():
        var scene : Node = source.instance()
        var tiles : TileMap = scene.get_node("TileMap")
        rect = tiles.get_used_rect()
        scene.queue_free()
        for y in range(rect.position.y, rect.end.y):
            for x in range(rect.position.x, rect.end.x):
                var tile = tiles.get_cell(x, y)
                dict[Vector2(x, y)] = tiles.tile_set.tile_get_name(tile)
    func generate(map : Dictionary, v : Vector2):
        for v2 in dict.keys():
            map[v + v2] = dict[v2]

class entrance extends Prefab:
    var reference = \
    """
    .........
    .xxx.xxx.
    .x.....x.
    ....x....
    ox..n..xo
    oxn...nxo
    ox.....xo
    ox..p..xo
    ox.....xo
    oxxxxxxxo
    """

func _ready():
    var _seed = OS.get_unix_time()
    #_seed = 0
    #_seed = 1647961932
    print("seed: %s" % _seed)
    seed(_seed)
    
    tiles = $TileMap
    fog = $FogOfWar
    
    generate_map()
    init_fog()
    
    yield(get_tree(), "idle_frame")
    Manager.play_bgm(preload("res://bgm/caves.ogg"))

func random_pick(array : Array):
    return array[randi() % array.size()]

func generate_map():
    for y in range(h):
        for x in range(w):
            map[Vector2(x, y)] = TILE.CLOSED
    #var startpoint = Vector2(randi()%w, randi()%h)
    var startpoint = Vector2(w/2, h/2).floor()
    
    open(startpoint)
    
    # grow maze
    while openset.size() < w*h/4 and frontier.size() > 0:
        var i = randi()%frontier.size()
        var pick = frontier[i]
        var valid_dirs = []
        for dir in directions:
            var v2 = pick + dir*2
            if !valid_coord(v2):
                continue
            if not v2 in openset or randf() < loop_frequency:
                valid_dirs.push_back(dir)
        if valid_dirs.size() == 0:
            frontier.remove(i)
            continue
        valid_dirs.shuffle()
        open(pick + valid_dirs[0], true)
        open(pick + valid_dirs[0]*2)
    
    # fill in edges
    for y in range(h+2):
        y -= 1
        map[Vector2(-1, y)] = TILE.CLOSED
        map[Vector2(w , y)] = TILE.CLOSED
    for x in range(w):
        map[Vector2(x, -1)] = TILE.CLOSED
        map[Vector2(x,  h)] = TILE.CLOSED
    
    # scan for and close up short dead ends
    for _i in range(3):
        for _v in openset.keys():
            var sum = 1
            for dir in directions:
                var v = _v + dir
                if !valid_coord(v):
                    continue
                if map[v] == TILE.OPEN:
                    sum += 1
            if sum == 2:
                map[_v] = TILE.CLOSED
                openset.erase(_v)
                for dir in directions:
                    var v = _v + dir
                    if !valid_coord(v):
                        continue
                    if v in openset:
                        openset.erase(v)
                    if map[v] != TILE.CLOSED:
                        map[v] = TILE.CLOSED
                        openset.erase(v)
    
    # scan for and open up small wall islands
    var islands = {}
    for y in range(h+2):
        y -= 1
        for x in range(w+2):
            x -= 1
            var v = Vector2(x, y)
            if map[v] == TILE.CLOSED:
                var found = false
                var added = false
                for base in islands:
                    if v in islands[base]:
                        found = true
                        break
                    for dir in directions:
                        var v2 = v + dir
                        if v2 in islands[base]:
                            islands[base][v] = null
                            added = true
                            break
                    if added:
                        break
                if added:
                    continue
                if found:
                    continue
                islands[v] = {v : null}
    
    for v in islands.keys():
        if Vector2(-1, -1) in islands[v]:
            islands.erase(v)
    
    var island_eraser_modifier = 9.0
    var island_eraser_cap = 0.9
    for v in islands.keys():
        var size = islands[v].size()
        var erase_chance = (1.0+island_eraser_modifier)/(size+island_eraser_modifier)
        erase_chance *= island_eraser_cap
        
        if randf() < erase_chance:
            for v2 in islands[v]:
                open(v2)
            islands.erase(v)
    
    
    # add features
    var added_features = {} # for rejecting overlapping features
    for i in range(5):
        var prefab = Prefab.new()
        var allowed = openset.keys()
        var pick = allowed[randi()%allowed.size()]
        var repick = true
        while repick:
            var start = pick + prefab.rect.position
            var end = pick + prefab.rect.end
            if start.x == 0 or start.y == 0 or end.x >= w or end.y >= h:
                repick = true
            else:
                repick = false
                for other in added_features.keys():
                    if  start.x <= other.end.x and end.x >= other.start.x \
                    and start.y <= other.end.y and end.y >= other.start.y:
                        repick = true
                        break
            if repick:
                if allowed.size() == 0:
                    continue
                allowed.erase(pick)
                pick = allowed[randi()%allowed.size()]
        if allowed.size() == 0:
            continue
        
        var info = {"start" : pick + prefab.rect.position, "end" : pick + prefab.rect.end}
        added_features[info] = null
        prefab.generate(map, pick)
        
        for v2 in prefab.dict.keys():
            var v = pick + v2
            if (map[v] is int and map[v] == TILE.CLOSED) or (map[v] is String and "SOLID" in map[v]):
                if v in openset:
                    openset.erase(v)
            else:
                openset[v] = null
    
    
    for y in range(h+2):
        y -= 1
        for x in range(w+2):
            x -= 1
            var tile = map[Vector2(x, y)]
            if tile is String:
                tile = tiles.tile_set.find_tile_by_name(tile)
            tiles.set_cell(x, y, tile)
    tiles.update_bitmask_region()
    
    var ent = preload("res://scenes/entities/Character.tscn")
    
    open = openset.keys()
    
    var player = ent.instance()
    player.is_player = true
    place_entity(player)
    
    place_entity(preload("res://scenes/entities/Stairs.tscn").instance())
    
    for _i in range(6):
        var stuff = preload("res://scenes/entities/Pickup.tscn").instance()
        stuff.randomify()
        place_entity(stuff)
        
    for _i in range(6):
        if open.size() == 0:
            return
        var possibilities = ["skeleton", "wolf", "slime", "eartheater"]
        var enemy = ent.instance()
        enemy.is_player = false
        enemy.as_a = random_pick(possibilities)
        place_entity(enemy)
    
func place_entity(entity):
    tiles.add_child(entity)
    if open.size() == 0:
        return entity
    var i = randi()%open.size()
    var pick = open[i]
    open.remove(i)
    if entity.has_method("set_tile_position"):
        entity.set_tile_position(pick)
    else:
        entity.global_position = pick*16.0 + Vector2(8.0, 8.0)
    return null

func init_fog():
    var minimum = Vector2()
    var maximum = Vector2()
    for tile in tiles.get_used_cells():
        minimum.x = min(minimum.x, tile.x)
        minimum.y = min(minimum.y, tile.y)
        maximum.x = max(maximum.x, tile.x)
        maximum.y = max(maximum.y, tile.y)
    
    var x_margin = ceil(1280.0/16.0/2.0)+1
    var y_margin = ceil(720.0/16.0/2.0)+1
    minimum.x -= x_margin
    maximum.x += x_margin
    minimum.y -= y_margin
    maximum.y += y_margin
    for y in range(minimum.y, maximum.y):
        for x in range(minimum.x, maximum.x):
            fog.set_cellv(Vector2(x, y), 0)
    
    fog.update_bitmask_region()
    
    for entity in Scheduler.characters():
        if entity.is_player: continue
        entity.has_been_seen = false

func tile_is_solid(map : TileMap, v : Vector2) -> bool:
    var tile = map.get_cellv(v.round())
    var tname : String = map.tile_set.tile_get_name(tile)
    return "SOLID" in tname

func raycast_in_tilemap(map : TileMap, start : Vector2, end : Vector2) -> bool:
    var dist = (end.round()-start.round()).abs()
    #var dist = (end-start).abs()
    var longer = max(dist.x, dist.y)
    #var longer
    #if dist.x > dist.y:
    #    longer = (end.round()-start.round()).abs().x
    #else:
    #    longer = (end.round()-start.round()).abs().y
    if longer == 0:
        return tile_is_solid(map, start)
    for i in range(longer+1.0):
        #print(i)
        var l = i/longer
        var f = start.linear_interpolate(end, l)
        if tile_is_solid(map, f):
            return true
    return false

var player_last_pos = null
func update_fog():
    for entity in Scheduler.characters():
        if entity.is_player or fog.get_cellv(entity.get_tile_position()) == -1:
            entity.show_hud()
        else:
            entity.hide_hud()
        pass
    
    var player = Scheduler.find_player()
    if !player:
        return
    var pos = fog.world_to_map(player.logical_position())
    if pos == player_last_pos:
        return
    player_last_pos = pos
    
    var _range = 6
    var force_range = 1
    for y in range(_range*2+1):
        y -= _range
        for x in range(_range*2+1):
            x -= _range
            var v = Vector2(x, y)
            if fog.get_cellv(pos+v) == -1:
                continue
            if abs(v.x) <= force_range and abs(v.y) <= force_range:
                fog.set_cellv(pos+v, -1)
            else:
                # TODO: make more efficient by knowing which tiles internal to the raycast are clear
                # (e.g. by making it return a list of clear tiles)
                # so that we only need to raycast the edge tiles and not the internal ones
                for dir in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
                    if !raycast_in_tilemap(tiles, pos, pos+v+dir/16.0):
                        fog.set_cellv(pos+v, -1)
                        break
    
    var __range = Vector2.ONE*(_range+1)
    fog.update_bitmask_region(pos - __range, pos + __range)


func _process(delta):
    update_fog()
