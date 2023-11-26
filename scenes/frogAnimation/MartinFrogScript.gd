extends CharacterBody2D

const SPEED = 500
const JUMP_VELOCITY = -900.0

const FOOT_DISTANCE = 150
const FOOT_DETECTION = 150
const FOOT_HEIGHT = 30

const FOOT_TIMER_INCREMENT = 0.1

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

var scaleScalar

var body

func _ready():
    legLTarget = $"FootL"
    raycastLegL = $"Skeleton2D/Hip/RaycastLegL"
    raycastLegL2 = $"Skeleton2D/Hip/RaycastLegL2"    
    
    legRTarget = $"FootR"
    raycastLegR = $"Skeleton2D/Hip/RaycastLegR"
    raycastLegR2 = $"Skeleton2D/Hip/RaycastLegR2"
    
    scaleScalar = scale.x
    
    body = $"Skeleton2D/Hip/Torso"

func _physics_process(delta):
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle Jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction = Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    move_and_slide()
    
    raycastLegs()
    
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
    
    body.rotation = deg_to_rad(-modifier * 25)
    
    var justStopped = wasMoving && !moving
    
    raycastLegL2.position = raycastLegL.position + Vector2(modifier, 0) * FOOT_DETECTION / scaleScalar
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
        timerL = min(timerL + FOOT_TIMER_INCREMENT, 1)
            
        legLTarget.set_global_position(target)
    else:
        currentTargetL = null

    raycastLegR2.position = raycastLegR.position + Vector2(modifier, 0) * FOOT_DETECTION / scaleScalar
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
        timerR = min(timerR + FOOT_TIMER_INCREMENT, 1)
            
        legRTarget.set_global_position(target)
    else:
        currentTargetR = null
        
    wasMoving = moving
        
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

