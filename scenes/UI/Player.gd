extends Node2D

var playerprogress

func _process(delta):
    playerprogress = get_node("Sprite2D").maxposition
