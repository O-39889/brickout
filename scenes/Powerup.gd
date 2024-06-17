class_name Powerup extends CharacterBody2D


const POWERUP_GRAVITY = 100;


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = Vector2.ZERO;


func _physics_process(delta):
	velocity.y += POWERUP_GRAVITY * delta;
	var collision := move_and_collide(velocity * delta);
	if collision:
		if collision.get_collider() is Paddle:
			print(self);
			queue_free();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _draw():
	pass
