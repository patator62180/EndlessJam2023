extends AnimatedSprite2D

#@export var bounce_collision = Area2D

#var ball 

func _ready():
    var rnd = RandomNumberGenerator.new()
    if get_node_or_null("AnimationPlayer"):
        $AnimationPlayer.advance(rnd.randf_range(0.0,5.0))

func _process(delta):
    if get_node_or_null("AnimationPlayer"):
        var is_in_ground = frame == 0

        $BouceCollision/CollisionShape2D.disabled = is_in_ground
        $StaticBody2D/CollisionShape2D.disabled = is_in_ground

#    bounce_collision.body_entered.connect(touch_ball)
#    bounce_collision.body_exited.connect(untouch_ball)
#
#func _process(delta):
#    if ball != null:
#        ball.apply_central_impulse(Vector2.UP.rotated(rotation) * 10000)
#        ball = null
#
#func touch_ball(body):
#    if body.is_in_group("ball"):
#        ball = body
#
#func untouch_ball(body):
#    if body.is_in_group("ball"):
#        ball = null
