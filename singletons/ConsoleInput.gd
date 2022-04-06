extends LineEdit

var console : RichTextLabel
var bg : Panel

func console_print(text):
    if !console.bbcode_text.ends_with("\n"):
        console.bbcode_text += "\n"
    console.bbcode_text += text
    var scrollbox : ScrollContainer = console.get_parent().get_parent()
    yield(get_tree(), "idle_frame")
    scrollbox.scroll_vertical = console.get_parent().rect_size.y
    yield(get_tree(), "idle_frame")
    scrollbox.scroll_vertical = console.get_parent().rect_size.y

func console_print_err(text):
    console_print("[color=red]error:[/color] %s" % text)

var history_cursor = -1
var history = []
var history_stash = ""

func _ready():
    console = get_tree().get_nodes_in_group("Console")[0]
    bg = get_parent().find_node("ConsoleBG")
    var _unused
    _unused = connect("text_entered", self, "confirm")
    _unused = connect("focus_exited", self, "hide_bg")
    _unused = connect("text_changed", self, "hide_placeholder")
    _unused = connect("focus_entered", self, "show_bg")
    yield(get_tree(), "idle_frame")
    erase()

func show_bg():
    bg.visible = true
func hide_bg():
    bg.visible = false
    erase()

var commands = {
    "inventory" : "cmd_inventory",
    "gear" : "cmd_gear",
    "equip" : "cmd_equip",
    "unequip" : "cmd_unequip",
    "search" : "cmd_search",
    "take" : "cmd_take",
    "help" : "cmd_help",
    "use" : "cmd_use",
}

func execute_command(text : String, loggify = true):
    text = text.strip_edges()
    if text == "":
        release_focus()
        return
    
    if loggify:
        history.push_back(text)
        history_cursor = -1
    if !text.begins_with("/"):
        return
    text = text.substr(1)
    var split = Array(text.split(" "))
    # TODO: parse console command
    if split[0] in commands:
        var args = split.slice(1, split.size())
        call(commands[split[0]], args)
    else:
        console_print("unknown command [color=yellow]%s[/color]" % split[0])

func cmd_inventory(_args : Array, get_desc = false):
    if get_desc:
        return "/inventory: prints your inventory"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    
    console_print("Inventory of %s:" % player.ent_name)
    if player.inventory.size() == 0:
        console_print("<empty>")
    else:
        var i = 0
        for item in player.inventory:
            console_print("Item %s: %s" % [i, item.writeinfo()])
            i += 1

func cmd_gear(_args : Array, get_desc = false):
    if get_desc:
        return "/gear: prints your current equipment"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    
    console_print("Gear of %s:" % player.ent_name)
    if player.ent.gear.size() == 0:
        console_print("<empty>")
    else:
        var i = 0
        for item in player.ent.gear:
            console_print("Item %s: %s" % [i, item.writeinfo()])
            i += 1

func cmd_search(_args : Array, get_desc = false):
    if get_desc:
        return "/search: searches under the player for items"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    
    var pickup = null
    for entity in get_tree().get_nodes_in_group("Pickup"):
        if entity.global_position.distance_to(player.logical_position()) < 8.0:
            pickup = entity
            break
    
    if pickup:
        console_print("Items:")
        if pickup.inventory.size() == 0:
            console_print("<empty>")
        else:
            var i = 0
            for item in pickup.inventory:
                console_print("Item %s: %s" % [i, item.writeinfo()])
                i += 1
    else:
        console_print("There is nothing to search")

func cmd_take(args : Array, get_desc = false):
    if get_desc:
        return "/take [number]: searches under the player for items"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    if args.size() < 1:
        console_print_err("missing argument")
        return
    if !args[0].is_valid_float():
        console_print_err("argument is not a number")
        return
    var i = int(args[0].to_float())
    
    var pickup = null
    for entity in get_tree().get_nodes_in_group("Pickup"):
        if entity.global_position.distance_to(player.logical_position()) < 8.0:
            pickup = entity
            break
    
    if pickup:
        if i >= pickup.inventory.size():
            console_print_err("no such item %s" % i)
            return
        else:
            var item = pickup.inventory.pop_at(i)
            console_print("Took %s" % item.name)
            player.inventory.push_back(item)
            if pickup.inventory.size() == 0:
                pickup.queue_free()
    else:
        console_print("There is nothing to pick up")

