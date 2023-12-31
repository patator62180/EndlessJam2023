extends CharacterBody2D

const SPEED = 700
const JUMP_VELOCITY = -1500.0

const FOOT_DISTANCE = 800
const FOOT_DETECTION = 150
const FOOT_HEIGHT = 30

const FOOT_TIMER_INCREMENT = 0.1

const BALL_GROUP = 'ball'

var push_force = 500
var throw_force = 15000

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

var legL
var legR
var footL
var footR

@export var foot_r_area = CollisionShape2D
@export var foot_l_area = CollisionShape2D

@export var step_noize = AudioStreamPlayer

var hand_l
var hand_r

func _ready():
    legLTarget = $"FootL"
    legL = $Skeleton2D/Hip/LegL
    footL = $Skeleton2D/Hip/LegL/ForeLegL/ForeForeLegL/FootL
    raycastLegL = $"Skeleton2D/RaycastLegL"
    raycastLegL2 = $"Skeleton2D/RaycastLegL2"    
    
    legRTarget = $"FootR"
    legR = $Skeleton2D/Hip/LegR
    footR = $Skeleton2D/Hip/LegR/ForeLegR/ForeForeLegR/FootR
    raycastLegR = $"Skeleton2D/RaycastLegR"
    raycastLegR2 = $"Skeleton2D/RaycastLegR2"
    
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
    
    hand_l = $"Skeleton2D/Hip/Torso/ArmL/ForeArmL/ForeForeArmL/HandL"
    hand_r = $"Skeleton2D/Hip/Torso/ArmR/ForeArmR/ForeForeArmR/HandR"

    #safeRockArea.body_entered.connect(body_entered_safe_rock_area)
    #safeRockArea.body_exited.connect(body_exited_safe_rock_area)
    #unsafeRockArea.body_entered.connect(body_entered_unsafe_rock_area)
    #unsafeRockArea.body_exited.connect(body_exited_unsafe_rock_area)
    
    safeRockArea.body_entered.connect(touch_ball)
    safeRockArea.body_exited.connect(untouch_ball)
    
    hipsOrigin = hips.position
    lastHipPosition = hips.position
    

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

var input_vector = 0

func spawn_hat():
    $Skeleton2D/Hip/Torso/Neck/HatFactory.spawn_hat()
    
func _physics_process(delta):
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta

    # Handle Jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !jumping and !touchingBall and !holding and !holdAnim and !throwAnim:
        #velocity.y = JUMP_VELOCITY
        #animator.play("Jump");
        #jumping = true
        velocity.y = JUMP_VELOCITY
        #$Skeleton2D/Hip/Torso/Neck/HatFactory.spawn_hat()

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var adjustedSpeed = SPEED if !touchingBall else SPEED / 2
    
    var direction = Input.get_axis("move_left", "move_right")
    
    input_vector = direction
    
    var body_rotation = deg_to_rad(input_vector * 15)
    
    body.rotation = lerp(body.rotation, body_rotation if touchingBall or holding or holdAnim else -body_rotation, 0.1)
    #var ballDirection = sign(ball.position.x - position.x) if ball != null else 0

    #if not blockedByBall or ballDirection != direction:
    if direction and !holding && !holdAnim and !throwAnim:
        velocity.x = direction * adjustedSpeed
    else:
        velocity.x = move_toward(velocity.x, 0, adjustedSpeed)

    move_and_slide()
    apply_floor_snap()

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
var previousTargetL
var currentTargetL
var midTargetL 

var timerR = 1
var previousTargetR 
var currentTargetR 
var midTargetR 

var wasMoving

var hipsOrigin
var lastHipPosition
var default_crouch = 25
var hold_crouch = 50
var throw_crouch = 100
    
func raycastLegs():
    var right = velocity.x > 0
    var left = velocity.x < 0
    var moving = right || left
    var modifier = 1 if right else -1 if left else 0
    
