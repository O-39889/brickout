class_name Paddle extends StaticBody2D


# I gave up on the BS all caps names
enum PaddleState {
	Normal,
	Sticky,
	Frozen,
	Ghost,	
};

enum PaddleSize {
	PADDLE_SIZE_TINY,
	PADDLE_SIZE_SMALL,
	PADDLE_SIZE_NORMAL,
	PADDLE_SIZE_LARGE,
	PADDLE_SIZE_HUMONGOUS,
	PADDLE_SIZE_MAX, # max enum size, not paddle size
};


const PADDLE_SIZES = [
	100,
	150,
	240,
	300,
	400,
];

const MAX_BOUNCE_ANGLES = [
	55.0,
	60.0,
	69.69696969,
	72.00001,
	75.17411852982168,
];

const STICKY_TIME: float = 15.0;
const STICKY_TIME_MAX: float = 30.000000000000004;
const FROZEN_TIME : float = 7.0;
const PADDLE_HEIGHT : float = 40;
const BALL_RELEASE_COOLDOWN_MAX : float = 0.2;
const BALL_AUTO_RELEASE_INTERVAL : float = 0.6;


var level : Node2D;
var balls : Array[Ball] = [];
var persistent_balls : Array[Ball] = [];


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var powerup_hitbox : CollisionShape2D = find_child("Area2DShape");
@onready var hitbox : RectangleShape2D = find_child('CollisionShape2D').shape;
@onready var sticky_timer : Timer = find_child('StickyTimer');
@onready var frozen_timer : Timer = find_child('FrozenTimer');
# cooldown between consecutive releases of the ball
# by clicking while in sticky state
@onready var ball_manual_timer : Timer = find_child('BallManualReleaseTimer');
# interval between consecutive releases of the stuck balls after switching from
# le sticky state to either le normal state or le frozen state
@onready var ball_auto_timer : Timer = find_child('BallAutoReleaseTimer');

var state : PaddleState = PaddleState.Normal:
	get:
		return state;
	set(value):
		state = value;
		match value:
			PaddleState.Normal:
				sticky_timer.stop();
				frozen_timer.stop();
				release_ephemeral_ball();
				ball_auto_timer.start(BALL_AUTO_RELEASE_INTERVAL);
			
			PaddleState.Sticky:
				frozen_timer.stop();
				ball_auto_timer.stop();
				Globals.start_or_extend_timer(sticky_timer, STICKY_TIME, STICKY_TIME_MAX);
			
			PaddleState.Frozen:
				sticky_timer.stop();
				Globals.start_or_extend_timer(frozen_timer, FROZEN_TIME);
				release_ephemeral_ball();
				ball_auto_timer.start(BALL_AUTO_RELEASE_INTERVAL);

var width_idx := PaddleSize.PADDLE_SIZE_NORMAL;
var width : float = PADDLE_SIZES[width_idx];


func _ready():
	ball_manual_timer.wait_time = BALL_RELEASE_COOLDOWN_MAX;
	ball_auto_timer.wait_time = BALL_AUTO_RELEASE_INTERVAL;
	assert(level != null, 'Level node not defined');
	if level == null:
		level = get_parent();
	hitbox.size.x = width;
	hitbox.size.y = PADDLE_HEIGHT;
	# it will always spawn with a ball, just for convenience
	var b : Ball = load("res://scenes/Ball.tscn").instantiate();
	add_bawl(b, true);


func add_bawl(b: Ball, persistent: bool):
	if b.get_parent() == null:
		add_child(b);
	else:
		b.reparent(self);
	b.stuck = true;
	b.position.y = -collision_shape.shape.size.y / 2 - b.BALL_RADIUS;
	balls.append(b);
	if persistent:
		persistent_balls.append(b);


func set_width(idx: PaddleSize):
	width = PADDLE_SIZES[idx];
	hitbox.size.x = width;


func enlarge():
	_change_size(true);


func shrink():
	_change_size(false);


func release_ball(ball: Ball):
	if ball not in balls:
		return;
	balls.erase(ball);
	persistent_balls.erase(ball);
	level.reparent_ball(ball);
	ball.launch(_bounce_ball_dir_controlled(ball.global_position));


func release_ephemeral_ball():
	var to_release : Array[Ball] = balls.filter(
		func(ball: Ball):
			return ball not in persistent_balls
	);
	if to_release.is_empty():
		return
	release_ball(to_release[0]);


