extends Area2D

@export var directional_bounce = false
@export var is_in_ground_pix_delta = 10
var ball 
var bounce_power = 10000
var in_ground_position

func _ready():
    in_ground_position = position
    body_entered.connect(touch_ball)
    body_exited.connect(untouch_ball)
    
func _process(delta):
    $CollisionShape2D.disabled = in_ground_position.distance_to(position) < is_in_ground_pix_delta
    
    if ball != null:
        if !directional_bounce:
            ball.apply_central_impulse(Vector2.UP.rotated(global_rotation) * bounce_power)
        else:
            ball.freeze = true
            ball.freeze = false
            var direction = (ball.global_position - global_position).normalized() * bounce_power
            ball.apply_central_impulse(direction)
        ball = null
    
func touch_ball(body):
    if body.is_in_group("ball"):
        ball = body
        
func untouch_ball(body):
    if body.is_in_group("ball"):
        ball = null
