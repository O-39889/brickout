class_name Ball extends CharacterBody2D


signal lost(ball);


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

# random data fur now
const BALL_SPEEDS = [
	500,
	600,
	750,	
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
	direction = Vector2(1, -1).normalized();
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
			collider.add_bawl(self);
		else:
			direction = paddle_bounce(collider, collision.get_position());
			velocity = speed * direction;
	else:
		if collider.has_method("hit"):
			collider.hit(self);
		velocity = velocity.bounce(collision.get_normal());
		direction = velocity.normalized();


func paddle_bounce(paddle: Paddle, collision_point: Vector2) -> Vector2:
	print(collision_point);
	var left : float = paddle.position.x;
	var right : float = paddle.position.x + paddle.width;
	var clamped : float = clampf(collision_point.x, left, right);
	var remapped : float = remap(clamped, left, right, -70.0, 70.0);
	return Vector2.UP.rotated(deg_to_rad(remapped));


func _physics_process(delta):
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	if position.y > get_viewport_rect().size.y + BALL_RADIUS * 4:
		lost.emit(self);