func handle_ball_collision(b: Ball, collision: KinematicCollision2D) -> void:
	match state:
		PaddleState.Normal:
			var ball_dir := _bounce_ball_dir_controlled(collision.get_position());
			b.change_direction(ball_dir);
		PaddleState.Sticky:
			# don't think I'll need any of that since I'll just do that
			# when we release it lol
			#var ball_dir := _bounce_ball_dir_controlled(collision.get_position());
			#b.change_direction(ball_dir);
			# if we hold down le left mouse button then it should just
			# bounce them off instantly
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				var ball_dir := _bounce_ball_dir_controlled(collision.get_position());
				b.change_direction(ball_dir);
			else:
				add_bawl(b, false);
		PaddleState.Frozen:
			# other stuff to handle? idk just bouncing it lol
			# actaully might trigger an explosion if le ball is fire ball
			# and then unfreeze le paddle
			b.change_direction(b.velocity.bounce(collision.get_normal()));
		# I'm prolly not even gonna add a ghost state anyway


func _bounce_ball_dir_controlled(collision_position: Vector2) -> Vector2:
	var left: float = position.x - width / 2;
	var right: float = position.x + width / 2;
	var clamped: float = clampf(collision_position.x, left, right);
	var max_angle : float = MAX_BOUNCE_ANGLES[width_idx];
	var remapped: float = remap(clamped, left, right, -max_angle, max_angle);
	return Vector2.UP.rotated(deg_to_rad(remapped));


func _bounce_ball_dir_uncontrolled(ball_direction: Vector2, normal: Vector2) -> Vector2:
	return ball_direction.bounce(normal);


func _change_size(should_enlarge: bool):
	var delta: int;
	if should_enlarge:
		delta = 1;
	else:
		delta = -1;
	var old_width := width;
	width_idx = clampi(width_idx + delta, PaddleSize.PADDLE_SIZE_TINY, PaddleSize.PADDLE_SIZE_MAX - 1);
	set_width(width_idx);
	for b in balls:
		# "stretch" or "shrink" the balls' positions across the paddle
		# when its size changes 
		b.position.x = remap(b.position.x, -old_width / 2, old_width / 2,
		-width / 2, width / 2);


func _input(event: InputEvent):
	match state:
		PaddleState.Normal, PaddleState.Sticky, PaddleState.Ghost:
			## TODO: FORGOT
			# Oh wait I remmeberd
			# Like, make it so that if mouse btn is held down in le sticky
			# state then it would automatically release any balls colliding
			# with it on the same frame (would probably need to put code
			# for that in the handling ball collision code though)
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				if event is InputEventMouseMotion:
					position.x += event.relative.x * Globals.MOUSE_SENSITIVITY;
					position.x = clamp(position.x, width / 2,
						get_viewport_rect().size.x - width / 2);
				if event is InputEventMouseButton:
					if (event.button_index == MOUSE_BUTTON_LEFT
					and event.pressed and balls.size() > 0
					and ball_manual_timer.is_stopped()):
						release_ball(balls[0]);
						ball_manual_timer.start(BALL_RELEASE_COOLDOWN_MAX);
		PaddleState.Frozen:
			## TODO: IDEA!!!
			# MAKE IT SO THAT WHEN YOU FLICK THE MOUSE CURSOR REALLY FAST IT WILL
			# SLOWLY INCH TOWARD THAT DIRECTION BUT NOT CONSTANTLY BUT JUST
			# IMPULSE-LIKE IDK
			# basically the paddle is still not fully stopped but it moves, like,
			# really really really slowly, and you can also flick le mouse
			# really fast to make it move a little bit faster
			# but that all is fur later
			pass


func _on_sticky_timer_timeout():
	state = PaddleState.Normal;


func _on_frozen_timer_timeout():
	state = PaddleState.Normal;


func _on_ball_manual_release_timer_timeout():
	pass # Replace with function body.


func _on_ball_auto_release_timer_timeout():
	release_ephemeral_ball();
	# we look only at ephemeral (non-persistent) balls
	# so here we remove persistent balls and see if there's no ephemeral balls left
	if balls.filter(func(ball: Ball): return ball not in persistent_balls).is_empty():
		# in which case we just ignore and don't continue
		pass
	# otherwise just restart le timer
	else:
		ball_auto_timer.start(BALL_AUTO_RELEASE_INTERVAL);
	
