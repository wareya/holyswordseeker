tool
class_name Character
extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    logger = get_tree().get_nodes_in_group("Logger")
    if logger.size() > 0:
        logger = logger[0]
    else:
        logger = null
    
    interp_pos = [global_position]
    var _zoom = 2.0
    $Sprite/Camera2D.zoom = Vector2(1/_zoom, 1/_zoom)
    if !Engine.editor_hint:
        #if is_player:
            #ent.equip(new_item("longsword"))
            #ent.equip(new_item("scarf"))
        ent.recalculate_stats()
        pass
    #last_pos = global_position
    Scheduler.connect("player_turn_ready", self, "turn_ready")
    pass # Replace with function body.

var hud_target_alpha = 1.0

func hide_hud():
    hud_target_alpha = 0.0

func show_hud():
    has_been_seen = true
    hud_target_alpha = 1.0

#signal took_turn
export var is_player = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
var anim_timer = 0.0
#var anim_timer_max = 0.3333333
var anim_timer_max = 0.4

var heading = Vector2.DOWN
var ent_name = "<dummy>"

var dead = false

var has_been_seen = true

export var is_friendly = false
export(Array, String) var cutscene = []
export var sprite : Texture = null

func _process(delta):
    if !Engine.editor_hint:
        var rel_a = $Relative.modulate.a
        if rel_a > hud_target_alpha:
            rel_a -= delta*6.0
        elif rel_a < hud_target_alpha:
            rel_a += delta*6.0
        $Relative.modulate.a = clamp(rel_a, 0.0, 1.0)
        var max_hp = ent.stats_calc.hp
        var hp = ent.stats.hp
        $Relative/HPBar.visible = ceil(hp) < max_hp
        $Relative/HPBar.max_value = max_hp
        $Relative/HPBar.value = ceil(hp)
        $Relative/HPBar/Label.bbcode_text = "[center]%s/%s[/center]" % [ceil(hp), max_hp]
        if ent.stats.hp <= 0.0 and !dead:
            dead = true
            if !is_player:
                if has_been_seen:
                    EmitterFactory.emit("enemydead")
            else:
                EmitterFactory.emit("playerdead")
            $Relative.hide()
            if is_in_group("PointCollider"):
                remove_from_group("PointCollider")
            modulate.a = 0.5
            z_index = -1
        #find_node("Heading").rotation = heading.angle()
        find_node("Heading").rotation = zoh_in_array(interp_heading, Scheduler.turn_progress).angle()
        if immobile:
            find_node("Heading").visible = false
        
        if is_player:
            var out = get_tree().get_nodes_in_group("Infoer")[0]
            out.bbcode_enabled = true
            out.bbcode_text = "[right]%s[/right]" % writeinfo()
        
    
        #$Sprite.global_position = lerp(last_pos, global_position, Scheduler.turn_progress)
        #var real_position = global_position
        #global_position = lerp_in_array(interp_pos, Scheduler.turn_progress)
        if interp_pos.size() > 0:
            global_position = interp_pos.back()
        $Sprite.global_position = lerp_in_array(interp_pos, Scheduler.turn_progress)
        $Relative.global_position = lerp_in_array(interp_pos, Scheduler.turn_progress)
        $Sprite2.global_position = lerp_in_array(interp_pos, Scheduler.turn_progress)
        
        if is_player:
            if Input.is_action_just_pressed("ui_accept"):
                want_to_interact = true
            elif !Input.is_action_pressed("ui_accept"):
                want_to_interact = false
        if $Sprite/Camera2D.current:
            var limitA = get_tree().get_nodes_in_group("CamLimitA")
            var limitB = get_tree().get_nodes_in_group("CamLimitB")
            if limitA.size() > 0:
                limitA = limitA[0]
            else:
                limitA = null
            if limitB.size() > 0:
                limitB = limitB[0]
            else:
                limitB = null
            
            if limitA:
                $Sprite/Camera2D.limit_left = limitA.global_position.x
                $Sprite/Camera2D.limit_top = limitA.global_position.y
            else:
                $Sprite/Camera2D.limit_left = -10000000
                $Sprite/Camera2D.limit_top = -10000000
            if limitB:
                $Sprite/Camera2D.limit_right = limitB.global_position.x
                $Sprite/Camera2D.limit_bottom = limitB.global_position.y
            else:
                $Sprite/Camera2D.limit_right = 10000000
                $Sprite/Camera2D.limit_bottom = 10000000
            #$Sprite/Camera2D.global_position = (global_position*16.0).round()/16.0 + Vector2(0, 0.25003053247928622)
    
    if !cannot_act():
        anim_timer += delta
    anim_timer = fmod(anim_timer, anim_timer_max)
    
    var _sprite = sprite
    if is_player:
        #ent_name = "Player"
        #if Scheduler.turn_progress < 1.0 and !cannot_act():
        #    anim_timer += delta
        #else:
        #    anim_timer = fmod(anim_timer, anim_timer_max)
        #    if anim_timer < anim_timer_threshold:
        #        anim_timer = anim_timer_threshold - 0.001
        #    else:
        #        anim_timer = anim_timer_max - 0.001
        if _sprite == null:
            _sprite = preload("res://art/mychar2.png")
        $Sprite/Camera2D.current = true
    else:
        #ent_name = "Skeleton"
        if _sprite == null:
            _sprite = preload("res://art/mymob.png")
        $Sprite/Camera2D.current = false
    
    $Sprite.texture = _sprite
    $Sprite/Bottom.texture = _sprite
    $Sprite/Bottom.flip_h = anim_timer < (anim_timer_max/2.0)
    
    if !Engine.editor_hint:
        sprite = _sprite
    pass

