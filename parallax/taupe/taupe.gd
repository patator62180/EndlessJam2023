extends AnimatedSprite2D

@export var bounce_collision = Area2D

var ball 

func _ready():
    var rnd = RandomNumberGenerator.new()
    $AnimationPlayer.advance(rnd.randf_range(0.0,5.0))
    
    bounce_collision.body_entered.connect(touch_ball)
    bounce_collision.body_exited.connect(untouch_ball)
    
func _process(delta):
    if ball != null:
        ball.apply_central_impulse(Vector2.UP.rotated(rotation) * 10000)
        ball = null
    
func touch_ball(body):
    if body.is_in_group("ball"):
        ball = body
        
func untouch_ball(body):
    if body.is_in_group("ball"):
        ball = null
