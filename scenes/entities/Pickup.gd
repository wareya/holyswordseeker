extends Node2D

func _ready():
    for item in items:
        inventory.push_back(Character.new_item(item))

export(Array, String) var items = []
var inventory = []

var bubble 

func pick(window, node):
    var item = node.userdata
    Scheduler.find_player().inventory.push_back(item)
    inventory.erase(item)
    window.remove_button(node)
    check_empty()

func focus(window, node):
    var item = node.userdata
    if bubble:
        bubble.buildify(item.description)

func cancel(window):
    window.queue_free()
    $Audio.stream = preload("res://sfx/blipdown.wav")
    $Audio.stop()
    $Audio.play()
    if bubble:
        bubble.kill()

var window

func check_empty():
    if inventory.size() == 0:
        disabled = true
        visible = false

func random_pick(array : Array):
    return array[randi() % array.size()]

func _process(delta):
    check_empty()

var disabled = false

func trigger(other):
    if disabled:
        return false
    if other.is_player:
        check_empty()
        if disabled:
            return false
        print("building picking window")
        window = TextWindow.build(Vector2(640, 32))
        window.connect("picked", self, "pick")
        window.connect("focused", self, "focus")
        window.connect("cancelled", self, "cancel")
        for i in range(inventory.size()):
            var item = inventory[i]
            window.push_button(item.name, item)
        bubble = TextBubble.display(Vector2(660, 339), inventory[0].description)
        window.add_child(bubble)
        
        $Audio.stream = preload("res://sfx/blipup.wav")
        $Audio.stop()
        $Audio.play()
        
        print("bubble: ", bubble)
        return true
    return false