func logical_position():
    if interp_pos.size() > 0:
        return interp_pos.back()
    else:
        return global_position

func rounded_position(pos : Vector2) -> Vector2:
    return (pos/16.0 + Vector2(0.5, 0.5)).floor()*16.0 - Vector2(8, 8)

func probe(_wishdir : Vector2, move = false) -> Object:
    _wishdir.x = sign(_wishdir.x)
    _wishdir.y = sign(_wishdir.y)
    _wishdir *= 16
    for entity in get_tree().get_nodes_in_group("PointCollider"):
        if entity == self:
            continue
        if (entity.logical_position() - (global_position + _wishdir)).length() < 8.0:
            return entity
    var collision = null
    for _tilemap in get_tree().get_nodes_in_group("Tilemap"):
        var tilemap : TileMap = _tilemap
        var cell = tilemap.get_cellv(tilemap.world_to_map(global_position + _wishdir))
        var tilename = tilemap.tile_set.tile_get_name(cell)
        if tilename.strip_edges().ends_with("SOLID"):
            collision = tilemap
            break
    if collision:
        return collision
    elif move:
        global_position += _wishdir
    return null

func attempt_motion(_wishdir):
    return !probe(_wishdir, true)

var last_pos = Vector2()
var turn_wait = 0.0

var overspeed_amount = 0

func clear_overspeed():
    overspeed_amount = 0
    $Relative/x2.text = ""
func reset_overspeed():
    overspeed_amount = 0
    $Relative/x2.text = "wait"
func tick_overspeed():
    if is_player:
        $Relative/x2.text = ""
        return
    overspeed_amount += 1
    if overspeed_amount > 1:
        $Relative/x2.text = "x%s" % overspeed_amount
    elif overspeed_amount < 1:
        $Relative/x2.text = "wait"
    else:
        $Relative/x2.text = ""

var interp_pos = []
var interp_heading = [Vector2.DOWN]
func cycle_interp_data(clear : bool):
    if clear:
        interp_pos = []
        interp_heading = []
    interp_pos.push_back(global_position)
    interp_heading.push_back(heading)

func lerp_in_array(array : Array, amount):
    if array.size() == 0:
        return null
    elif array.size() == 1:
        return array[0]
    else:
        #print("lerp time")
        amount *= array.size()-1.0
        var index = floor(amount)
        if index+1 >= array.size():
            return array.back()
        amount -= index
        return lerp(array[index], array[index+1], amount)

func zoh_in_array(array : Array, amount):
    if array.size() == 0:
        return null
    elif array.size() == 1:
        return array[0]
    else:
        amount *= array.size()-1.0
        var index = ceil(amount)
        if index >= array.size():
            return array.back()
        return array[index]

func advance_turn():
    if is_player:
        var ret = player_take_turn()
        if ret != TURN_END_NONE:
            turn_wait += ent.stats.turnspeed()
            return ret
        else:
            return ret
    else:
        var ret = ai_take_turn()
        turn_wait += ent.stats.turnspeed()
        return ret

