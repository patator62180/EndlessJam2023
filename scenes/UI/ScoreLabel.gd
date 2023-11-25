extends Label

func _process(delta):
    var node = get_parent()
    text = str(node.playerprogress)
