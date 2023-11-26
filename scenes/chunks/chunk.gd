extends StaticBody2D

class_name Chunk

enum {SQUARE, STEEP}

@export var collisionShape: CollisionShape2D
@export_enum("Square", "Steep") var type: String

func get_segment():
    return collisionShape.shape as SegmentShape2D

func disable_segment():
    collisionShape.hide()
    collisionShape.disabled = true