var wishdir = Vector2()
var action = ""
var regen = 1/8.0

func handle_action_begin():
    last_action = action
    if is_player:
        regen = 1/8.0
    if !is_player:
        regen = 1/8.0/4.0
    regen = 0.0
    if ent.stats.hp < ent.stats_calc.hp:
        ent.stats.hp = clamp(ent.stats.hp+regen, ent.stats.hp, ent.stats_calc.hp)
    pass
func handle_action_end():
    cycle_interp_data(false)
    pass

class Stats extends Reference:
    var level = 1
    
    var hp = 32
    var mp = 16
    
    var strength = 5 # numbers in damage out. also carrying capacity.
    var willpower = 5 # numbers in magic damage out. also max mp.
    var endurance = 5 # numbers in less damage in. also max hp.
    var perception = 5 # numbers in less magic damage in. also identification.
    var speed = 5 # evasion and turn rate
    
    var capacity = 0 # based on max(strength, endurance/2) and willpower/4
    var insight = 0 # based on perception
    var agility = 0 # based on speed and perception/4
    
    var attack = 0 # numbers in damage out Plus Gear.
    var defense = 0 # numbers in less damage in Plus Gear.
    var attunement = 0 # numbers in magic damage out Plus Gear.
    var defiance = 0 # numbers in less magic damage in Plus Gear.
    
    func _init(empty = false):
        if empty:
            hp = 0
            mp = 0
            
            strength = 0
            willpower = 0
            endurance = 0
            perception = 0
            speed = 0
    
    func damage(other):
        var dmg = (2.0*attack*attack) / (attack+other.defense) - attack/2
        dmg = ceil(dmg)
        return dmg
    
    func turnspeed():
        var x = round(log(max(1.0, agility+1.0))/log(2)*10)/10.0
        #print(x)
        return 1.0/x
    
    func clone() -> Stats:
        var new = Stats.new()
        for prop in get_property_list():
            if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                continue
            var x = get(prop.name)
            if x is Object and x.has_method("duplicate"):
                x = x.duplicate()
            elif x is Object and x.has_method("clone"):
                x = x.clone()
            new.set(prop.name, x)
        return new

enum {
    EQUIP_SLOT_NONE
    
    EQUIP_SLOT_HEAD
    EQUIP_SLOT_BODY
    EQUIP_SLOT_PANTS
    EQUIP_SLOT_SHOES
    
    EQUIP_SLOT_HAND1
    EQUIP_SLOT_HAND2
    EQUIP_SLOT_NECK
    EQUIP_SLOT_ACCESSORY
}

class Item extends Reference:
    var internal_name = "nothing"
    var name = "Nothing"
    var undentified = false
    var description = "Nothing"
    var stats = Stats.new(true)
    var weight = 0
    var durability = 0
    var max_durability = 0
    var slot = EQUIP_SLOT_NONE
    var usable = false
    var consumable = false
    
    static func _clone_internal(old, new):
        for prop in old.get_property_list():
            if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                continue
            var x = old.get(prop.name)
            if x is Object and x.has_method("duplicate"):
                x = x.duplicate()
            elif x is Object and x.has_method("clone"):
                x = x.clone()
            new.set(prop.name, x)
    
    func clone() -> Item:
        var new = Item.new()
        Item._clone_internal(self, new)
        return new
    
    func writeinfo() -> String:
        var s = "Name: %s Level: %s Weight: %s" % [name, stats.level, weight]
        for prop in stats.get_property_list():
            if prop.name == "level":
                continue
            if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                continue
            var x = stats.get(prop.name)
            if x != 0:
                s += " %s: %s" % [prop.name.capitalize(), x]
        return s
    
    func use(user):
        if internal_name == "potion":
            user.heal_damage(stats.hp, user)
            if user.is_player or user.has_been_seen:
                user.add_text_effect(stats.hp, user.global_position, "#3F3")

