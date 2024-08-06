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
const BALL_RELEASE_COOLDOWN_MAX : float = 0.15;
const BALL_AUTO_RELEASE_INTERVAL : float = BALL_RELEASE_COOLDOWN_MAX * 2;

# the relative position of the left gun mounted on the paddle
# (with 0 being the paddle's left edge and 1 being the paddle's right edge)
# the relative position of the right gun would just be 1 - GUN_POS
const GUN_POS : float = 0.1;


var level : Node2D;
var balls : Array[Ball] = [];
var persistent_balls : Array[Ball] = [];

var my_velocity : float = float(((((((0.0 as float) as float) as float) as float) as float) as float) as float) as float;
var last_tick_position : Vector2;
var slip : bool = false;


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

var has_gun : bool = false;
var gun_equipped : ProjectileAttributes = null;
var ammo_left : int = 0;
var left_gun : Node2D = null;
var right_gun : Node2D = null;
# Whether to shoot out of the left or out of the right gun next
var left_right_toggle : bool = false;

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
	last_tick_position = position;


func add_bawl(b: Ball, persistent: bool):
	b.stuck = true;
	if b.get_parent() == null:
		add_child(b);
	else:
		b.reparent(self);
	b.position.y = -collision_shape.shape.size.y / 2 - b.BALL_RADIUS;
	balls.append(b);
	if persistent:
		persistent_balls.append(b);


func _physics_process(delta):
	if not slip:
		my_velocity = (position.x - last_tick_position.x) / delta;
	last_tick_position = position;
	$DebugLbl.text = String.num(ammo_left, 9);
	$DebugLbl.global_position.x = 810;
	if slip:
		if absf(my_velocity) < 2.5:
			my_velocity = 0;
		var accel = delta * my_velocity * my_velocity * 0.00025;
		if accel > 300 * delta:
			$DebugLbl.modulate = Color.RED;
		else:
			$DebugLbl.modulate = Color.BLUE;
		if my_velocity < 0:
			my_velocity += max(accel, 350 * delta);
		elif my_velocity > 0:
			my_velocity -= max(accel, 350 * delta);
		var collision := move_and_collide(Vector2(my_velocity, 0) * delta);
		if collision:
			var collider = collision.get_collider();
			if collider is StaticBody2D:
				if collider.is_in_group(&'walls'):
					my_velocity *= -1;

	position.x = clamp(position.x, width / 2, get_viewport_rect().size.x - width / 2);


#region Width

func set_width(idx: PaddleSize):
	width = PADDLE_SIZES[idx];
	hitbox.size.x = width;


func enlarge():
	_change_size(true);


func shrink():
	_change_size(false);

#endregion


func equip_gun(gun_type: Projectile.GunType):
	reset_gun();
	has_gun = true;
	match gun_type:
		Projectile.GunType.Regular:
			gun_equipped = load("res://resources/projectiles/bullet.tres");
			ammo_left = gun_equipped.amount;
			left_gun = CollisionShape2D.new();
			left_gun.disabled = true;
			right_gun = CollisionShape2D.new();
			right_gun.disabled = true;
			var rect := RectangleShape2D.new();
			rect.size = Vector2(15, 40);
			left_gun.debug_color = Color.BISQUE;
			right_gun.debug_color = Color.BISQUE;
			left_gun.shape = rect;
			right_gun.shape = rect;
			add_child(left_gun);
			add_child(right_gun);
		Projectile.GunType.Rocket:
			pass
	set_gun_positions();


func set_gun_positions():
	if left_gun:
		left_gun.position.x = -width / 2 + width * GUN_POS;
		left_gun.position.y = -PADDLE_HEIGHT + 8;
	if right_gun:
		right_gun.position.x = -width / 2 + width * (1 - GUN_POS);
		right_gun.position.y = -PADDLE_HEIGHT + 8;
		right_gun.modulate = Color.BLACK;


func reset_gun():
	has_gun = false;
	gun_equipped = null;
	ammo_left = 0;
	if left_gun:
		remove_child(left_gun);
		left_gun.queue_free();
		left_gun = null;
	if right_gun:
		remove_child(right_gun);
		right_gun.queue_free();
		right_gun = null;
	left_right_toggle = false;


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
	set_gun_positions();


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
				if event is InputEventMouseMotion and not slip:
					position.x += event.relative.x * Globals.MOUSE_SENSITIVITY;
					position.x = clamp(position.x, width / 2,
						get_viewport_rect().size.x - width / 2);
				if event is InputEventMouseButton:
					if (event.button_index == MOUSE_BUTTON_LEFT
					and event.pressed and balls.size() > 0
					and ball_manual_timer.is_stopped()):
						release_ball(balls[0]);
						ball_manual_timer.start(BALL_RELEASE_COOLDOWN_MAX);
					elif event.button_index == MOUSE_BUTTON_RIGHT\
					and event.pressed and has_gun:
						var bullet = load('res://scenes/bullet.tscn').instantiate();
						bullet.position.x = global_position.x - width / 2\
						+ width * (1 - GUN_POS if left_right_toggle else GUN_POS);
						bullet.position.y = global_position.y - PADDLE_HEIGHT - 10;
						left_right_toggle = not left_right_toggle;
						level.add_child(bullet);
						ammo_left -= 1;
						if ammo_left == 0:
							reset_gun();
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
	
