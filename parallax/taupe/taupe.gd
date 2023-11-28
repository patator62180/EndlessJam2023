extends AnimatedSprite2D


func _ready():
    var rnd = RandomNumberGenerator.new()
    $AnimationPlayer.advance(rnd.randf_range(0.0,5.0))