const stat_db = {
    "player" : {
        name = "Player",
        level = 1,
        hp = 32,
        mp = 16,
        strength = 5,
        willpower = 5,
        endurance = 5,
        perception = 5,
        speed = 5,
        sprite = preload("res://art/mychar2.png"),
    },
    "npc" : {
        name = "NPC",
        level = 1,
        hp = 32,
        mp = 16,
        strength = 5,
        willpower = 5,
        endurance = 5,
        perception = 5,
        speed = 5,
        sprite = preload("res://art/npc.png"),
    },
    "skeleton" : {
        name = "Skeleton",
        level = 1,
        hp = 24,
        mp = 0,
        strength = 7,
        willpower = 0,
        endurance = 2,
        perception = 3,
        speed = 5,
        sprite = preload("res://art/mymob.png"),
    },
    "slime" : {
        name = "Slime",
        level = 1,
        hp = 10,
        mp = 20,
        strength = 3,
        willpower = 10,
        endurance = 20,
        perception = 5,
        speed = 3,
        sprite = preload("res://art/slime.png"),
    },
    "wolf" : {
        name = "Cave Wolf",
        level = 1,
        hp = 20,
        mp = 0,
        strength = 10,
        willpower = 0,
        endurance = 5,
        perception = 10,
        speed = 7,
        sprite = preload("res://art/wolf.png"),
    },
    "eartheater" : {
        name = "Earth Eater",
        level = 1,
        hp = 10,
        mp = 20,
        strength = 5,
        willpower = 5,
        endurance = 3,
        perception = 3,
        speed = 10,
        sprite = preload("res://art/eartheater.png"),
    },
}

export var as_a : String = "player"

func _notification(what):
    if what == NOTIFICATION_ENTER_TREE:
        yield(Scheduler.get_tree(), "idle_frame")
        if is_player:
            as_a = "player"
        elif is_friendly:
            as_a = "npc"
        if as_a in stat_db:
            var basis = stat_db[as_a].duplicate()
            ent.stats_base.hp = basis.hp
            ent.stats_base.mp = basis.mp
            ent.stats_base.strength = basis.strength
            ent.stats_base.willpower = basis.willpower
            ent.stats_base.endurance = basis.endurance
            ent.stats_base.perception = basis.perception
            ent.stats_base.speed = basis.speed
            ent.recalculate_stats()
            sprite = basis.sprite
            ent_name = basis.name

const item_db = {
    "longsword" : {
        internal_name = "longsword",
        name = "Longsword",
        description = "A straight, double-edged sword, about a meter in length.",
        weight = 4,
        attack = 5,
        slot = EQUIP_SLOT_HAND1
    },
    "dagger" : {
        internal_name = "dagger",
        name = "Dagger",
        description = "A dagger.",
        weight = 1,
        attack = 3,
        slot = EQUIP_SLOT_HAND1
    },
    "scarf" : {
        internal_name = "scarf",
        name = "Scarf",
        description = "A cute scarf.",
        weight = 1,
        defiance = 2,
        agility = 2,
        slot = EQUIP_SLOT_NECK
    },
    "tough_robe" : {
        internal_name = "tough_robe",
        name = "Tough Robe",
        description = "A robe made from tough fabric. Breaks easily.",
        weight = 2,
        defense = 2,
        slot = EQUIP_SLOT_BODY
    },
    "leather_armor" : {
        internal_name = "leather_armor",
        name = "Leather Armor",
        description = "A chest piece made from coated leather.",
        weight = 4,
        defense = 3,
        slot = EQUIP_SLOT_BODY
    },
    "chainmail" : {
        internal_name = "chainmail",
        name = "Chainmail",
        description = "Body armor made from interconnected metal links, with padding.",
        weight = 7,
        defense = 6,
        slot = EQUIP_SLOT_BODY
    },
    "iron_armor" : {
        internal_name = "iron_armor",
        name = "Iron Armor",
        description = "Body armor made from plates of iron, carefully attached to underlying padding.",
        weight = 15,
        defense = 10,
        slot = EQUIP_SLOT_BODY
    },
    "mythril_armor" : {
        internal_name = "mythril_armor",
        name = "Mythril Armor",
        description = "Body armor made from a very rare magical metal. Heavy.",
        weight = 20,
        defense = 14,
        agility = -3,
        slot = EQUIP_SLOT_BODY
    },
    "wayfarer_boots" : {
        internal_name = "wayfarer_boots",
        name = "Wayfarer's Boots",
        description = "Boots made in the image of a legendary hero, said to have traveled the world.",
        weight = 2,
        agility = 10,
        slot = EQUIP_SLOT_SHOES
    },
    "potion" : {
        internal_name = "potion",
        name = "Potion",
        description = "A healing potion. Restores 10 HP.",
        weight = 1,
        hp = 10,
        usable = true,
        consumable = true
    },
}

