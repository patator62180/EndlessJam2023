extends CanvasLayer

var score = 0
@export var scorelabel:Label
var initialposition:int
@export var frog:Node2D

func _ready():
    score = 0
    initialposition = frog.global_position.y

func _physics_process(delta):
    score = int(max(initialposition-frog.global_position.y,score))
    scorelabel.text=str(score)
