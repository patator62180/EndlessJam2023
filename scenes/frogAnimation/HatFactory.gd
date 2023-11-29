extends Node2D

var chapi_chapeau

var last_hat
var first_hat
var index = 0

@export var rotation_target = Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
    chapi_chapeau = preload("res://scenes/chapeaux/hat.tscn")
    last_hat = self
    first_hat = self
    
func _process(delta):
    balance_hats()
    
func spawn_hat():
    var instance = chapi_chapeau.instantiate()
    last_hat.add_child(instance)
    
    instance.position = Vector2(0, -200)
    
    last_hat = last_hat.get_node("Hat")
    index += 1
    
func balance_hats():
    var current_hat = first_hat
    
    for i in range(index + 1):
        if current_hat != null:
            #current_hat.rotation = current_hat.get_parent().rotation + rotation_target.rotation / 2
            current_hat.rotation = rotation_target.rotation * i / 20
            current_hat = current_hat.get_node("Hat")
            print(i)
        else:
            return
    
