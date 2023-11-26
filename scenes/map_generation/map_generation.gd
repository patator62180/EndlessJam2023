extends Node2D

const Y_PRECISION = 10
const POLYGON_MINIMUM_HEIGHT = 200

@export var start_chunk: Chunk
@export var square_chunks_bank: Array[PackedScene]
@export var steep_chunks_bank: Array[PackedScene]
@export var chunks_root: Node2D
@export var collision_polygon: CollisionPolygon2D

@export_category("Chunks")
@export var chunks_count: int = 50
@export var min_square_series: int = 2
@export var max_square_series: int = 3
@export var min_steep_series: int = 4
@export var max_steep_series: int = 10


var points: Array[Vector2] = [];

func _ready():
    var chunks: Array[Chunk] = [];
    var previous_chunk = start_chunk;
    var rng = RandomNumberGenerator.new();
    
    chunks.push_back(start_chunk);
    points.push_back(start_chunk.position + start_chunk.get_segment().a);
    
    var bank = square_chunks_bank
    var series_counter = 1
    var series_length = rng.randi_range(min_square_series, max_square_series)
    var bank_type = Chunk.Type.SQUARE
    
    for index in range(chunks_count):
        var packed_chunk = bank[rng.randi_range(0, len(bank) - 1)];
        
        series_counter += 1
        
        if series_counter == series_length:
            series_counter = 0

            if bank_type == Chunk.Type.SQUARE:
                bank = steep_chunks_bank
                series_length = rng.randi_range(min_steep_series, max_steep_series)
                bank_type = Chunk.Type.STEEP
            else:
                bank = square_chunks_bank
                series_length = rng.randi_range(min_square_series, max_square_series)
                bank_type = Chunk.Type.SQUARE                

        var new_chunk = attach_new_chunk(previous_chunk, packed_chunk)
        var new_point = new_chunk.position + new_chunk.get_segment().a
        
        remove_extra_points(new_point)
        points.push_back(new_point)
        chunks.push_back(new_chunk)
        
        previous_chunk = new_chunk
        
    var last_chunk_right_point = chunks[len(chunks) - 1].position + chunks[len(chunks) - 1].get_segment().b
    
    remove_extra_points(last_chunk_right_point)
    points.push_back(last_chunk_right_point)

    points.push_back(Vector2(points[len(points) - 1].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
    points.push_back(Vector2(points[0].x, points[0].y + POLYGON_MINIMUM_HEIGHT));
    points.push_back(points[0]);

    collision_polygon.polygon = points;

    for chunk in chunks:
        chunk.disable_segment()

func remove_extra_points(new_point: Vector2):
    if (len(points) >= 2):
        var p_a = points[len(points) - 2]
        var p_b = points[len(points) - 1]
        var p_c = new_point
        
        var aligned_y = p_a.y + (p_c.y - p_a.y) * (p_b.x - p_a.x) / (p_c.x - p_a.x)
        
        if (abs(aligned_y - p_b.y) <= Y_PRECISION):
            points.erase(p_b)

func attach_new_chunk(previous_chunk: Chunk, packedChunk: PackedScene):
    var new_chunk = packedChunk.instantiate() as Chunk

    chunks_root.add_child(new_chunk);
    new_chunk.position = Vector2(previous_chunk.get_segment().b.x + previous_chunk.position.x - new_chunk.get_segment().a.x, previous_chunk.position.y + previous_chunk.get_segment().b.y - new_chunk.get_segment().a.y)
    return new_chunk

