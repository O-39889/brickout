class_name Ball extends CharacterBody2D


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

# random data fur now
const BALL_SPEEDS = [
	380,
	500,
	700,	
];

const BALL_RADIUS = 20;


var speed := BALL_SPEEDS[BallSpeed.BALL_SPEED_NORMAL];
var direction : Vector2 = Vector2(1, -1).normalized();
var stuck : bool = false;


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");


func _ready():
	if stuck:
		process_mode = Node.PROCESS_MODE_DISABLED;
	collision_shape.shape.radius = BALL_RADIUS;


func launch():
	process_mode = Node.PROCESS_MODE_INHERIT;
	stuck = false;
	direction = Vector2(1, -1);
	velocity = direction * speed;


func handle_collision(collision: KinematicCollision2D):
	var new_vel := velocity.bounce(collision.get_normal());
	var collider := collision.get_collider();
	if collider is Ball:
		# and here we would somehow alter another guy's velocity
		print("Not implemented!!!");
		pass
	if collider is Paddle:
		if collider.sticky or true:
			stuck = true;
			process_mode = Node.PROCESS_MODE_DISABLED;
			velocity = Vector2.ZERO;
			collider.add_bawl(self);
			return;
		new_vel = paddle_bounce(collider);
		new_vel = velocity.bounce(collision.get_normal());
	velocity = new_vel;
	direction = velocity.normalized();		


func paddle_bounce(paddle: Paddle) -> Vector2:
	return Vector2.ZERO;


func _physics_process(delta):
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	else:
		pass;
