extends Node2D

var chapi_chapeaux : Array
var rnd

var last_hat
var first_hat
var index = 0

@export var rotation_target = Node2D

var height = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat1.tscn"))
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat2.tscn"))
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat3.tscn"))
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat4.tscn"))    
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat5.tscn"))    
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat6.tscn"))    
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat7.tscn"))    
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat8.tscn"))    
    chapi_chapeaux.push_back(preload("res://scenes/chapeaux/hat9.tscn"))
    last_hat = self
    first_hat = self
    rnd = RandomNumberGenerator.new()
    
func _process(delta):
    balance_hats()
    
func spawn_hat():
    var instance = chapi_chapeaux[rnd.randi_range(0,chapi_chapeaux.size()-1)].instantiate()
    last_hat.add_child(instance)
    
    instance.position = Vector2(0, -last_hat.height)
    
    last_hat = last_hat.get_node("Hat")
    index += 1
    
func balance_hats():
    var current_hat = first_hat
    
    for i in range(index):
        if current_hat != null:
            #current_hat.rotation = current_hat.get_parent().rotation + rotation_target.rotation / 2
            current_hat.rotation = lerp(current_hat.rotation, rotation_target.rotation * i / 20, 0.01) 
            current_hat = current_hat.get_node("Hat")
        else:
            return
    
