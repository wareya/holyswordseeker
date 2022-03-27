extends CanvasLayer

func _ready():
    pass

func hide():
    $HUD.hide()
func show():
    $HUD.show()

func add(control : Node):
    $HUD.add_child(control)
    return control
