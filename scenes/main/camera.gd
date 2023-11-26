extends Camera2D

@export var frog = Node2D
@export var initVector = Vector2(0, 500)

var target

func _ready():
    target = frog.position + initVector
    position = target
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    target = lerp(target, frog.position, 0.01)
    position = target
