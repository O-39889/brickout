extends Node2D


var mouse_captured := false;

@onready var wall_right = find_child("WallRight");
@onready var paddle : Paddle = find_child("Paddle");
@onready var ball_packed = preload("res://scenes/Ball.tscn");
@onready var powerup_packed = preload("res://scenes/Powerup.tscn");


## careful! this will place the topmost ball first!! probably...
var y_sort_balls_asc : Callable = func(a: Ball, b: Ball):
	if a.position.y < b.position.y:
		return true;
	return false;

var filter_stuck_balls : Callable = func(b: Ball):
	return not b.stuck;


# Called when the node enters the scene tree for the first time.
func _ready():
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
	b.lost.connect(_on_ball_lost);
	add_child(b);


func add_ball_to_paddle(b: Ball):
	b.lost.connect(_on_ball_lost);
	paddle.add_bawl(b);


func clone_balls(b: Ball, n: int):
	var angle_range : float = TAU if b.stuck else 2.0 * TAU;
	for i in range(n):
		pass
		var new_ball : Ball = ball_packed.instantiate();
		new_ball.position = b.position;
		if b.stuck:
			new_ball.position.y -= 1;
			# i think it's clockwise
			new_ball.velocity = b.speed * Vector2.LEFT.rotated((i + 1) * (angle_range / (n + 1)));
			new_ball.direction = new_ball.velocity.normalized();
		else:
			new_ball.velocity = b.velocity.rotated((i + 1) * (angle_range / (n + 1)));
			new_ball.direction = b.velociy.normalized();
		add_ball(new_ball);


func _on_ball_lost(ball: Ball):
	print('Lost ball ' + str(ball));
	ball.queue_free();
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
				powerup.powerup.id = [
				'add_ball',
				'triple_ball',
				'double_balls',
				'pop_ball',
				][randi_range(0, 3)];
				powerup.find_child('DebugLbl').text = powerup.powerup.id;
		else:
			pass
	if brick is UnbreakableBrick:
		pass


func _on_powerup_collected(node: Powerup, powerup: Dictionary):
	match powerup.id:
		# GOOD
		'paddle_enlarge':
			paddle.change_size(true);
		'paddle_shrink':
			paddle.change_size(false);
		'add_ball':
			# we will actually not even add it to the level
			# but parent it to the paddle instead
			var new_ball : Ball = ball_packed.instantiate();
			new_ball.position = paddle.position - Vector2(0,1) * Ball.BALL_RADIUS;
			new_ball.stuck = true;
			add_ball_to_paddle(new_ball);
		'triple_ball':
			# gotta go back to enums and shit i guess with the powerup ids
			# also will have to check for whether that random ball is stuck or not
			var random_ball : Ball = get_tree().get_nodes_in_group('balls')[randi_range(
				0, get_tree().get_nodes_in_group('balls').size() - 1
			)];
			var new_balls : Array[Ball];
			# bruh
			for i in range(2):
				new_balls.append(ball_packed.instantiate());
				new_balls.back().position = random_ball.position;
				new_balls.back().velocity = random_ball.velocity.rotated((i + 1) * 2.0 * TAU / 3.0);
				new_balls.back().direction = random_ball.direction.rotated((i + 1) * 2.0 * TAU / 3.0);
			for b in new_balls:
				add_ball(b);
				# the same stuck check again
				# actually might even actually just create a function that would
				# just for a given N create N balls aroond a ball
				# it's just that in case of double_balls it will hav to be
				# done for every existing ball
		'double_balls':
			for b in get_tree().get_nodes_in_group('balls'):
				var new_ball : Ball = ball_packed.instantiate();
				new_ball.position = b.position;
				new_ball.velocity = -b.velocity;
				new_ball.direction = -b.direction;
				add_ball(new_ball);
		# NEUTRAL
		# BAD
		'pop_ball':
			var balls_arr := get_tree().get_nodes_in_group('balls').duplicate();
			if balls_arr.size() == 1:
				return;
			balls_arr.sort_custom(y_sort_balls_asc);
			balls_arr = balls_arr.filter(filter_stuck_balls);
			print('Sorted bawls:');
			for b in balls_arr:
				print(b.position);
			balls_arr[0].queue_free();
			


func _input(event):
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		get_tree().reload_current_scene();
	if event.is_action_pressed("debug_do"):
		pass