static func new_item(name : String):
    if name in item_db:
        var data = item_db[name]
        var item : Object = Item.new()
        for prop in data.keys():
            if prop in item:
                var x = data.get(prop)
                item.set(prop, x)
            if prop in item.stats:
                var x = data.get(prop)
                item.stats.set(prop, x)
        return item
    return null

class Entity extends Reference:
    var stats_base = Stats.new()
    var stats_calc = Stats.new() # counting equipment
    var stats = Stats.new() # counting damage
    var gear = []
    
    func equip(item) -> Item:
        if item.slot == EQUIP_SLOT_NONE:
            return item
        for other in gear:
            if other.slot == item.slot:
                gear.erase(other)
                gear.push_back(item)
                recalculate_stats()
                return other
        gear.push_back(item)
        recalculate_stats()
        return null
    
    func recalculate_stats():
        var old_calc = stats_calc.clone()
        stats_calc = stats_base.clone()
        for item in gear:
            for prop in stats_calc.get_property_list():
                if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                    continue
                if prop.name == "level":
                    continue
                var a = stats_calc.get(prop.name)
                var b = item.stats.get(prop.name)
                if b != 0:
                    print("adding %s to %s" % [b, prop.name])
                stats_calc.set(prop.name, a + b)
        
        stats_calc.capacity += max(stats_calc.strength, stats_calc.endurance/2.0) + stats_calc.willpower/4.0
        stats_calc.insight += stats_calc.perception
        stats_calc.agility += stats_calc.speed + stats_calc.perception/4.0
        
        stats_calc.attack += stats_calc.strength
        stats_calc.defense += stats_calc.endurance
        stats_calc.attunement += stats_calc.willpower
        stats_calc.defiance += stats_calc.perception
        
        # FIXME: make this be based on the old calc and end stats instead of the base and old calc stats
        # (doing so will make it more resilient)
        for prop in stats_calc.get_property_list():
            if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                continue
            var a = stats_calc.get(prop.name)
            var b = old_calc.get(prop.name)
            var delta = a - b
            if delta != 0:
                print("delta for %s: %s" % [prop.name, delta])
            var c = stats.get(prop.name)
            stats.set(prop.name, c + delta)
        
    
    func clone() -> Entity:
        var new = Entity.new()
        for prop in get_property_list():
            if not prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                continue
            var x = get(prop.name)
            if x is Object and x.has_method("duplicate"):
                x = x.duplicate()
            elif x is Object and x.has_method("clone"):
                x = x.clone()
            new.set(prop.name, x)
        return new

var ent = Entity.new()
var inventory = []

func set_tile_position(where : Vector2):
    global_position = where*16.0 + Vector2(8.0, 8.0)
    interp_pos = [global_position]

func get_tile_position():
    return (global_position/16.0 - Vector2(0.5, 0.5)).round()

var logger
func _log(text : String):
    logger.bbcode_text += "%s\n" % text

func cannot_act():
    return ent.stats.hp <= 0

func deal_damage(amount, _other):
    ent.stats.hp = max(0, ent.stats.hp-amount)
func heal_damage(amount, _other):
    ent.stats.hp = min(ent.stats_calc.hp, ent.stats.hp+amount)
    _log("%s healed %s hp" % [ent_name, amount])

enum {
    TURN_END_NONE,
    TURN_END_INSTANT,
    TURN_END_ANIMATE
}

class FloatingText extends Node2D:
    var life = 0.0
    var velocity = Vector2()
    var gravity = 64
    var child
    func _init(_text, color : String):
        child = RichTextLabel.new()
        child.bbcode_enabled = true
        child.fit_content_height = true
        child.rect_size.x = 500.0
        child.bbcode_text = "[center][color=%s]%s[/color][/center]" % [color, str(_text)]
        child.rect_position = -child.rect_size/2
        child.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var dynfont = DynamicFont.new()
        dynfont.font_data = preload("res://art/Play-Regular.ttf")
        dynfont.size = 24
        dynfont.outline_size = 2
        dynfont.outline_color = Color(0x10101080)
        child.add_font_override("normal_font", dynfont)
        velocity = Vector2(rand_range(-2, 2)*16.0, rand_range(4, 7)*-16.0)
        add_child(child)
        z_index = 10
        scale = Vector2(0.5, 0.5)
    func _process(delta):
        child.rect_position = -child.rect_size/2 - Vector2(0, 16.0)
        life += delta
        velocity.y += gravity*delta
        global_position += velocity*delta
        var x = 1.0-life*life
        modulate.a = clamp(x, 0.0, 1.0)
        if life > 1.0:
            queue_free()
            pass

