extends CharacterBody2D

const SPEED = 700
const JUMP_VELOCITY = -900.0

const FOOT_DISTANCE = 150
const FOOT_DETECTION = 150
const FOOT_HEIGHT = 30

const FOOT_TIMER_INCREMENT = 0.1

const BALL_GROUP = 'ball'

var push_force = 200
var throw_force = 8000

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
var safeRockArea
var unsafeRockArea
var touchingBall
var blockedByBall
var hips

var ball

var handRRest
var handLRest

var animator

var jumping
var holding

var rockThrowTarget

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
    safeRockArea = $"SafeRockArea"
    hips = $"Skeleton2D/Hip"
    handLRest = $"Skeleton2D/Hip/HandLRest"
    handRRest = $"Skeleton2D/Hip/HandRRest"
    animator = $AnimationPlayer
    
    rockThrowTarget = $"Skeleton2D/Hip/RockThrowTarget"

    #safeRockArea.body_entered.connect(body_entered_safe_rock_area)
    #safeRockArea.body_exited.connect(body_exited_safe_rock_area)
    #unsafeRockArea.body_entered.connect(body_entered_unsafe_rock_area)
    #unsafeRockArea.body_exited.connect(body_exited_unsafe_rock_area)
    
    safeRockArea.body_entered.connect(touch_ball)
    safeRockArea.body_exited.connect(untouch_ball)

func touch_ball(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        touchingBall = true
        ball = body

func untouch_ball(body: Node2D):
    if body.is_in_group(BALL_GROUP):
        touchingBall = false
    
#func body_entered_safe_rock_area(body: Node2D):
#	if body.is_in_group(BALL_GROUP):
#		touchingBall = true
#		ball = body as RigidBody2D

#func body_exited_safe_rock_area(body: Node2D):
#	if body.is_in_group(BALL_GROUP):
#		touchingBall = false

#func body_entered_unsafe_rock_area(body: Node2D):
#	if body.is_in_group(BALL_GROUP):
#		blockedByBall = true

#func body_exited_unsafe_rock_area(body: Node2D):
#	if body.is_in_group(BALL_GROUP):
#		blockedByBall = false

func _physics_process(delta):
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle Jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !jumping and !touchingBall:
        #velocity.y = JUMP_VELOCITY
        animator.play("Jump");
        jumping = true

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var adjustedSpeed = SPEED if !touchingBall else SPEED / 2
    
    var direction = Input.get_axis("move_left", "move_right")
    
    #var ballDirection = sign(ball.position.x - position.x) if ball != null else 0
    
    var moving = false

    #if not blockedByBall or ballDirection != direction:
    if direction and !holding && !holdAnim:
        velocity.x = direction * adjustedSpeed
    else:
        velocity.x = move_toward(velocity.x, 0, adjustedSpeed)

    
    move_and_slide()
    #apply_floor_snap()

    raycastLegs()
    rayCastArms()
    
    if !holding && !holdAnim:
        for i in get_slide_collision_count():
            var c = get_slide_collision(i)
            if c.get_collider() is RigidBody2D:
                c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
            
    throw_rock(direction)

    #if touchingBall and not ball == null:
    #	ball.linear_velocity = velocity
    
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
    var targetL
    var targetR
    
    if touchingBall:
        targetL = lerp(armLTarget.get_global_position(), ball.targetL.get_global_position(), 0.1)
        targetR = lerp(armRTarget.get_global_position(), ball.targetR.get_global_position(), 0.1)
    elif holding || holdAnim:
        targetL = lerp(armLTarget.get_global_position(), ball.targetR.get_global_position(), 0.5)
        targetR = lerp(armRTarget.get_global_position(), ball.targetL.get_global_position(), 0.5)
    else:
        targetL = lerp(armLTarget.get_global_position(), handLRest.get_global_position(), 0.1)
        targetR = lerp(armRTarget.get_global_position(), handRRest.get_global_position(), 0.1)
        
    armLTarget.set_global_position(targetL)
    armRTarget.set_global_position(targetR)
    
  
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

func _on_animation_player_animation_finished(anim_name):
    if anim_name == "Jump":
        velocity.y = JUMP_VELOCITY
        jumping = false
        
var holdAnim = false

var ballHoldStart
var ballHoldMid
var ballHoldT = 1

func throw_rock(direction):
    if touchingBall && Input.is_action_just_pressed("ui_accept") and !jumping:
        #holding = true
        holdAnim = true
        ballHoldStart = ball.global_position
        var vector = (ballHoldStart + rockThrowTarget.global_position) / 2
        ballHoldMid = vector + Vector2.UP * 200
        ballHoldT = 0
        
        ball.freeze = true     
        ball.sleeping = true
        hips.position.y += 100
        
        ball.get_node("CollisionShape2D").disabled = true
        
    var dir = 1 if direction > 0 else -1 if direction < 0 else 0
        
    if holding:
        hips.rotation = lerp(hips.rotation, deg_to_rad(dir * 45), 0.1)
        ball.global_position = rockThrowTarget.global_position
        
    if holding and !Input.is_action_pressed("ui_accept"):
        holding = false
        ball.freeze = false
        ball.sleeping = false
        ball.get_node("CollisionShape2D").disabled = false
        ball.apply_central_impulse((Vector2.UP + Vector2(dir, 0) * 0.5) * throw_force)
        hips.position.y -= 100
        
    if holdAnim:
        if ballHoldT >= 1:
            holdAnim = false
            holding = true
        else:
            ball.global_position = _quadratic_bezier(ballHoldStart, ballHoldMid, rockThrowTarget.global_position, ballHoldT)
            ballHoldT += 0.05
        
        
