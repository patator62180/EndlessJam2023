extends Node2D

const Y_PRECISION = 10
const POLYGON_MINIMUM_HEIGHT = 200
const FROG_GROUP = 'frog'
const SEED_LABEL_GROUP = 'seed_label'


@export var map_name = ""
@export var start_chunk: Chunk
@export var start_rock: StaticBody2D
@export var square_chunks_bank: Array[PackedScene]
@export var steep_chunks_bank: Array[PackedScene]
@export var steep_obstacle_chunks_bank: Array[PackedScene]
@export var square_obstacle_chunks_bank: Array[PackedScene]
@export var square_checkpoint_chunks_bank: Array[PackedScene]
@export var chunks_root: Node2D
@export var chunks_pool_root: Node2D
@export var collision_polygon: CollisionPolygon2D
@export var enable_physics: bool = true

@export_category("Chunks")
@export var initial_chunks_count: int = 3
@export var chunks_count_trigger: int = 30
@export var min_square_series: int = 3
@export var max_square_series: int = 4
@export var min_steep_series: int = 4
@export var max_steep_series: int = 10
@export var average_chunk_width: int = 652
@export var min_chunks_before_obstacle: int = 6
@export var max_chunks_before_obstacle: int = 10
@export var min_chunks_before_checkpoint: int = 20
@export var max_chunks_before_checkpoint: int = 100
@export var trigger_scale: float = 1
@export var seed: int = 0


enum ChunkType {Square, Steep}


class ChunkDef:
    var pool: Array[Chunk]
    var type: ChunkType
    var obstacle: bool
    var checkpoint: bool


class Bounds:
    var min: int
    var max: int

var chunks_pools_size
var chunks_count_since_checkpoint: int = 0
var chunks_count_since_obstacle: int = 0
var next_obstacle_threshold: int = 0
var next_checkpoint_threshold: int = 0
var chunk_count_since_type_change: int = 0
var next_chunk_threshold: int = 0
var chunk_defs: Array[ChunkDef] = []
var chunks: Array[Chunk] = []
var rng: RandomNumberGenerator
var last_chunk_index: int = -1
var first_chunk_index: int = 0
var points: Array[Vector2] = []
var frog: Node2D
var square_chunks_pool: Array[Array] = []
var steep_chunks_pool: Array[Array] = []
var steep_obstacle_chunks_pool: Array[Array] = []
var square_obstacle_chunks_pool: Array[Array] = []
var square_checkpoint_chunks_pool: Array[Array] = []


func build_chunk_pools():
    build_chunk_pool_type(ChunkType.Square, false, false)
    build_chunk_pool_type(ChunkType.Square, true, false)
    build_chunk_pool_type(ChunkType.Square, false, true)
    build_chunk_pool_type(ChunkType.Steep, false, false)
    build_chunk_pool_type(ChunkType.Steep, true, false)


func build_chunk_pool_type(type: ChunkType, obstacle: bool, checkpoint: bool):
    var bank: Array[PackedScene] = []
    var pool: Array[Array] = []
    
    
    if type == ChunkType.Square and obstacle == false and checkpoint == true:
        bank = square_checkpoint_chunks_bank
        pool = square_checkpoint_chunks_pool
    elif type == ChunkType.Square and obstacle == false and checkpoint == false:
        bank = square_chunks_bank
        pool = square_chunks_pool
    elif type == ChunkType.Square and obstacle == true and checkpoint == false:
        bank = square_obstacle_chunks_bank
        pool = square_obstacle_chunks_pool
    elif type == ChunkType.Steep and obstacle == true and checkpoint == false:
        bank = steep_obstacle_chunks_bank
        pool = steep_obstacle_chunks_pool
    else:
        bank = steep_chunks_bank
        pool = steep_chunks_pool

    if not enable_physics and start_rock.get_parent() != null:
        start_rock.get_parent().remove_child(start_rock)
 
    for packed_chunk in bank:
        var typed_pool: Array[Chunk] = []

        for index in range(chunks_pools_size):
            var chunk = packed_chunk.instantiate() as Chunk
    
            chunks_pool_root.add_child(chunk)

            if not enable_physics:
                disable_nested_physics(chunk)

            chunk.position = Vector2.ZERO
            chunk.disable_segment()
            typed_pool.append(chunk)

        pool.append(typed_pool)


