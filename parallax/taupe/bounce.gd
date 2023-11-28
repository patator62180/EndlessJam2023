extends Area2D

var ball 

@export var directional_bounce = false

func _ready(): 
    body_entered.connect(touch_ball)
    body_exited.connect(untouch_ball)
    
func _process(delta):
    if ball != null:
        if !directional_bounce:
            ball.apply_central_impulse(Vector2.UP.rotated(global_rotation) * 10000)
        else:
            ball.freeze = true
            ball.freeze = false
            var direction = (ball.global_position - global_position).normalized() * 10000
            ball.apply_central_impulse(direction)
        ball = null
    
func touch_ball(body):
    if body.is_in_group("ball"):
        ball = body
        
func untouch_ball(body):
    if body.is_in_group("ball"):
        ball = null