#    if is_on_floor():
#        hips.rotation = lerp(hips.rotation, get_floor_angle(), 0.1) 
#    else:
#        hips.rotation = lerp(hips.rotation, deg_to_rad(0), 0.1) 
        
    #body.rotation = lerp(body.rotation, deg_to_rad(-modifier * 25), 0.1)         
    
    var justStopped = wasMoving && !moving
    var footSpeedModifier = 1 if ! touchingBall else 0.75
    
    var floorAngle = 0 if !is_on_floor() else get_floor_angle()
    

    var foot_area_size = 100
    var foot_speed = 0.08 * footSpeedModifier

    if foot_l_area.global_position.y != foot_r_area.global_position.y:
        hips.position = hipsOrigin - Vector2(0, (foot_l_area.global_position.y - foot_r_area.global_position.y) / 2 - default_crouch) / scaleScalar
        lastHipPosition = hips.position
#    if holding or holdAnim:
#        var current_hold_crouch = lerp(0, hold_crouch, ballHoldT)
#        hips.position.y += current_hold_crouch / scaleScalar
#
#    if throwAnim:
#        hips.position.y += throw_crouch / scaleScalar
    
    ##RIGHT LEG       
    var collider = raycastLegR.get_collider()
    var collider2 = raycastLegR2.get_collision_point()   
    
    if collider != null:
        foot_r_area.global_position = raycastLegR.get_collision_point()
        
        if currentTargetR == null:
            currentTargetR = raycastLegR.get_collision_point()

        if (currentTargetR.distance_to(foot_r_area.global_position) > foot_area_size or (input_vector == 0 && currentTargetR.distance_to(foot_r_area.global_position) > 10)) && timerL >= 1 && timerR >= 1:
            timerR = 0
            previousTargetR = footR.global_position
            raycastLegR2.global_position = raycastLegR.global_position + Vector2(input_vector, 0) * foot_area_size * 0.75
            collider2 = raycastLegR2.get_collision_point()   
    else:
        currentTargetR = null
              
    var target = currentTargetR
    
    if timerR < 1:
        if collider2 != null:
            currentTargetR = raycastLegR2.get_collision_point()   
        timerR += foot_speed   
        #target = lerp(previousTargetR, currentTargetR, timerR)
        
        var midPoint = (previousTargetR + currentTargetR) / 2
        var midPointModifier = Vector2.UP * 100 
        midTargetR = midPoint + midPointModifier
        
        target = _quadratic_bezier(previousTargetR, midTargetR, currentTargetR, timerR)
        #legRTarget.rotation = raycastLegR2.get_collision_normal().angle() + deg_to_rad(90)
    
    if timerR > 1:
        timerR = 1
        play_foot_noize()
    
    if target != null:
        legRTarget.global_position = target
    else:
        legRTarget.global_position = lerp(legRTarget.global_position, foot_r_area.global_position, 0.1)
        
    ##LEFT LEG        
    collider = raycastLegL.get_collider()
    collider2 = raycastLegL2.get_collision_point()   
    
    if collider != null:
        foot_l_area.global_position = raycastLegL.get_collision_point()
        
        if currentTargetL == null:
            currentTargetL = raycastLegL.get_collision_point()

        if (currentTargetL.distance_to(foot_l_area.global_position) > foot_area_size or (input_vector == 0 && currentTargetL.distance_to(foot_l_area.global_position) > 10)) && timerR >= 1 && timerL >= 1:
            timerL = 0
            previousTargetL = currentTargetL  
            raycastLegL2.global_position = raycastLegL.global_position + Vector2(input_vector, 0) * foot_area_size * 0.75
            collider2 = raycastLegL2.get_collision_point()   
    else:
        currentTargetL = null
        
    target = currentTargetL
    
    if timerL < 1:
        if collider2 != null:
            currentTargetL = raycastLegL2.get_collision_point()   
        timerL += foot_speed   
        #target = lerp(previousTargetL, currentTargetL, timerL)
        
        var midPoint = (previousTargetL + currentTargetL) / 2
        var midPointModifier = Vector2.UP * 100 
        midTargetL = midPoint + midPointModifier
        
        target = _quadratic_bezier(previousTargetL, midTargetL, currentTargetL, timerL)
        #legLTarget.rotation = raycastLegL2.get_collision_normal().angle() + deg_to_rad(90)
    
    if timerL > 1:
        timerL = 1
        play_foot_noize()
    
    if target != null:
        legLTarget.global_position = target
    else:
        legLTarget.global_position = lerp(legLTarget.global_position, foot_l_area.global_position, 0.1)
        
    #raycastLegL2.position = raycastLegL.position + Vector2(modifier, 0).normalized().rotated(-floorAngle) * FOOT_DETECTION / scaleScalar
    #var rayCastL = raycastLegL if !moving || !is_on_floor() else raycastLegL2