func disable_nested_physics(parent: Node):
    for child in parent.get_children():
        var static_body = child as StaticBody2D
        var area2D = child as Area2D
        var animation_player = child as AnimationPlayer
        
        if static_body != null or animation_player != null or area2D != null:
            parent.remove_child(child)

        disable_nested_physics(child)


func generate_next_threshold(type: ChunkType):
    var bounds = get_series_bounds_for_type(type)
    
    return rng.randi_range(bounds.min, bounds.max)


func get_series_bounds_for_type(type: ChunkType):
    var bounds: Bounds = Bounds.new()

    if type == ChunkType.Square:
        bounds.min = min_square_series
        bounds.max = max_square_series
    else:
        bounds.min = min_steep_series
        bounds.max = max_steep_series
    
    return bounds


func get_current_type():
    return chunk_defs[len(chunk_defs) - 1].type if len(chunk_defs) > 0 else ChunkType.Square


func toggle_type(type):
    return ChunkType.Square if type == ChunkType.Steep else ChunkType.Steep


func pick_pool(type: ChunkType, obstacle: bool, checkpoint: bool):
    if type == ChunkType.Square and obstacle == false and checkpoint == true:
        return square_checkpoint_chunks_pool
    elif type == ChunkType.Square and obstacle == false and checkpoint == false:
        return square_chunks_pool
    if type == ChunkType.Square and obstacle == true and checkpoint == false:
        return square_obstacle_chunks_pool
    elif type == ChunkType.Steep and obstacle == true and checkpoint == false:
        return steep_obstacle_chunks_pool
    else:
        return steep_chunks_pool


func append_chunk_def():
    if len(chunk_defs) == 0:
        next_chunk_threshold = generate_next_threshold(ChunkType.Square)
        next_obstacle_threshold = rng.randi_range(min_chunks_before_obstacle, max_chunks_before_obstacle)
        next_checkpoint_threshold = min_chunks_before_checkpoint
        chunk_count_since_type_change = 1
    
    var type = get_current_type()
    var bounds = get_series_bounds_for_type(type)
    var chunk_def = ChunkDef.new()

    chunk_def.obstacle = false
    chunk_def.checkpoint = false
    chunk_def.type = type
    
    if chunk_count_since_type_change == next_chunk_threshold:
        chunk_def.type = toggle_type(type)
        next_chunk_threshold = generate_next_threshold(chunk_def.type)
        chunk_count_since_type_change = 0
    elif chunks_count_since_checkpoint >= next_checkpoint_threshold:
        next_checkpoint_threshold = min(max_chunks_before_checkpoint, next_checkpoint_threshold + 5)
        chunk_def.checkpoint = true
        chunks_count_since_checkpoint = -1
    elif chunks_count_since_obstacle >= next_obstacle_threshold:
        next_obstacle_threshold = rng.randi_range(min_chunks_before_obstacle, max_chunks_before_obstacle)
        chunk_def.obstacle = true
        chunks_count_since_obstacle = -1

    chunks_count_since_obstacle += 1
    chunks_count_since_checkpoint += 1
    chunk_count_since_type_change += 1
    var pool = pick_pool(chunk_def.type, chunk_def.obstacle, chunk_def.checkpoint)

    chunk_def.pool = pool[rng.randi_range(0, len(pool) - 1)]
    chunk_defs.append(chunk_def)


func spawn_chunk(index: int):
    var chunk: Chunk = chunk_defs[index].pool.pop_front()

    if len(points) == 0:
        points.append(start_chunk.position + start_chunk.get_segment().a)

    chunks_pool_root.remove_child(chunk)
    chunks_root.add_child(chunk)

    if index < last_chunk_index:
        var next_chunk = chunks[index + 1]
        chunk.position = Vector2(next_chunk.get_segment().a.x + next_chunk.position.x - chunk.get_segment().b.x, next_chunk.position.y + next_chunk.get_segment().a.y - chunk.get_segment().b.y)
        chunks_root.move_child(chunk, 0)
    else:
        var previous_chunk = chunks[index - 1] if (len(chunks) > 0) and index > 0 else start_chunk
        chunk.position = Vector2(previous_chunk.get_segment().b.x + previous_chunk.position.x - chunk.get_segment().a.x, previous_chunk.position.y + previous_chunk.get_segment().b.y - chunk.get_segment().a.y)

    if len(chunks) < index + 1:
        var new_point = chunk.position + chunk.get_segment().a

        chunks.append(null)
        remove_extra_points(new_point)
        points.append(new_point)

    chunks[index] = chunk

    if first_chunk_index > index:
        first_chunk_index = index

    if last_chunk_index < index:
        last_chunk_index = index


