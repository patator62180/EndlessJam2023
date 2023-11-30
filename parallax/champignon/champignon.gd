extends Node2D

@export var bounceMin = 8000
@export var bounceMax = 20000


func _ready():    
    var rnd = RandomNumberGenerator.new()
    var rndf = rnd.randf()
    var sprite1 = $AnimationParent/AnimatedSprite2D
    var sprite2 = $AnimationParent/AnimatedSprite2D2
    
    sprite2.material = sprite2.material.duplicate()
    sprite2.material.set_shader_parameter("hueShift", rndf)
    var rndFrame = rnd.randi_range(0,4); 
    sprite1.frame = rndFrame
    sprite2.frame = rndFrame
    $BounceCollision.bounce_power = (bounceMax-bounceMin)*rndf + bounceMin
    
func bounce():
    $AnimationPlayer.play("Bounce")
