extends Sprite2D

const speed = 500

func _physics_process(delta):
	if Input.is_action_pressed("move_right"):
		position.x += speed * delta		
	if Input.is_action_pressed("move_left"):
		position.x -= speed * delta		
	if Input.is_action_pressed("move_up"):
		position.y -= speed * delta
	if Input.is_action_pressed("move_down"):
		position.y += speed * delta
