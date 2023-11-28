extends CanvasLayer

var score = 0
@export var scorelabel:Label
@export var current_score_label = Label
var initialposition:int
@export var target:Node2D

var divider = 100

func _ready():
    score = 0
    initialposition = target.global_position.y

func _physics_process(delta):
    score = int(max(initialposition-target.global_position.y,score))
    scorelabel.text=str(score / divider)
    
    var current_score = int(initialposition-target.global_position.y)
    current_score_label.text = str(current_score / divider)