func cmd_equip(args : Array, get_desc = false):
    if get_desc:
        return "/equip [number]: moves an item from inventory to gear"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    if args.size() < 1:
        console_print_err("missing argument")
        return
    if !args[0].is_valid_float():
        console_print_err("argument is not a number")
        return
    var i = int(args[0].to_float())
    
    if i >= player.inventory.size():
        console_print_err("no such item %s in inventory" % i)
        return
    
    var item = player.inventory.pop_at(i)
    var other = player.ent.equip(item)
    if other:
        console_print("%s is not equippable" % item.name)
        player.inventory.insert(i, other)
    else:
        console_print("Equipped %s" % item.name)
    player.ent.recalculate_stats()

func cmd_use(args : Array, get_desc = false):
    if get_desc:
        return "/use [number]: uses an item if it is usable. consumes it if it is a consumable."
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    if args.size() < 1:
        console_print_err("missing argument")
        return
    if !args[0].is_valid_float():
        console_print_err("argument is not a number")
        return
    var i = int(args[0].to_float())
    
    if i >= player.inventory.size():
        console_print_err("no such item %s in inventory" % i)
        return
    
    var item = player.inventory[i]
    if item.usable:
        item.use(player)
    else:
        console_print_err("item `%s` is not usable" % item.internal_name)
    

func cmd_unequip(args : Array, get_desc = false):
    if get_desc:
        return "/unequip [number]: moves an item from gear to inventory"
    var player = Scheduler.find_player()
    if !player:
        console_print_err("failed to find player")
        return
    if args.size() < 1:
        console_print_err("missing argument")
        return
    if !args[0].is_valid_float():
        console_print_err("argument is not a number")
        return
    
    var i = int(args[0].to_float())
    if i >= player.ent.gear.size():
        console_print_err("no such item %s in gear" % i)
        return
    
    var item = player.ent.gear.pop_at(i)
    player.inventory.push_back(item)
    player.ent.recalculate_stats()
    console_print("Unequipped %s" % item.name)
        
func cmd_help(_args : Array, get_desc = false):
    if get_desc:
        return "/help: lists available commands"
    console_print("Available commands:")
    for command in commands.keys():
        console_print("%s" % [call(commands[command], [], true)])

func confirm(new_text : String):
    execute_command(new_text)
    erase()

func erase():
    text = ""
    placeholder_text = " "

func hide_placeholder(new_text : String):
    placeholder_text = " "
    if new_text == "":
        erase()

func _gui_input(event : InputEvent):
    if !has_focus():
        return
    get_tree().set_input_as_handled()
    if event is InputEventKey:
        for action in InputMap.get_actions():
            if event.is_action(action):
                Input.action_release(action)
    if event is InputEventKey and event.physical_scancode == KEY_ESCAPE:
        release_focus()
        return

func caret_to_end():
    yield(get_tree(), "idle_frame")
    caret_position = text.length()

func _input(event : InputEvent):
    if event is InputEventMouseButton:
        if event.button_index <= 2 and !get_global_rect().has_point(event.global_position):
            if has_focus():
                release_focus()
    if event is InputEventKey:
        if event.pressed:
            if event.physical_scancode == KEY_SLASH:
                if !has_focus():
                    grab_focus()
            if !has_focus():
                return
            if event.physical_scancode == KEY_UP:
                if history_cursor == -1:
                    history_stash = text
                    history_cursor = history.size()
                history_cursor -= 1
                if history_cursor < 0 and history.size() > 0:
                    history_cursor = 0
                if history_cursor >= 0 and history_cursor < history.size():
                    text = history[history_cursor]
                    caret_to_end()
                elif history_cursor >= history.size():
                    text = history_stash
                    caret_to_end()
            if event.physical_scancode == KEY_DOWN:
                if history_cursor == -1:
                    history_stash = text
                    history_cursor = history.size()
                history_cursor += 1
                if history_cursor >= history.size():
                    history_cursor = -1
                    text = history_stash
                    caret_to_end()
                elif history_cursor >= 0 and history_cursor < history.size():
                    text = history[history_cursor]
                    caret_to_end()
