class_name TextWindow

static func build(location : Vector2):
    var window = preload("res://TextWindow.tscn").instance()
    HUD.add(window)
    window.rect_position = location - Vector2(window.rect_size.x/2, 0)
    return window
