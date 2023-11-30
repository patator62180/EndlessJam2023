extends RigidBody2D

#extends Node2D

@export var shadow: Sprite2D
@export var frog: CharacterBody2D

@export var particles: CPUParticles2D

var handsTarget

var targetL
var targetR

func _ready():
    handsTarget = $"HandTargets"
    targetL = $"HandTargets/HandL"
    targetR = $"HandTargets/HandR"
    
    max_contacts_reported = 3
    

func _process(delta):
    shadow.rotation = -rotation
    handsTarget.look_at(frog.global_position)
    
    handsTarget.rotate(deg_to_rad(180))

func _integrate_forces(state):
    if linear_velocity.length() <= 50:
        particles.emitting = false
        return
        
    for i in range(state.get_contact_count()):
        if (state.get_contact_collider_object(i).name == "WorldPolygonBody"):
            particles.global_position = state.get_contact_local_position(i)
            particles.emitting = true
            return
            
    particles.emitting = false
    
    
