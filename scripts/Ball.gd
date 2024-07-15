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
var stuck : bool = false:
	get:
		return stuck;
	set(value):
		stuck = value;
		if value:
			process_mode = Node.PROCESS_MODE_DISABLED;
		else:
			process_mode = Node.PROCESS_MODE_INHERIT;
## TODO: REPLACE THOSE TWO WITH A SINGLE STATE ENUM THINGY
var acid: bool = false:
	get:
		return acid;
	set(value):
		acid = value;
		if value:
			collision_shape.debug_color.h = (100.0 / 360.0);
			fire_ball = false;
		elif not fire_ball:
			collision_shape.debug_color.h = (189.0 / 360.0);

var fire_ball : bool = false:
	get:
		return fire_ball;
	set(value):
		fire_ball = value;
		if value:
			collision_shape.debug_color.h = (20.0 / 360.0);
			acid = false;
		elif not acid:
			collision_shape.debug_color.h = (189.0 / 360.0);


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var explosion_packed := preload("res://scenes/Explosion.tscn");


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
		# und also avoid reduplication or idk lol
		print("Not implemented!!!");
		pass
	if collider is Paddle:
		collider.handle_ball_collision(self, collision);
	else:
		if collider.has_method("hit"):
			if collider is Brick and fire_ball:
				var explosion : Explosion = explosion_packed.instantiate();
				add_child(explosion);
				explosion.exclude_parent = true;
				explosion.force_shapecast_update();
				for c in explosion.collision_result:
					c.collider.hit(self, 999);
				explosion.queue_free();
				fire_ball = false;
			else:
				collider.hit(self, 999 if acid else 1);
		if not (collider is RegularBrick and acid):
			velocity = velocity.bounce(collision.get_normal());
			direction = velocity.normalized();


func _physics_process(delta):
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	if position.y > get_viewport_rect().size.y + BALL_RADIUS * 4:
		lost.emit(self);
