#extends RigidBody2D
extends Node2D

@export var shadow: Sprite2D
@export var frog: CharacterBody2D

var handsTarget

var targetL
var targetR

func _ready():
    handsTarget = $"HandTargets"
    targetL = $"HandTargets/HandL"
    targetR = $"HandTargets/HandR"

func _process(delta):
    shadow.rotation = -rotation
    handsTarget.look_at(frog.global_position)
    
    handsTarget.rotate(deg_to_rad(180))
