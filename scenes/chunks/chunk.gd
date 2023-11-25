extends StaticBody2D

class_name Chunk

@export var collisionShape: CollisionShape2D;

func get_segment():
    return collisionShape.shape as SegmentShape2D

func disable_segment():
    collisionShape.hide()
    collisionShape.disabled = true
