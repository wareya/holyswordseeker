extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


onready var flow_target : Node = $Scroller/Container

func _ready():
    for child in flow_target.get_children():
        child.free()
        pass
    
    if false:
        push_button("LIST OF STUFF").grab_focus()
        push_button("Thing A")
        push_button("Thing B", null, 5)
        push_button("Thing C with a really, really, really, really long name, like why is this so long????")
        push_button("Thing D with not as long name but still long enough to linewrap", null, 14)
        push_button("Thing")
        push_button("Thing")
        push_button("Thing")
        push_button("Thing", null, 16)
        push_button("Thing", null, 17)
        push_button("Thing", null, 18)
        push_button("Thing", null, 19)
    
    var _unused = connect("picked", self, "print_confirmed")
    _unused = connect("focused", self, "print_focused")
    _unused = connect("cancelled", self, "print_cancelled")
    _unused = $Scroller.get_v_scrollbar().connect("scrolling", self, "_grab_focus")
    
    var scroller_code = """
extends ScrollContainer
func _draw():
    get_parent().draw_highlight()

onready var _v_scroll : VScrollBar = get_v_scrollbar()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and (event.button_index == BUTTON_WHEEL_DOWN || event.button_index == BUTTON_WHEEL_UP):
        _v_scroll.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
    else:
        _v_scroll.set_mouse_filter(Control.MOUSE_FILTER_PASS)
"""
    var script = GDScript.new()
    script.source_code = scroller_code
    script.reload()
    $Scroller.set_script(script)
    
    focused = true

class MyLabel extends RichTextLabel:
    var userdata = null

func remove_button(node : Node):
    if flow_target.is_a_parent_of(node):
        node.queue_free()

func push_button(bbcode, userdata = null, icon = null):
    var label = MyLabel.new()
    label.userdata = userdata
    label.theme = preload("res://BigTheme.tres")
    label.fit_content_height = true
    label.bbcode_enabled = true
    if icon:
        var font = BitmapFont.new()
        font.ascent = 2
        label.push_font(font)
        if icon is Texture:
            label.add_image(icon, 32, 32)
        else:
            var texture = AtlasTexture.new()
            texture.atlas = preload("res://art/borrowed/items.png")
            var atlas_tile_width = int(floor(texture.atlas.get_size().x/16.0))
            texture.filter_clip = true
            texture.region.position.x = int(icon) % atlas_tile_width
            texture.region.position.y = int(icon) / atlas_tile_width
            texture.region.position *= 16.0
            texture.region.size = Vector2(16, 16)
            label.add_image(texture, 32, 32)
        label.pop()
    label.append_bbcode(bbcode)
    label.focus_mode = FOCUS_ALL
    flow_target.add_child(label)
    buttons.push_back(label)
    label.hide()
    label.show()
    label.rect_position.x = 5.0
    return label

func _grab_focus():
    if flow_target.get_child_count() > 0 and (!get_focus_owner() or !is_a_parent_of(get_focus_owner())):
        flow_target.get_children()[0].grab_focus()

func print_confirmed(_window, node):
    print("confirmed: ", node)
    $Confirm.play()

func print_focused(_window, node):
    print("focused: ", node)
    if last_target != null:
        $Move.play()

func print_cancelled(_window):
    print("cancelled")

# Called every frame. 'delta' is the elapsed time since the previous frame.
var process_time = 0.0
var last_scroll = -1
var flow_dirty = false
var focused = false
var buttons = []
var last_target = null
func _process(delta):
    if get_focus_owner() and is_a_parent_of(get_focus_owner()):
        modulate.a = 1.0
    else:
        modulate.a = 0.7
    
    if get_focus_owner() != last_target:
        process_time = 0.0
        if get_focus_owner() != null and get_focus_owner().is_visible_in_tree():
            emit_signal("focused", self, get_focus_owner())
        last_target = get_focus_owner()
    
    process_time += delta
    
    for _child in flow_target.get_children():
        var child : Control = _child
        if focused:
            child.mouse_filter = MOUSE_FILTER_STOP
            child.focus_mode = FOCUS_ALL
        else:
            child.mouse_filter = MOUSE_FILTER_IGNORE
            child.focus_mode = FOCUS_NONE
    
    if focused:
        _grab_focus()
    if !focused and get_focus_owner() and is_a_parent_of(get_focus_owner()):
        get_focus_owner().release_focus()
    
    update()
    
    last_scroll = $Scroller.scroll_vertical

func _notification(notif : int):
    if notif in [NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT]:
        update()
        $Scroller.update()

