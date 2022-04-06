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
        ent.connect("increase_message", self, "increase_message")
        ent.recalculate_stats()
    
    Scheduler.connect("player_turn_ready", self, "turn_ready")

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
            if is_in_group("Interactable"):
                remove_from_group("Interactable")
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
    _wishdir.x = round(_wishdir.x)
    _wishdir.y = round(_wishdir.y)
    _wishdir *= 16.0
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
var action = null

var turns_taken : int = 0
var regen_timer : int = 0
func handle_action_begin():
    last_action = action
    turns_taken += 1
    regen_timer += 1
    
    var regen = 1
    var regen_rate = 8
    if is_player:
        regen_rate = 8
    else:
        regen_rate = 16
    regen = 1.0
    regen_timer %= regen_rate
    if regen_timer == 0:
        if ent.stats.hp < ent.stats_calc.hp:
            ent.stats.hp = clamp(ent.stats.hp+regen, ent.stats.hp, ent.stats_calc.hp)
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
    var stackable = false
    
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
    
    func use(user : Character):
        if internal_name == "potion":
            user.heal_damage(stats.hp, user)
            if user.is_player or user.has_been_seen:
                user.add_text_effect(stats.hp, user.global_position, "#3F3")
        if internal_name == "rock":
            user.action = RockThrow.new(self)
        
        if consumable:
            var index = user.inventory.find(self)
            if index >= 0:
                user.inventory.remove(index)
        
        user.ent.recalculate_stats()

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
        strength = 10,
        willpower = 0,
        endurance = 3,
        perception = 7,
        speed = 5,
        sprite = preload("res://art/mymob.png"),
    },
    "slime" : {
        name = "Slime",
        level = 1,
        hp = 10,
        mp = 20,
        strength = 3,
        willpower = 7,
        endurance = 15,
        perception = 1,
        speed = 3,
        sprite = preload("res://art/slime.png"),
    },
    "wolf" : {
        name = "Cave Wolf",
        level = 1,
        hp = 20,
        mp = 0,
        strength = 9,
        willpower = 0,
        endurance = 4,
        perception = 10,
        speed = 7,
        sprite = preload("res://art/wolf.png"),
    },
    "eartheater" : {
        name = "Earth Eater",
        level = 1,
        hp = 10,
        mp = 20,
        strength = 7,
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
    "rock" : {
        internal_name = "rock",
        name = "Rock",
        description = "A nicely-sized rock. Does 10 attack worth of damage to whatever you throw it at. Range of 3 tiles.",
        weight = 1,
        hp = 1,
        usable = true,
        consumable = true
    },
}

