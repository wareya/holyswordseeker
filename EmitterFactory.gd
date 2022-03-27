extends Node


var sounds = {
"whiff": preload("res://sfx/tm2_swing000.wav"),
"slash": preload("res://sfx/swing.wav"),
"hit": preload("res://sfx/hit29defanged.wav"),
"bit": preload("res://sfx/bite-small.wav"),
"playerhurt": preload("res://sfx/playerHurt.wav"),
"enemydead": preload("res://sfx/shade11.wav"),
"playerdead": preload("res://sfx/UI_016.wav"),
}

class Emitter2D extends AudioStreamPlayer2D:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, arg_position, channel):
        parent.add_child(self)
        position = arg_position
        var abs_position = global_position
        parent.remove_child(self)
        parent.get_tree().get_root().add_child(self)
        global_position = abs_position
        stream = sound
        bus = channel
        play()
        ready = true
        return self


class Emitter extends AudioStreamPlayer:
    var ready = false
    var frame_counter = 0

    func _process(_delta):
        if ready and !playing:
            frame_counter += 1
        if frame_counter > 2:
            queue_free()

    func emit(parent : Node, sound, channel):
        parent.add_child(self)
        stream = sound
        bus = channel
        volume_db = -3
        play()
        ready = true
        return self

func emit(sound, parent = null, arg_position = Vector2(), channel = "SFX"):
    var stream = null
    if sound in sounds:
        stream = sounds[sound]
    elif sound is AudioStream:
        stream = sound
    if parent:
        return Emitter2D.new().emit(parent, stream, arg_position, channel)
    else:
        return Emitter.new().emit(self, stream, channel)

var player = AudioStreamPlayer.new()
var receive = AudioStreamGenerator.new()
var send = AudioEffectCapture.new()

var send_ready = false

func _ready():
    return
    
    yield(get_tree(), "idle_frame")
    
    receive.mix_rate = AudioServer.get_mix_rate()
    receive.buffer_length = 0.1
    player.stream = receive
    player.bus = "Reverb"
    player.play()
    add_child(player)
    
    # feed some very quiet nonzero audio data into the SFX channel so that our
    # AudioEffectCapture effect sees something other than zeroes during boot
    # (this prevents some weird initialization bug that can make it output audio
    # even though it's being fed silence)
    # this clip lasts for ~5 seconds, which SHOULD be enough to keep playing
    # while the AudioEffectCapture intializes
    emit(self, "___invisiblip")
    
    yield(get_tree().create_timer(0.5), "timeout")
    var sfx = AudioServer.get_bus_index("SFX")
    AudioServer.add_bus_effect(sfx, send)
    var index = AudioServer.get_bus_effect_count(sfx)-1
    AudioServer.set_bus_effect_enabled(sfx, index, true)
    
    send_ready = true


var time_since_init = 0.0

func _process(delta):
    if !send_ready:
        return
    time_since_init += delta
    if time_since_init < 0.1:
        return
    var playback = player.get_stream_playback()
    var available = send.get_frames_available()
    var pushable = playback.can_push_buffer(available)
    #var sfx = AudioServer.get_bus_index("SFX")
    #Manager.debug_text("AUDIO:")
    #Manager.debug_text(available)
    #Manager.debug_text(playback.get_frames_available())
    #Manager.debug_text(player.playing)
    #Manager.debug_text(player.stream == receive)
    #Manager.debug_text(player.bus)
    #Manager.debug_text(AudioServer.get_bus_effect(sfx, 0))
    #Manager.debug_text(AudioServer.is_bus_effect_enabled(sfx, 0))
    #Manager.debug_text(AudioServer.is_bus_bypassing_effects(sfx))
    while !pushable and available > 0:
        available -= 1
        pushable = playback.can_push_buffer(available)
    if available > 0:
        playback.push_buffer(send.get_buffer(available))
        send.clear_buffer()
    else:
        #Manager.debug_text("no buffer to push")
        pass
    #Manager.debug_text("----")
    pass