func add_text_effect(_text, location, color = "white"):
    var fx = FloatingText.new(_text, color)
    get_parent().add_child(fx)
    fx.global_position = location

class Effect extends Sprite:
    var time = 1.0
    var life = 0.0
    var fadeout = false
    func _init(_texture : Texture, _frames : int = 1, _time = 0.2, _fadeout : bool = false):
        texture = _texture
        hframes = _frames
        fadeout = _fadeout
        time = _time
        z_index = 1
        material = CanvasItemMaterial.new()
        material.blend_mode = material.BLEND_MODE_ADD
    func _process(delta):
        life += delta/time
        frame = int(clamp(floor(hframes) * life, 0, hframes-1))
        if fadeout:
            modulate.a = 1.0-life
        if life > 1.0:
            queue_free()

func add_effect(_texture : Texture, _frames : int = 1, _time = 0.2, _fadeout : bool = false):
    var fx = Effect.new(_texture, _frames, _time, _fadeout)
    add_child(fx)
    fx.position = Vector2()
    return fx

func heading_effect(_texture : Texture, _frames : int = 1, _time = 0.2, _fadeout : bool = false):
    var fx = add_effect(_texture, _frames, _time, _fadeout)
    fx.position = heading * 16.0
    fx.rotation = heading.angle() + PI/2
    return fx

var last_action = ""

func turn_ready():
    if last_action != "move":
        return
    for trigger in get_tree().get_nodes_in_group("PostTrigger"):
        if global_position.distance_to(trigger.global_position) < 8.0:
            print("triggering post trigger")
            trigger.trigger(self)

func handle_action():
    if action != "" and action != "move":
        #_log("%s is acting %s %s %s" % [ent_name, action, wishdir, heading])
        handle_action_begin()
    var return_value = TURN_END_NONE
    if action == "move":
        if attempt_motion(wishdir):
            handle_action_begin()
            return_value = TURN_END_INSTANT
            if is_player:
                for trigger in get_tree().get_nodes_in_group("Trigger"):
                    if global_position.distance_to(trigger.global_position) < 8.0:
                        print("triggering pre trigger")
                        if trigger.trigger(self):
                            return_value = TURN_END_ANIMATE
    elif action == "interact":
        var other : Node = probe(heading)
        if other and other.is_in_group("Interactable"):
            if !(is_player and other.is_friendly):
                if is_player:
                    EmitterFactory.emit("slash")
                elif has_been_seen:
                    EmitterFactory.emit("bite")
                if other.is_player:
                    EmitterFactory.emit("playerhurt")
                elif has_been_seen:
                    EmitterFactory.emit("hit")
                var damage = ent.stats.damage(other.ent.stats)
                other.deal_damage(damage, self)
                _log("%s dealt %s damage to %s" % [ent_name, damage, other.ent_name])
                var color = "white"
                if !is_player:
                    color = "yellow"
                if damage < 0:
                    color = "green"
                if is_player or has_been_seen:
                    add_text_effect(damage, other.global_position, color)
            else:
                TextBubble.build(other.global_position, other.cutscene)
        else:
            if is_player:
                EmitterFactory.emit("whiff")
            _log("%s whiffed" % ent_name)
            if is_player or has_been_seen:
                add_text_effect("miss", global_position + heading*16.0)
            heading_effect(preload("res://art/slash fx.png"), 4, 0.15)
        return_value = TURN_END_ANIMATE
    
    if return_value != TURN_END_NONE:
        handle_action_end()
    
    return return_value

var want_to_interact = false

