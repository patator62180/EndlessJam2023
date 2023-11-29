extends Node2D

@export var bounceMin = 8000
@export var bounceMax = 20000


func _ready():    
    var rnd = RandomNumberGenerator.new()
    var rndf = rnd.randf()
    $AnimatedSprite2D2.material = $AnimatedSprite2D2.material.duplicate()
    $AnimatedSprite2D2.material.set_shader_parameter("hueShift", rndf)
    var rndFrame = rnd.randi_range(0,4); 
    $AnimatedSprite2D.frame = rndFrame
    $AnimatedSprite2D2.frame = rndFrame
    $BounceCollision.bounce_power = (bounceMax-bounceMin)*rndf + bounceMin
