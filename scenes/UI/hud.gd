extends CanvasLayer

var score = 0
var score_label

func _ready():
	score_label = get_parent().get_node("ScoreLabel")
	score = 0

func _physics_process(delta):
	var velocity = Vector2()
