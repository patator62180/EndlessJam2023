extends Node2D

const Y_PRECISION = 10
const POLYGON_MINIMUM_HEIGHT = 200

@export var start_chunk: Chunk
@export var square_chunks_bank: Array[PackedScene]
@export var steep_chunks_bank: Array[PackedScene]
@export var steep_obstacle_chunks_bank: Array[PackedScene]
@export var chunks_root: Node2D
@export var collision_polygon: CollisionPolygon2D

@export_category("Chunks")
@export var chunks_count: int = 50
@export var min_square_series: int = 3
@export var max_square_series: int = 4
@export var min_steep_series: int = 4
@export var max_steep_series: int = 10
@export var average_chunk_width: int = 652
@export var min_chunks_before_obstacle: int = 6
@export var max_chunks_before_obstacle: int = 10

@export_category("Spawn")
@export var frog: Node2D
@export var chunks_count_trigger: int = 10

enum ChunkType {Square, Steep}

class ChunkDef:
    var packed_chunk: PackedScene
    var type: ChunkType
    var obstacle: bool

class Bounds:
    var min: int
    var max: int

class Map:
    var last_obstacle_position: int = 0
    var chunk_count_since_type_change: int = 0
    var next_chunk_threshold: int = 0
    var chunk_defs: Array[ChunkDef] = []
    var chunks: Array[Chunk] = []
    var rng: RandomNumberGenerator
    var min_square_series: int
    var max_square_series: int
    var min_steep_series: int
    var max_steep_series: int
    var average_chunk_width: int
    var min_chunks_before_obstacle: int
    var max_chunks_before_obstacle: int
    var start_chunk: Chunk
    var square_chunks_bank: Array[PackedScene]
    var steep_chunks_bank: Array[PackedScene]
    var steep_obstacle_chunks_bank: Array[PackedScene]
    var chunks_root: Node2D
    var collision_polygon: CollisionPolygon2D
    var last_chunk_index: int = -1
    var points: Array[Vector2] = []
    var chunks_count_trigger: int

    func _init():
        rng = RandomNumberGenerator.new()
   
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
    
    func pick_bank(type: ChunkType, obstacle: bool):
        if type == ChunkType.Square:
            return square_chunks_bank
        elif type == ChunkType.Steep and obstacle == true:
            return steep_obstacle_chunks_bank
        else:
            return steep_chunks_bank
    
    func append_chunk_def():
        if len(chunk_defs) == 0:
            next_chunk_threshold = generate_next_threshold(ChunkType.Square)
            chunk_count_since_type_change = 1
        
        var type = get_current_type()
        var bounds = get_series_bounds_for_type(type)
        var chunk_def = ChunkDef.new()

        chunk_def.obstacle = false
        
#        print("type: {type} chunk_count_since_type_change: {chunk_count_since_type_change}, next_chunk_threshold: {next_chunk_threshold}".format({"type": type, "chunk_count_since_type_change": chunk_count_since_type_change, "next_chunk_threshold": next_chunk_threshold}))
        if chunk_count_since_type_change == next_chunk_threshold:
            chunk_def.type = toggle_type(type)
            next_chunk_threshold = generate_next_threshold(chunk_def.type)
            chunk_count_since_type_change = 0
        else:
            chunk_def.type = type

        chunk_count_since_type_change += 1
        var bank = pick_bank(chunk_def.type, chunk_def.obstacle)

        chunk_def.packed_chunk = bank[rng.randi_range(0, len(bank) - 1)]
        chunk_defs.append(chunk_def)

    func spawn_chunk(index: int):
        var chunk = chunk_defs[index].packed_chunk.instantiate() as Chunk
        var previous_chunk = chunks[last_chunk_index] if len(chunks) > 0 else start_chunk

        if len(points) == 0:
            points.append(start_chunk.position + start_chunk.get_segment().a)

        chunk.position = Vector2(previous_chunk.get_segment().b.x + previous_chunk.position.x - chunk.get_segment().a.x, previous_chunk.position.y + previous_chunk.get_segment().b.y - chunk.get_segment().a.y)

        var new_point = chunk.position + chunk.get_segment().a

        chunks_root.add_child(chunk);
        chunks.append(chunk)
        chunk.disable_segment()
        remove_extra_points(new_point)

        if index > len(points) - 1:
            points.append(new_point)

        last_chunk_index = index
    
    func draw_polygon():
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
#                    print("popuplate chunk_def %d" % index)
                    append_chunk_def()
                if absolute_index > last_chunk_index:
#                    print("spawn chunk %d" % index)
                    spawn_chunk(absolute_index)
                    draw_polygon()

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

#        print("x_distance: {x_distance}, chunks_distance: {chunks_distance}, frog_chunk: {frog_chunk}".format({"x_distance": x_distance, "chunks_distance": chunks_distance, "frog_chunk": frog_chunk}))
#        print(chunks_distance)
#        print(frog_chunk + chunks_count_trigger)
        populate_chunks(frog_chunk + chunks_count_trigger)

var points: Array[Vector2] = []
var map: Map

func _ready():
    map = Map.new()

    map.min_square_series = min_square_series
    map.max_square_series = max_square_series
    map.min_steep_series = min_steep_series
    map.max_steep_series = max_steep_series
    map.average_chunk_width = average_chunk_width
    map.min_chunks_before_obstacle = min_chunks_before_obstacle
    map.max_chunks_before_obstacle = max_chunks_before_obstacle
    map.start_chunk = start_chunk
    map.square_chunks_bank = square_chunks_bank
    map.steep_chunks_bank = steep_chunks_bank
    map.steep_obstacle_chunks_bank = steep_obstacle_chunks_bank
    map.chunks_root = chunks_root
    map.collision_polygon = collision_polygon
    map.chunks_count_trigger = chunks_count_trigger

    map.populate_chunks(3)
    
func _process(delta):
    if map != null and frog != null:
        map.populate_relative(frog)
        
