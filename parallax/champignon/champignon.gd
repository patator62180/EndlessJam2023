extends Node2D


func _ready():    
    var rnd = RandomNumberGenerator.new()
    $AnimatedSprite2D2.material = $AnimatedSprite2D2.material.duplicate()
    $AnimatedSprite2D2.material.set_shader_parameter("hueShift", rnd.randf())
    var rndFrame = rnd.randi_range(0,4); 
    $AnimatedSprite2D.frame = rndFrame
    $AnimatedSprite2D2.frame = rndFrame
