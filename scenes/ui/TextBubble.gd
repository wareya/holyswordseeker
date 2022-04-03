extends Node2D

var display_only = false

func _init(_display_only = false):
    display_only = _display_only

func _ready():
    if cutscene and cutscene.size() > 0:
        poppify()
    else:
        queue_free()
    modulate.a = 0.0

func poppify():
    buildify(cutscene.pop_front())

func buildify(text : String):
    $Label.bbcode_text = "."
    $Label.hide()
    $Label.show()
    $Label.rect_size.x = 400.0
    $Label.rect_size.y = 0
    $Label.hide()
    $Label.show()
    var base_height = $Label.rect_size.y
    print("base height: ", base_height)
    $Label.bbcode_text = text
    $Label.hide()
    $Label.show()
    text_characters = 0
    $Label.visible_characters = 0
    
    var text_size = $Label.rect_size * $Label.rect_scale
    
    # comment out to make the textbox not shrink for messages longer than one line
    base_height = $Label.rect_size.y
    
    while $Label.rect_size.y == base_height and $Label.rect_size.x > 5:
        $Label.rect_size.x -= 5
        $Label.hide()
        $Label.show()
    if $Label.rect_size.x < 400.0:
        $Label.rect_size.x += 5
        $Label.hide()
        $Label.show()
        $Label.rect_size.y = 0
        $Label.hide()
        $Label.show()
    text_size = $Label.rect_size * $Label.rect_scale
    
    var size = text_size + Vector2(16, 8)
    $Rect.rect_size = size
    print("rect size in: ", $Rect.rect_size)
    if is_inside_tree():
        relocate()

var origin : Vector2 = Vector2()
func relocate(_origin : Vector2 = origin):
    origin = _origin
    global_position = origin
    
    var viewport_position = Manager.get_tree().current_scene.get_viewport().canvas_transform.xform(Vector2(1, 1))
    var viewport_size = Manager.get_tree().current_scene.get_viewport().get_visible_rect().size
    var viewport_rect = Rect2(-viewport_position/2, viewport_size)
    
    var rect_size = $Rect.rect_size
    print("rect size out: ", rect_size)
    global_position.y -= (rect_size.y + 16)
    global_position.x -= rect_size.x/2
    var rect_pos = $Rect.rect_global_position
    var rect_end = rect_size + rect_pos
    
    var y_sign = 1.0
    if rect_pos.x < viewport_rect.position.x:
        global_position.x += rect_size.x/2
    elif rect_end.x > viewport_rect.end.x:
        global_position.x -= rect_size.x/2
    
    print(rect_pos)
    print(viewport_rect)
    if rect_pos.y < viewport_rect.position.y:
        global_position.y += rect_size.y*2 - 16
    
    #var arrow = $Rect/ArrowLeft
    # TODO add arrow if targeted

var focused = true

export var cutscene = []

var chars_per_second = 60.0*2.5

signal done
var text_characters = -1
var fade_time = 0.075
var life_state = true
var life = 0.0
func _process(delta):
    if display_only:
        $Blip.playing = false
        text_characters = -1
        $Label.visible_characters = -1
        focused = false
    
    if life < 1.0 and life_state:
        life += delta/fade_time
    elif life >= 1.0 and life_state:
        if text_characters >= 0 and text_characters < $Label.get_total_character_count():
            text_characters += delta*chars_per_second
            $Label.visible_characters = text_characters
            if !$Blip.playing:
                $Blip.playing = true
                var stream : AudioStream = $Blip.stream
                if "loop" in stream:
                    stream.loop = true
                elif "loop_mode" in stream:
                    stream.loop_mode = AudioStreamSample.LOOP_FORWARD
        else:
            cancel_blip()
        if focused and !display_only:
            if (Input.is_action_just_pressed("ui_accept") or
                Input.is_action_just_pressed("ui_cancel")):
                continue_action()
                Input.action_release("ui_accept")
                Input.action_release("ui_cancel")
    else:
        life -= delta/fade_time
        if life <= 0.0:
            queue_free()
    life = clamp(life, 0.0, 1.0)
    modulate.a = life

func kill():
    yield(get_tree(), "idle_frame")
    life_state = false
    focused = false
    
func cancel_blip():
    var stream : AudioStream = $Blip.stream
    if "loop" in stream:
        stream.loop = false
    elif "loop_mode" in stream:
        stream.loop_mode = AudioStreamSample.LOOP_DISABLED

func continue_action():
    if text_characters >= 0 and text_characters < $Label.get_total_character_count():
        text_characters = -1
        $Label.visible_characters = -1
    else:
        if cutscene.size() > 0:
            buildify(cutscene.pop_front())
        else:
            yield(get_tree(), "idle_frame")
            emit_signal("done")
            kill()
    