func player_take_turn():
    if !Scheduler.is_simulation_allowed():
        return TURN_END_NONE
    wishdir = Vector2()
    action = ""
    if Input.is_action_pressed("ui_down"):
        wishdir.y += 1
    if Input.is_action_pressed("ui_up"):
        wishdir.y -= 1
    if Input.is_action_pressed("ui_right"):
        wishdir.x += 1
    if Input.is_action_pressed("ui_left"):
        wishdir.x -= 1
    if wishdir != Vector2():
        if !Input.is_action_pressed("ctrl") or (abs(sign(wishdir.x)) == 1 and abs(sign(wishdir.y)) == 1):
            wishdir.x = sign(wishdir.x)
            wishdir.y = sign(wishdir.y)
            heading = wishdir
        if !Input.is_action_pressed("ctrl") and !Input.is_action_pressed("shift"):
            action = "move"
    if want_to_interact:
        want_to_interact = false
        action = "interact"
    
    return handle_action()


var aggro_range = 3.0
var attack_range = 1.0

func find_in_range(_range):
    for entity in Scheduler.characters():
        if entity == self or entity.ent.stats.hp <= 0 or !(entity.is_player or entity.is_friendly):
            continue
        if is_in_range(entity, _range):
            return entity
    return null
    
func is_in_range(other, _range):
    if !other:
        return false
    if other.ent.stats.hp <= 0:
        return false
    var delta = (other.global_position - global_position)/16
    return abs(delta.x) < _range+0.5 and abs(delta.y) < _range+0.5

func writeinfo():
    return """Name: {name}
HP: {hp}/{hp_max} MP: {mp}/{mp_max}
Str: {str} Will: {will} End: {end} Perc: {perc} Speed: {speed}
Atk: {atk} Def: {def} Attune: {attune} Defy: {defy}
Agi: {agi}""".format(
    { name = ent_name,
      hp = ent.stats.hp, hp_max = ent.stats_calc.hp, mp = ent.stats.mp, mp_max = ent.stats_calc.mp,
      str = ent.stats.strength, will = ent.stats.willpower, end = ent.stats.endurance, perc = ent.stats.perception, speed = ent.stats.speed,
      atk = ent.stats.attack, def = ent.stats.defense, attune = ent.stats.attunement, defy = ent.stats.defiance,
      agi = ent.stats.agility
    })

var aggro = null
var target = null
export var immobile = false
func ai_take_turn():
    if immobile:
        return TURN_END_INSTANT
    if is_friendly:
        # TODO: add friendly AI
        return TURN_END_INSTANT
    wishdir = Vector2()
    action = ""
    
    if !is_in_range(aggro, aggro_range):
        aggro = find_in_range(aggro_range)
        if aggro:
            print("changing aggro target")
    if !is_in_range(target, attack_range):
        if is_in_range(aggro, attack_range):
            target = aggro
        else:
            target = find_in_range(attack_range)
        if target:
            aggro = target
    if target:
        var delta = (target.global_position - global_position)/16
        heading = delta.round()
        heading.x = sign(heading.x)
        heading.y = sign(heading.y)
        action = "interact"
    elif aggro:
        action = "move"
        
        var delta = (aggro.global_position - global_position)/16
        wishdir = delta.round()
        if abs(wishdir.x) > abs(wishdir.y) and abs(wishdir.y) > 0:
            wishdir.x = sign(wishdir.x)
            wishdir.y = (randi()&1) * sign(wishdir.y)
        if abs(wishdir.y) > abs(wishdir.x) and abs(wishdir.x) > 0:
            wishdir.x = (randi()&1) * sign(wishdir.x)
            wishdir.y = sign(wishdir.y)
        else:
            wishdir.x = sign(wishdir.x)
            wishdir.y = sign(wishdir.y)
        
        var test_target = probe(wishdir)
        if test_target and test_target != aggro:
            if wishdir.x == 0:
                wishdir.x = randi()%3 - 1
            elif wishdir.y == 0:
                wishdir.y = randi()%3 - 1
            else:
                if randi()&1:
                    wishdir.x = 0
                else:
                    wishdir.y = 0
            test_target = probe(wishdir)
            if test_target and test_target != aggro:
                if wishdir.x == 0:
                    wishdir.x = randi()%3 - 1
                elif wishdir.y == 0:
                    wishdir.y = randi()%3 - 1
                else:
                    if randi()&1:
                        wishdir.x = 0
                    else:
                        wishdir.y = 0
        
        if wishdir != Vector2():
            heading = wishdir
        
    else:
        action = "move"
        
        var directions = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT,
                        Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
        #directions.shuffle()
        wishdir = directions[randi()%directions.size()]
        if wishdir != Vector2():
            heading = wishdir
    
    return handle_action()

