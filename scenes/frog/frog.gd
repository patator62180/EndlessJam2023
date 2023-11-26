extends CharacterBody2D

const VELOCITY_SCALE: float = 300
const BALL_GROUP = 'ball'
const MOVE_RIGHT_INPUT = 'move_right'

@export var left_arm: Node2D
@export var right_arm: Node2D
@export var hand: Area2D
@export var wrist: Area2D

var screen_size: Vector2
var viewport: Viewport

var left_arm_range = Vector2(deg_to_rad(-113), deg_to_rad(-31.8))
var right_arm_range = Vector2(deg_to_rad(-127), deg_to_rad(-26.5))
var ball: RigidBody2D;
var hand_touching_ball: bool;
var wrist_touching_ball: bool;

# Called when the node enters the scene tree for the first time.
func _ready():
    viewport = get_viewport()
    screen_size = viewport.get_visible_rect().size
    hand.body_entered.connect(hand_had_body_entered)
    hand.body_exited.connect(hand_had_body_exited)
    wrist.body_entered.connect(wrist_had_body_entered)
    wrist.body_exited.connect(wrist_had_body_exited)
    
    var ball_group = get_tree().get_nodes_in_group(BALL_GROUP)
    
    if len(ball_group) > 0:
        ball = ball_group[0] as RigidBody2D


func hand_had_body_entered(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        hand_touching_ball = true

func hand_had_body_exited(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        hand_touching_ball = false

func wrist_had_body_entered(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        wrist_touching_ball = true

func wrist_had_body_exited(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        wrist_touching_ball = false

func _process(delta):
    var mouse_target = max(0, min(viewport.get_mouse_position().y / screen_size.y, 1))
    var moving_right = Input.is_action_pressed(MOVE_RIGHT_INPUT)
    
    left_arm.rotation = left_arm_range.x + (left_arm_range.y - left_arm_range.x) * mouse_target
    right_arm.rotation = right_arm_range.x + (right_arm_range.y - right_arm_range.x) * mouse_target
    
    var new_velocity = velocity
    
    new_velocity.y += 500 * delta;

    if moving_right and not wrist_touching_ball:
        new_velocity.x = VELOCITY_SCALE
    else:
        new_velocity.x = 0

    velocity = new_velocity

    if is_on_floor():
        var floor_normal = get_floor_normal()

        if (up_direction != floor_normal):
            up_direction = floor_normal

    move_and_slide()
    
    if not moving_right and hand_touching_ball:
        ball.sleeping = true
    elif moving_right and hand_touching_ball:
        ball.sleeping = false
        ball.linear_velocity = Vector2(VELOCITY_SCALE * 2, 0)
    elif not hand_touching_ball:
        ball.sleeping = false
