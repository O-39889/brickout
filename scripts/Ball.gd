class_name Ball extends CharacterBody2D


signal lost(ball);


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

# random data fur now
const BALL_SPEEDS = [
	390,
	600,
	810,
];

const BALL_RADIUS = 20;


static var target_speed_idx : BallSpeed = BallSpeed.BALL_SPEED_NORMAL:
	get:
		return target_speed_idx;
	set(value):
		target_speed_idx = clampi(value, BallSpeed.BALL_SPEED_SLOW, BallSpeed.BALL_SPEED_FAST);
		EventBus.ball_target_speed_idx_changed.emit();

var speed : float = BALL_SPEEDS[target_speed_idx]:
	get:
		return speed;
	set(value):
		speed = value;
		velocity = speed * direction;

var direction : Vector2 = Vector2(0, -1):
	get:
		return direction;
	set(value):
		direction = value;
		velocity = speed * direction;

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
	EventBus.ball_target_speed_idx_changed.connect(_on_target_speed_idx_changed);
	collision_shape.shape.radius = BALL_RADIUS;
	if stuck:
		process_mode = Node.PROCESS_MODE_DISABLED;


func launch():
	stuck = false;
	velocity = direction * speed;


static func increase_speed():
	target_speed_idx += 1;


static func decrease_speed():
	target_speed_idx -= 1;


func handle_collision(collision: KinematicCollision2D):
	var collider := collision.get_collider();
	if collider is Ball:
		# and here we would somehow alter another guy's velocity
		# und also avoid reduplication or idk lol
		assert(false, 'NOT IMPLEMENTED!!!! AAAAAAHHHHHHHH');
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
				collider.hit(self, 1997 if acid else 1);
		# lmao that's why you use le state pattern
		if not (collider is RegularBrick and acid):
			direction = direction.bounce(collision.get_normal());


func _physics_process(delta):
	velocity = direction * speed;
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	if position.y > get_viewport_rect().size.y + BALL_RADIUS * 4:
		lost.emit(self);
	get_window().title = str(target_speed_idx);


func _on_target_speed_idx_changed():
	speed = BALL_SPEEDS[target_speed_idx];
