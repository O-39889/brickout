class_name Ball extends CharacterBody2D


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

enum HorizontalCooldown {
	# normal state
	Inactive,
	# detected the ball moving horizontally
	Waiting,
	# the ball is moving horizontally for at leat MAX_HORIZONTAL_TIME seconds,
	# need to change
	# apparntly I didn't need that lol
	Active,
}

const BALL_SPEEDS = [
	450,
	600,
	800,
];

const SPEED_CAP = BALL_SPEEDS[BallSpeed.BALL_SPEED_FAST] * 1.5;
const SPEED_CAP_SQUARED = SPEED_CAP * SPEED_CAP;
const BALL_RADIUS = 15;
const MAX_HORIZONTAL_TIME = 5;
const ACCELERATION = 250; # px / sec^2

static var target_speed_idx : BallSpeed = BallSpeed.BALL_SPEED_NORMAL:
	get:
		return target_speed_idx;
	set(value):
		target_speed_idx = clampi(value, BallSpeed.BALL_SPEED_SLOW, BallSpeed.BALL_SPEED_FAST);
		EventBus.ball_target_speed_idx_changed.emit();
		

static var target_speed : float:
	get:
		return BALL_SPEEDS[target_speed_idx];

# TODO: make it also check that it doesn't collide with regular bricks before
# starting the horizontal cooldown (and reset it each time it collides with
# a regular breakable brick just so that it doesn't detect being "stuck"
# while it might possibly be not stuck yet)
var horizontal_cooldown: float = MAX_HORIZONTAL_TIME;
var horizontal_state : HorizontalCooldown = HorizontalCooldown.Inactive;
var speed : float = BALL_SPEEDS[target_speed_idx];

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

var explosion_packed := preload("res://scenes/Explosion.tscn");
var last_direction : Vector2;
@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var ball_detection_area : Area2D = find_child('OtherBallDetectionArea');


func _ready():
	$VisibleOnScreenNotifier2D.rect.position = Vector2(-BALL_RADIUS * 2, -BALL_RADIUS * 2);
	$VisibleOnScreenNotifier2D.rect.size = Vector2(BALL_RADIUS * 4, BALL_RADIUS * 4);
	collision_shape.shape.radius = BALL_RADIUS;
	ball_detection_area.find_child('CollisionShape2D').shape.radius = BALL_RADIUS + 1.01;
	if stuck:
		process_mode = Node.PROCESS_MODE_DISABLED;
	else:
		await get_tree().physics_frame;
		if ball_detection_area:
			if ball_detection_area.get_overlapping_bodies().filter(func(x):
				return x is Ball and x != self).is_empty():
					set_collision_mask_value(3, true);


static func increase_speed():
	target_speed_idx += 1;


static func decrease_speed():
	target_speed_idx -= 1;


static func reset_target_speed():
	target_speed_idx = BallSpeed.BALL_SPEED_NORMAL;


## Launch the ball in the specified direction with its target speed.
func launch(direction: Vector2):
	stuck = false;
	velocity = direction.normalized() * target_speed;
	last_direction = velocity.normalized();
	await get_tree().physics_frame;
	if ball_detection_area:
		if ball_detection_area.get_overlapping_bodies().filter(
			func(x): return x is Ball and x != self
		).is_empty():
			set_collision_mask_value(3, true);
			ball_detection_area.visible = false;
			ball_detection_area.process_mode = Node.PROCESS_MODE_DISABLED;


## Change the direction of the ball, its current speed remaining the same.
func change_direction(to: Vector2):
	velocity = to.normalized() * velocity.length();


## Change the velocity by a given amount.
func apply_impulse(impulse: Vector2):
	velocity += impulse;


func handle_cloned(clones: Array[Ball]):
	if false:
		return;
		set_collision_mask_value(3, false);
		collision_shape.self_modulate = Color.BLACK;
		for ball in clones:
			ball.set_collision_mask_value(3, false);
			ball.collision_shape.self_modulate = Color.BLACK;
		get_tree().create_timer(BALL_RADIUS * 2 / target_speed).\
			timeout.connect(func():
				set_collision_mask_value(3, true);
				collision_shape.self_modulate = Color.WHITE;
				for b in clones:
					b.set_collision_mask_value(3, true)
					b.collision_shape.self_modulate = Color.WHITE);
	ball_detection_area.visible = true;
	ball_detection_area.process_mode = Node.PROCESS_MODE_INHERIT;	
	set_collision_mask_value(3, false);


