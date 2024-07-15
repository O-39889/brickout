extends Node2D


const BALL_LIMIT : int = 20;
'''
basically initially the timer is set to 15 seconds
but you can stuck it up to 35 if you collect another sticky powerup
while the first one is active
'''


const ACID_TIME : float = 20.0;


var mouse_captured := false;
var barrier;


@onready var wall_right = find_child("WallRight");
@onready var paddle : Paddle = find_child("Paddle");
# TODO: move to balls instead? idk lol might need to delegate it to somewhere else
# bc i wanna have a single common timer for acid bawls
@onready var timer_acid : Timer = find_child("AcidTimer");


var ball_packed = preload("res://scenes/Ball.tscn");
@onready var powerup_packed = preload("res://scenes/Powerup.tscn");
@onready var barrier_packed = preload("res://scenes/Barrier.tscn");

@onready var current_ball_speed_idx : Ball.BallSpeed = Ball.BallSpeed.BALL_SPEED_NORMAL;

@onready var weight_pool : Array[Powerup] = [];


## careful! this will place the topmost ball first!! probably...
var y_sort_balls_asc : Callable = func(a: Ball, b: Ball):
	if a.position.y < b.position.y:
		return true;
	return false;

var filter_stuck_balls : Callable = func(b: Ball):
	return not b.stuck;


func stuff():
	print('Hello I am in here');
	print('Hello I am in here');
	print('Hello I am in here');
	


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.ball_target_speed_idx_changed.connect(stuff);
	paddle.spawn_ball = true;
	paddle.position.x = (get_viewport_rect().size.x - paddle.width) / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;
	set_mouse_capture(true);
	for b in get_tree().get_nodes_in_group("balls"):
		b.lost.connect(_on_ball_lost);
	for b in get_tree().get_nodes_in_group("bricks"):
		b.hitted.connect(_on_brick_hit);


func set_mouse_capture(captured: bool):
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	mouse_captured = captured;


func life_lost():
	get_tree().reload_current_scene();


func add_ball(b: Ball):
	if get_tree().get_nodes_in_group('balls').size() >= BALL_LIMIT:
		return;
	# TODO: REPLACE THIS WITH EVENT BUS
	b.lost.connect(_on_ball_lost);
	add_child(b);


func add_ball_to_paddle(b: Ball):
	if get_tree().get_nodes_in_group('balls').size() >= BALL_LIMIT:
		return;
	# TODO: REPLACE THIS      WITH EVENT BUS
	b.lost.connect(_on_ball_lost);
	paddle.add_bawl(b);


func clone_balls(b: Ball, n: int):
	var angle_range : float = PI if b.stuck else TAU;
	for i in range(n):
		var new_ball : Ball = ball_packed.instantiate();
		var angle_offset : float = (i + 1) * angle_range / (n + 1);
		if b.stuck:
			new_ball.position = b.global_position;
			new_ball.position.y -= 1; # "just in case"
			new_ball.direction = Vector2.LEFT.rotated(angle_offset);
		else:
			new_ball.position = b.position;
			new_ball.direction = b.direction.rotated(angle_offset);
		add_ball(new_ball);


func murder_ball(b: Ball):
	paddle.balls.erase(b);
	b.queue_free();


func _on_ball_lost(ball: Ball):
	murder_ball(ball);
	# because the ball is queue'd free on the next frame so for now
	# we still have it in the tree so will have to wait fur the next frame
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group("balls").size() == 0:
		life_lost();


func _on_brick_hit(brick: Brick, ball: Ball):
	if brick is RegularBrick:
		if brick.durability == 1:
			if randf() < 0.33333 or true:
				var powerup := powerup_packed.instantiate();
				powerup.position = brick.position;
				powerup.collected.connect(_on_powerup_collected);
				add_child(powerup);
				if randf() < 0.5 and false:
					powerup.powerup.id = 'sticky_paddle';
					powerup.find_child("DebugLbl").text = powerup.powerup.id
		else:
			pass
	if brick is UnbreakableBrick:
		pass


