extends AnimatedSprite2D


func _ready():
    var rnd = RandomNumberGenerator.new()
    material = material.duplicate()
    material.set_shader_parameter("hue", rnd.randf())
    material.set_shader_parameter("sat", rnd.randf_range(0.6,0.8))