#    var colliderL = rayCastL.get_collider()
#    if colliderL != null:
#        var pos = rayCastL.get_collision_point()
#
#        if distanceL >= FOOT_DISTANCE * scaleScalar and timerL == 1 and timerR == 1 and distanceL > distanceR:
#            oldTargetL = footL.global_position
#            currentTargetL = pos
#            var midPoint = (oldTargetL + currentTargetL) / 2
#            var midPointModifier = rayCastL.get_collision_normal() * FOOT_HEIGHT / scaleScalar if !justStopped else Vector2.ZERO
#            midTargetL = midPoint + midPointModifier
#            timerL = 0
#
#        if currentTargetL == null:
#            oldTargetL = pos
#            currentTargetL = pos
#            midTargetL = pos
#            timerL = 1
#
#        var target = _quadratic_bezier(oldTargetL, midTargetL, currentTargetL, timerL)
#        timerL = min(timerL + FOOT_TIMER_INCREMENT, 1)
#
#        legLTarget.set_global_position(target)
#    else:
#        currentTargetL = null
#
#    raycastLegR2.position = raycastLegR.position + Vector2(modifier, 0).normalized().rotated(-floorAngle) * FOOT_DETECTION / scaleScalar
#    var rayCastR = raycastLegR if !moving || !is_on_floor() else raycastLegR2
#
#    var colliderR = rayCastR.get_collider()
#    if colliderR != null:
#        var pos = rayCastR.get_collision_point()
#
#        if distanceR >= FOOT_DISTANCE * scaleScalar and timerR == 1 and timerL == 1 and distanceR > distanceL:
#            oldTargetR = footR.global_position
#            currentTargetR = pos
#            var midPoint = (oldTargetR + currentTargetR) / 2
#            var midPointModifier = rayCastR.get_collision_normal() * FOOT_HEIGHT / scaleScalar if !justStopped else Vector2.ZERO
#            midTargetR = midPoint + midPointModifier
#            timerR = 0
#
#        if currentTargetR == null:
#            oldTargetR = pos
#            currentTargetR = pos
#            midTargetR = pos
#            timerR = 1
#
#        var target = _quadratic_bezier(oldTargetR, midTargetR, currentTargetR, timerR)
#        timerR = min(timerR + FOOT_TIMER_INCREMENT, 1)
#
#        legRTarget.set_global_position(target)
#    else:
#        currentTargetR = null







#    raycastLegR2.position = raycastLegR.position + Vector2(modifier, 0).normalized().rotated(-floorAngle) * FOOT_DETECTION / scaleScalar 
#    var rayCastR = raycastLegR if !moving || !is_on_floor() else raycastLegR2
#
#    var colliderR = rayCastR.get_collider()
#    if colliderR != null:
#        var pos = rayCastR.get_collision_point()
#
#        if currentTargetR == null || (legR.global_position.distance_to(footR.global_position) >= FOOT_DISTANCE * scaleScalar && timerL == 1 ) || justStopped:
#            if currentTargetR == null:
#                oldTargetR = pos
#                currentTargetR = pos
#                midTargetR = pos
#                timerR = 1
#            else:
#                #oldTargetR = currentTargetR if !justStopped else legRTarget.get_global_position()
#                oldTargetR = footR.global_position
#                currentTargetR = pos #+ normal
#                var midPoint = (oldTargetR + currentTargetR) / 2
#                var midPointModifier = rayCastR.get_collision_normal() * FOOT_HEIGHT / scaleScalar if !justStopped else Vector2.ZERO
#                midTargetR = midPoint + midPointModifier
#                timerR = 0
#
#        var target = _quadratic_bezier(oldTargetR, midTargetR, currentTargetR, timerR)
#        timerR = min(timerR + FOOT_TIMER_INCREMENT * footSpeedModifier, 1)
#
#        legRTarget.set_global_position(target)
#    else:
#        currentTargetR = null
        
    wasMoving = moving


@export var hand_l_follow = Node2D
@export var hand_r_follow = Node2D