func draw_collision_polygon():
    if enable_physics:
        var looped_points = [] + points

        looped_points.append(Vector2(points[len(points) - 1].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
        looped_points.append(Vector2(points[0].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
        looped_points.append(points[0]);

        collision_polygon.polygon = looped_points;


func return_chunk_to_pool(index: int):
    var chunk_def: ChunkDef = chunk_defs[index]
    var chunk: Chunk = chunks[index]
    
    chunk_def.pool.append(chunk)
    chunks_root.remove_child(chunk)
    chunks_pool_root.add_child(chunk)
    chunk.position = Vector2.ZERO


func free_chunk_right():
    return_chunk_to_pool(last_chunk_index)
    chunks[last_chunk_index] = null
    last_chunk_index -= 1


func free_chunk_left():
    return_chunk_to_pool(first_chunk_index)
    chunks[first_chunk_index] = null
    first_chunk_index += 1


func populate_chunks(left_target: int, right_target: int):
    if right_target > last_chunk_index + 1:
        for index in range(right_target - last_chunk_index):
            if last_chunk_index + 1 > len(chunk_defs) - 1:
                append_chunk_def()
            if last_chunk_index + 1 > last_chunk_index:
                spawn_chunk(last_chunk_index + 1)
                draw_collision_polygon()
    elif right_target < last_chunk_index + 1:
        for index in range(last_chunk_index - right_target):
            free_chunk_right()


    if left_target > first_chunk_index:
        for index in range(left_target - first_chunk_index):
            free_chunk_left()
    elif left_target >= 0 and left_target < first_chunk_index:
        for index in range(first_chunk_index - left_target):
            spawn_chunk(first_chunk_index - 1)


func remove_extra_points(new_point: Vector2):
    if (len(points) >= 2):
        var p_a = points[len(points) - 2]
        var p_b = points[len(points) - 1]
        var p_c = new_point
        
        var aligned_y = p_a.y + (p_c.y - p_a.y) * (p_b.x - p_a.x) / (p_c.x - p_a.x)
        
        if (abs(aligned_y - p_b.y) <= Y_PRECISION):
            points.erase(p_b)


func populate_relative(frog: Node2D):
    var x_distance = abs(frog.global_position.x - start_chunk.global_position.x)
    var chunks_distance = ceil(x_distance / average_chunk_width)
    var frog_chunk = floor(x_distance / average_chunk_width) * trigger_scale

#    if map_name == 'Level':
#        print("{l},{f},{r}".format({
#            'l': frog_chunk - chunks_count_trigger,
#            'f': frog_chunk,
#            'r': frog_chunk + chunks_count_trigger
#        }))
    
    populate_chunks(frog_chunk - chunks_count_trigger, frog_chunk + chunks_count_trigger)


func _ready():
    var frogs = get_tree().get_nodes_in_group(FROG_GROUP)
    var seeds_labels = get_tree().get_nodes_in_group(SEED_LABEL_GROUP)

    if len(frogs) > 0:
        frog = frogs[0]
    else:
        printerr('No frog found in tree, cannot update map automatically')

    rng = RandomNumberGenerator.new()
    
    if seed != 0:
        var message = 'MAP GEN: force set seed {seed}'.format({'seed': seed})
        print(message)
        
        if len(seeds_labels) != 0:
            var seed_label = seeds_labels[0] as Label
            seed_label.text = message
        
        rng.set_seed(seed)
    else:
        seed = rng.get_seed()
        print('Seed for {name} = {seed}'.format({'name': map_name, 'seed': seed}))

    chunks_pools_size = 3 * chunks_count_trigger
    build_chunk_pools()
    populate_chunks(0, initial_chunks_count)


func _process(delta):
    if frog != null:
        populate_relative(frog)
        
