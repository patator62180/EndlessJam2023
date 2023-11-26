extends Node2D

@export var range = 30

var origin
# Called when the node enters the scene tree for the first time.
func _ready():
    origin = position # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var target = origin + Vector2(randi_range(-range, range), randi_range(-range, range))
    position = lerp(position, target, 0.05)