var dust_effects = {
    cat = {
        internal_name = "cat",
        name = "Feline Transmorphism",
        desc = "You develop catlike features, heightened physical abilities, and a knack for magic. But you can no longer wear heavy armor, headgear, or pants, and your ability to carry items is lessened.",
        stats = {
            strength = 2,
            willpower = 2,
            endurance = 2,
            perception = 2,
            speed = 2,
            capacity = -10,
        },
        score = 1,
        # non-stat: sprite change, armor mechanics change
    },
    age = {
        internal_name = "age",
        name = "Elderliness",
        desc = "You suffer a hard hit to many of your physical abilities, but your power of will grows stronger. Also, your hair turns white.",
        stats = {
            strength = -3,
            willpower = 5,
            endurance = -3,
            perception = -3,
            speed = -3,
        },
        score = 3,
        # non-stat: sprite change
    },
    vampire = {
        internal_name = "vampire",
        name = "Vampirism",
        desc = "A strong sense of power, both physical and magical, fills you, yet you need to consume blood to continue to survive.",
        stats = {
            strength = 5,
            willpower = 5,
            endurance = 5,
            perception = 5,
            speed = 5,
        },
        score = -3,
        # non-stat: you need to kill living vertebrate enemies once per 20 turns or your health starts draining (down to 1 hp). can be cured with any holy consumable item. sprite change (eye color)
    },
    immortal = {
        internal_name = "immortal",
        name = "Biological Immortality",
        desc = "The fates have taken pity on you, and made it so that you do not age or fall ill, and your constitution is strengthened. Yet you cannot grow, and wounds may still kill.",
        stats = {
            hp = 40,
            endurance = 10,
            perception = 5,
        },
        score = 1,
        # non-stat: you don't gain *any* experience. prevents you from gaining positive-scored traits. can only be cured by using cursed items.
    },
    dustblind = {
        internal_name = "dustblind",
        name = "Dustblindness",
        desc = "You can no longer see the places you have once seen, or where you once were.",
        score = 3,
        # non-stat: fog of war resets every single turn
    },
    slowgrowth = {
        internal_name = "slowgrowth",
        name = "Slowgrowth",
        desc = "You now grow stronger more slowly than before.",
        score = 3,
        # non-stat: you only receive 60% of the xp you normally do
    },
    pain = {
        internal_name = "pain",
        name = "Pain of Life",
        desc = "Your every bone aches, and your limbs struggle to move as they should. Your health deteriorates, and you struggle to act quickly.",
        stats = {
            speed = -5,
        },
        score = 5
        # non-stat: health drain instead of regen. stops at 50%
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

    var xp = 0 # out of 100 per level
    
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
            #if delta != 0:
            #    print("delta for %s: %s" % [prop.name, delta])
            var c = stats.get(prop.name)
            stats.set(prop.name, c + delta)
    
    func random_pick(array : Array):
        return array[randi() % array.size()]
    
    signal increase_message
    func levelup():
        stats_base.level += 1
        var hp_boost = max(4, stats_base.endurance)
        var mp_boost = max(4, stats_base.willpower)
        stats_base.hp += hp_boost
        stats_base.mp += mp_boost
        
        #var which : String = random_pick(["strength", "willpower", "endurance", "perception", "speed"])
        var which : String = random_pick(["strength", "endurance", "speed"])
        stats_base.set(which, stats_base.get(which) + 1)
        
        emit_signal("increase_message", ["HP", hp_boost])
        emit_signal("increase_message", ["MP", mp_boost])
        emit_signal("increase_message", [which.capitalize(), 1])
        
        recalculate_stats()
    
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

func increase_message(what, amount):
    _log("%s's %s increased by %s" % [ent_name, what, amount])

func gain_xp(other_ent : Entity):
    var level = ent.stats_base.level
    
    var other_effective_level = 0.0
    for what in ["strength", "willpower", "endurance", "perception", "speed"]:
        other_effective_level += other_ent.stats_base.get(what)
    other_effective_level -= 25.0
    other_effective_level += 1.0
    
    level = max(1, level)
    other_effective_level = max(1, other_effective_level)
    
    var hpdiff = other_ent.stats_base.hp - ent.stats_base.hp
    hpdiff /= max(1, (other_ent.stats_base.hp + ent.stats_base.hp)/2.0)
    
    var gained = 20 + 4*(other_effective_level - level) + 4*hpdiff
    gained = max(gained, gained/2.0+2)
    gained = ceil(max(1, gained))
    ent.xp += gained
    
    _log("%s gained %s%% experience" % [ent_name, gained])
    
    check_levelup()

func check_levelup():
    while ent.xp >= 100:
        ent.xp -= 100
        ent.levelup()
        _log("%s levelled up to level %s!" % [ent_name, ent.stats_base.level])

# TODO: add skill that temporarily gives a massive speed boost until the player next attacks or X turns expire
class Skill extends Reference:
    var stats : Stats = Stats.new(true)
    
    func consumes_turn(by : Character):
        return false
    
    func perform(by : Character):
        pass

class RockThrow extends Skill:
    class Anim extends Sprite:
        var life = 0.0
        var max_life = Scheduler._turn_time * 0.5
        var start : Vector2
        var end : Vector2
        func _init(_start : Vector2, _end : Vector2):
            start = _start
            end = _end
            texture = preload("res://art/projectile effect.png")
        
        func _process(delta):
            life += delta/max_life
            life = clamp(life, 0.0, 1.0)
            global_position = lerp(start, end, life)
            if life >= 1.0:
                queue_free()
            
    var original : Item
    func _init(_original = null):
        original = _original
        stats.attack = 10
    func consumes_turn(by : Character):
        return true
    func perform(by : Character):
        EmitterFactory.emit(preload("res://sfx/fwup.wav"))
        var target = Vector2()
        var other = null
        for _i in range(3):
            target += by.heading
            other = by.probe(target)
            if other:
                break
        
        if other is TileMap:
            target -= by.heading
        
        var anim = Anim.new(by.logical_position(), by.logical_position() + target*16.0)
        by.get_parent().add_child(anim)
        
        if other and not other is TileMap:
            var damage = stats.damage(other.ent.stats)
            other.deal_damage(damage, by)
            return
        
        var where = by.logical_position() + target * 16.0
        var what = load("res://scenes/entities/Pickup.tscn").instance()
        what.hide_temporarily = 1.0
        if original:
            what.inventory = [original]
        else:
            what.inventory = [by.new_item("rock")]
        by.get_parent().add_child(what)
        what.global_position = where
        

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

func deal_damage(amount, other):
    if amount > 0.0:
        regen_timer = 0.0
        ent.stats.hp = max(0, ent.stats.hp-amount)
    
    _log("%s dealt %s damage to %s" % [ent_name, amount, other.ent_name])
    var color = "white"
    if !is_player:
        color = "yellow"
    if amount < 0:
        color = "green"
    if is_player or has_been_seen:
        if amount == 0.0:
            amount = 0.0
        add_text_effect(amount, global_position, color)
    
    if ent.stats.hp <= 0.0:
        other.gain_xp(ent)

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

var last_action = null

func turn_ready():
    if not last_action is String or last_action != "move":
        return
    for trigger in get_tree().get_nodes_in_group("PostTrigger"):
        if global_position.distance_to(trigger.global_position) < 8.0:
            print("triggering post trigger")
            trigger.trigger(self)

func handle_action():
    if action != null and (not action is String or action != "move"):
        #_log("%s is acting %s %s %s" % [ent_name, action, wishdir, heading])
        handle_action_begin()
    var return_value = TURN_END_NONE
    if action is String and action == "move":
        if attempt_motion(wishdir):
            handle_action_begin()
            return_value = TURN_END_INSTANT
            if is_player:
                for trigger in get_tree().get_nodes_in_group("Trigger"):
                    if global_position.distance_to(trigger.global_position) < 8.0:
                        print("triggering pre trigger")
                        if trigger.trigger(self):
                            return_value = TURN_END_ANIMATE
    elif action is String and action == "interact":
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
    
    elif action is Skill:
        action.perform(self)
        if action.consumes_turn(self):
            return_value = TURN_END_ANIMATE
        else:
            return_value = TURN_END_NONE
    
    if return_value != TURN_END_NONE:
        handle_action_end()
    
    action = null
    
    return return_value

var want_to_interact = false

func player_take_turn():
    if !Scheduler.is_simulation_allowed():
        return TURN_END_NONE
    wishdir = Vector2()
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
HP: {hp}/{hp_max} MP: {mp}/{mp_max} Level: {level} Exp: {xp}
Str: {str} Will: {will} End: {end} Perc: {perc} Speed: {speed}
Atk: {atk} Def: {def} Attune: {attune} Defy: {defy}
Agi: {agi}""".format(
    { name = ent_name, level = ent.stats_base.level, xp = ent.xp,
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
    action = null
    
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

