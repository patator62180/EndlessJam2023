extends Node2D

@export var bounceMin = 8000
@export var bounceMax = 20000

@export var volumeMin = -5
@export var volumeMax = 5

var rndf

func _ready():
    if get_node_or_null("BounceCollision"):
        var rnd = RandomNumberGenerator.new()
        rndf = rnd.randf()
        var sprite1 = $AnimationParent/AnimatedSprite2D
        var sprite2 = $AnimationParent/AnimatedSprite2D2
        
        sprite2.material = sprite2.material.duplicate()
        sprite2.material.set_shader_parameter("hueShift", rndf)
        var rndFrame = rnd.randi_range(0,4); 
        sprite1.frame = rndFrame
        sprite2.frame = rndFrame
        $BounceCollision.bounce_power = (bounceMax-bounceMin)*rndf + bounceMin
    
func bounce():
    if $AnimationPlayer:
        $AnimationPlayer.play("Bounce")
        $AudioStreamPlayer2D.volume_db = (volumeMax-volumeMin)*rndf + volumeMin 
        $AudioStreamPlayer2D.play()
