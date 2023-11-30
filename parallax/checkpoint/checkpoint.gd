extends Node2D


func _ready():
    if $Area2D:
        $Area2D.body_entered.connect(_on_checkpoint_enter)
    
    
func _on_checkpoint_enter(body):
    if $Area2D and body.is_in_group("ball"):
        $AnimatedSprite2D.modulate = Color.WHITE
        $CPUParticles2D.emitting = true
        get_tree().get_root().get_node("Main/FROGG").spawn_hat()
        $Area2D.body_entered.disconnect(_on_checkpoint_enter)
        
        $AudioStreamPlayer.play()