func _on_powerup_collected(powerup: Powerup):
	match powerup.id:
		# GOOD
		'paddle_enlarge':
			paddle.enlarge();
		'paddle_shrink':
			paddle.shrink();
		'add_ball':
			# we will actually not even add it to the level
			# but parent it to the paddle instead
			var new_ball : Ball = ball_packed.instantiate();
			new_ball.position.y = -Ball.BALL_RADIUS;
			new_ball.position.x = paddle.width / 2;
			new_ball.direction = Vector2.UP;
			add_ball_to_paddle(new_ball);
		'triple_ball':
			# gotta go back to enums and shit i guess with the powerup ids
			# also will have to check for whether that random ball is stuck or not
			var ball_selection : Array[Ball];
			# have a lower chance of picking a non-stuck ball
			for b in get_tree().get_nodes_in_group('balls'):
				if b.stuck:
					if randf() < 0.4:
						ball_selection.append(b);
				# only check the free bawls above the paddle
				elif b.position.y <= paddle.position.y:
					ball_selection.append(b);
			# fallback (just get the first bawl available)
			if ball_selection.is_empty():
				ball_selection.append(get_tree().get_first_node_in_group('balls'));
			clone_balls(ball_selection.pick_random(), 2);
		'double_balls':
			for b in get_tree().get_nodes_in_group('balls'):
				clone_balls(b, 1);
		'sticky_paddle':
			paddle.state = Paddle.PaddleState.Sticky;
		'barrier':
			add_barrier();
		'fire_ball':
			for b in get_tree().get_nodes_in_group('balls'):
				b.state = Ball.BallState.Fire;
		'acid_ball':
			for b in get_tree().get_nodes_in_group('balls'):
				b.state = Ball.BallState.Acid;
			start_or_extend_timer(timer_acid, ACID_TIME);
		# NEUTRAL
		'ball_speed_up':
			Ball.increase_speed();
		'ball_slow_down':
			Ball.decrease_speed();
		# BAD
		'pop_ball':
			var balls_arr : Array[Ball];
			if get_tree().get_nodes_in_group('balls').size() == 1:
				return;
			for b in get_tree().get_nodes_in_group('balls'):
				if b.stuck:
					if randf() < 0.4:
						balls_arr.append(b);
				else:
					balls_arr.append(b);
			if balls_arr.is_empty():
				balls_arr.append(get_tree().get_first_node_in_group('balls'));
			balls_arr.sort_custom(y_sort_balls_asc);
			murder_ball(balls_arr[0]);
		'pop_all_balls':
			var balls_arr : Array = get_tree().get_nodes_in_group('balls');
			if balls_arr.size() == 1:
				return;
			var safe_ball : Ball = null;
			for b in balls_arr:
				if b.stuck:
					safe_ball = b;
					break;
			if safe_ball == null:
				balls_arr.sort_custom(y_sort_balls_asc);
				safe_ball = balls_arr[0];
			balls_arr.erase(safe_ball);
			for b in balls_arr:
				murder_ball(b);
		'paddle_freeze':
			paddle.state = Paddle.PaddleState.Frozen;


func start_or_extend_timer(t: Timer, set_val: float, max_val: float = set_val):
	if t.is_stopped():
		t.start(set_val);
	else:
		t.start(minf(t.time_left + set_val, max_val));


func add_barrier():
	if barrier:
		return;
	barrier = barrier_packed.instantiate();
	barrier.position.y = get_viewport_rect().size.y - (Globals.PADDLE_OFFSET / 2.0);
	barrier.hitted.connect(_on_barrier_hit);
	add_child(barrier);


func _physics_process(delta):
	pass


func _input(event):
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		get_tree().reload_current_scene();
	if event.is_action_pressed("debug_do"):
		pass
	var add_powerup : Callable = func(id: String, type: String):
		var p : PowerupNode = powerup_packed.instantiate();
		p.position = paddle.position - Vector2(0, 1) * 50 + Vector2(1, 0) * paddle.width / 2;
		p.pool = [Powerup.new(id, type)];
		p.collected.connect(_on_powerup_collected);
		add_child(p);
	if event.is_action_pressed('debug_1'):
		add_powerup.call('add_ball', 'good');
	if event.is_action_pressed('debug_2'):
		add_powerup.call('paddle_freeze', 'bad');
	if event.is_action_pressed('debug_3'):
		add_powerup.call('ball_speed_up', 'neutral');
	if event.is_action_pressed('debug_4'):
		add_powerup.call('ball_slow_down', 'neutral');
	if event.is_action_pressed('debug_5'):
		add_powerup.call('fire_ball', 'good');


func _on_barrier_hit(b: Barrier):
	barrier = null;
	b.queue_free();


func _on_acid_timer_timeout():
	for b in get_tree().get_nodes_in_group('balls'):
		if b.state == Ball.BallState.Acid:
			b.state = Ball.BallState.Normal;
