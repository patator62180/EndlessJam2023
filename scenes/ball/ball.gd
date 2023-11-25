extends RigidBody2D

@export var shadow: Sprite2D

func _process(delta):
    shadow.rotation = -rotation
