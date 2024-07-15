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


var balls : Array[Ball] = [];
# whether a paddle should spawn a ball on itself or not when created
var spawn_ball;


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");
@onready var powerup_hitbox : CollisionShape2D = find_child("Area2DShape");
@onready var sticky_timer : Timer = find_child('StickyTimer');
@onready var frozen_timer : Timer = find_child('FrozenTimer');
@onready var state : PaddleState = PaddleState.Normal:
	get:
		return state;
	set(value):
		state = value;
		match value:
			PaddleState.Normal:
				sticky_timer.stop();
				frozen_timer.stop();
			
			PaddleState.Sticky:
				frozen_timer.stop();
				Globals.start_or_extend_timer(sticky_timer, STICKY_TIME, STICKY_TIME_MAX);
			
			PaddleState.Frozen:
				sticky_timer.stop();
				Globals.start_or_extend_timer(frozen_timer, FROZEN_TIME);

@onready var width_idx := PaddleSize.PADDLE_SIZE_NORMAL;
@onready var width : float = PADDLE_SIZES[width_idx];


func _ready():
	collision_shape.shape.b.x = width;
	powerup_hitbox.position.x = width / 2;
	powerup_hitbox.shape.size.x = width;
	# just make it ALWAYS spawn with a bawl
	var b : Ball = load("res://scenes/Ball.tscn").instantiate();
	b.position.x = width / 2.0;
	b.position.y = -b.BALL_RADIUS;
	b.direction = Vector2.UP;
	add_bawl(b);


func add_bawl(b: Ball):
	if b.get_parent() == null:
		add_child(b);
	else:
		b.reparent(self);
	b.stuck = true;
	balls.append(b);	


# would really need to change that stuff so that the paddle is also centered
# even just for my own convenience
func set_width(idx: PaddleSize):
	var old_center := position.x + width / 2;
	width = PADDLE_SIZES[idx];
	collision_shape.shape.b.x = width;
	position.x = clamp(old_center - width / 2, 0, get_viewport_rect().size.x - width);
	powerup_hitbox.position.x = width / 2;
	powerup_hitbox.shape.size.x = width;


func enlarge():
	_change_size(true);


func shrink():
	_change_size(false);


func handle_ball_collision(b: Ball, collision: KinematicCollision2D) -> void:
	match state:
		PaddleState.Normal:
			var ball_dir := _bounce_ball_dir_controlled(b.velocity, collision.get_position());
			b.direction = ball_dir;
		PaddleState.Sticky:
			var ball_dir := _bounce_ball_dir_controlled(b.velocity, collision.get_position());
			b.direction = ball_dir;
			add_bawl(b);
		PaddleState.Frozen:
			# other stuff to handle? idk just bouncing it lol
			# actaully might trigger an explosion if le ball is fire ball
			# and then unfreeze le paddle
			b.direction = b.direction.bounce(collision.get_normal());
		# I'm prolly not even gonna add a ghost state anyway


func _bounce_ball_dir_controlled(ball_velocity: Vector2, collision_position: Vector2) -> Vector2:
	var left: float = position.x;
	var right: float = position.x + width;
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
		b.position.x = remap(b.position.x, 0, old_width, 0, width);


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
					position.x = clamp(position.x, 0, get_viewport_rect().size.x - width);
				if event is InputEventMouseButton:
					if (event.button_index == MOUSE_BUTTON_LEFT
					and event.pressed and balls.size() > 0):
						# release the bawl	
						var first_bawl : Ball = balls.pop_front();
						first_bawl.reparent(get_parent());
						first_bawl.launch();
						pass
		PaddleState.Frozen:
			## TODO: IDEA!!!
			# MAKE IT SO THAT WHEN YOU YANK THE MOUSE CURSOR REALLY FAST IT WILL
			# SLOWLY INCH TOWARD THAT DIRECTION BUT NOT CONSTANTLY BUT JUST
			# IMPULSE-LIKE IDK
			# basically the paddle is still not fully stopped but it moves, like,
			# really really really slowly, and you can also jerk le mouse
			# really fast to make it move a little bit faster
			# but that all is fur later
			pass


func _process(delta: float):
	match state:
		PaddleState.Normal:
			$DebugLbl.text = '';
		PaddleState.Sticky:
			$DebugLbl.text = String.num(sticky_timer.time_left, 2);
		PaddleState.Frozen:
			$DebugLbl.text = String.num(frozen_timer.time_left, 2);


func _on_sticky_timer_timeout():
	state = PaddleState.Normal;


func _on_frozen_timer_timeout():
	state = PaddleState.Normal;
