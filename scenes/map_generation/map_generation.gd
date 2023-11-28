extends Node2D

const Y_PRECISION = 10
const POLYGON_MINIMUM_HEIGHT = 200
const FROG_GROUP = 'frog'

@export var start_chunk: Chunk
@export var square_chunks_bank: Array[PackedScene]
@export var steep_chunks_bank: Array[PackedScene]
@export var steep_obstacle_chunks_bank: Array[PackedScene]
@export var chunks_root: Node2D
@export var chunks_pool_root: Node2D
@export var collision_polygon: CollisionPolygon2D
@export var enable_collision_polygon: bool = true

@export_category("Chunks")
@export var initial_chunks_count: int = 3
@export var chunks_count_trigger: int = 10
@export var min_square_series: int = 3
@export var max_square_series: int = 4
@export var min_steep_series: int = 4
@export var max_steep_series: int = 10
@export var average_chunk_width: int = 652
@export var min_chunks_before_obstacle: int = 6
@export var max_chunks_before_obstacle: int = 10
@export var chunks_pools_size: int = 20

enum ChunkType {Square, Steep}


class ChunkDef:
    var pool: Array[Chunk]
    var type: ChunkType
    var obstacle: bool


class Bounds:
    var min: int
    var max: int


var last_obstacle_position: int = 0
var chunk_count_since_type_change: int = 0
var next_chunk_threshold: int = 0
var chunk_defs: Array[ChunkDef] = []
var chunks: Array[Chunk] = []
var rng: RandomNumberGenerator
var last_chunk_index: int = -1
var points: Array[Vector2] = []
var frog: Node2D
var square_chunks_pool: Array[Array] = []
var steep_chunks_pool: Array[Array] = []
var steep_obstacle_chunks_pool: Array[Array] = []


func build_chunk_pools():
    build_chunk_pool_type(ChunkType.Square, false)
    build_chunk_pool_type(ChunkType.Steep, false)
    build_chunk_pool_type(ChunkType.Steep, true)


func build_chunk_pool_type(type: ChunkType, obstacle: bool):
    var bank: Array[PackedScene] = []
    var pool: Array[Array] = []
    
    if type == ChunkType.Square:
        bank = square_chunks_bank
        pool = square_chunks_pool
    elif type == ChunkType.Steep and obstacle == true:
        bank = steep_obstacle_chunks_bank
        pool = steep_obstacle_chunks_pool
    else:
        bank = steep_chunks_bank
        pool = steep_chunks_pool
   
    for packed_chunk in bank:
        var typed_pool: Array[Chunk] = []

        for index in range(chunks_pools_size):
            var chunk = packed_chunk.instantiate() as Chunk
    
            chunks_pool_root.add_child(chunk)
            chunk.position = Vector2.ZERO
            chunk.disable_segment()
            typed_pool.append(chunk)

        pool.append(typed_pool)


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


func pick_pool(type: ChunkType, obstacle: bool):
    if type == ChunkType.Square:
        return square_chunks_pool
    elif type == ChunkType.Steep and obstacle == true:
        return steep_obstacle_chunks_pool
    else:
        return steep_chunks_pool


func append_chunk_def():
    if len(chunk_defs) == 0:
        next_chunk_threshold = generate_next_threshold(ChunkType.Square)
        chunk_count_since_type_change = 1
    
    var type = get_current_type()
    var bounds = get_series_bounds_for_type(type)
    var chunk_def = ChunkDef.new()

    chunk_def.obstacle = false
    
    if chunk_count_since_type_change == next_chunk_threshold:
        chunk_def.type = toggle_type(type)
        next_chunk_threshold = generate_next_threshold(chunk_def.type)
        chunk_count_since_type_change = 0
    else:
        chunk_def.type = type

    chunk_count_since_type_change += 1
    var pool = pick_pool(chunk_def.type, chunk_def.obstacle)

    chunk_def.pool = pool[rng.randi_range(0, len(pool) - 1)]
    chunk_defs.append(chunk_def)


func spawn_chunk(index: int):
    var chunk: Chunk = chunk_defs[index].pool.pop_front()
    var previous_chunk = chunks[last_chunk_index] if len(chunks) > 0 else start_chunk

    if len(points) == 0:
        points.append(start_chunk.position + start_chunk.get_segment().a)

    chunks_pool_root.remove_child(chunk)
    chunks_root.add_child(chunk)

    chunk.position = Vector2(previous_chunk.get_segment().b.x + previous_chunk.position.x - chunk.get_segment().a.x, previous_chunk.position.y + previous_chunk.get_segment().b.y - chunk.get_segment().a.y)

    var new_point = chunk.position + chunk.get_segment().a

    chunks.append(chunk)
    remove_extra_points(new_point)

    if index > len(points) - 1:
        points.append(new_point)

    last_chunk_index = index


func draw_collision_polygon():
    if enable_collision_polygon:
        var looped_points = [] + points

        looped_points.append(Vector2(points[len(points) - 1].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
        looped_points.append(Vector2(points[0].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
        looped_points.append(points[0]);
        
        collision_polygon.polygon = looped_points;


func populate_chunks(target: int):
    var initial_last_chunk_index = last_chunk_index
    
    if target > last_chunk_index + 1:
        for index in range(target - initial_last_chunk_index):
            var absolute_index = initial_last_chunk_index + index + 1
            
            if absolute_index > len(chunk_defs) - 1:
                append_chunk_def()
            if absolute_index > last_chunk_index:
                spawn_chunk(absolute_index)
                draw_collision_polygon()


func remove_extra_points(new_point: Vector2):
    if (len(points) >= 2):
        var p_a = points[len(points) - 2]
        var p_b = points[len(points) - 1]
        var p_c = new_point
        
        var aligned_y = p_a.y + (p_c.y - p_a.y) * (p_b.x - p_a.x) / (p_c.x - p_a.x)
        
        if (abs(aligned_y - p_b.y) <= Y_PRECISION):
            points.erase(p_b)        


func populate_relative(frog: Node2D):
    var x_distance = chunks[last_chunk_index].global_position.x + chunks[last_chunk_index].get_segment().a.x - frog.global_position.x
    var chunks_distance = ceil(x_distance / average_chunk_width)
    var frog_chunk = last_chunk_index - chunks_distance

    populate_chunks(frog_chunk + chunks_count_trigger)


func _ready():
    var frogs = get_tree().get_nodes_in_group(FROG_GROUP)

    if len(frogs) > 0:
        frog = frogs[0]
    else:
        printerr('No frog found in tree, cannot update map automatically')

    rng = RandomNumberGenerator.new()
    build_chunk_pools()
    populate_chunks(initial_chunks_count)

    
func _process(delta):
    if frog != null:
        populate_relative(frog)
        
