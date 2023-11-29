extends Node2D


func _ready():
    $Area2D.body_entered.connect(_on_checkpoint_enter)
    
    
func _on_checkpoint_enter(body):
    if body.is_in_group("ball"):
        $AnimatedSprite2D.modulate = Color.WHITE
        $CPUParticles2D.emitting = true
        $Area2D.body_entered.disconnect(_on_checkpoint_enter)
