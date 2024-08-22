class_name Level extends Node2D;


enum LevelCompletionState {
	None,
	Clear,
	Lost,
	GameOver,
};


const BALL_PACKED : PackedScene = preload('res://scenes/Ball.tscn');
const PADDLE_PACKED : PackedScene = preload("res://scenes/Paddle.tscn");


@export var BALL_LIMIT : int = 20;

var mouse_captured : bool = false:
	get:
		return mouse_captured;
	set(value):
		mouse_captured = value;
		if value:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;


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

var state : LevelCompletionState = LevelCompletionState.None;


# Called when the node enters the scene tree for the first time.
func _ready():
	if add_paddle:
		create_paddle();
	$Walls/WallRight.position.x = get_viewport_rect().size.x;


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
		
	paddle = find_child('Paddle');
	if paddle:
		paddle.level = self;


func create_paddle():
	if paddle:
		return;
	paddle = PADDLE_PACKED.instantiate();
	paddle.level = self;
	paddle.position.x = get_viewport_rect().size.x / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;
	mouse_captured = true;
	add_child(paddle);


## Returns true if the adding was successful (the amount of balls is below
## the limit), false otherwise
func add_ball(b: Ball) -> bool:
	b.is_finish_state = (state == Level.LevelCompletionState.Clear);
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return false;
	reparent_ball(b);
	return true;


## Returns true if the adding was successful (the amount of balls is below
## the limit), false otherwise
func add_ball_to_paddle(b: Ball, persistent: bool):
	b.is_finish_state = (state == Level.LevelCompletionState.Clear);
	if get_tree().get_nodes_in_group(&'balls').size() >= BALL_LIMIT:
		return false;
	paddle.add_bawl(b, persistent);
	return true;


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


func activate_sticky_powerup():
	pass


func activate_acid_powerup():
	pass


func activate_freeze_powerup():
	pass


func finish():
	if state != Level.LevelCompletionState.None:
		return;
	state = Level.LevelCompletionState.Clear;
	EventBus.level_cleared.emit();
	print('Win');
