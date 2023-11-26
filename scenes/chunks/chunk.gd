extends StaticBody2D

class_name Chunk

enum Type {SQUARE, STEEP}

@export var collisionShape: CollisionShape2D
@export var type: Type

func get_segment():
    return collisionShape.shape as SegmentShape2D

func disable_segment():
    collisionShape.hide()
    collisionShape.disabled = true
