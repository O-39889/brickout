class_name Ball extends CharacterBody2D


signal lost(ball);


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

# random data fur now
const BALL_SPEEDS = [
	400,
	600,
	800,
];

const BALL_RADIUS = 20;


var speed_idx : BallSpeed = BallSpeed.BALL_SPEED_NORMAL:
	get:
		return speed_idx;
	set(value):
		speed_idx = value;
		speed = BALL_SPEEDS[speed_idx];
var speed : float = BALL_SPEEDS[speed_idx];
var direction : Vector2 = Vector2(1, -1).normalized();
var stuck : bool = false;


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");


func _ready():
	collision_shape.shape.radius = BALL_RADIUS;
	if stuck:
		process_mode = Node.PROCESS_MODE_DISABLED;


func launch():
	process_mode = Node.PROCESS_MODE_INHERIT;
	stuck = false;
	velocity = direction * speed;


func increase_speed():
	speed_idx = mini(speed_idx + 1, BallSpeed.BALL_SPEED_FAST);
	speed = BALL_SPEEDS[speed_idx];
	velocity = direction * speed;


func decrease_speed():
	speed_idx = maxi(speed_idx - 1, BallSpeed.BALL_SPEED_SLOW);
	speed = BALL_SPEEDS[speed_idx];
	velocity = direction * speed;


func handle_collision(collision: KinematicCollision2D):
	var collider := collision.get_collider();
	if collider is Ball:
		# and here we would somehow alter another guy's velocity
		print("Not implemented!!!");
		pass
	if collider is Paddle:
		if collider.sticky:
			stuck = true;
			process_mode = Node.PROCESS_MODE_DISABLED;
			velocity = Vector2.ZERO;
			direction = collider.calculate_bounce_dir(collision.get_position());;
			collider.add_bawl(self);
		else:
			direction = collider.calculate_bounce_dir(collision.get_position());;
			velocity = speed * direction;
	else:
		if collider.has_method("hit"):
			collider.hit(self);
		velocity = velocity.bounce(collision.get_normal());
		direction = velocity.normalized();


func _physics_process(delta):
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	if position.y > get_viewport_rect().size.y + BALL_RADIUS * 4:
		lost.emit(self);