var keep_your_hands_up_timer = 1

func rayCastArms():
    var targetL
    var targetR
    
    var hand_gravity = Vector2.DOWN * 50
    hand_l_follow.global_position = lerp(hand_l_follow.global_position, hand_l.global_position + hand_gravity, 0.05)
    hand_r_follow.global_position = lerp(hand_r_follow.global_position, hand_r.global_position + hand_gravity, 0.05)
    
    if holding || holdAnim || touchingBall || throwAnim:
        var speed = 0.1 if touchingBall else 0.5
        targetL = lerp(armLTarget.get_global_position(), ball.targetR.get_global_position(), speed)
        targetR = lerp(armRTarget.get_global_position(), ball.targetL.get_global_position(), speed)
        
        if keep_your_hands_up_timer >= 1:
            hand_l_follow.global_position = targetL
            hand_r_follow.global_position = targetR
        else:
            keep_your_hands_up_timer += 0.1
    else:
        targetL = hand_l_follow.global_position
        targetR = hand_r_follow.global_position
        
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
#    if anim_name == "Jump":
#        velocity.y = JUMP_VELOCITY
    jumping = false
        
var holdAnim = false
var throwAnim = false

var ballHoldStart
var ballHoldMid
var ballHoldT = 1

var throw_timer = 1
var squat_vector
var squat_start
var squat_end

var impulse

func throw_rock(direction):
    if touchingBall && Input.is_action_pressed("ui_accept") and !jumping and is_on_floor() and !holding and !holdAnim and !throwAnim and keep_your_hands_up_timer >= 1:
        #holding = true
        holdAnim = true
        ballHoldStart = ball.global_position
        var vector = (ballHoldStart + rockThrowTarget.global_position) / 2
        ballHoldMid = vector + Vector2.UP * 200
        ballHoldT = 0
        
        ball.freeze = true     
        ball.sleeping = true
        #hips.position.y += 100
        
        ball.get_node("CollisionShape2D").disabled = true
        ball.particles.emitting = false
        
    var dir = 1 if direction > 0 else -1 if direction < 0 else 0
        
    if holding or holdAnim:
        hips.position = lerp(hips.position, lastHipPosition + Vector2(0, hold_crouch) / scaleScalar, ballHoldT)
        
    if holding:
        hips.rotation = lerp(hips.rotation, deg_to_rad(dir * 20), 0.1)
        ball.global_position = rockThrowTarget.global_position
        ball.rotation = hips.rotation
    elif !throwAnim:
        hips.rotation = lerp(hips.rotation, deg_to_rad(0), 0.1)
    else :
        hips.position = _quadratic_bezier(squat_start, squat_vector, squat_end, throw_timer)
        ball.global_position = rockThrowTarget.global_position

        
    if holding and !Input.is_action_pressed("ui_accept"):
        holding = false
        #ball.freeze = false
        #ball.sleeping = false
        #ball.get_node("CollisionShape2D").disabled = false
        #ball.apply_central_impulse((Vector2.UP + Vector2(dir, 0) * 0.5) * throw_force)
        #hips.position.y -= 100
        
        throwAnim = true
        throw_timer = 0
        
        squat_start = hips.position
        squat_end = lastHipPosition
        squat_vector = squat_start - Vector2.UP.rotated(hips.rotation) * 200 / scaleScalar
        
        impulse = (Vector2.UP + Vector2(dir, 0) * 0.5) * throw_force
        
    if holdAnim:
        if ballHoldT >= 1:
            holdAnim = false
            holding = true
        else:
            ball.global_position = _quadratic_bezier(ballHoldStart, ballHoldMid, rockThrowTarget.global_position, ballHoldT)
            ballHoldT += 0.05
            
    if throwAnim:
        if throw_timer >= 1:
            ball.freeze = false
            ball.sleeping = false
            ball.get_node("CollisionShape2D").disabled = false
            ball.apply_central_impulse(impulse)
            
            hand_l_follow.global_position += impulse / 75
            hand_r_follow.global_position += impulse / 75
            
            keep_your_hands_up_timer = 0
            
            throwAnim = false
        else:
            throw_timer += 0.05

func play_foot_noize():
    step_noize.pitch_scale = randf_range(0.5, 1.5)
    step_noize.playing = true
        
        
