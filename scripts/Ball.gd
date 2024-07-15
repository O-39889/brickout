class_name Ball extends CharacterBody2D


signal lost(ball);


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

enum BallState {
	Normal,
	Fire,
	Acid,
}

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


var state: BallState = BallState.Normal:
	get:
		return state;
	set(value):
		state = value;
		match value:
			BallState.Normal:
				collision_shape.debug_color.h = (189.0 / 360.0);
			BallState.Fire:
				collision_shape.debug_color.h = (20.0 / 360.0);
			BallState.Acid:
				collision_shape.debug_color.h = (100.0 / 360.0);


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
var explosion_packed := preload("res://scenes/Explosion.tscn");


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


# that started to look worse somehow
func handle_collision(collision: KinematicCollision2D):
	var collider := collision.get_collider();
	if collider is Ball:
		# and here we would somehow alter another guy's velocity
		# und also avoid reduplication or idk lol
		assert(false, 'NOT IMPLEMENTED!!!! AAAAAAHHHHHHHH');
	elif collider is Paddle:
		collider.handle_ball_collision(self, collision);
		if state == BallState.Fire:
			explode_stuff();
			if collider.state == Paddle.PaddleState.Frozen:
				collider.state = Paddle.PaddleState.Normal;
	else:
		match state:
			BallState.Normal:
				if collider.has_method('hit'):
					collider.hit(self, 1);
				direction = direction.bounce(collision.get_normal());
			BallState.Fire:
				if collider.has_method('hit'):
					if collider is Brick:
						explode_stuff();
				direction = direction.bounce(collision.get_normal());
			BallState.Acid:
				if not (collider is RegularBrick):
					direction = direction.bounce(collision.get_normal());
				if collider.has_method('hit'):
					collider.hit(self, 1997);


func generate_explosion() -> Array:
	var explosion : Explosion = explosion_packed.instantiate();
	explosion.exclude_parent = true;
	add_child(explosion);
	explosion.force_shapecast_update();
	var result = explosion.collision_result;
	explosion.queue_free();
	return result;


func explode_stuff():
	for c in generate_explosion():
		c.collider.hit(self, 1997);
	state = BallState.Normal;


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
