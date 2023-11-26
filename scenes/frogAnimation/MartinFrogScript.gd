extends CharacterBody2D

const SPEED = 500
const JUMP_VELOCITY = -900.0

const FOOT_DISTANCE = 150
const FOOT_DETECTION = 150
const FOOT_HEIGHT = 30

const FOOT_TIMER_INCREMENT = 0.1

const BALL_GROUP = 'ball'

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var legLTarget
var raycastLegL
var raycastLegL2
var lastLFootPos

var legRTarget
var raycastLegR
var raycastLegR2
var lastRFootPos

var armLTarget
var armRTarget

var scaleScalar

var body
var bodyCollider
var touchingBall
var hips

var ball


func _ready():
    legLTarget = $"FootL"
    raycastLegL = $"Skeleton2D/Hip/RaycastLegL"
    raycastLegL2 = $"Skeleton2D/Hip/RaycastLegL2"    
    
    legRTarget = $"FootR"
    raycastLegR = $"Skeleton2D/Hip/RaycastLegR"
    raycastLegR2 = $"Skeleton2D/Hip/RaycastLegR2"
    
    armLTarget = $"HandL"
    armRTarget = $"HandR"
    
    scaleScalar = scale.x
    
    body = $"Skeleton2D/Hip/Torso"
    bodyCollider = $"IsTouchingRock"
    
    hips = $"Skeleton2D/Hip"
    
    bodyCollider.body_entered.connect(collision_start)
    bodyCollider.body_exited.connect(collision_end)
    
func collision_start(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        touchingBall = true
        ball = body

func collision_end(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        touchingBall = false

func _physics_process(delta):
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle Jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var adjustedSpeed = SPEED if !touchingBall else SPEED / 2
    
    var direction = Input.get_axis("move_left", "move_right")
    if direction:
        #if is_on_floor():
        #   velocity = Vector2(direction, 0).rotated(deg_to_rad(get_floor_angle())) * SPEED
        #else:
        velocity.x = direction * adjustedSpeed
    else:
        velocity.x = move_toward(velocity.x, 0, adjustedSpeed)
        
    move_and_slide()
    
    apply_floor_snap()
    
    raycastLegs()
    rayCastArms()
    
var timerL = 1
var oldTargetL
var currentTargetL
var midTargetL

var timerR = 1
var oldTargetR
var currentTargetR
var midTargetR

var wasMoving
    
func raycastLegs():
    var right = velocity.x > 0
    var left = velocity.x < 0
    var moving = right || left
    var modifier = 1 if right else -1 if left else 0
    
    #if modifier == 0:
    #    return
    
    
    #sbody.rotation = deg_to_rad(-modifier * 25)
    
    if is_on_floor():
        hips.rotation = lerp(hips.rotation, -get_floor_angle(), 0.1) 
    else:
        hips.rotation = lerp(hips.rotation, deg_to_rad(0), 0.1) 
        
    body.rotation = lerp(body.rotation, deg_to_rad(-modifier * 25), 0.1)         
    
    var justStopped = wasMoving && !moving
    var footSpeedModifier = 1 if ! touchingBall else 0.5
    
    var footAngleModifier = 40
    #raycastLegL2.position = raycastLegL.position + Vector2(modifier, 0) * FOOT_DETECTION / scaleScalar
    raycastLegL2.rotation = deg_to_rad(modifier * -footAngleModifier)
    var rayCastL = raycastLegL if !moving || !is_on_floor() else raycastLegL2
    
    var colliderL = rayCastL.get_collider()
    if colliderL != null:
        var pos = rayCastL.get_collision_point()
        
        if currentTargetL == null || (currentTargetL.distance_to(pos) >= FOOT_DISTANCE && timerR == 1) || justStopped:
            #var normal = rayCastL.get_collision_normal()
            if currentTargetL == null:
                oldTargetL = pos
                currentTargetL = pos
                midTargetL = pos
                timerL = 1
            else:
                oldTargetL = currentTargetL if !justStopped else legLTarget.get_global_position()
                currentTargetL = pos #+ normal
                var midPoint = (oldTargetL + currentTargetL) / 2
                var midPointModifier = rayCastL.get_collision_normal() * FOOT_HEIGHT / scaleScalar if !justStopped else Vector2.ZERO
                midTargetL = midPoint + midPointModifier
                timerL = 0
            
        var target = _quadratic_bezier(oldTargetL, midTargetL, currentTargetL, timerL)
        timerL = min(timerL + FOOT_TIMER_INCREMENT * footSpeedModifier, 1)
            
        legLTarget.set_global_position(target)
    else:
        currentTargetL = null

    #raycastLegR2.position = raycastLegR.position + Vector2(modifier, 0) * FOOT_DETECTION / scaleScalar
    raycastLegR2.rotation = deg_to_rad(modifier * -footAngleModifier)
    var rayCastR = raycastLegR if !moving || !is_on_floor() else raycastLegR2
    
    var colliderR = rayCastR.get_collider()
    if colliderR != null:
        var pos = rayCastR.get_collision_point()
        
        if currentTargetR == null || (currentTargetR.distance_to(pos) >= FOOT_DISTANCE && timerL == 1) || justStopped:
            if currentTargetR == null:
                oldTargetR = pos
                currentTargetR = pos
                midTargetR = pos
                timerR = 1
            else:
                oldTargetR = currentTargetR if !justStopped else legRTarget.get_global_position()
                currentTargetR = pos #+ normal
                var midPoint = (oldTargetR + currentTargetR) / 2
                var midPointModifier = rayCastR.get_collision_normal() * FOOT_HEIGHT / scaleScalar if !justStopped else Vector2.ZERO
                midTargetR = midPoint + midPointModifier
                timerR = 0
            
        var target = _quadratic_bezier(oldTargetR, midTargetR, currentTargetR, timerR)
        timerR = min(timerR + FOOT_TIMER_INCREMENT * footSpeedModifier, 1)
            
        legRTarget.set_global_position(target)
    else:
        currentTargetR = null
        
    wasMoving = moving
      
func rayCastArms():
    if touchingBall:
        armLTarget.set_global_position(ball.targetL.get_global_position())
        armRTarget.set_global_position(ball.targetR.get_global_position())
  
func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
    var q0 = p0.lerp(p1, t)
    var q1 = p1.lerp(p2, t)
    var r = q0.lerp(q1, t)
    return r
        
#TODO 
# rotate the secondary colliders based on normal
# move arms ?
# interact with boulder
# throwing
# better jumping (looking & feeling)

