extends Node2D


var mouse_captured := false;

@onready var wall_right = find_child("WallRight");
@onready var paddle = find_child("Paddle");
@onready var ball_packed = preload("res://scenes/Ball.tscn");


# Called when the node enters the scene tree for the first time.
func _ready():
	paddle.position.x = (get_viewport_rect().size.x - paddle.width) / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;


func add_and_launch_ball(pos: Vector2, dir: Vector2 = Vector2(1,-1).normalized()):
	var ball = ball_packed.instantiate();
	ball.position = pos;
	add_child(ball);


func launch_ball(ball: CharacterBody2D, dir: Vector2 = Vector2(1,1).normalized()):
	pass


func _input(event):
	if not mouse_captured:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				add_and_launch_ball(event.position);
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		set_mouse_capture(not mouse_captured);
	if event.is_action_pressed("debug_do"):
		pass


func set_mouse_capture(captured: bool):
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	mouse_captured = captured;
