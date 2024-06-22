class_name Powerup extends CharacterBody2D


const POWERUP_GRAVITY = 150;
const INITIAL_SPEED = 200;


# Called when the node enters the scene tree for the first time.
func _ready():
	velocity = get_launch_vector();


func _physics_process(delta):
	velocity.y += POWERUP_GRAVITY * delta;
	var collision := move_and_collide(velocity * delta);
	if collision:
		if collision.get_collider() is Paddle:
			print(self);
			queue_free();


func get_launch_vector() -> Vector2:
	'''
	so, instead of suffering through analytical methods with that
	apparently implicit function/equation, I would instead use numerical
	methods, something like this:
		1) initial angle range is let's say from 50 to 90 degrees
			* for the rightward direction, we rotate Vector2.RIGHT CCW
			* for the leftward direction, we rotate Vector2.LEFT CW
		2) we compute the horizontal distance the body travels at the min angle
		if it's fine then we set it as the lower bound
		3) otherwise we compute the distance at the midpoint between
		the two angles and see whether it's still outside the screen bounds
			* if it's too small then we do the same thing with the midpoint of
			the range with a smaller angle
			* if it overshoots then we redo that with the range from the larger
			angle (so basically this whole thing is kind of a binary search)
			* and if it's within the tolerance threshold (let's say this is 1 px)
			then we set the lower bound as that angle
		4) we do that with both sides and get the lower angle bounds from left
		and right side, with both ranges touching at 90 degrees exactly upward
		then we pick a random angle out of that range
		and rotate the initial speed vector by that angle
	'''
	return Vector2.UP * INITIAL_SPEED;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _draw():
	pass
