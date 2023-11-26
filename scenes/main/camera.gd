extends Camera2D

@export var frog = Node2D

var target

func _ready():
    target = Vector2.ZERO
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    target = lerp(target, frog.position, 0.01)
    position = target