func focus_next(loop = true):
    if is_a_parent_of(get_focus_owner()):
        var next = get_focus_owner().find_next_valid_focus()
        if !flow_target.is_a_parent_of(next):
            next = null
        if loop and !next and flow_target.get_child_count() > 0:
            next = flow_target.get_children().front()
        if next:
            next.grab_focus()
    else:
        _grab_focus()

func focus_prev(loop = true):
    if is_a_parent_of(get_focus_owner()):
        var prev = get_focus_owner().find_prev_valid_focus()
        if !flow_target.is_a_parent_of(prev):
            prev = null
        if loop and !prev and flow_target.get_child_count() > 0:
            prev = flow_target.get_children().back()
        if prev:
            prev.grab_focus()
    else:
        _grab_focus()

var focus_wrap = false
signal picked
signal focused
signal cancelled
var click_target = null
var click_target_confirmed = true
func _input(_e):
    var e : InputEvent = _e
    if focused and e.is_action_released("ui_m2") and !Input.is_mouse_button_pressed(2):
        focused = false
        emit_signal("cancelled", self)
    
    if !focused:
        return
    
    var focus_changed = false
    var rescroll_nobuffer = false
    var old_focused = focused
    if e.is_action_pressed("ui_down", true):
        if flow_target.get_child_count() > 0 and flow_target.get_children().back().has_focus():
            focus_next()
            get_tree().set_input_as_handled()
    if e.is_action_pressed("ui_up", true):
        if flow_target.get_child_count() > 0 and flow_target.get_children().front().has_focus():
            focus_prev()
            get_tree().set_input_as_handled()
    
    if e.is_action_pressed("ui_page_down", true):
        if false and flow_target.get_child_count() > 0 and flow_target.get_children().back().has_focus():
            focus_next()
        else:
            for _i in range(8):
                focus_next(false)
    if e.is_action_pressed("ui_page_up", true):
        if false and flow_target.get_child_count() > 0 and flow_target.get_children().front().has_focus():
            focus_prev()
        else:
            for _i in range(8):
                focus_prev(false)
    if e.is_action_pressed("ui_accept"):
        var focuser : Control = get_focus_owner()
        if focuser and is_a_parent_of(focuser):
            print("consuming")
            emit_signal("picked", self, focuser)
            get_tree().set_input_as_handled()
            Input.action_release("ui_accept")
    if e.is_action_pressed("ui_cancel"):
        emit_signal("cancelled", self)
        get_tree().set_input_as_handled()
        focused = false
    if e.is_action_released("ui_m1") and !Input.is_mouse_button_pressed(1):
        var mouse_pos = $Scroller.get_local_mouse_position()
        print(mouse_pos)
        if mouse_pos.y > 0 and mouse_pos.y < $Scroller.rect_size.y:
            var focuser : Control = get_focus_owner()
            if (focuser and is_a_parent_of(focuser) and
                focuser.get_global_rect().has_point(focuser.get_global_mouse_position())):
                process_time = 0.0
                emit_signal("picked", self, focuser)
                get_tree().set_input_as_handled()
            else:
                for target in flow_target.get_children():
                    if target.get_global_rect().has_point(target.get_global_mouse_position()):
                        target.grab_focus()
                        break
            pass
    if focused:
        if false and e.is_action_released("ui_mscroll_down"):
            $Scroller.scroll_vertical += 32 * (1.0 if not "factor" in e else e.factor)
        if false and e.is_action_released("ui_mscroll_up"):
            $Scroller.scroll_vertical -= 32 * (1.0 if not "factor" in e else e.factor)
    pass

func triwave(x : float):
    x = fmod(x, 2.0)
    return x if x < 1.0 else 2.0 - x

func _draw():
    if $Scroller.visible:
        $Scroller.update()

func draw_highlight():
    var focused = get_focus_owner()
    if !focused:
        return
    if is_a_parent_of(focused):
        var rect : Rect2 = focused.get_rect()
        var offset = flow_target.rect_position
        var poly_verts = PoolVector2Array([
          offset + rect.position + Vector2(-3, 0),
          offset + Vector2(rect.position.x, rect.end.y),
          offset + rect.end,
          offset + Vector2(rect.end.x,rect.position.y) + Vector2(-3, 0)
        ])
        var colorA = Color(1.0, 1.0, 0.0, 0.25*(1.0-triwave(process_time)))
        var colorB = colorA
        colorB.a = 0.0
        var poly_color = PoolColorArray([colorA, colorA, colorB, colorB])
        
        $Scroller.draw_polygon(poly_verts, poly_color, PoolVector2Array(), null, null, true)