# that started to look worse somehow
func handle_collision(collision: KinematicCollision2D):
	var collider := collision.get_collider();
	if collider is Ball:
		#assert(false, 'Also there was supposed to be a jumpscare in here');
		# and here we would somehow alter another guy's velocity
		# und also avoid reduplication or idk lol
		# actually might even be okay to use signals
		# just will actually generalize the signal to just include any other
		# CollisionObject2D it can collide with instead
		EventBus.ball_collision.emit(self, collider);
		#assert(false, 'NOT IMPLEMENTED!!!! AAAAAAHHHHHHHH');
	elif collider is Paddle:
		collider.handle_ball_collision(self, collision);
		if state == BallState.Fire and collider.state == Paddle.PaddleState.Frozen:
			explode_stuff();
			collider.state = Paddle.PaddleState.Normal;
	else:
		match state:
			BallState.Normal:
				if collider.has_method('hit'):
					collider.hit(self, 1);
				velocity = velocity.bounce(collision.get_normal());
			BallState.Fire:
				if collider.has_method('hit'):
					if collider is Brick:
						explode_stuff();
				velocity = velocity.bounce(collision.get_normal());
			BallState.Acid:
				if not (collider is RegularBrick):
					velocity = velocity.bounce(collision.get_normal());
				if collider.has_method('hit'):
					collider.hit(self, 1997);
	# № 1
	# Check for whether we move (almost) horizontally after le collision
	# If so, then we set the cooldown and start ticking down
	if (horizontal_state == HorizontalCooldown.Inactive and
	is_zero_approx(velocity.normalized().y)):
		horizontal_state = HorizontalCooldown.Waiting;
		horizontal_cooldown = MAX_HORIZONTAL_TIME;
	# № 2
	# After setting the state in № 1 and decrementing in № 1.5,
	# during the next collision we check if the timer runs out
	if (horizontal_state == HorizontalCooldown.Waiting
		and horizontal_cooldown <= 0):
			# if at this point we're still moving horizontally
			if is_zero_approx(velocity.normalized().y):
				# then we apply a random rotation to the direction vector
				# just so that the ball never gets stuck
				velocity = velocity.rotated(deg_to_rad(
					randf_range(1.0, 6.16) * (-1 if randf() < 0.5 else 1)));
				# and then reset the whole state thingy
				horizontal_state = HorizontalCooldown.Inactive;
			# if otherwise we are already moving not horizontally
			# then we just don't have to change the direction ourselves
			else:
				horizontal_state = HorizontalCooldown.Inactive;


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
	#modulate = Color.WHITE if get_collision_mask_value(3) else Color.BLACK;
	# btw the last direction variable is unused yet
	var velocity_dir : Vector2 = velocity.normalized();
	var scalar_speed_difference : float = (
		target_speed - velocity.length()
	);
	# to snap to the needed velocity without oscillating constantly around it
	# in small increments or something
	if abs(scalar_speed_difference) <= delta * ACCELERATION:
		velocity = velocity_dir * target_speed;
	# current speed is smaller than the target speed
	elif scalar_speed_difference > 0:
		# we will need to accelerate
		velocity += velocity_dir * ACCELERATION * delta;
	# current speed is larger than the target speed
	else:
		# will need to decelerate
		velocity -= velocity_dir * ACCELERATION * delta;
	#var speed_difference : Vector2 = (velocity_dir
		#* target_speed - velocity);
	#if speed_difference.length() <= delta * ACCELERATION:
		#velocity = velocity_dir * target_speed;
	#else:
		#velocity += ACCELERATION * delta * velocity_dir;
	
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	# № 1.5)
	# If we're waiting with a horizontal cooldown then we decrement the counter
	# that acts as a timer
	if horizontal_state == HorizontalCooldown.Waiting:
		horizontal_cooldown -= delta;
	if velocity.length_squared() > target_speed * target_speed * 2.25:
		velocity = velocity.limit_length(target_speed * 1.5);
	if not velocity.is_zero_approx():
		last_direction = velocity_dir;
	queue_redraw();


func _draw():
	var string;
	if get_parent() is Paddle:
		string = 'PDL';
	elif get_parent().name == 'BallComponent':
		string = 'BALL';
	else:
		string = 'LVL';
	string = '';
	if stuck:
		if get_parent() is Paddle:
			var pdl := get_parent() as Paddle;
			if self in pdl.persistent_balls:
				string = 'P';
			else:
				string = 'E';
	string = str(int(get_collision_mask_value(3)));
	draw_string(ThemeDB.fallback_font, Vector2.ZERO, string,HORIZONTAL_ALIGNMENT_CENTER,
	-1, 32)


func _on_target_speed_idx_changed():
	pass;


func _on_visible_on_screen_notifier_2d_screen_exited():
	await get_tree().physics_frame; # idk why lol but okay
	EventBus.ball_lost.emit(self);


func _on_other_ball_detection_area_body_exited(body):
	var bodies := ball_detection_area.get_overlapping_bodies();
	var filtered := bodies.filter(func(x): return x is Ball and not x == self)
	if filtered.is_empty():
		ball_detection_area.visible = false;
		ball_detection_area.process_mode = Node.PROCESS_MODE_DISABLED;	
		set_collision_mask_value(3, true);
