extends Node2D;


const BALL_LIMIT : int = 20;
const ACID_TIME : float = 20.0;
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

@onready var brick_mgr := find_child('BrickManager');
@onready var powerup_mgr := find_child('PowerupManager');
# TODO: move to balls instead? idk lol might need to delegate it to somewhere else
# bc i wanna have a single common timer for acid bawls
@onready var timer_acid : Timer = find_child("AcidTimer");

@onready var current_ball_speed_idx : Ball.BallSpeed = Ball.BallSpeed.BALL_SPEED_NORMAL;

@onready var weight_pool : Array[Powerup] = [];


# Called when the node enters the scene tree for the first time.
func _ready():
	if add_paddle:
		create_paddle();
	if brick_mgr:
		brick_mgr.level = self;
	if powerup_mgr:
		powerup_mgr.level = self;
	EventBus.ball_lost.connect(_on_ball_lost);
	EventBus.barrier_hit.connect(_on_barrier_hit);


func create_paddle():
	if paddle:
		return;
	paddle = PADDLE_PACKED.instantiate();
	paddle.level = self;
	paddle.position.x = (get_viewport_rect().size.x - paddle.width) / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;
	mouse_captured = true;
	add_child(paddle);


func add_ball(b: Ball):
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return;
	add_child(b);


func add_ball_to_paddle(b: Ball):
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return;
	paddle.add_bawl(b);


func clone_balls(b: Ball, n: int):
	var angle_range : float = PI if b.stuck else TAU;
	for i in range(n):
		var new_ball : Ball = BALL_PACKED.instantiate();
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
	if paddle:
		paddle.balls.erase(b);
	b.queue_free(); # why though lol but okay


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
	await get_tree().create_timer(1.0).timeout;
	create_paddle();


func _on_ball_lost(ball: Ball):
	murder_ball(ball);
	# because the ball is queue'd free on the next frame so for now
	# we still have it in the tree so will have to wait fur the next frame
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group(&"balls").size() == 0:
		life_lost();


func _input(event):
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		get_tree().reload_current_scene();


func _on_barrier_hit():
	barrier = null;


func _on_acid_timer_timeout():
	for b in get_tree().get_nodes_in_group(&'balls'):
		if b.state == Ball.BallState.Acid:
			b.state = Ball.BallState.Normal;
