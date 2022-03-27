class_name TextBubble

static func build(location : Vector2, cutscene : Array):
    var bubble = preload("res://TextBubble.tscn").instance()
    bubble.cutscene = cutscene.duplicate(true)
    var scene : Node = Manager.get_tree().current_scene
    scene.add_child(bubble)
    bubble.relocate(location)
    return bubble

static func display(location : Vector2, text : String):
    var bubble = preload("res://TextBubble.tscn").instance()
    bubble._init(true)
    bubble.scale = Vector2(2.0, 2.0)
    bubble.cutscene = [text]
    #HUD.add(bubble)
    HUD.add_child(bubble)
    
    bubble.relocate(location)
    return bubble
