tool
extends TextureRect

export(Texture) var fade_texture = preload("res://art/transition/noiseburned.png")
export(Texture) var normal_map = preload("res://art/normal/4733-normal.jpg")
export(float, 0.0, 4.0) var fade_contrast = 0.0
export var fade_invert = false

export var normal_strength = Vector2(0, 0)
export var normal_scale = Vector2(1.0, 1.0)
export var normal_timescale = Vector2(0.0, 0.0)
export var normal_offset = Vector2(0, 0)

var _normal_configs = [
    {"normal_strength" : Vector2(0, 0),
     "normal_scale" : Vector2(1.0, 1.0),
     "normal_timescale" : Vector2(0.0, 0.0),
    },
    {"normal_strength" : Vector2(0.055, -0.013),
     "normal_scale" : Vector2(8.0, 0.74),
     "normal_timescale" : Vector2(0.067, -0.0007),
    },
]

var normal_config = _normal_configs[0].duplicate()

func configure_bg_distortion(mode : int):
    normal_config = _normal_configs[clamp(mode, 0, _normal_configs.size()-1)].duplicate()

func _ready():
    if Engine.editor_hint:
        return
    material = material.duplicate()
    fadeamount = 0.0
    fade_contrast = 0.0
    material.set_shader_param("texture2", null)
    material.set_shader_param("texture3", fade_texture)
    material.set_shader_param("contrast", fade_contrast)
    material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    material.set_shader_param("fadeamount", fadeamount)
    material.set_shader_param("position", Vector2(0.0, 0.0))
    material.set_shader_param("scale", Vector2(1.0, 1.0))
    material.set_shader_param("invert", fade_invert)
    
    material.set_shader_param("normalmap", normal_map)
    material.set_shader_param("normal_strength", normal_config.normal_strength/10.0)
    var _normal_scale = normal_config.normal_scale
    if _normal_scale.x == 0:
        _normal_scale.x = 0.00001
    if _normal_scale.y == 0:
        _normal_scale.y = 0.00001
    material.set_shader_param("normal_scale", _normal_scale)
    material.set_shader_param("normal_offset", normal_offset)
    pass # Replace with function body.

export(Texture) var texture2 : Texture
export(float, 0.0, 1.0) var fadeamount : float
export(Vector2) var position = Vector2(0,0)
export(Vector2) var scale = Vector2(1,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    if Engine.editor_hint:
        normal_config.normal_scale = normal_scale
        normal_config.normal_strength = normal_strength
        normal_config.normal_timescale = normal_timescale
    
    if normal_config.normal_scale.x != 0:
        normal_offset.x += -normal_config.normal_timescale.x*delta/normal_config.normal_scale.x
    else:
        normal_offset.x += -normal_config.normal_timescale.x*delta
    if normal_config.normal_scale.y != 0:
        normal_offset.y += -normal_config.normal_timescale.y*delta/normal_config.normal_scale.y
    else:
        normal_offset.y += -normal_config.normal_timescale.y*delta
    normal_offset = normal_offset.posmod(1.0)
    
    update_uniforms()

func update_uniforms():
    #if Engine.editor_hint:
    material.set_shader_param("texture2", texture2)
    material.set_shader_param("texture3", fade_texture)
    material.set_shader_param("contrast", fade_contrast)
    if texture2:
        material.set_shader_param("texture2size", texture2.get_size())
    else:
        material.set_shader_param("texture2size", Vector2(1.0, 1.0))
    if texture:
        material.set_shader_param("texturesize", texture.get_size())
    else:
        material.set_shader_param("texturesize", Vector2(1.0, 1.0))
    material.set_shader_param("fadeamount", fadeamount)
    material.set_shader_param("position", Vector2(0.0, 0.0))
    material.set_shader_param("scale", Vector2(1.0, 1.0))
    material.set_shader_param("invert", fade_invert)
    
    material.set_shader_param("normalmap", normal_map)
    material.set_shader_param("normal_strength", normal_config.normal_strength/10.0)
    var _normal_scale = normal_config.normal_scale
    if _normal_scale.x == 0:
        _normal_scale.x = 0.00001
    if _normal_scale.y == 0:
        _normal_scale.y = 0.00001
    material.set_shader_param("normal_scale", _normal_scale)
    material.set_shader_param("normal_offset", normal_offset)
