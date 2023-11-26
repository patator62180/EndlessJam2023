extends StaticBody2D

class_name Chunk

enum Type {SQUARE, STEEP}

@export var collisionShape: CollisionShape2D
@export var type: Type

func get_segment():
    return collisionShape.shape as SegmentShape2D

func get_width():
    var segment = get_segment()
    return abs(segment.b.x - segment.a.x)

func disable_segment():
    collisionShape.hide()
    collisionShape.disabled = true
