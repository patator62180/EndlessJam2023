extends ParallaxLayer

@export var pigeonScene : PackedScene
@export var spawn_frequency : float = 0.001
@export var max_squad_size : int = 4
@export var spawn_y_range_min : float = 500
@export var spawn_y_range_max : float = 1800
@export var path_x_noize_range : float = 200
@export var path_y_noize_range : float = 500

var rnd =  RandomNumberGenerator.new()

func _process(delta):
    if rnd.randf() < spawn_frequency:
        spawn_pigeons()

func spawn_pigeons():
        var squad_size = rnd.randi_range(1,max_squad_size)
        for i in range(squad_size):
            var pigeon = pigeonScene.instantiate()
            add_child(pigeon)
            var sprite2D = pigeon.get_node("PathFollow2D/Sprite2D") as AnimatedSprite2D
            sprite2D.frame = rnd.randi_range(0, 6)
            pigeon.position.y = rnd.randf_range(spawn_y_range_min, spawn_y_range_max)
            var curve = pigeon.curve.duplicate()
            for index in range(1, curve.point_count - 1):
                var point = curve.get_point_position(index)
                var offset = Vector2(rnd.randf()*path_x_noize_range, rnd.randf()*path_y_noize_range)
                curve.set_point_position(index, point + offset)
            pigeon.curve = curve
