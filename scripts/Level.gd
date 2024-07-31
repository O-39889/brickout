extends Node2D;


const BALL_LIMIT : int = 20;
const BARRIER_PACKED : PackedScene = preload("res://scenes/Barrier.tscn");
const BALL_PACKED : PackedScene = preload('res://scenes/Ball.tscn');
const PADDLE_PACKED : PackedScene = preload("res://scenes/Paddle.tscn");


var mouse_captured : bool = false:
	get:
		return mouse_captured;
	set(value):
		mouse_captured = value;
		if value:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;

var barrier : Barrier;


@export var add_paddle : bool = true; # ????? bruh lmao please stop
## Base chance to generate a power-up after destroying a regular brick.
@export_range(0.0, 1.0) var powerup_chance : float = 0.1;
@export var pool_type : Global.PowerupPoolType = Global.PowerupPoolType.Default;

var paddle : Paddle;

var brick_component: Node2D;
var powerup_component: Node2D;
var ball_component: Node2D;


@onready var current_ball_speed_idx : Ball.BallSpeed = Ball.BallSpeed.BALL_SPEED_NORMAL;

@onready var weight_pool : Array[Powerup] = [];


# Called when the node enters the scene tree for the first time.
func _ready():
	if add_paddle:
		create_paddle();
	EventBus.ball_lost.connect(_on_ball_lost);
	EventBus.barrier_hit.connect(_on_barrier_hit);


func _enter_tree():
	# hmm
	# this is called before the level _ready()
	# and even before the children's _ready()
	# but at this point the manager nodes already exist
	# so that might be where we infuse them with le level
	brick_component = find_child('BrickComponent');
	if brick_component:
		brick_component.level = self;
	powerup_component = find_child('PowerupComponent');
	if powerup_component:
		powerup_component.level = self;
	ball_component = find_child('BallComponent');
	if ball_component:
		ball_component.level = self;


func create_paddle():
	if paddle:
		return;
	paddle = PADDLE_PACKED.instantiate();
	paddle.level = self;
	paddle.position.x = get_viewport_rect().size.x / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;
	mouse_captured = true;
	add_child(paddle);


func add_ball(b: Ball):
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return;
	reparent_ball(b);


func reparent_ball(ball: Ball):
	if ball.get_parent():
		if ball_component:
			ball.reparent(ball_component);
		else:
			ball.reparent(self);
	else:
		if ball_component:
			ball_component.add_child(ball);
		else:
			add_child(ball);


func add_ball_to_paddle(b: Ball):
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return;
	paddle.add_bawl(b);


func clone_balls(b: Ball, n: int):
	var angle_range : float = PI if b.stuck else TAU;
	var cloned_balls : Array[Ball] = [];
	for i in range(n):
		var new_ball : Ball = BALL_PACKED.instantiate();
		var angle_offset : float = (i + 1) * angle_range / (n + 1);
		var launch_vector : Vector2;
		if b.stuck:
			new_ball.position = b.global_position;
			new_ball.position.y -= 1; # "just in case"
			launch_vector = Vector2.LEFT.rotated(angle_offset);
		else:
			new_ball.position = b.position;
			launch_vector = b.velocity.normalized().rotated(angle_offset);
		add_ball(new_ball);
		cloned_balls.append(new_ball);
		new_ball.launch(launch_vector);
	b.handle_cloned(cloned_balls);


func murder_ball(b: Ball):
	if paddle:
		paddle.balls.erase(b);
	b.queue_free();


func add_barrier():
	if barrier:
		return;
	barrier = BARRIER_PACKED.instantiate();
	barrier.position.y = get_viewport_rect().size.y - (Globals.PADDLE_OFFSET / 2.0);
	add_child(barrier);


func life_lost():
	Ball.reset_target_speed();
	paddle.queue_free();
	paddle = null;
	EventBus.life_lost.emit();
	await get_tree().create_timer(1.0).timeout;
	create_paddle();


func _on_ball_lost(ball: Ball):
	murder_ball(ball);
	# because the ball is queue'd free on the next frame so for now
	# we still have it in the tree so will have to wait fur the next frame
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group(&"balls").is_empty():
		life_lost();


func _input(event):
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		get_tree().reload_current_scene();
	if event.is_action_pressed("debug_1"):
		powerup_component._request_powerup('double_balls',
			paddle.position - Vector2(0, 69));
	if event.is_action_pressed("debug_2"):
		powerup_component._request_powerup('triple_ball',
			paddle.position - Vector2(0, 69));
	if event.is_action_pressed('debug_3'):
		powerup_component._request_powerup('acid_ball',
			paddle.position - Vector2(0, 69));
	if event.is_action_pressed('debug_4'):
		Engine.time_scale = 1.0;


func _on_barrier_hit():
	barrier = null;
